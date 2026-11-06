import os
import re
import tempfile
from uuid import uuid4

from flask import Blueprint, current_app, g, jsonify, request, send_from_directory
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename

try:
    from auth_utils import create_auth_token, require_auth
    from db import get_db_connection
except ImportError:
    from backend.auth_utils import create_auth_token, require_auth
    from backend.db import get_db_connection


auth_bp = Blueprint("auth", __name__)
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PROFILE_PHOTO_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}
MAX_PROFILE_PHOTO_SIZE = 5 * 1024 * 1024
if os.environ.get("VERCEL"):
    PROFILE_PHOTO_FOLDER = os.path.join(tempfile.gettempdir(), "unote_profile_photos")
else:
    PROFILE_PHOTO_FOLDER = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "uploads",
        "profile_photos",
    )


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
    return {
        "id": row["user_id"],
        "name": row["name"],
        "email": row["email"],
        "role": row.get("role") or "student",
        "branch": row.get("branch"),
        "semester": semester,
        "profile_photo_url": profile_photo_url,
    }


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
        cursor.execute("SELECT user_id FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({"error": "Email already registered"}), 409

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
        connection.commit()
        user = {
            "user_id": cursor.lastrowid,
            "name": name,
            "email": email,
            "role": role,
            "branch": academic_data["branch_name"] if academic_data else None,
            "semester": academic_data["semester_name"] if academic_data else None,
            "profile_photo": None,
        }
        return jsonify({
            "message": "Account created successfully",
            "user": _user_payload(user),
            "token": create_auth_token(user["user_id"]),
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
        cursor.execute(
            """
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.password_hash,
                u.role,
                u.profile_photo,
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

            photo_file = request.files.get("profile_photo")
            if photo_file and photo_file.filename:
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
                        "message": "Profile photo must be non-empty and no larger than 5 MB."
                    }), 400
                updates.append("profile_photo = %s")
                values.append(photo_filename)
            elif data.get("remove_profile_photo") == "1":
                updates.append("profile_photo = NULL")

            values.append(g.user_id)
            cursor.execute(
                f"UPDATE users SET {', '.join(updates)} WHERE user_id = %s",
                values
            )
            connection.commit()
            saved_photo_path = None

        cursor.execute(
            """
            SELECT
                u.user_id, u.name, u.email, u.role, u.profile_photo,
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
    if safe_filename.rsplit(".", 1)[1].lower() not in PROFILE_PHOTO_EXTENSIONS:
        return jsonify({"success": False, "message": "Profile photo not found."}), 404
    return send_from_directory(PROFILE_PHOTO_FOLDER, safe_filename)
