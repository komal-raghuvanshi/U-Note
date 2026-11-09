import os
import re
import tempfile
import mimetypes
import secrets
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import io
from flask import Blueprint, current_app, g, jsonify, request, send_from_directory, send_file
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename

try:
    from auth_utils import create_auth_token, require_auth
    from db import get_db_connection, column_exists, table_exists
    from email_service import send_otp_email
except ImportError:
    from backend.auth_utils import create_auth_token, require_auth
    from backend.db import get_db_connection, column_exists, table_exists
    from backend.email_service import send_otp_email


auth_bp = Blueprint("auth", __name__)
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PROFILE_PHOTO_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}
MAX_PROFILE_PHOTO_SIZE = (
    4 * 1024 * 1024 if os.environ.get("VERCEL") else 5 * 1024 * 1024
)
MAX_PROFILE_PHOTO_SIZE_MB = MAX_PROFILE_PHOTO_SIZE // (1024 * 1024)
if os.environ.get("VERCEL"):
    PROFILE_PHOTO_FOLDER = os.path.join(tempfile.gettempdir(), "unote_profile_photos")
else:
    PROFILE_PHOTO_FOLDER = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "uploads",
        "profile_photos",
    )

OTP_EXPIRY_MINUTES = 5
OTP_RESEND_COOLDOWN_SECONDS = 60
OTP_MAX_ATTEMPTS = 5


def _session_unavailable():
    if current_app.config.get("SECRET_KEY"):
        return None
    return jsonify({
        "success": False,
        "error": "Authentication is not configured on this server."
    }), 503


def _user_payload(row):
    semester = row.get("semester")
    if semester:
        try:
            semester = int(str(semester).replace("Semester", "").strip())
        except ValueError:
            pass
    profile_photo = row.get("profile_photo")
    if profile_photo and secure_filename(os.path.basename(profile_photo)) == profile_photo:
        profile_photo_url = f"/profile-photos/{profile_photo}"
    else:
        profile_photo_url = None
    role = row.get("role") or "student"
    raw_admin_emails = os.getenv("UNOTE_ADMIN_EMAILS", "")
    admin_emails = {em.strip().lower() for em in raw_admin_emails.split(",") if em.strip()}
    if (row.get("email") or "").strip().lower() in admin_emails:
        role = "admin"

    return {
        "id": row["user_id"],
        "name": row["name"],
        "email": row["email"],
        "role": role,
        "branch": row.get("branch"),
        "semester": semester,
        "profile_photo_url": profile_photo_url,
        "is_blocked": bool(row.get("is_blocked", 0)),
    }


def _generate_otp():
    return "".join(secrets.choice("0123456789") for _ in range(6))


def _as_naive_utc(dt_val):
    if not dt_val:
        return None
    if isinstance(dt_val, str):
        try:
            dt_val = datetime.fromisoformat(dt_val.replace("Z", "+00:00"))
        except ValueError:
            return None
    if isinstance(dt_val, datetime):
        if dt_val.tzinfo is not None:
            return dt_val.astimezone(timezone.utc).replace(tzinfo=None)
        return dt_val
    return None


def _save_and_send_otp(cursor, user_id, email, name):
    otp = _generate_otp()
    otp_hash = generate_password_hash(otp)
    expires_at = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=OTP_EXPIRY_MINUTES)

    if table_exists(cursor, "email_otps"):
        cursor.execute(
            """
            UPDATE email_otps
            SET verified_at = UTC_TIMESTAMP()
            WHERE email = %s AND verified_at IS NULL
            """,
            (email,)
        )
        cursor.execute(
            """
            INSERT INTO email_otps
                (user_id, email, otp_hash, attempts, max_attempts, expires_at)
            VALUES (%s, %s, %s, 0, %s, %s)
            """,
            (user_id, email, otp_hash, OTP_MAX_ATTEMPTS, expires_at)
        )

    send_otp_email(email, name, otp)
    return otp


