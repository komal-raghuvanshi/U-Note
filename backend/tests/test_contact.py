import unittest

from flask import Flask

from backend.routes.contact import contact_bp


class ContactRouteTests(unittest.TestCase):
    def setUp(self):
        app = Flask(__name__)
        app.register_blueprint(contact_bp)
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


if __name__ == "__main__":
    unittest.main()
