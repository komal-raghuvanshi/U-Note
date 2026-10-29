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

    def test_student_cannot_update_another_users_request(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "actor_role": "student"
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Fulfilled", "user_id": 7},
                headers=self.auth_headers(99)
            )

        self.assertEqual(response.status_code, 403)
        connection.commit.assert_not_called()

    def test_request_owner_can_update_status(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "request_id": 12,
            "user_id": 7,
            "actor_role": "student"
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(requests_routes, "get_db_connection", return_value=connection):
            response = self.client.patch(
                "/requests/12/status",
                json={"status": "Fulfilled"},
                headers=self.auth_headers(7)
            )

        self.assertEqual(response.status_code, 200)
        connection.commit.assert_called_once()


if __name__ == "__main__":
    unittest.main()
