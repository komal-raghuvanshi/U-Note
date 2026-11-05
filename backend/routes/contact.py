
import os
import re
import smtplib
from email.message import EmailMessage

from flask import Blueprint, request, jsonify, current_app

contact_bp = Blueprint("contact", __name__)


@contact_bp.route("/contact", methods=["POST"])
def send_contact_message():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({
            "success": False,
            "message": "A JSON object is required."
        }), 400

    fields = ("name", "email", "subject", "message")
    if any(not isinstance(data.get(field), str) for field in fields):
        return jsonify({
            "success": False,
            "message": "All fields must be text."
        }), 400

    name = data["name"].strip()
    email = data["email"].strip()
    subject = data["subject"].strip()
    message = data["message"].strip()

    if not all([name, email, subject, message]):
        return jsonify({
            "success": False,
            "message": "All fields are required."
        }), 400

    if len(name) > 100 or len(email) > 254 or len(subject) > 150 or len(message) > 5000:
        return jsonify({
            "success": False,
            "message": "One or more fields exceed the allowed length."
        }), 400

    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
        return jsonify({
            "success": False,
            "message": "Please enter a valid email address."
        }), 400

    sender_email = os.getenv("UNOTE_EMAIL")
    app_password = os.getenv("UNOTE_EMAIL_APP_PASSWORD")

    if not sender_email or not app_password:
        return jsonify({
            "success": False,
            "message": "Email service is not configured."
        }), 503

    mail = EmailMessage()
    mail["Subject"] = f"U-NOTE Contact: {subject}"
    mail["From"] = sender_email
    mail["To"] = sender_email
    mail["Reply-To"] = email

    mail.set_content(
        f"""
New message received through U-NOTE Contact Us.

Name: {name}
Email: {email}
Subject: {subject}

Message:
{message}
"""
    )

    try:
        with smtplib.SMTP("smtp.gmail.com", 587, timeout=20) as smtp:
            smtp.ehlo()
            smtp.starttls()
            smtp.ehlo()
            smtp.login(sender_email, app_password)
            smtp.send_message(mail)

        return jsonify({
            "success": True,
            "message": "Your message has been sent successfully!"
        }), 200

    except Exception:
        current_app.logger.exception("Contact email sending failed")
        return jsonify({
            "success": False,
            "message": "Unable to send your message right now. Please try again later."
        }), 500
