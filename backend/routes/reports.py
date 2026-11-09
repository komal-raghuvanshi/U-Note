from flask import Blueprint, current_app, g, jsonify, request

try:
    from auth_utils import require_auth
    from db import get_db_connection, table_exists
    from notifications_service import notify_admins
except ImportError:
    from backend.auth_utils import require_auth
    from backend.db import get_db_connection, table_exists
    from backend.notifications_service import notify_admins

reports_bp = Blueprint("reports", __name__)

VALID_REASONS = {
    "inappropriate": "Inappropriate Content",
    "incorrect": "Incorrect or Outdated Material",
    "duplicate": "Duplicate Resource",
    "broken_file": "Broken or Corrupted File",
    "copyright": "Copyright Violation",
    "other": "Other Reason",
}


@reports_bp.route("/resources/<int:resource_id>/reports", methods=["POST"])
@require_auth
def submit_report(resource_id):
    data = request.get_json(silent=True) or request.form or {}
    reason = (data.get("reason") or "").strip()
    details = (data.get("details") or "").strip()

    if not reason:
        return jsonify({"success": False, "message": "Please specify a reason for this report."}), 400

    if len(reason) > 100:
        return jsonify({"success": False, "message": "Reason must be 100 characters or fewer."}), 400

    if len(details) > 1000:
        return jsonify({"success": False, "message": "Details must be 1000 characters or fewer."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT resource_id, title FROM resources WHERE resource_id = %s", (resource_id,))
        resource = cursor.fetchone()
        if not resource:
            return jsonify({"success": False, "message": "Resource not found."}), 404

        if not table_exists(cursor, "resource_reports"):
            return jsonify({"success": False, "message": "Reporting service is currently unavailable."}), 503

        # Prevent spam: check if user already submitted a pending report for this resource
        cursor.execute(
            """
            SELECT report_id FROM resource_reports
            WHERE resource_id = %s AND user_id = %s AND status = 'pending'
            """,
            (resource_id, g.user_id)
        )
        if cursor.fetchone():
            return jsonify({
                "success": False,
                "message": "You already have a pending report for this resource under review."
            }), 400

        cursor.execute(
            """
            INSERT INTO resource_reports
                (resource_id, user_id, reason, details, status)
            VALUES (%s, %s, %s, %s, 'pending')
            """,
            (resource_id, g.user_id, reason, details or None)
        )
        report_id = cursor.lastrowid
        conn.commit()

        # Notify admins
        notify_admins(
            cursor,
            "Resource Reported",
            f"Resource '{resource['title']}' was reported for '{reason}'.",
            notification_type="admin_alert",
            related_resource_id=resource_id
        )

        return jsonify({
            "success": True,
            "report_id": report_id,
            "message": "Thank you. Your report has been submitted to moderators for review."
        }), 201
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to submit resource report")
        return jsonify({"success": False, "message": "Unable to submit report. Please try again."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass
