import os
from flask import Blueprint, current_app, g, jsonify, request

try:
    from auth_utils import require_auth
    from db import get_db_connection, table_exists
except ImportError:
    from backend.auth_utils import require_auth
    from backend.db import get_db_connection, table_exists

notifications_bp = Blueprint("notifications", __name__)


@notifications_bp.route("/notifications", methods=["GET"])
@require_auth
def get_notifications():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return jsonify({"success": True, "notifications": []}), 200

        cursor.execute(
            """
            SELECT
                notification_id AS id,
                user_id,
                title,
                message,
                notification_type,
                related_resource_id,
                is_read,
                created_at
            FROM notifications
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT 50
            """,
            (g.user_id,)
        )
        rows = cursor.fetchall()

        for r in rows:
            r["is_read"] = bool(r.get("is_read", 0))
            if r.get("created_at") and hasattr(r["created_at"], "isoformat"):
                r["created_at"] = r["created_at"].isoformat()

        return jsonify({
            "success": True,
            "count": len(rows),
            "notifications": rows
        }), 200
    except Exception:
        current_app.logger.exception("Failed to fetch notifications")
        return jsonify({"success": False, "message": "Unable to load notifications."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/notifications/unread-count", methods=["GET"])
@require_auth
def get_unread_count():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return jsonify({"success": True, "unread_count": 0}), 200

        cursor.execute(
            "SELECT COUNT(*) AS unread_count FROM notifications WHERE user_id = %s AND is_read = 0",
            (g.user_id,)
        )
        row = cursor.fetchone()
        return jsonify({
            "success": True,
            "unread_count": int(row["unread_count"] if row else 0)
        }), 200
    except Exception:
        current_app.logger.exception("Failed to get unread notifications count")
        return jsonify({"success": False, "unread_count": 0}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/notifications/<int:notification_id>/read", methods=["PUT"])
@require_auth
def mark_notification_read(notification_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return jsonify({"success": True}), 200

        cursor.execute(
            "UPDATE notifications SET is_read = 1 WHERE notification_id = %s AND user_id = %s",
            (notification_id, g.user_id)
        )
        conn.commit()
        return jsonify({"success": True, "message": "Notification marked as read."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to mark notification as read")
        return jsonify({"success": False, "message": "Unable to update notification."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/notifications/read-all", methods=["PUT"])
@require_auth
def mark_all_notifications_read():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return jsonify({"success": True}), 200

        cursor.execute(
            "UPDATE notifications SET is_read = 1 WHERE user_id = %s AND is_read = 0",
            (g.user_id,)
        )
        conn.commit()
        return jsonify({"success": True, "message": "All notifications marked as read."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to mark all notifications as read")
        return jsonify({"success": False, "message": "Unable to update notifications."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/notifications/<int:notification_id>", methods=["DELETE"])
@require_auth
def delete_notification(notification_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return jsonify({"success": True}), 200

        cursor.execute(
            "DELETE FROM notifications WHERE notification_id = %s AND user_id = %s",
            (notification_id, g.user_id)
        )
        conn.commit()
        return jsonify({"success": True, "message": "Notification removed."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to delete notification")
        return jsonify({"success": False, "message": "Unable to delete notification."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/notifications", methods=["DELETE"])
@require_auth
def clear_all_notifications():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return jsonify({"success": True}), 200

        cursor.execute("DELETE FROM notifications WHERE user_id = %s", (g.user_id,))
        conn.commit()
        return jsonify({"success": True, "message": "All notifications cleared."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to clear notifications")
        return jsonify({"success": False, "message": "Unable to clear notifications."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/push/subscribe", methods=["POST"])
@require_auth
def subscribe_push():
    data = request.get_json(silent=True) or {}
    endpoint = data.get("endpoint")
    keys = data.get("keys") or {}
    p256dh = keys.get("p256dh") or data.get("p256dh")
    auth = keys.get("auth") or data.get("auth")

    if not endpoint or not p256dh or not auth:
        return jsonify({"success": False, "message": "Endpoint, p256dh and auth keys are required."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "push_subscriptions"):
            return jsonify({"success": True}), 200

        # Replace existing subscription for this endpoint
        cursor.execute("DELETE FROM push_subscriptions WHERE endpoint = %s", (endpoint,))
        cursor.execute(
            """
            INSERT INTO push_subscriptions (user_id, endpoint, p256dh, auth)
            VALUES (%s, %s, %s, %s)
            """,
            (g.user_id, endpoint, p256dh, auth)
        )
        conn.commit()
        return jsonify({"success": True, "message": "Push notifications registered."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to register push subscription")
        return jsonify({"success": False, "message": "Unable to register push subscription."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@notifications_bp.route("/push/unsubscribe", methods=["POST"])
@require_auth
def unsubscribe_push():
    data = request.get_json(silent=True) or {}
    endpoint = data.get("endpoint")
    if not endpoint:
        return jsonify({"success": False, "message": "Endpoint is required."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "push_subscriptions"):
            return jsonify({"success": True}), 200

        cursor.execute("DELETE FROM push_subscriptions WHERE endpoint = %s AND user_id = %s", (endpoint, g.user_id))
        conn.commit()
        return jsonify({"success": True, "message": "Push notifications disabled."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to unregister push subscription")
        return jsonify({"success": False, "message": "Unable to remove subscription."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass
