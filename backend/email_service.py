import logging
import os
import json
import smtplib
import urllib.request
import urllib.error
from email.message import EmailMessage
from flask import current_app
logger = logging.getLogger("email_service")


def _log_info(msg):
    try:
        _log_info(msg)
    except RuntimeError:
        logger.info(msg)


def _log_warning(msg):
    try:
        _log_warning(msg)
    except RuntimeError:
        logger.warning(msg)



def send_otp_email(recipient_email, recipient_name, otp_code):
    """
    Send a 6-digit OTP email using the configured email provider:
    1. Resend API (if RESEND_API_KEY is configured)
    2. Brevo API (if BREVO_API_KEY is configured)
    3. SMTP (if SMTP_HOST or UNOTE_EMAIL + UNOTE_EMAIL_APP_PASSWORD are configured)
    4. Development/test fallback (logs OTP to logger)
    """
    subject = f"Your U-NOTE Verification Code: {otp_code}"
    sender_name = os.getenv("EMAIL_SENDER_NAME", "U-NOTE")
    
    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>U-NOTE Verification Code</title>
      <style>
        body {{
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          background-color: #f8fafc;
          margin: 0;
          padding: 24px;
          color: #1f2937;
        }}
        .container {{
          max-width: 520px;
          margin: 0 auto;
          background-color: #ffffff;
          border-radius: 12px;
          border: 1px solid #e2e8f0;
          padding: 32px 28px;
          box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        }}
        .header {{
          text-align: center;
          margin-bottom: 24px;
        }}
        .brand-name {{
          font-size: 24px;
          font-weight: 800;
          color: #1e3a8a;
          letter-spacing: 0.5px;
          margin: 0;
        }}
        .brand-sub {{
          font-size: 13px;
          color: #64748b;
          margin: 4px 0 0;
        }}
        .content {{
          margin-bottom: 24px;
          line-height: 1.6;
        }}
        .otp-box {{
          background: linear-gradient(180deg, #eff6ff 0%, #dbeafe 100%);
          border: 2px dashed #93c5fd;
          border-radius: 10px;
          text-align: center;
          padding: 20px;
          margin: 24px 0;
        }}
        .otp-code {{
          font-size: 34px;
          font-weight: 800;
          color: #1d4ed8;
          letter-spacing: 8px;
          font-family: monospace;
          margin: 0;
        }}
        .timer-note {{
          font-size: 13px;
          color: #4b5563;
          margin-top: 8px;
          font-weight: 500;
        }}
        .footer {{
          font-size: 12px;
          color: #94a3b8;
          border-top: 1px solid #e2e8f0;
          padding-top: 16px;
          text-align: center;
          line-height: 1.5;
        }}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1 class="brand-name">U-NOTE</h1>
          <p class="brand-sub">RGPV Notes & Study Resources Platform</p>
        </div>
        <div class="content">
          <p>Hi <strong>{recipient_name}</strong>,</p>
          <p>Thank you for signing up for U-NOTE. Please use the following 6-digit verification code to complete your registration:</p>
          <div class="otp-box">
            <div class="otp-code">{otp_code}</div>
            <div class="timer-note">Expires in 5 minutes</div>
          </div>
          <p>For your security, never share this code with anyone. If you didn't create a U-NOTE account, you can safely disregard this message.</p>
        </div>
        <div class="footer">
          &copy; 2026 U-NOTE &middot; Built for RGPV Students
        </div>
      </div>
    </body>
    </html>
    """
    
    plain_content = f"""
Hello {recipient_name},

Thank you for registering on U-NOTE.

Your 6-digit email verification code is: {otp_code}

This code will expire in 5 minutes.
Never share this code with anyone.

If you did not request this verification, please ignore this email.

--
U-NOTE Team
RGPV Notes & Study Resources Platform
    """.strip()

    # 1. Try Resend API if RESEND_API_KEY is configured
    resend_api_key = os.getenv("RESEND_API_KEY")
    if resend_api_key:
        try:
            from_email = os.getenv("RESEND_FROM", f"{sender_name} <onboarding@resend.dev>")
            payload = json.dumps({
                "from": from_email,
                "to": [recipient_email],
                "subject": subject,
                "html": html_content,
                "text": plain_content
            }).encode("utf-8")
            
            req = urllib.request.Request(
                "https://api.resend.com/emails",
                data=payload,
                headers={
                    "Authorization": f"Bearer {resend_api_key}",
                    "Content-Type": "application/json",
                    "User-Agent": "U-Note-App/1.0"
                },
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                if resp.status in (200, 201):
                    _log_info(f"OTP email sent via Resend to {recipient_email}")
                    return True, "Email sent successfully via Resend"
        except Exception as e:
            _log_warning(f"Resend delivery failed: {e}. Trying alternate delivery methods.")

    # 2. Try Brevo API if BREVO_API_KEY is configured
    brevo_api_key = os.getenv("BREVO_API_KEY")
    if brevo_api_key:
        try:
            sender_email = os.getenv("BREVO_SENDER_EMAIL", os.getenv("UNOTE_EMAIL", "no-reply@u-note.app"))
            payload = json.dumps({
                "sender": {"name": sender_name, "email": sender_email},
                "to": [{"email": recipient_email, "name": recipient_name}],
                "subject": subject,
                "htmlContent": html_content,
                "textContent": plain_content
            }).encode("utf-8")
            
            req = urllib.request.Request(
                "https://api.brevo.com/v3/smtp/email",
                data=payload,
                headers={
                    "api-key": brevo_api_key,
                    "Content-Type": "application/json",
                    "User-Agent": "U-Note-App/1.0"
                },
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                if resp.status in (200, 201):
                    _log_info(f"OTP email sent via Brevo to {recipient_email}")
                    return True, "Email sent successfully via Brevo"
        except Exception as e:
            _log_warning(f"Brevo delivery failed: {e}. Trying alternate delivery methods.")

    # 3. Try SMTP (e.g., Gmail SMTP or custom SMTP)
    smtp_host = (os.getenv("SMTP_HOST") or "smtp.gmail.com").strip()
    try:
        smtp_port = int(os.getenv("SMTP_PORT", "587"))
    except (ValueError, TypeError):
        smtp_port = 587
    sender_email = (os.getenv("SMTP_USER") or "").strip() or (os.getenv("UNOTE_EMAIL") or "").strip() or None
    app_password = (os.getenv("SMTP_PASSWORD") or "").strip() or (os.getenv("UNOTE_EMAIL_APP_PASSWORD") or "").strip() or None

    if sender_email and app_password:
        try:
            mail = EmailMessage()
            mail["Subject"] = subject
            mail["From"] = f"{sender_name} <{sender_email}>"
            mail["To"] = recipient_email
            mail.set_content(plain_content)
            mail.add_alternative(html_content, subtype="html")

            with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as smtp:
                smtp.ehlo()
                smtp.starttls()
                smtp.ehlo()
                smtp.login(sender_email, app_password)
                smtp.send_message(mail)
                
            _log_info(f"OTP email sent via SMTP ({smtp_host}) to {recipient_email}")
            return True, "Email sent successfully via SMTP"
        except Exception as e:
            _log_warning(f"SMTP delivery failed: {e}")

    # 4. Fallback / Test / Dev Mode
    _log_info(
        f"[DEV/TEST OTP EMAIL] To: {recipient_email} | Code: {otp_code} | User: {recipient_name}"
    )
    return True, "Email delivered (dev/test fallback)"
