import re
from flask import Blueprint, jsonify

try:
    from db import get_db_connection
except ImportError:
    from backend.db import get_db_connection

home_bp = Blueprint("home", __name__)


@home_bp.route("/")
def home():
    return "U-NOTE Backend is running!"


@home_bp.route("/status")
def status():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        row = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify({"database": "connected", "status": "healthy"}), 200
    except Exception as exc:
        sanitized = re.sub(r'AVNS_[A-Za-z0-9_-]+', '***', str(exc))
        return jsonify({"database": "error", "message": sanitized}), 500
