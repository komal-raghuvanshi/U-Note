import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class VercelImportTests(unittest.TestCase):
    def test_local_upload_limits_remain_unchanged(self):
        backend_directory = Path(__file__).resolve().parents[1]
        script = """
import app
from routes import auth, resources

assert app.app.config["MAX_CONTENT_LENGTH"] == 26 * 1024 * 1024
assert resources.MAX_FILE_SIZE == 25 * 1024 * 1024
assert auth.MAX_PROFILE_PHOTO_SIZE == 5 * 1024 * 1024
"""
        environment = os.environ.copy()
        environment.pop("VERCEL", None)
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        result = subprocess.run(
            [sys.executable, "-c", script],
            cwd=backend_directory,
            env=environment,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        self.assertEqual(
            result.returncode,
            0,
            "Local upload limits changed unexpectedly.",
        )

    def test_app_import_does_not_create_directories(self):
        backend_directory = Path(__file__).resolve().parents[1]
        script = """
import os
import tempfile

def fail_on_directory_creation(*args, **kwargs):
    raise AssertionError("Application import attempted filesystem directory creation")

os.makedirs = fail_on_directory_creation
os.mkdir = fail_on_directory_creation
os.environ.update({
    "UNOTE_DB_HOST": "preview.aivencloud.com",
    "UNOTE_DB_PORT": "1234",
    "UNOTE_DB_USER": "deployment-test-user",
    "UNOTE_DB_PASSWORD": "deployment-test-password",
    "UNOTE_DB_NAME": "defaultdb",
    "UNOTE_SECRET_KEY": "deployment-test-secret",
})
import app
from routes import auth, resources

routes = {rule.rule for rule in app.app.url_map.iter_rules()}
assert "/branches" in routes
assert "/profile-photos/<path:filename>" in routes
assert "/download/<filename>" in routes
temp_directory = tempfile.gettempdir()
assert os.path.commonpath([auth.PROFILE_PHOTO_FOLDER, temp_directory]) == temp_directory
assert os.path.commonpath([resources.UPLOAD_FOLDER, temp_directory]) == temp_directory
assert app.app.config["SECRET_KEY"] == os.environ["UNOTE_SECRET_KEY"]
assert app.app.config["MAX_CONTENT_LENGTH"] == 4_500_000
assert resources.MAX_FILE_SIZE == 4 * 1024 * 1024
assert auth.MAX_PROFILE_PHOTO_SIZE == 4 * 1024 * 1024

import db
from unittest.mock import MagicMock, patch

with patch.object(db.mysql.connector, "connect") as connect:
    db.get_db_connection()

connection_options = connect.call_args.kwargs
assert connection_options["host"] == os.environ["UNOTE_DB_HOST"]
assert connection_options["port"] == int(os.environ["UNOTE_DB_PORT"])
assert connection_options["user"] == os.environ["UNOTE_DB_USER"]
assert connection_options["password"] == os.environ["UNOTE_DB_PASSWORD"]
assert connection_options["database"] == "defaultdb"
assert connection_options["ssl_verify_cert"] is True
assert connection_options["ssl_verify_identity"] is True

client = app.app.test_client()
cursor = MagicMock()
cursor.fetchall.return_value = []
connection = MagicMock()
connection.cursor.return_value = cursor
with patch("routes.branches.get_db_connection", return_value=connection):
    assert client.get("/branches").status_code == 200
    assert client.get("/semesters?branch=AIML").status_code == 200
with patch("routes.subjects.get_db_connection", return_value=connection):
    assert client.get("/subjects?branch=AIML&semester=1").status_code == 200
    assert client.get("/units?branch=AIML&semester=1").status_code == 200
with patch("routes.resources._fetch_all_resources", return_value=[]):
    assert client.get("/resources").status_code == 200
"""
        environment = os.environ.copy()
        environment["VERCEL"] = "1"
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        result = subprocess.run(
            [sys.executable, "-c", script],
            cwd=backend_directory,
            env=environment,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        self.assertEqual(
            result.returncode,
            0,
            "Flask import failed under read-only filesystem guard.",
        )


if __name__ == "__main__":
    unittest.main()
