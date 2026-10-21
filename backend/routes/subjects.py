
from flask import Blueprint, jsonify, request
from db import get_db_connection

subjects_bp = Blueprint("subjects", __name__)


@subjects_bp.route("/subjects", methods=["GET"])
def get_subjects():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    query = """
        SELECT
            s.subject_id AS id,
            s.subject_name AS name,
            b.branch_name AS branch,
            sem.semester_name AS semester
        FROM subjects s
        JOIN semesters sem ON s.semester_id = sem.semester_id
        JOIN branches b ON sem.branch_id = b.branch_id
    """

    conditions = []
    values = []

    branch = request.args.get("branch")
    semester = request.args.get("semester")

    if branch:
        conditions.append("LOWER(b.branch_name) = LOWER(%s)")
        values.append(branch)

    if semester:
        try:
            semester = int(semester)
        except ValueError:
            cursor.close()
            connection.close()
            return jsonify({"error": "Semester must be a valid number"}), 400

        conditions.append("sem.semester_name = %s")
        values.append(f"Semester {semester}")

    if conditions:
        query += " WHERE " + " AND ".join(conditions)

    cursor.execute(query, values)
    subjects = cursor.fetchall()

    cursor.close()
    connection.close()

    return jsonify(subjects), 200
