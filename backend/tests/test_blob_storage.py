import io
import unittest
from unittest.mock import MagicMock, patch

from flask import Flask

from backend.routes import auth, resources


class BlobStorageTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.app.config["SECRET_KEY"] = "test-blob-storage-secret"
        self.app.register_blueprint(resources.resources_bp)
        self.app.register_blueprint(auth.auth_bp)
        self.client = self.app.test_client()

    def test_open_file_serves_from_resource_files_when_disk_missing(self):
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = {
            "mime_type": "application/pdf",
            "file_data": b"%PDF-1.4 mock pdf data",
            "file_size": 22,
        }
        mock_conn = MagicMock()
        mock_conn.cursor.return_value = mock_cursor

        with (
            patch.object(resources, "get_db_connection", return_value=mock_conn),
            patch.object(resources, "table_exists", return_value=True),
        ):
            # Pass a mock cursor whose __module__ is not unittest.mock so DB path executes
            mock_cursor.__class__.__module__ = "mysql.connector.cursor"
            response = self.client.get("/uploads/test_remote_only.pdf")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, b"%PDF-1.4 mock pdf data")
        self.assertEqual(response.content_type, "application/pdf")
        self.assertIn("max-age=86400", response.headers.get("Cache-Control", ""))

    def test_download_file_serves_as_attachment(self):
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = {
            "mime_type": "application/pdf",
            "file_data": b"%PDF-1.4 downloadable mock data",
            "file_size": 31,
        }
        mock_conn = MagicMock()
        mock_conn.cursor.return_value = mock_cursor

        with (
            patch.object(resources, "get_db_connection", return_value=mock_conn),
            patch.object(resources, "table_exists", return_value=True),
        ):
            mock_cursor.__class__.__module__ = "mysql.connector.cursor"
            response = self.client.get("/download/test_downloadable.pdf")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, b"%PDF-1.4 downloadable mock data")
        self.assertIn("attachment", response.headers.get("Content-Disposition", ""))

    def test_profile_photo_serves_from_resource_files(self):
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = {
            "mime_type": "image/png",
            "file_data": b"\x89PNG\r\n\x1a\n mock png avatar",
        }
        mock_conn = MagicMock()
        mock_conn.cursor.return_value = mock_cursor

        with (
            patch.object(auth, "get_db_connection", return_value=mock_conn),
            patch.object(auth, "table_exists", return_value=True),
        ):
            mock_cursor.__class__.__module__ = "mysql.connector.cursor"
            response = self.client.get("/profile-photos/avatar.png")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, b"\x89PNG\r\n\x1a\n mock png avatar")
        self.assertEqual(response.content_type, "image/png")


if __name__ == "__main__":
    unittest.main()
