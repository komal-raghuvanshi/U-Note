
from flask import Blueprint, current_app, jsonify, request

try:
    from db import get_db_connection
except ImportError:
    from backend.db import get_db_connection

branches_bp = Blueprint("branches", __name__)


@branches_bp.route("/branches", methods=["GET"])
def get_branches():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT branch_id AS id, branch_name AS name
            FROM branches
            ORDER BY branch_name ASC
        """)
        branches = cursor.fetchall()
        return jsonify({"count": len(branches), "branches": branches}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch branches")
        return jsonify({"success": False, "message": "Unable to fetch branches from the database."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@branches_bp.route("/semesters", methods=["GET"])
def get_semesters():
    branch = request.args.get("branch", "").strip()
    if not branch:
        return jsonify({"count": 0, "semesters": []}), 200

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT
                sem.semester_id AS id,
                sem.semester_name AS name,
                CAST(SUBSTRING_INDEX(sem.semester_name, ' ', -1) AS UNSIGNED) AS number,
                b.branch_name AS branch
            FROM semesters sem
            JOIN branches b ON b.branch_id = sem.branch_id
            WHERE LOWER(b.branch_name) = LOWER(%s)
            ORDER BY number ASC
        """, (branch,))
        semesters = cursor.fetchall()
        return jsonify({"count": len(semesters), "semesters": semesters}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch semesters")
        return jsonify({"success": False, "message": "Unable to fetch semesters from the database."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
