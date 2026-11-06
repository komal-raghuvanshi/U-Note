import os
import tempfile
import unittest
from datetime import datetime
from io import BytesIO
from unittest.mock import MagicMock, patch

from flask import Flask

from backend.auth_utils import create_auth_token
from backend.routes import resources


class ResourceRouteTests(unittest.TestCase):
    def setUp(self):
        self.upload_directory = tempfile.TemporaryDirectory()
        self.upload_folder_patch = patch.object(
            resources, "UPLOAD_FOLDER", self.upload_directory.name
        )
        self.upload_folder_patch.start()
        self.addCleanup(self.upload_folder_patch.stop)
        self.addCleanup(self.upload_directory.cleanup)

        self.app = Flask(__name__)
        self.app.config["SECRET_KEY"] = "test-secret-for-resource-tests"
        self.app.register_blueprint(resources.resources_bp)
        self.client = self.app.test_client()

    def auth_headers(self, user_id):
        with self.app.app_context():
            token = create_auth_token(user_id)
        return {"Authorization": f"Bearer {token}"}

    def test_shared_resources_are_filtered_by_owner_and_include_metadata(self):
        filename = "owned-resource.pdf"
        with open(os.path.join(self.upload_directory.name, filename), "wb") as file:
            file.write(b"resource content")

        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 9,
            "title": "Study notes",
            "resource_url": f"/uploads/{filename}",
            "type": "PDF Notes",
            "description": "Notes for all units",
            "branch": "AIML",
            "semester": "Semester 4",
            "subject": "Machine Learning",
            "subject_code": "AIML402",
            "unit": None,
            "unit_name": None,
            "unit_scope": "all",
            "uploaded_at": datetime(2026, 10, 23, 6, 0),
            "uploaded_by": 42
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.get("/resources/shared", headers=self.auth_headers(42))

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["count"], 1)
        self.assertEqual(data["resources"][0]["unit"], "all")
        self.assertEqual(data["resources"][0]["unit_label"], "All Units")
        self.assertEqual(data["resources"][0]["branch"], "AIML")
        self.assertEqual(data["resources"][0]["semester"], 4)
        self.assertTrue(data["resources"][0]["uploaded_at"].startswith("2026-10-23T06:00"))

        query, parameters = cursor.execute.call_args.args
        self.assertIn("WHERE r.uploaded_by = %s", query)
        self.assertEqual(parameters, (42,))

    def test_upload_persists_all_units_with_explicit_scope_and_owner(self):
        self.assert_upload_persists_unit_scope("all", None, "all")

    def test_upload_keeps_existing_individual_unit_selection(self):
        self.assert_upload_persists_unit_scope("3", {"unit_id": 30, "unit_name": "Unit 3"}, "unit")

    def test_upload_requires_a_signed_session(self):
        with patch.object(resources, "get_db_connection") as get_db_connection:
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "notes.pdf"),
                    "title": "Study notes",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": "3",
                    "type": "PDF Notes",
                },
                content_type="multipart/form-data",
            )

        self.assertEqual(response.status_code, 401)
        get_db_connection.assert_not_called()

    def test_shared_resources_requires_a_signed_session(self):
        with patch.object(resources, "get_db_connection") as get_db_connection:
            response = self.client.get("/resources/shared?user_id=42")

        self.assertEqual(response.status_code, 401)
        get_db_connection.assert_not_called()

    def test_invalid_filters_are_rejected_before_database_access(self):
        with patch.object(resources, "get_db_connection") as get_db_connection:
            invalid_semester = self.client.get("/resources?semester=invalid")
            invalid_unit = self.client.get("/resources?unit=0")

        self.assertEqual(invalid_semester.status_code, 400)
        self.assertEqual(invalid_unit.status_code, 400)
        get_db_connection.assert_not_called()

    def test_youtube_type_rejects_non_youtube_urls(self):
        with patch.object(resources, "get_db_connection") as get_db_connection:
            response = self.client.post(
                "/resources/upload",
                data={
                    "youtube_url": "https://example.com/video",
                    "type": "YouTube Resources"
                },
                headers=self.auth_headers(42)
            )

        self.assertEqual(response.status_code, 400)
        get_db_connection.assert_not_called()

    def test_download_uploaded_file(self):
        filename = "test_download.pdf"
        file_path = os.path.join(self.upload_directory.name, filename)
        with open(file_path, "wb") as f:
            f.write(b"PDF-download-test-bytes")

        response = self.client.get(f"/download/{filename}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, b"PDF-download-test-bytes")
        response.close()

    def test_download_missing_file_returns_404(self):
        response = self.client.get("/download/nonexistent.pdf")
        self.assertEqual(response.status_code, 404)

    def test_delete_resource_by_owner(self):
        filename = "to_delete.pdf"
        file_path = os.path.join(self.upload_directory.name, filename)
        with open(file_path, "wb") as f:
            f.write(b"delete me")

        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {
                "resource_id": 10,
                "resource_url": f"/uploads/{filename}",
                "uploaded_by": 5
            },
            None,
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.delete(
                "/resources/10?user_id=99",
                headers=self.auth_headers(5)
            )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.get_json()["success"])
        self.assertFalse(os.path.exists(file_path))

    def test_delete_resource_forbidden_for_non_owner(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "resource_id": 10,
            "resource_url": "/uploads/other.pdf",
            "uploaded_by": 99
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.delete("/resources/10", headers=self.auth_headers(5))

        self.assertEqual(response.status_code, 403)

    def test_request_linked_resource_cannot_be_deleted(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {
                "resource_id": 10,
                "resource_url": "/uploads/linked.pdf",
                "uploaded_by": 5,
            },
            {"request_id": 25},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.delete("/resources/10", headers=self.auth_headers(5))

        self.assertEqual(response.status_code, 409)
        self.assertFalse(any("DELETE FROM resources" in call.args[0] for call in cursor.execute.call_args_list))
        connection.commit.assert_not_called()

    def test_saved_resources_only_return_the_authenticated_users_saved_items(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{"resource_id": 9}]
        connection = MagicMock()
        connection.cursor.return_value = cursor
        resources_for_user = [
            {"id": 9, "title": "Saved resource"},
            {"id": 10, "title": "Not saved by this user"},
        ]

        with patch.object(resources, "get_db_connection", return_value=connection), patch.object(
            resources, "_fetch_all_resources", return_value=resources_for_user
        ):
            response = self.client.get("/resources/saved", headers=self.auth_headers(42))

        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["id"] for item in response.get_json()["resources"]], [9])
        query, parameters = cursor.execute.call_args.args
        self.assertIn("WHERE user_id = %s", query)
        self.assertEqual(parameters, (42,))

    def test_saving_a_resource_uses_the_authenticated_user_id(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"resource_id": 9}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/9/saved",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.get_json()["saved"])
        query, parameters = cursor.execute.call_args_list[1].args
        self.assertIn("INSERT IGNORE INTO saved_resources", query)
        self.assertEqual(parameters, (42, 9))

    def test_rating_submission_is_scoped_to_the_authenticated_user(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"user_id": 42},
            {"resource_id": 9},
            {"avg_rating": 4.0, "rating_count": 2},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/9/ratings",
                json={"rating": 4, "review": "Helpful"},
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.get_json()["success"])
        rating_query, rating_values = cursor.execute.call_args_list[2].args
        self.assertIn("INSERT INTO ratings (user_id, resource_id, rating, review)", rating_query)
        self.assertEqual(rating_values, (42, 9, 4, "Helpful"))
        connection.commit.assert_called_once()

    def test_student_upload_fulfills_and_links_another_users_request(self):
        self.assert_upload_fulfills_request("student")

    def test_upload_fulfills_a_request_for_an_eighth_unit(self):
        cursor = MagicMock()
        cursor.lastrowid = 101
        cursor.rowcount = 1
        cursor.fetchone.side_effect = [
            {"branch_id": 2, "branch_name": "AIML"},
            {"semester_id": 8, "semester_name": "Semester 4"},
            {"subject_id": 13, "subject_name": "Machine Learning", "subject_code": "AL-405"},
            {"unit_id": 88, "unit_name": "Unit 8"},
            {"user_id": 42, "name": "Student B", "role": "student"},
            {"request_id": 41, "subject_id": 13, "unit_id": 88, "status": "Pending", "user_id": 7},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "unit-8.pdf"),
                    "title": "Machine Learning Unit 8",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": "8",
                    "type": "PDF Notes",
                    "request_id": "41",
                },
                content_type="multipart/form-data",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 201, response.get_json())
        resource_insert = next(
            call for call in cursor.execute.call_args_list
            if call.args[0].lstrip().startswith("INSERT INTO resources")
        )
        self.assertEqual(resource_insert.args[1][5:7], (88, "unit"))
        update_call = next(
            call for call in cursor.execute.call_args_list
            if "UPDATE requests" in call.args[0]
        )
        self.assertEqual(update_call.args[1], (42, 101, 41))
        connection.commit.assert_called_once()

    def test_deleted_request_cannot_be_fulfilled(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"branch_id": 2, "branch_name": "AIML"},
            {"semester_id": 8, "semester_name": "Semester 4"},
            {"subject_id": 13, "subject_name": "Machine Learning", "subject_code": "AL-405"},
            {"user_id": 42, "name": "Student B", "role": "student"},
            None,
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "notes.pdf"),
                    "title": "Machine Learning notes",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": "all",
                    "type": "PDF Notes",
                    "request_id": "41",
                },
                content_type="multipart/form-data",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 404)
        self.assertFalse(any("INSERT INTO resources" in call.args[0] for call in cursor.execute.call_args_list))
        self.assertFalse(any("UPDATE requests" in call.args[0] for call in cursor.execute.call_args_list))
        self.assertEqual(os.listdir(self.upload_directory.name), [])
        connection.commit.assert_not_called()

    def test_soft_deleted_request_cannot_be_fulfilled(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"branch_id": 2, "branch_name": "AIML"},
            {"semester_id": 8, "semester_name": "Semester 4"},
            {"subject_id": 13, "subject_name": "Machine Learning", "subject_code": "AL-405"},
            {"user_id": 42, "name": "Student B", "role": "student"},
            None,
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "notes.pdf"),
                    "title": "Machine Learning notes",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": "all",
                    "type": "PDF Notes",
                    "request_id": "41",
                },
                content_type="multipart/form-data",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 404)
        self.assertFalse(any("INSERT INTO resources" in call.args[0] for call in cursor.execute.call_args_list))
        self.assertEqual(os.listdir(self.upload_directory.name), [])
        connection.commit.assert_not_called()

    def test_teacher_upload_fulfills_request_with_equal_permissions(self):
        self.assert_upload_fulfills_request("teacher")

    def test_upload_database_failure_does_not_commit_request_fulfillment(self):
        cursor = MagicMock()
        cursor.lastrowid = 101
        cursor.rowcount = 1
        cursor.fetchone.side_effect = [
            {"branch_id": 2, "branch_name": "AIML"},
            {"semester_id": 8, "semester_name": "Semester 4"},
            {"subject_id": 13, "subject_name": "Machine Learning", "subject_code": "AL-405"},
            {"user_id": 42, "name": "Student B", "role": "student"},
            {"request_id": 41, "subject_id": 13, "unit_id": None, "status": "Pending", "user_id": 7},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor
        connection.commit.side_effect = RuntimeError("simulated commit failure")

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "notes.pdf"),
                    "title": "Machine Learning notes",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": "all",
                    "type": "PDF Notes",
                    "request_id": "41",
                },
                content_type="multipart/form-data",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 500)
        connection.rollback.assert_called_once()
        update_call = next(
            call for call in cursor.execute.call_args_list
            if "UPDATE requests" in call.args[0]
        )
        self.assertEqual(update_call.args[1], (42, 101, 41))
        uploaded_file = next(iter(os.listdir(self.upload_directory.name)), None)
        self.assertIsNone(uploaded_file)

    def assert_upload_fulfills_request(self, role):
        cursor = MagicMock()
        cursor.lastrowid = 101
        cursor.rowcount = 1
        cursor.fetchone.side_effect = [
            {"branch_id": 2, "branch_name": "AIML"},
            {"semester_id": 8, "semester_name": "Semester 4"},
            {"subject_id": 13, "subject_name": "Machine Learning", "subject_code": "AL-405"},
            {"user_id": 42, "name": "Contributor", "role": role},
            {"request_id": 41, "subject_id": 13, "unit_id": None, "status": "Pending", "user_id": 7},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "notes.pdf"),
                    "title": "Machine Learning notes",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": "all",
                    "type": "PDF Notes",
                    "request_id": "41",
                },
                content_type="multipart/form-data",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 201, response.get_json())
        self.assertEqual(response.get_json()["request"], {
            "id": 41,
            "status": "Fulfilled",
            "fulfilled_by": 42,
            "fulfilled_resource_id": 101,
        })
        update_call = next(
            call for call in cursor.execute.call_args_list
            if "UPDATE requests" in call.args[0]
        )
        self.assertIn("status = 'Fulfilled'", update_call.args[0])
        self.assertEqual(update_call.args[1], (42, 101, 41))
        request_lock = next(
            call for call in cursor.execute.call_args_list
            if "FOR UPDATE" in call.args[0]
        )
        self.assertIn("user_id", request_lock.args[0])
        self.assertNotIn("deleted_at", request_lock.args[0])
        self.assertEqual(request_lock.args[1], (41,))
        resource_insert = next(
            call for call in cursor.execute.call_args_list
            if call.args[0].lstrip().startswith("INSERT INTO resources")
        )
        self.assertEqual(resource_insert.args[1][4], 42)
        connection.commit.assert_called_once()

    def assert_upload_persists_unit_scope(self, selected_unit, unit_row, expected_scope):
        cursor = MagicMock()
        cursor.lastrowid = 101
        cursor.fetchone.side_effect = [
            {"branch_id": 2, "branch_name": "AIML"},
            {"semester_id": 8, "semester_name": "Semester 4"},
            {"subject_id": 13, "subject_name": "Machine Learning", "subject_code": "AL-405"},
            *([unit_row] if unit_row else []),
            {"user_id": 42},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(resources, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/resources/upload",
                data={
                    "file": (BytesIO(b"resource content"), "notes.pdf"),
                    "title": "Study notes",
                    "branch": "AIML",
                    "semester": "4",
                    "subject": "Machine Learning",
                    "unit": selected_unit,
                    "type": "PDF Notes",
                    "uploaded_by": "99",
                },
                content_type="multipart/form-data",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 201, response.get_json())
        self.assertTrue(connection.commit.called)
        insert_call = next(
            call for call in cursor.execute.call_args_list
            if call.args[0].lstrip().startswith("INSERT INTO resources")
        )
        values = insert_call.args[1]
        self.assertEqual(values[4], 42)
        self.assertEqual(values[5], unit_row["unit_id"] if unit_row else None)
        self.assertEqual(values[6], expected_scope)
        self.assertEqual(response.get_json()["resource"]["unit_scope"], expected_scope)



    def test_resources_fallback_when_catalogue_metadata_is_missing(self):
        filename = "test_note.pdf"
        with open(os.path.join(self.upload_directory.name, filename), "wb") as f:
            f.write(b"content")

        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 1,
            "title": "Notes",
            "resource_url": f"/uploads/{filename}",
            "type": "PDF Notes",
            "description": "Desc",
            "branch": "AIML",
            "semester": "Semester 4",
            "subject": "Machine Learning",
            "subject_code": "AIML402",
            "unit": 1,
            "unit_name": "Unit 1",
            "unit_scope": "unit",
            "uploaded_at": datetime.now(),
            "uploaded_by": 1,
            "uploader_name": "Author",
            "uploader_role": "student",
            "avg_rating": 4.5,
            "rating_count": 2,
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with (
            patch.object(resources, "get_db_connection", return_value=connection),
            patch.object(resources, "table_exists", return_value=False),
        ):
            response = self.client.get("/resources")

        self.assertEqual(response.status_code, 200)
        query = cursor.execute.call_args.args[0]
        self.assertNotIn("subject_catalogue_metadata", query)


if __name__ == "__main__":
    unittest.main()
