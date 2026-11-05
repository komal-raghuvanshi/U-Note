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
        self.assertEqual(insert_call.args[1], (7, 10, None, "Need notes"))
        connection.commit.assert_called_once()

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

    def test_get_requests_requires_a_signed_session(self):
        with patch.object(requests_routes, "get_db_connection") as get_connection:
            response = self.client.get("/requests")

        self.assertEqual(response.status_code, 401)
        get_connection.assert_not_called()

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


if __name__ == "__main__":
    unittest.main()
