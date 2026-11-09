import unittest
from unittest.mock import MagicMock, patch
from flask import Flask

from backend.auth_utils import create_auth_token
from backend.routes.admin import admin_bp
from backend.routes.notifications import notifications_bp
from backend.routes.reports import reports_bp


class AdminAndNotificationsTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.app.config["SECRET_KEY"] = "admin-test-secret"
        self.app.register_blueprint(admin_bp)
        self.app.register_blueprint(notifications_bp)
        self.app.register_blueprint(reports_bp)
        self.client = self.app.test_client()

    def auth_headers(self, user_id):
        with self.app.app_context():
            token = create_auth_token(user_id)
        return {"Authorization": f"Bearer {token}"}

    def test_admin_stats_requires_admin(self):
        # 1. No token -> 401
        res = self.client.get("/admin/stats")
        self.assertEqual(res.status_code, 401)

        # 2. Regular user (role = student) -> 403
        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.auth_utils.is_admin_user", return_value=False), \
             patch("backend.auth_utils.get_db_connection", return_value=MagicMock()):
            headers = self.auth_headers(101)
            res = self.client.get("/admin/stats", headers=headers)
            self.assertEqual(res.status_code, 403)
            data = res.get_json()
            self.assertIn("Admin privileges are required", data["message"])

    def test_admin_stats_success_for_admin(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"total": 50},  # total users
            {"total": 120}, # total resources
            {"total": 3},   # pending approvals
            {"total": 12},  # total requests
            {"total": 1},   # pending reports
        ]
        cursor.fetchall.side_effect = [
            [], # recent resource uploads
            [], # recent reports
        ]
        conn = MagicMock()
        conn.cursor.return_value = cursor

        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.auth_utils.is_admin_user", return_value=True), \
             patch("backend.auth_utils.get_db_connection", return_value=conn), \
             patch("backend.routes.admin.get_db_connection", return_value=conn), \
             patch("backend.routes.admin.column_exists", return_value=True), \
             patch("backend.routes.admin.table_exists", return_value=True):
            headers = self.auth_headers(1)
            res = self.client.get("/admin/stats", headers=headers)
            self.assertEqual(res.status_code, 200)
            data = res.get_json()
            self.assertTrue(data["success"])
            self.assertEqual(data["stats"]["total_users"], 50)
            self.assertEqual(data["stats"]["total_resources"], 120)

    def test_admin_block_user(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"user_id": 42, "name": "Student Bad", "is_blocked": 0, "role": "student"}
        conn = MagicMock()
        conn.cursor.return_value = cursor

        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.auth_utils.is_admin_user", return_value=True), \
             patch("backend.auth_utils.get_db_connection", return_value=conn), \
             patch("backend.routes.admin.get_db_connection", return_value=conn):
            headers = self.auth_headers(1)
            res = self.client.put("/admin/users/42/block", json={"is_blocked": True}, headers=headers)
            self.assertEqual(res.status_code, 200)
            data = res.get_json()
            self.assertTrue(data["success"])
            cursor.execute.assert_any_call("UPDATE users SET is_blocked = %s WHERE user_id = %s", (1, 42))

    def test_admin_cannot_block_self(self):
        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.auth_utils.is_admin_user", return_value=True), \
             patch("backend.auth_utils.get_db_connection", return_value=MagicMock()):
            headers = self.auth_headers(1)
            res = self.client.put("/admin/users/1/block", json={"is_blocked": True}, headers=headers)
            self.assertEqual(res.status_code, 400)
            data = res.get_json()
            self.assertIn("cannot block your own admin account", data["message"])

    def test_admin_update_resource_approval(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"resource_id": 10, "title": "Math Notes", "uploaded_by": 5}
        conn = MagicMock()
        conn.cursor.return_value = cursor

        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.auth_utils.is_admin_user", return_value=True), \
             patch("backend.auth_utils.get_db_connection", return_value=conn), \
             patch("backend.routes.admin.get_db_connection", return_value=conn), \
             patch("backend.routes.admin.column_exists", return_value=True), \
             patch("backend.routes.admin.create_notification") as mock_notif:
            headers = self.auth_headers(1)
            res = self.client.put("/admin/resources/10/approval", json={"approval_status": "approved"}, headers=headers)
            self.assertEqual(res.status_code, 200)
            data = res.get_json()
            self.assertTrue(data["success"])
            mock_notif.assert_called_once()

    def test_submit_report_and_spam_prevention(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [
            {"resource_id": 5, "title": "Algorithms 101"}, # resource exists
            {"report_id": 99} # already pending report exists!
        ]
        conn = MagicMock()
        conn.cursor.return_value = cursor

        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.routes.reports.get_db_connection", return_value=conn), \
             patch("backend.routes.reports.table_exists", return_value=True):
            headers = self.auth_headers(20)
            res = self.client.post("/resources/5/reports", json={
                "reason": "Duplicate Resource",
                "details": "This exact file was already uploaded."
            }, headers=headers)
            self.assertEqual(res.status_code, 400)
            data = res.get_json()
            self.assertIn("already have a pending report", data["message"])

    def test_notifications_flow(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = {"unread_count": 3}
        conn = MagicMock()
        conn.cursor.return_value = cursor

        with patch("backend.auth_utils.check_user_blocked", return_value=False), \
             patch("backend.routes.notifications.get_db_connection", return_value=conn), \
             patch("backend.routes.notifications.table_exists", return_value=True):
            headers = self.auth_headers(15)
            res = self.client.get("/notifications/unread-count", headers=headers)
            self.assertEqual(res.status_code, 200)
            data = res.get_json()
            self.assertEqual(data["unread_count"], 3)


if __name__ == "__main__":
    unittest.main()
