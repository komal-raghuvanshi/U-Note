
from flask import Blueprint, current_app, jsonify

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
