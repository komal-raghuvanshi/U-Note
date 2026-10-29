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
            invalid_unit = self.client.get("/resources?unit=9")

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
        cursor.fetchone.return_value = {
            "resource_id": 10,
            "resource_url": f"/uploads/{filename}",
            "uploaded_by": 5
        }
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


if __name__ == "__main__":
    unittest.main()
