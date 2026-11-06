import unittest
from unittest.mock import MagicMock, patch

from flask import Flask

from backend.auth_utils import create_auth_token
from backend.routes import requests as requests_routes


class RequestRouteTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.app.config["SECRET_KEY"] = "request-route-test-secret"
        self.app.register_blueprint(requests_routes.requests_bp)
        self.client = self.app.test_client()

    def auth_headers(self, user_id):
        with self.app.app_context():
            token = create_auth_token(user_id)
        return {"Authorization": f"Bearer {token}"}

    def test_create_request_requires_signed_session(self):
        with patch.object(requests_routes, "get_db_connection") as get_connection:
            response = self.client.post("/requests", json={
                "user_id": 1,
                "branch": "AIML",
                "semester": 4,
                "subject": "Machine Learning",
                "description": "Need notes"
            })

        self.assertEqual(response.status_code, 401)
        get_connection.assert_not_called()

    def test_authenticated_student_can_create_a_request(self):
        cursor = MagicMock()
        cursor.lastrowid = 41
        cursor.fetchone.side_effect = [
            {"user_id": 7, "name": "Student A"},
            {"subject_id": 10, "subject_name": "Machine Learning"},
            None,
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/requests",
                json={
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                    "unit": "all",
                    "description": "Need notes",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.get_json()["request_id"], 41)
        insert_call = next(
            call for call in cursor.execute.call_args_list
            if "INSERT INTO requests" in call.args[0]
        )
        self.assertEqual(insert_call.args[1], (7, 10, None, "Machine Learning", "Need notes"))
        connection.commit.assert_called_once()

    def test_request_can_target_an_eighth_unit(self):
        cursor = MagicMock()
        cursor.lastrowid = 42
        cursor.fetchone.side_effect = [
            {"user_id": 7, "name": "Student A"},
            {"subject_id": 10, "subject_name": "Machine Learning"},
            {"unit_id": 88},
            None,
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/requests",
                json={
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                    "unit": "8",
                    "description": "Need Unit 8 notes",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 201)
        insert_call = next(
            call for call in cursor.execute.call_args_list
            if "INSERT INTO requests" in call.args[0]
        )
        self.assertEqual(
            insert_call.args[1],
            (7, 10, 88, "Machine Learning", "Need Unit 8 notes")
        )
        connection.commit.assert_called_once()

    def test_identical_pending_request_is_rejected(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"user_id": 7, "name": "Student A"},
            {"subject_id": 10, "subject_name": "Machine Learning"},
            {"request_id": 40},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.post(
                "/requests",
                json={
                    "title": "Machine Learning notes",
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                    "unit": "all",
                    "description": "Need notes",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 409)
        self.assertEqual(
            response.get_json()["message"],
            "An identical pending request already exists for this subject and unit."
        )
        self.assertFalse(any(
            "INSERT INTO requests" in call.args[0]
            for call in cursor.execute.call_args_list
        ))
        connection.commit.assert_not_called()

    def test_student_cannot_update_another_users_request(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "status": "Pending"
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Rejected", "user_id": 7},
                headers=self.auth_headers(99)
            )

        self.assertEqual(response.status_code, 403)
        connection.commit.assert_not_called()

    def test_request_owner_can_update_status(self):
        cursor = MagicMock()
        cursor.rowcount = 1
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "status": "Pending"
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Rejected"},
                headers=self.auth_headers(7)
            )

        self.assertEqual(response.status_code, 200)
        connection.commit.assert_called_once()

    def test_teacher_cannot_update_another_users_request(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "status": "Pending"
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Rejected"},
                headers=self.auth_headers(99)
            )

        self.assertEqual(response.status_code, 403)
        connection.commit.assert_not_called()

    def test_users_cannot_manually_mark_a_request_fulfilled(self):
        with patch.object(requests_routes, "get_db_connection") as get_connection:
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Fulfilled"},
                headers=self.auth_headers(7)
            )

        self.assertEqual(response.status_code, 409)
        get_connection.assert_not_called()

    def test_get_my_requests_returns_identity(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [
            {
                "id": 1,
                "description": "Need Unit 3 notes",
                "status": "Pending",
                "created_at": None,
                "user_id": 7,
                "user_name": "Test User",
                "user_role": "student",
                "subject_id": 10,
                "subject": "Machine Learning",
                "subject_code": "AL-401",
                "semester": "Semester 4",
                "branch": "AIML",
                "unit": 3,
                "unit_name": "Decision Trees"
            }
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests/my", headers=self.auth_headers(7))

        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertTrue(data["success"])
        self.assertEqual(data["requests"][0]["user_id"], 7)
        self.assertEqual(data["requests"][0]["user_name"], "Test User")

    def test_public_request_list_hides_requester_and_fulfiller_identity(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 41,
            "description": "Need study notes",
            "status": "Pending",
            "created_at": None,
            "user_id": None,
            "user_name": None,
            "user_role": None,
            "fulfilled_by": None,
            "fulfilled_by_name": None,
            "fulfilled_resource_id": None,
            "semester": "Semester 4",
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests")

        self.assertEqual(response.status_code, 200)
        request_data = response.get_json()["requests"][0]
        self.assertIsNone(request_data["user_id"])
        self.assertIsNone(request_data["user_name"])
        self.assertIsNone(request_data["user_role"])
        self.assertIsNone(request_data["fulfilled_by"])
        self.assertIsNone(request_data["fulfilled_by_name"])
        query, parameters = cursor.execute.call_args.args
        self.assertIn("NULL AS user_id", query)
        self.assertIn("NULL AS user_name", query)
        self.assertIn("NULL AS fulfilled_by_name", query)
        self.assertEqual(parameters, [])

    def test_student_can_view_another_users_request(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 41,
            "description": "Need study notes",
            "status": "Pending",
            "created_at": None,
            "user_id": 7,
            "user_name": "Student A",
            "semester": "Semester 4",
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests", headers=self.auth_headers(42))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["requests"][0]["id"], 41)
        self.assertEqual(response.get_json()["requests"][0]["user_id"], 7)
        self.assertEqual(response.get_json()["requests"][0]["user_name"], "Student A")
        query, parameters = cursor.execute.call_args.args
        self.assertIn("u.user_id", query)
        self.assertIn("u.name AS user_name", query)
        self.assertNotIn("WHERE req.user_id = %s", query)
        self.assertEqual(parameters, [])

    def test_teacher_request_list_has_same_unfiltered_visibility(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = []
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests", headers=self.auth_headers(7))

        self.assertEqual(response.status_code, 200)
        query, parameters = cursor.execute.call_args.args
        self.assertNotIn("req.user_id = %s", query)
        self.assertEqual(parameters, [])

    def test_get_requests_supports_rejected_status(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = []
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get(
                "/requests?status=Rejected",
                headers=self.auth_headers(7)
            )

        self.assertEqual(response.status_code, 200)

    def test_request_details_include_linked_resource_and_fulfiller(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "id": 41,
            "user_id": 7,
            "status": "Fulfilled",
            "fulfilled_by": 42,
            "fulfilled_by_name": "Student B",
            "fulfilled_resource_id": 101,
            "fulfilled_resource_title": "Machine Learning notes",
            "fulfilled_resource_url": "/uploads/notes.pdf",
            "semester": "Semester 4",
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests/41", headers=self.auth_headers(7))

        self.assertEqual(response.status_code, 200)
        request_data = response.get_json()["request"]
        self.assertEqual(request_data["fulfilled_resource_id"], 101)
        self.assertEqual(request_data["fulfilled_by_name"], "Student B")
        query, parameters = cursor.execute.call_args.args
        self.assertIn("fulfilled_resource.resource_id", query)
        self.assertEqual(parameters, (41,))

    def test_requester_sees_fulfilled_status_and_shared_resource_in_list(self):
        cursor = MagicMock()
        cursor.fetchall.return_value = [{
            "id": 41,
            "user_id": 7,
            "status": "Fulfilled",
            "fulfilled_by": 42,
            "fulfilled_by_name": "Student B",
            "fulfilled_resource_id": 101,
            "fulfilled_resource_title": "Machine Learning notes",
            "fulfilled_resource_url": "/uploads/notes.pdf",
            "created_at": None,
            "semester": "Semester 4",
        }]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests", headers=self.auth_headers(7))

        self.assertEqual(response.status_code, 200)
        request_data = response.get_json()["requests"][0]
        self.assertEqual(request_data["status"], "Fulfilled")
        self.assertEqual(request_data["fulfilled_by_name"], "Student B")
        self.assertEqual(request_data["fulfilled_resource_id"], 101)
        self.assertEqual(request_data["fulfilled_resource_title"], "Machine Learning notes")

    def test_fulfilled_request_cannot_be_manually_reopened(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 13,
            "user_id": 7,
            "status": "Fulfilled",
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/13/status",
                json={"status": "Pending"},
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 409)
        self.assertEqual(cursor.execute.call_count, 1)
        connection.commit.assert_not_called()

    def test_owner_can_edit_pending_request_and_academic_scope(self):
        cursor = MagicMock()
        cursor.rowcount = 1
        cursor.fetchone.side_effect = [
            {"request_id": 12, "user_id": 7, "status": "Pending"},
            {"subject_id": 11, "subject_name": "Database Management Systems"},
            {"unit_id": 88},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12",
                json={
                    "title": "DBMS Unit 8 notes",
                    "description": "Please share worked examples.",
                    "branch": "AIML",
                    "semester": 5,
                    "subject": "Database Management Systems",
                    "unit": "8",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 200)
        update_call = next(
            call for call in cursor.execute.call_args_list
            if "UPDATE requests" in call.args[0]
        )
        self.assertEqual(
            update_call.args[1],
            ("DBMS Unit 8 notes", "Please share worked examples.", 11, 88, 12, 7)
        )
        connection.commit.assert_called_once()

    def test_user_cannot_edit_another_users_request(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "status": "Pending",
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12",
                json={
                    "title": "Edited",
                    "description": "Edited",
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                    "unit": "all",
                },
                headers=self.auth_headers(99),
            )

        self.assertEqual(response.status_code, 403)
        self.assertEqual(cursor.execute.call_count, 1)
        connection.commit.assert_not_called()

    def test_fulfilled_request_cannot_be_edited(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "status": "Fulfilled",
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12",
                json={
                    "title": "Edited",
                    "description": "Edited",
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                    "unit": "all",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 409)
        self.assertEqual(cursor.execute.call_count, 1)
        connection.commit.assert_not_called()

    def test_permanently_deleted_request_cannot_be_edited(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = None
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12",
                json={
                    "title": "Edited",
                    "description": "Edited",
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                    "unit": "all",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 404)
        connection.commit.assert_not_called()

    def test_edit_requires_an_explicit_unit_selection(self):
        with patch.object(requests_routes, "get_db_connection") as get_connection:
            response = self.client.patch(
                "/requests/12",
                json={
                    "title": "Edited",
                    "description": "Edited",
                    "branch": "AIML",
                    "semester": 4,
                    "subject": "Machine Learning",
                },
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 400)
        get_connection.assert_not_called()

    def test_owner_can_permanently_delete_request_without_deleting_resource(self):
        cursor = MagicMock()
        cursor.rowcount = 1
        cursor.fetchone.return_value = {"request_id": 12, "user_id": 7}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.delete(
                "/requests/12",
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 200)
        delete_call = next(
            call for call in cursor.execute.call_args_list
            if "DELETE FROM requests" in call.args[0]
        )
        self.assertEqual(delete_call.args[1], (12, 7))
        self.assertFalse(any(
            "DELETE FROM resources" in call.args[0]
            for call in cursor.execute.call_args_list
        ))
        connection.commit.assert_called_once()

    def test_user_cannot_permanently_delete_another_users_request(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"request_id": 12, "user_id": 7}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.delete(
                "/requests/12",
                headers=self.auth_headers(99),
            )

        self.assertEqual(response.status_code, 403)
        self.assertEqual(cursor.execute.call_count, 1)
        connection.commit.assert_not_called()

    def test_owner_can_permanently_delete_fulfilled_request(self):
        cursor = MagicMock()
        cursor.rowcount = 1
        cursor.fetchone.return_value = {"request_id": 12, "user_id": 7}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.delete(
                "/requests/12",
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 200)
        connection.commit.assert_called_once()

    def test_cancelled_status_is_not_a_supported_filter(self):
        with patch.object(requests_routes, "get_db_connection") as get_connection:
            response = self.client.get(
                "/requests?status=Cancelled",
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 400)
        get_connection.assert_not_called()

    def test_cancelled_status_cannot_be_set(self):
        with patch.object(requests_routes, "get_db_connection") as get_connection:
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Cancelled"},
                headers=self.auth_headers(7),
            )

        self.assertEqual(response.status_code, 400)
        get_connection.assert_not_called()

    def test_cancel_endpoint_is_not_registered(self):
        response = self.client.patch(
            "/requests/12/cancel",
            headers=self.auth_headers(7),
        )

        self.assertEqual(response.status_code, 404)

    def test_normal_request_lists_query_only_existing_rows(self):
        for path, expected_owner_filter in [
            ("/requests", False),
            ("/requests/my", True),
        ]:
            with self.subTest(path=path):
                cursor = MagicMock()
                cursor.fetchall.return_value = []
                connection = MagicMock()
                connection.cursor.return_value = cursor

                with patch.object(requests_routes, "get_db_connection", return_value=connection):
                    response = self.client.get(path, headers=self.auth_headers(7))

                self.assertEqual(response.status_code, 200)
                query = cursor.execute.call_args.args[0]
                self.assertNotIn("deleted_at", query)
                self.assertEqual("req.user_id = %s" in query, expected_owner_filter)

    def test_deleted_request_details_are_not_accessible(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = None
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.get("/requests/12", headers=self.auth_headers(7))

        self.assertEqual(response.status_code, 404)
        self.assertNotIn("deleted_at", cursor.execute.call_args.args[0])


if __name__ == "__main__":
    unittest.main()
