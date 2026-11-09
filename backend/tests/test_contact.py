import os
import unittest
from unittest.mock import patch

from flask import Flask

from backend.routes import contact


class ContactRouteTests(unittest.TestCase):
    def setUp(self):
        app = Flask(__name__)
        app.register_blueprint(contact.contact_bp)
        self.client = app.test_client()

    def test_contact_requires_json_object(self):
        response = self.client.post("/contact", json=[])

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.get_json()["message"], "A JSON object is required.")

    def test_contact_rejects_non_text_fields(self):
        response = self.client.post("/contact", json={
            "name": 123,
            "email": "student@example.com",
            "subject": "Help",
            "message": "Question",
        })

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.get_json()["message"], "All fields must be text.")

    def test_contact_reports_missing_email_configuration_without_sending(self):
        payload = {
            "name": "Preview Check",
            "email": "preview@example.invalid",
            "subject": "Configuration check",
            "message": "No email should be sent by this test.",
        }
        with (
            patch.dict(os.environ, {
                "UNOTE_EMAIL": "",
                "UNOTE_EMAIL_APP_PASSWORD": "",
            }),
            patch.object(contact.smtplib, "SMTP") as smtp,
        ):
            response = self.client.post("/contact", json=payload)

        self.assertEqual(response.status_code, 503)
        self.assertEqual(
            response.get_json()["message"],
            "Email service is not configured."
        )
        smtp.assert_not_called()


if __name__ == "__main__":
    unittest.main()
