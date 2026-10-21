
from flask import Blueprint, request, jsonify
from db import get_db_connection
from werkzeug.security import generate_password_hash, check_password_hash

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.get_json()

    name = data.get("name", "").strip()
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not name or not email or not password:
        return jsonify({"error": "Name, email and password are required"}), 400

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT user_id FROM users WHERE email = %s",
            (email,)
        )

        if cursor.fetchone():
            return jsonify({"error": "Email already registered"}), 409

        
        branch = data.get("branch", "").strip()
        semester = data.get("semester")

        if not branch or not semester:
            return jsonify({"error": "Branch and semester are required"}), 400

        try:
            semester = int(semester)
            if semester < 1 or semester > 8:
                raise ValueError
        except (ValueError, TypeError):
            return jsonify({"error": "Invalid semester"}), 400

        
        cursor.execute(
            """
            SELECT b.branch_id, s.semester_id
            FROM branches b
            JOIN semesters s ON s.branch_id = b.branch_id
            WHERE LOWER(b.branch_name) = LOWER(%s)
              AND s.semester_name = %s
            """,
            (branch, f"Semester {semester}")
        )

        academic_data = cursor.fetchone()

        if not academic_data:
            return jsonify({
                "error": "Selected branch and semester are not available"
            }), 400

        branch_id = academic_data["branch_id"]
        semester_id = academic_data["semester_id"]


        password_hash = generate_password_hash(password)

        
        cursor.execute(
            """
            INSERT INTO users
                (name, email, password_hash, role, branch_id, semester_id)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                name,
                email,
                password_hash,
                "student",
                branch_id,
                semester_id
            )
        )


        connection.commit()

        return jsonify({
            "message": "Account created successfully",
            "user": {
                "id": cursor.lastrowid,
                "name": name,
                "email": email,
                "role": "student"
            }
        }), 201

    finally:
        cursor.close()
        connection.close()


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()

    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    try:
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

        user = cursor.fetchone()

        if not user or not check_password_hash(user["password_hash"], password):
            return jsonify({"error": "Invalid email or password"}), 401

        return jsonify({
            "message": "Login successful",
            "user": {
                "id": user["user_id"],
                "name": user["name"],
                "email": user["email"],
                "role": user["role"],
                "branch": user["branch"],
                "semester": user["semester"]
            }
        }), 200

    finally:
        cursor.close()
        connection.close()