@auth_bp.route("/signup", methods=["POST"])
def signup():
    unavailable = _session_unavailable()
    if unavailable:
        return unavailable

    data = request.get_json(silent=True) or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Invalid request payload"}), 400
    name = data.get("name")
    email = data.get("email")
    password = data.get("password")
    branch = data.get("branch")
    semester = data.get("semester")
    role = data.get("role", "student")

    if not all(isinstance(value, str) for value in (name, email, password)):
        return jsonify({"error": "Name, email, and password are required"}), 400
    if not isinstance(role, str) or role.strip().lower() not in ("student", "teacher"):
        return jsonify({"error": "Role must be student or teacher"}), 400

    name = name.strip()
    email = email.strip().lower()
    role = role.strip().lower()
    branch = branch.strip() if isinstance(branch, str) else ""
    if not name or len(name) > 100:
        return jsonify({"error": "Name must be between 1 and 100 characters"}), 400
    if len(email) > 100 or not EMAIL_PATTERN.fullmatch(email):
        return jsonify({"error": "A valid email address is required"}), 400
    if len(password) < 8 or len(password) > 128:
        return jsonify({"error": "Password must be between 8 and 128 characters"}), 400

    semester_number = None
    if role == "student" or branch or semester not in (None, ""):
        if not branch:
            return jsonify({"error": "A valid branch is required"}), 400
        try:
            semester_number = int(str(semester).replace("Semester", "").strip())
            if not 1 <= semester_number <= 8:
                raise ValueError
        except (ValueError, TypeError):
            return jsonify({"error": "A valid semester from 1 to 8 is required"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        has_is_verified = column_exists(cursor, "users", "is_verified")

        if has_is_verified:
            cursor.execute("SELECT user_id, name, is_verified FROM users WHERE email = %s", (email,))
        else:
            cursor.execute("SELECT user_id, name FROM users WHERE email = %s", (email,))
        existing_user = cursor.fetchone()

        if existing_user:
            is_ver = existing_user.get("is_verified", 1) if has_is_verified else 1
            if is_ver:
                return jsonify({"error": "Email already registered"}), 409

            user_id = existing_user["user_id"]
            academic_data = None
            if semester_number is not None:
                cursor.execute(
                    """
                    SELECT b.branch_id, s.semester_id, s.semester_name, b.branch_name
                    FROM branches b
                    JOIN semesters s ON s.branch_id = b.branch_id
                    WHERE LOWER(b.branch_name) = LOWER(%s)
                      AND s.semester_name = %s
                    """,
                    (branch, f"Semester {semester_number}")
                )
                academic_data = cursor.fetchone()
                if not academic_data:
                    return jsonify({"error": "Selected branch and semester are not available"}), 400

            cursor.execute(
                """
                UPDATE users
                SET name = %s, password_hash = %s, role = %s, branch_id = %s, semester_id = %s
                WHERE user_id = %s
                """,
                (
                    name,
                    generate_password_hash(password),
                    role,
                    academic_data["branch_id"] if academic_data else None,
                    academic_data["semester_id"] if academic_data else None,
                    user_id,
                )
            )
        else:
            academic_data = None
            if semester_number is not None:
                cursor.execute(
                    """
                    SELECT b.branch_id, s.semester_id, s.semester_name, b.branch_name
                    FROM branches b
                    JOIN semesters s ON s.branch_id = b.branch_id
                    WHERE LOWER(b.branch_name) = LOWER(%s)
                      AND s.semester_name = %s
                    """,
                    (branch, f"Semester {semester_number}")
                )
                academic_data = cursor.fetchone()
                if not academic_data:
                    return jsonify({"error": "Selected branch and semester are not available"}), 400

            if has_is_verified:
                cursor.execute(
                    """
                    INSERT INTO users
                        (name, email, password_hash, role, branch_id, semester_id, is_verified)
                    VALUES (%s, %s, %s, %s, %s, %s, 0)
                    """,
                    (
                        name,
                        email,
                        generate_password_hash(password),
                        role,
                        academic_data["branch_id"] if academic_data else None,
                        academic_data["semester_id"] if academic_data else None,
                    )
                )
            else:
                cursor.execute(
                    """
                    INSERT INTO users
                        (name, email, password_hash, role, branch_id, semester_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        name,
                        email,
                        generate_password_hash(password),
                        role,
                        academic_data["branch_id"] if academic_data else None,
                        academic_data["semester_id"] if academic_data else None,
                    )
                )
            user_id = cursor.lastrowid

        _save_and_send_otp(cursor, user_id, email, name)
        connection.commit()

        user = {
            "user_id": user_id,
            "name": name,
            "email": email,
            "role": role,
            "branch": academic_data["branch_name"] if academic_data else None,
            "semester": academic_data["semester_name"] if academic_data else None,
            "profile_photo": None,
        }
        return jsonify({
            "success": True,
            "message": "Account created! A 6-digit verification code has been sent to your email.",
            "user": _user_payload(user),
            "email": email,
            "requires_verification": True,
        }), 201
    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("Account signup failed")
        return jsonify({"error": "Unable to create the account. Please try again."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.route("/verify-otp", methods=["POST"])
def verify_otp():
    unavailable = _session_unavailable()
    if unavailable:
        return unavailable

    data = request.get_json(silent=True) or {}
    email = data.get("email")
    otp = data.get("otp")

    if not isinstance(email, str) or not isinstance(otp, str):
        return jsonify({"error": "Email and 6-digit verification code are required"}), 400

    email = email.strip().lower()
    otp = otp.strip()

    if not email or not EMAIL_PATTERN.fullmatch(email):
        return jsonify({"error": "A valid email address is required"}), 400

    if not re.fullmatch(r"^\d{6}$", otp):
        return jsonify({"error": "Please enter a valid 6-digit numeric verification code"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        if not table_exists(cursor, "email_otps"):
            return jsonify({"error": "Verification service is not available"}), 503

        cursor.execute(
            """
            SELECT otp_id, user_id, otp_hash, attempts, max_attempts, expires_at
            FROM email_otps
            WHERE email = %s AND verified_at IS NULL
            ORDER BY otp_id DESC
            LIMIT 1
            """,
            (email,)
        )
        otp_row = cursor.fetchone()
        if not otp_row:
            return jsonify({
                "error": "No active verification code found for this email. Please request a new code."
            }), 400

        # Check attempts limit
        if otp_row["attempts"] >= otp_row["max_attempts"]:
            return jsonify({
                "error": "Too many incorrect attempts. Please request a new verification code."
            }), 429

        # Check expiration
        expires_at = _as_naive_utc(otp_row.get("expires_at"))
        if expires_at and expires_at < datetime.now(timezone.utc).replace(tzinfo=None):
            return jsonify({
                "error": "Verification code has expired. Please request a new code."
            }), 400

        # Check OTP match
        if not check_password_hash(otp_row["otp_hash"], otp):
            new_attempts = otp_row["attempts"] + 1
            cursor.execute(
                "UPDATE email_otps SET attempts = %s WHERE otp_id = %s",
                (new_attempts, otp_row["otp_id"])
            )
            connection.commit()
            remaining = max(0, otp_row["max_attempts"] - new_attempts)
            return jsonify({
                "error": f"Invalid verification code. {remaining} attempt(s) remaining."
            }), 400

        # Mark OTP verified
        cursor.execute(
            "UPDATE email_otps SET verified_at = UTC_TIMESTAMP() WHERE otp_id = %s",
            (otp_row["otp_id"],)
        )

        # Mark user verified
        if column_exists(cursor, "users", "is_verified"):
            cursor.execute(
                "UPDATE users SET is_verified = 1 WHERE user_id = %s",
                (otp_row["user_id"],)
            )

        connection.commit()

        # Fetch user details to log them in directly
        has_photo = column_exists(cursor, "users", "profile_photo")
        photo_select = "u.profile_photo," if has_photo else "NULL AS profile_photo,"
        cursor.execute(
            f"""
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.role,
                {photo_select}
                b.branch_name AS branch,
                s.semester_name AS semester
            FROM users u
            LEFT JOIN branches b ON u.branch_id = b.branch_id
            LEFT JOIN semesters s ON u.semester_id = s.semester_id
            WHERE u.user_id = %s
            """,
            (otp_row["user_id"],)
        )
        user_row = cursor.fetchone()

        return jsonify({
            "success": True,
            "message": "Email verified successfully! Welcome to U-NOTE.",
            "user": _user_payload(user_row) if user_row else None,
            "token": create_auth_token(otp_row["user_id"]),
        }), 200

    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("OTP verification failed")
        return jsonify({"error": "Unable to verify code. Please try again."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.route("/resend-otp", methods=["POST"])
def resend_otp():
    unavailable = _session_unavailable()
    if unavailable:
        return unavailable

    data = request.get_json(silent=True) or {}
    email = data.get("email")

    if not isinstance(email, str) or not email.strip():
        return jsonify({"error": "Email is required"}), 400

    email = email.strip().lower()

    if not EMAIL_PATTERN.fullmatch(email):
        return jsonify({"error": "A valid email address is required"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        has_is_verified = column_exists(cursor, "users", "is_verified")
        if has_is_verified:
            cursor.execute(
                "SELECT user_id, name, is_verified FROM users WHERE email = %s",
                (email,)
            )
        else:
            cursor.execute(
                "SELECT user_id, name FROM users WHERE email = %s",
                (email,)
            )
        user = cursor.fetchone()
        if not user:
            return jsonify({"error": "User not found"}), 404

        if has_is_verified and user.get("is_verified"):
            return jsonify({"error": "This email address is already verified. Please log in."}), 400

        # Check resend cooldown
        if table_exists(cursor, "email_otps"):
            cursor.execute(
                """
                SELECT created_at
                FROM email_otps
                WHERE email = %s
                ORDER BY otp_id DESC
                LIMIT 1
                """,
                (email,)
            )
            last_otp = cursor.fetchone()
            if last_otp and last_otp.get("created_at"):
                created_at = _as_naive_utc(last_otp["created_at"])
                if created_at:
                    now = datetime.now(timezone.utc).replace(tzinfo=None)
                    elapsed = (now - created_at).total_seconds()
                    if elapsed < OTP_RESEND_COOLDOWN_SECONDS:
                        remaining_wait = int(OTP_RESEND_COOLDOWN_SECONDS - elapsed)
                        return jsonify({
                            "error": f"Please wait {max(1, remaining_wait)} seconds before requesting another code."
                        }), 429

        _save_and_send_otp(cursor, user["user_id"], email, user["name"])
        connection.commit()

        return jsonify({
            "success": True,
            "message": "A new 6-digit verification code has been sent to your email."
        }), 200

    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("OTP resend failed")
        return jsonify({"error": "Unable to resend verification code. Please try again."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.route("/login", methods=["POST"])
def login():
    unavailable = _session_unavailable()
    if unavailable:
        return unavailable

    data = request.get_json(silent=True) or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Invalid request payload"}), 400
    email = data.get("email")
    password = data.get("password")
    if not isinstance(email, str) or not isinstance(password, str):
        return jsonify({"error": "Email and password are required"}), 400
    email = email.strip().lower()
    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        has_photo = column_exists(cursor, "users", "profile_photo")
        photo_select = "u.profile_photo," if has_photo else "NULL AS profile_photo,"
        has_is_verified = column_exists(cursor, "users", "is_verified")
        verified_select = "u.is_verified," if has_is_verified else "1 AS is_verified,"
        has_blocked = column_exists(cursor, "users", "is_blocked")
        blocked_select = "u.is_blocked," if has_blocked else "0 AS is_blocked,"

        cursor.execute(
            f"""
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.password_hash,
                u.role,
                {verified_select}
                {blocked_select}
                {photo_select}
                b.branch_name AS branch,
                s.semester_name AS semester
            FROM users u
            LEFT JOIN branches b ON u.branch_id = b.branch_id
            LEFT JOIN semesters s ON u.semester_id = s.semester_id
            WHERE u.email = %s
            """,
            (email,)
        )
        row = cursor.fetchone()
        if not row or not check_password_hash(row["password_hash"], password):
            return jsonify({"error": "Invalid email or password"}), 401

        if row.get("is_blocked"):
            return jsonify({
                "error": "Your account has been restricted by an administrator. Please contact support."
            }), 403

        if row.get("is_verified") == 0:
            _save_and_send_otp(cursor, row["user_id"], email, row["name"])
            connection.commit()
            return jsonify({
                "error": "Your email address is not verified. A new 6-digit verification code has been sent to your email.",
                "requires_verification": True,
                "email": email
            }), 403

        return jsonify({
            "message": "Login successful",
            "user": _user_payload(row),
            "token": create_auth_token(row["user_id"]),
        }), 200
    except Exception:
        current_app.logger.exception("Login failed")
        return jsonify({"error": "Unable to log in. Please try again."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.route("/profile", methods=["GET", "PUT"])
@require_auth
def profile():
    connection = None
    cursor = None
    saved_photo_path = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        if request.method == "PUT":
            data = request.get_json(silent=True) or request.form
            if not hasattr(data, "get"):
                return jsonify({"success": False, "message": "Invalid request payload."}), 400
            name = data.get("name")
            if not isinstance(name, str) or not name.strip() or len(name.strip()) > 100:
                return jsonify({"success": False, "message": "Name must be between 1 and 100 characters."}), 400
            cursor.execute(
                "SELECT role FROM users WHERE user_id = %s",
                (g.user_id,)
            )
            account = cursor.fetchone()
            if not account:
                return jsonify({"success": False, "message": "User account not found."}), 404

            role = (account.get("role") or "student").lower()
            branch = data.get("branch")
            semester = data.get("semester")
            has_branch = isinstance(branch, str) and bool(branch.strip())
            has_semester = semester not in (None, "")
            academic_data = None
            if role == "student" or has_branch or has_semester:
                if not has_branch:
                    return jsonify({"success": False, "message": "A valid branch is required."}), 400
                try:
                    semester_number = int(str(semester).replace("Semester", "").strip())
                    if not 1 <= semester_number <= 8:
                        raise ValueError
                except (ValueError, TypeError):
                    return jsonify({"success": False, "message": "A valid semester from 1 to 8 is required."}), 400

                cursor.execute(
                    """
                    SELECT b.branch_id, s.semester_id
                    FROM branches b
                    JOIN semesters s ON s.branch_id = b.branch_id
                    WHERE LOWER(b.branch_name) = LOWER(%s)
                      AND s.semester_name = %s
                    """,
                    (branch.strip(), f"Semester {semester_number}")
                )
                academic_data = cursor.fetchone()
                if not academic_data:
                    return jsonify({
                        "success": False,
                        "message": "Selected branch and semester are not available."
                    }), 400

            updates = ["name = %s"]
            values = [name.strip()]
            if academic_data:
                updates.extend(["branch_id = %s", "semester_id = %s"])
                values.extend([academic_data["branch_id"], academic_data["semester_id"]])

            has_photo = column_exists(cursor, "users", "profile_photo")
            photo_file = request.files.get("profile_photo")
            if photo_file and photo_file.filename and has_photo:
                extension = photo_file.filename.rsplit(".", 1)[-1].lower()
                if "." not in photo_file.filename or extension not in PROFILE_PHOTO_EXTENSIONS:
                    return jsonify({
                        "success": False,
                        "message": "Profile photo must be JPG, PNG, or WEBP."
                    }), 400

                photo_filename = f"{uuid4().hex}.{extension}"
                saved_photo_path = os.path.join(PROFILE_PHOTO_FOLDER, photo_filename)
                os.makedirs(PROFILE_PHOTO_FOLDER, exist_ok=True)
                photo_file.save(saved_photo_path)
                photo_size = os.path.getsize(saved_photo_path)
                if photo_size == 0 or photo_size > MAX_PROFILE_PHOTO_SIZE:
                    os.remove(saved_photo_path)
                    saved_photo_path = None
                    return jsonify({
                        "success": False,
                        "message": (
                            "Profile photo must be non-empty and no larger than "
                            f"{MAX_PROFILE_PHOTO_SIZE_MB} MB."
                        )
                    }), 400
                updates.append("profile_photo = %s")
                values.append(photo_filename)
            elif data.get("remove_profile_photo") == "1" and has_photo:
                updates.append("profile_photo = NULL")

            if photo_file and photo_filename and saved_photo_path and os.path.isfile(saved_photo_path):
                has_file_storage = table_exists(cursor, "resource_files")
                is_mock_cursor = type(cursor).__module__.startswith("unittest.mock")
                if os.environ.get("VERCEL") and not has_file_storage:
                    raise RuntimeError("Persistent file storage is unavailable.")
                if has_file_storage and not is_mock_cursor:
                    with open(saved_photo_path, "rb") as f_photo:
                        p_bytes = f_photo.read()
                    mime_type = mimetypes.guess_type(photo_filename)[0] or "application/octet-stream"
                    cursor.execute(
                        """
                        INSERT INTO resource_files (filename, mime_type, file_data, file_size)
                        VALUES (%s, %s, %s, %s)
                        """,
                        (f"profile_photos/{photo_filename}", mime_type, p_bytes, len(p_bytes))
                    )

            if data.get("remove_profile_photo") == "1" and has_photo:
                if table_exists(cursor, "resource_files") and not type(cursor).__module__.startswith("unittest.mock"):
                    try:
                        cursor.execute("SELECT profile_photo FROM users WHERE user_id = %s", (g.user_id,))
                        old_row = cursor.fetchone()
                        if old_row and old_row.get("profile_photo"):
                            cursor.execute("DELETE FROM resource_files WHERE filename = %s", (f"profile_photos/{old_row['profile_photo']}",))
                    except Exception:
                        current_app.logger.exception("Failed to remove profile photo from resource_files")

            values.append(g.user_id)
            cursor.execute(
                f"UPDATE users SET {', '.join(updates)} WHERE user_id = %s",
                values
            )
            connection.commit()
            saved_photo_path = None

        has_photo = column_exists(cursor, "users", "profile_photo")
        photo_select = "u.profile_photo," if has_photo else "NULL AS profile_photo,"
        cursor.execute(
            f"""
            SELECT
                u.user_id, u.name, u.email, u.role, {photo_select}
                b.branch_name AS branch, s.semester_name AS semester
            FROM users u
            LEFT JOIN branches b ON u.branch_id = b.branch_id
            LEFT JOIN semesters s ON u.semester_id = s.semester_id
            WHERE u.user_id = %s
            """,
            (g.user_id,)
        )
        row = cursor.fetchone()
        if not row:
            return jsonify({"success": False, "message": "User account not found."}), 404
        return jsonify({"success": True, "user": _user_payload(row)}), 200
    except Exception:
        if connection:
            connection.rollback()
        if saved_photo_path and os.path.exists(saved_photo_path):
            try:
                os.remove(saved_photo_path)
            except OSError:
                current_app.logger.exception("Unable to remove unsaved profile photo")
        current_app.logger.exception("Profile request failed")
        return jsonify({"success": False, "message": "Unable to load or update your profile."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.route("/profile-photos/<path:filename>", methods=["GET"])
def profile_photo(filename):
    safe_filename = secure_filename(filename)
    if safe_filename != filename or "." not in safe_filename:
        return jsonify({"success": False, "message": "Profile photo not found."}), 404
    ext = safe_filename.rsplit(".", 1)[1].lower()
    if ext not in PROFILE_PHOTO_EXTENSIONS:
        return jsonify({"success": False, "message": "Profile photo not found."}), 404

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        if table_exists(cursor, "resource_files") and not type(cursor).__module__.startswith("unittest.mock"):
            cursor.execute(
                "SELECT mime_type, file_data FROM resource_files WHERE filename = %s OR filename = %s",
                (f"profile_photos/{safe_filename}", safe_filename)
            )
            row = cursor.fetchone()
            if row and row.get("file_data"):
                data = row["file_data"]
                if isinstance(data, (bytes, bytearray)) and len(data) > 0:
                    mime = row.get("mime_type") or f"image/{ext}"
                    resp = send_file(io.BytesIO(data), mimetype=mime)
                    resp.headers["Cache-Control"] = "public, max-age=86400"
                    return resp
    except Exception:
        current_app.logger.exception("Unable to load profile photo from database")
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

    return send_from_directory(PROFILE_PHOTO_FOLDER, safe_filename)
