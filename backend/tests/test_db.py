import os
import unittest
from unittest.mock import patch

from backend import db


class DatabaseConnectionTests(unittest.TestCase):
    def setUp(self):
        self.environment = {
            "UNOTE_DB_HOST": "db.example",
            "UNOTE_DB_PORT": "3307",
            "UNOTE_DB_NAME": "u_note",
        }

    def getenv(self, name, default=None):
        return self.environment.get(name, default)

    def test_connection_uses_project_ca_with_certificate_verification(self):
        self.environment["UNOTE_DB_HOST"] = "test.aivencloud.com"
        ca_path = os.path.join(os.path.dirname(os.path.abspath(db.__file__)), "ca.pem")
        with (
            patch.object(db.os, "getenv", side_effect=self.getenv),
            patch.object(db.os.path, "isfile", return_value=True),
            patch.object(db.mysql.connector, "connect") as connect,
        ):
            db.get_db_connection()

        options = connect.call_args.kwargs
        self.assertEqual(options["ssl_ca"], ca_path)
        self.assertTrue(options["ssl_verify_cert"])
        self.assertTrue(options["ssl_verify_identity"])
        self.assertEqual(options["host"], "test.aivencloud.com")
        self.assertEqual(options["port"], 3307)
        self.assertIsNone(options["user"])
        self.assertIsNone(options["password"])
        self.assertEqual(options["database"], "u_note")

    def test_local_connection_remains_compatible_when_ca_is_present(self):
        with (
            patch.object(db.os, "getenv", side_effect=self.getenv),
            patch.object(db.os.path, "isfile", return_value=True),
            patch.object(db.mysql.connector, "connect") as connect,
        ):
            db.get_db_connection()

        self.assertNotIn("ssl_ca", connect.call_args.kwargs)
        self.assertNotIn("ssl_verify_cert", connect.call_args.kwargs)
        self.assertNotIn("ssl_verify_identity", connect.call_args.kwargs)

    def test_local_connection_remains_compatible_when_ca_is_missing(self):
        with (
            patch.object(db.os, "getenv", side_effect=self.getenv),
            patch.object(db.os.path, "isfile", return_value=False),
            patch.object(db.mysql.connector, "connect") as connect,
        ):
            db.get_db_connection()

        self.assertNotIn("ssl_ca", connect.call_args.kwargs)
        self.assertNotIn("ssl_verify_cert", connect.call_args.kwargs)
        self.assertNotIn("ssl_verify_identity", connect.call_args.kwargs)

    def test_vercel_connection_fails_clearly_when_ca_is_missing(self):
        def vercel_getenv(name, default=None):
            return "1" if name == "VERCEL" else self.environment.get(name, default)

        with (
            patch.object(db.os, "getenv", side_effect=vercel_getenv),
            patch.object(db.os.path, "isfile", return_value=False),
            patch.object(db.mysql.connector, "connect") as connect,
        ):
            with self.assertRaisesRegex(FileNotFoundError, "ca.pem"):
                db.get_db_connection()

        connect.assert_not_called()


if __name__ == "__main__":
    unittest.main()
