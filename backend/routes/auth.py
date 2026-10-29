import re

from flask import Blueprint, current_app, g, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

try:
    from auth_utils import create_auth_token, require_auth
    from db import get_db_connection
except ImportError:
    from backend.auth_utils import create_auth_token, require_auth
    from backend.db import get_db_connection


auth_bp = Blueprint("auth", __name__)
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


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
    return {
        "id": row["user_id"],
        "name": row["name"],
        "email": row["email"],
        "role": row.get("role") or "student",
        "branch": row.get("branch"),
        "semester": semester,
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

    if not all(isinstance(value, str) for value in (name, email, password, branch)):
        return jsonify({"error": "Name, email, password, and branch are required"}), 400

    name = name.strip()
    email = email.strip().lower()
    branch = branch.strip()
    if not name or len(name) > 100:
        return jsonify({"error": "Name must be between 1 and 100 characters"}), 400
    if len(email) > 100 or not EMAIL_PATTERN.fullmatch(email):
        return jsonify({"error": "A valid email address is required"}), 400
    if len(password) < 8 or len(password) > 128:
        return jsonify({"error": "Password must be between 8 and 128 characters"}), 400

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

        cursor.execute(
            """
            SELECT b.branch_id, s.semester_id, s.semester_name
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
            VALUES (%s, %s, %s, 'student', %s, %s)
            """,
            (
                name,
                email,
                generate_password_hash(password),
                academic_data["branch_id"],
                academic_data["semester_id"],
            )
        )
        connection.commit()
        user = {
            "user_id": cursor.lastrowid,
            "name": name,
            "email": email,
            "role": "student",
            "branch": branch,
            "semester": academic_data["semester_name"],
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
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        if request.method == "PUT":
            data = request.get_json(silent=True) or {}
            if not isinstance(data, dict):
                return jsonify({"success": False, "message": "Invalid request payload."}), 400
            name = data.get("name")
            branch = data.get("branch")
            semester = data.get("semester")
            if not isinstance(name, str) or not name.strip() or len(name.strip()) > 100:
                return jsonify({"success": False, "message": "Name must be between 1 and 100 characters."}), 400
            if not isinstance(branch, str) or not branch.strip():
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
                return jsonify({"success": False, "message": "Selected branch and semester are not available."}), 400

            cursor.execute(
                """
                UPDATE users
                SET name = %s, branch_id = %s, semester_id = %s
                WHERE user_id = %s
                """,
                (name.strip(), academic_data["branch_id"], academic_data["semester_id"], g.user_id)
            )
            connection.commit()

        cursor.execute(
            """
            SELECT
                u.user_id, u.name, u.email, u.role,
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
        current_app.logger.exception("Profile request failed")
        return jsonify({"success": False, "message": "Unable to load or update your profile."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
