
from flask import Blueprint, jsonify
from db import get_db_connection

branches_bp = Blueprint("branches", __name__)


@branches_bp.route("/branches", methods=["GET"])
def get_branches():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("""
        SELECT branch_id AS id, branch_name AS name
        FROM branches
    """)

    branches = cursor.fetchall()

    cursor.close()
    connection.close()

    return jsonify({
        "count": len(branches),
        "branches": branches
    }), 200
