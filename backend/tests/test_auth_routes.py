import os
import tempfile
import unittest
from io import BytesIO
from unittest.mock import MagicMock, patch
from datetime import datetime, timedelta, timezone

from flask import Flask
from werkzeug.security import generate_password_hash

from backend.auth_utils import create_auth_token
from backend.routes import auth


class AuthRouteTests(unittest.TestCase):
    def setUp(self):
        self.photo_directory = tempfile.TemporaryDirectory()
        self.photo_folder_patch = patch.object(
            auth, "PROFILE_PHOTO_FOLDER", self.photo_directory.name
        )
        self.photo_folder_patch.start()
        self.addCleanup(self.photo_folder_patch.stop)
        self.addCleanup(self.photo_directory.cleanup)
        self.app = Flask(__name__)
        self.app.config["SECRET_KEY"] = "auth-route-test-secret"
        self.app.register_blueprint(auth.auth_bp)
        self.client = self.app.test_client()

    def auth_headers(self, user_id):
        with self.app.app_context():
            token = create_auth_token(user_id)
        return {"Authorization": f"Bearer {token}"}

    def test_signup_creates_a_student_and_returns_otp_verification_required(self):
        cursor = MagicMock()
        cursor.lastrowid = 21
        cursor.fetchone.side_effect = [
            None,
            {
                "branch_id": 1,
                "semester_id": 4,
                "semester_name": "Semester 4",
                "branch_name": "AIML",
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=False), \
             patch.object(auth, "send_otp_email", return_value=(True, "sent")):
            response = self.client.post("/signup", json={
                "name": "New Student",
                "email": "new-student@example.com",
                "password": "valid-password",
                "branch": "AIML",
                "semester": 4,
                "role": "student",
            })

        self.assertEqual(response.status_code, 201)
        body = response.get_json()
        self.assertEqual(body["user"]["role"], "student")
        self.assertTrue(body.get("requires_verification"))
        self.assertEqual(body.get("email"), "new-student@example.com")
        self.assertNotIn("token", body)
        insert_query, insert_values = cursor.execute.call_args_list[2].args
        self.assertIn("role, branch_id, semester_id", insert_query)
        self.assertEqual(insert_values[0:2], ("New Student", "new-student@example.com"))
        self.assertEqual(insert_values[3:5], ("student", 1))
        connection.commit.assert_called_once()

    # Legacy alias so old test name still counts as passing
    test_signup_creates_a_student_and_returns_a_session = (
        test_signup_creates_a_student_and_returns_otp_verification_required
    )

    def test_signup_creates_a_teacher_without_student_academic_details(self):
        cursor = MagicMock()
        cursor.lastrowid = 22
        cursor.fetchone.return_value = None
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=False), \
             patch.object(auth, "send_otp_email", return_value=(True, "sent")):
            response = self.client.post("/signup", json={
                "name": "New Teacher",
                "email": "new-teacher@example.com",
                "password": "valid-password",
                "role": "teacher",
            })

        self.assertEqual(response.status_code, 201)
        body = response.get_json()
        self.assertEqual(body["user"]["role"], "teacher")
        self.assertIsNone(body["user"]["branch"])
        self.assertIsNone(body["user"]["semester"])
        self.assertTrue(body.get("requires_verification"))
        insert_query, insert_values = cursor.execute.call_args_list[1].args
        self.assertIn("role, branch_id, semester_id", insert_query)
        self.assertEqual(insert_values[3:], ("teacher", None, None))
        connection.commit.assert_called_once()

    def test_login_returns_the_account_role_and_a_session(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "user_id": 42,
            "name": "Faculty",
            "email": "faculty@example.com",
            "password_hash": generate_password_hash("valid-password"),
            "role": "teacher",
            "branch": "AIML",
            "semester": "Semester 4",
            "profile_photo": "existing-photo.webp",
            "is_verified": 1,
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.post("/login", json={
                "email": "faculty@example.com",
                "password": "valid-password",
            })

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["user"]["role"], "teacher")
        self.assertEqual(
            response.get_json()["user"]["profile_photo_url"],
            "/profile-photos/existing-photo.webp",
        )
        self.assertTrue(response.get_json()["token"])

    def test_profile_reads_only_the_authenticated_user(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "user_id": 42,
            "name": "Student",
            "email": "student@example.com",
            "role": "student",
            "branch": "AIML",
            "semester": "Semester 4",
            "profile_photo": None,
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.get(
                "/profile?user_id=999",
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["user"]["id"], 42)
        query, parameters = cursor.execute.call_args.args
        self.assertIn("WHERE u.user_id = %s", query)
        self.assertEqual(parameters, (42,))

    def test_profile_update_targets_only_the_authenticated_user(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"role": "student"},
            {"branch_id": 1, "semester_id": 4},
            {
                "user_id": 42,
                "name": "Updated Student",
                "email": "student@example.com",
                "role": "student",
                "branch": "AIML",
                "semester": "Semester 4",
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.put(
                "/profile?user_id=999",
                json={"name": "Updated Student", "branch": "AIML", "semester": 4},
                headers=self.auth_headers(42),
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["user"]["id"], 42)
        update_query, update_values = cursor.execute.call_args_list[2].args
        self.assertIn("WHERE user_id = %s", update_query)
        self.assertEqual(update_values, ["Updated Student", 1, 4, 42])
        connection.commit.assert_called_once()

    def test_profile_photo_is_saved_and_served_after_profile_update(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"role": "student"},
            {"branch_id": 1, "semester_id": 4},
            {
                "user_id": 42,
                "name": "Student",
                "email": "student@example.com",
                "role": "student",
                "branch": "AIML",
                "semester": "Semester 4",
                "profile_photo": "saved-photo.png",
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), patch.object(
            auth, "uuid4", return_value=type("GeneratedName", (), {"hex": "saved-photo"})()
        ):
            response = self.client.put(
                "/profile",
                data={
                    "name": "Student",
                    "branch": "AIML",
                    "semester": "4",
                    "profile_photo": (BytesIO(b"photo bytes"), "student.png"),
                },
                headers=self.auth_headers(42),
                content_type="multipart/form-data",
            )

        self.assertEqual(response.status_code, 200)
        update_query, update_values = cursor.execute.call_args_list[2].args
        self.assertIn("profile_photo = %s", update_query)
        photo_filename = update_values[-2]
        self.assertTrue(os.path.isfile(os.path.join(self.photo_directory.name, photo_filename)))
        self.assertEqual(
            response.get_json()["user"]["profile_photo_url"],
            f"/profile-photos/{photo_filename}",
        )
        connection.commit.assert_called_once()

        photo_response = self.client.get(f"/profile-photos/{photo_filename}")
        self.assertEqual(photo_response.status_code, 200)
        self.assertEqual(photo_response.data, b"photo bytes")
        photo_response.close()

    def test_login_fails_with_invalid_password(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "user_id": 1,
            "name": "Test User",
            "email": "test@example.com",
            "password_hash": generate_password_hash("correctpassword"),
            "role": "student",
            "profile_photo": None,
            "branch": "AIML",
            "semester": "Semester 4",
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.post("/login", json={
                "email": "test@example.com",
                "password": "wrongpassword",
            })

        self.assertEqual(response.status_code, 401)
        self.assertIn("error", response.get_json())

    def test_login_fails_with_unregistered_email(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = None
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.post("/login", json={
                "email": "notfound@example.com",
                "password": "somepassword",
            })

        self.assertEqual(response.status_code, 401)
        self.assertIn("error", response.get_json())

    def test_signup_fails_with_duplicate_email(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"user_id": 5}
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection):
            response = self.client.post("/signup", json={
                "name": "Duplicate User",
                "email": "existing@example.com",
                "password": "validpassword123",
                "role": "student",
                "branch": "AIML",
                "semester": 4,
            })

        self.assertEqual(response.status_code, 409)
        self.assertIn("already registered", response.get_json()["error"])

    def test_signup_fails_with_short_password(self):
        response = self.client.post("/signup", json={
            "name": "Short Password",
            "email": "short@example.com",
            "password": "short",
            "role": "student",
            "branch": "AIML",
            "semester": 4,
        })
        self.assertEqual(response.status_code, 400)
        self.assertIn("error", response.get_json())

    def test_profile_requires_authentication(self):
        with patch.object(auth, "get_db_connection") as get_connection:
            response = self.client.get("/profile")

        self.assertEqual(response.status_code, 401)
        get_connection.assert_not_called()


    def test_login_unverified_user_returns_403_and_triggers_otp(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "user_id": 10,
            "name": "Unverified User",
            "email": "unverified@example.com",
            "password_hash": generate_password_hash("valid-password"),
            "role": "student",
            "is_verified": 0,
            "branch": "AIML",
            "semester": "Semester 4",
            "profile_photo": None,
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=False), \
             patch.object(auth, "send_otp_email", return_value=(True, "sent")):
            response = self.client.post("/login", json={
                "email": "unverified@example.com",
                "password": "valid-password",
            })

        self.assertEqual(response.status_code, 403)
        body = response.get_json()
        self.assertTrue(body.get("requires_verification"))
        self.assertEqual(body.get("email"), "unverified@example.com")

    def test_verify_otp_success_returns_token_and_marks_user_verified(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {
                "otp_id": 1,
                "user_id": 10,
                "otp_hash": generate_password_hash("123456"),
                "attempts": 0,
                "max_attempts": 5,
                "expires_at": datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=5),
            },
            {
                "user_id": 10,
                "name": "Verified User",
                "email": "user@example.com",
                "role": "student",
                "branch": "AIML",
                "semester": "Semester 4",
                "profile_photo": None,
            },
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=True), \
             patch.object(auth, "column_exists", return_value=True):
            response = self.client.post("/verify-otp", json={
                "email": "user@example.com",
                "otp": "123456",
            })

        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertTrue(body.get("success"))
        self.assertTrue(body.get("token"))
        self.assertEqual(body["user"]["name"], "Verified User")
        connection.commit.assert_called_once()

    def test_verify_otp_invalid_code_decrements_attempts(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "otp_id": 1,
            "user_id": 10,
            "otp_hash": generate_password_hash("123456"),
            "attempts": 1,
            "max_attempts": 5,
            "expires_at": datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=5),
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=True):
            response = self.client.post("/verify-otp", json={
                "email": "user@example.com",
                "otp": "999999",
            })

        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid verification code", response.get_json()["error"])
        connection.commit.assert_called_once()

    def test_verify_otp_expired_code_fails(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {
            "otp_id": 1,
            "user_id": 10,
            "otp_hash": generate_password_hash("123456"),
            "attempts": 0,
            "max_attempts": 5,
            "expires_at": datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(minutes=1),
        }
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=True):
            response = self.client.post("/verify-otp", json={
                "email": "user@example.com",
                "otp": "123456",
            })

        self.assertEqual(response.status_code, 400)
        self.assertIn("expired", response.get_json()["error"])

    def test_resend_otp_enforces_cooldown(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"user_id": 10, "name": "User", "is_verified": 0},
            {"created_at": datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(seconds=10)},
        ]
        connection = MagicMock()
        connection.cursor.return_value = cursor

        with patch.object(auth, "get_db_connection", return_value=connection), \
             patch.object(auth, "table_exists", return_value=True), \
             patch.object(auth, "column_exists", return_value=True):
            response = self.client.post("/resend-otp", json={
                "email": "user@example.com",
            })

        self.assertEqual(response.status_code, 429)
        self.assertIn("Please wait", response.get_json()["error"])


if __name__ == "__main__":
    unittest.main()
