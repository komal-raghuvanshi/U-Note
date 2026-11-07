import os
import json
import logging
from flask import current_app

try:
    from db import get_db_connection, table_exists
except ImportError:
    from backend.db import get_db_connection, table_exists

logger = logging.getLogger("notifications_service")


def _get_admin_emails():
    raw = os.getenv("UNOTE_ADMIN_EMAILS", "")
    return {email.strip().lower() for email in raw.split(",") if email.strip()}


def create_notification(cursor_or_conn, user_id, title, message, notification_type, related_resource_id=None):
    """
    Insert an in-app notification and trigger web push if subscription exists.
    Can accept a cursor or opens its own connection.
    """
    if not user_id:
        return None

    own_conn = None
    cursor = None
    try:
        if hasattr(cursor_or_conn, "execute"):
            cursor = cursor_or_conn
        else:
            own_conn = get_db_connection()
            cursor = own_conn.cursor(dictionary=True)

        if not table_exists(cursor, "notifications"):
            return None

        cursor.execute(
            """
            INSERT INTO notifications
                (user_id, title, message, notification_type, related_resource_id, is_read)
            VALUES (%s, %s, %s, %s, %s, 0)
            """,
            (user_id, title[:150], message, notification_type[:50], related_resource_id)
        )
        notification_id = cursor.lastrowid
        if own_conn:
            own_conn.commit()

        # Trigger Web Push notification if subscriptions exist
        _send_web_push(cursor, user_id, title, message, notification_type, related_resource_id)

        return notification_id
    except Exception as e:
        logger.warning(f"Failed to create notification for user {user_id}: {e}")
        return None
    finally:
        if own_conn:
            try: cursor.close()
            except Exception: pass
            try: own_conn.close()
            except Exception: pass


def notify_admins(cursor_or_conn, title, message, notification_type="admin_alert", related_resource_id=None):
    """
    Notify all admin users in the database and any configured in UNOTE_ADMIN_EMAILS.
    """
    own_conn = None
    cursor = None
    try:
        if hasattr(cursor_or_conn, "execute"):
            cursor = cursor_or_conn
        else:
            own_conn = get_db_connection()
            cursor = own_conn.cursor(dictionary=True)

        admin_emails = _get_admin_emails()
        cursor.execute("SELECT user_id, email, role FROM users WHERE role = 'admin'")
        admin_rows = cursor.fetchall()
        admin_ids = {r["user_id"] for r in admin_rows}

        if admin_emails:
            format_strings = ','.join(['%s'] * len(admin_emails))
            cursor.execute(f"SELECT user_id FROM users WHERE LOWER(email) IN ({format_strings})", tuple(admin_emails))
            for r in cursor.fetchall():
                admin_ids.add(r["user_id"])

        for admin_id in admin_ids:
            create_notification(cursor, admin_id, title, message, notification_type, related_resource_id)

        if own_conn:
            own_conn.commit()
    except Exception as e:
        logger.warning(f"Failed to notify admins: {e}")
    finally:
        if own_conn:
            try: cursor.close()
            except Exception: pass
            try: own_conn.close()
            except Exception: pass


def _send_web_push(cursor, user_id, title, message, notification_type, related_resource_id=None):
    """
    Send Web Push notification using stored subscriptions if available.
    Fails gracefully if push is not configured or unsupported.
    """
    try:
        if not table_exists(cursor, "push_subscriptions"):
            return

        cursor.execute("SELECT endpoint, p256dh, auth FROM push_subscriptions WHERE user_id = %s", (user_id,))
        subscriptions = cursor.fetchall()
        if not subscriptions:
            return

        payload = json.dumps({
            "title": title,
            "body": message,
            "icon": "/logo.png",
            "badge": "/favicon.png",
            "tag": f"unote-{notification_type}",
            "data": {
                "notification_type": notification_type,
                "related_resource_id": related_resource_id,
                "url": "/resources" if related_resource_id else "/"
            }
        })

        # Try pywebpush if available and VAPID key is configured
        vapid_private_key = os.getenv("VAPID_PRIVATE_KEY")
        vapid_claims = {"sub": os.getenv("VAPID_CLAIM_EMAIL", "mailto:unote.support@gmail.com")}

        if vapid_private_key:
            try:
                from pywebpush import webpush
                for sub in subscriptions:
                    try:
                        webpush(
                            subscription_info={
                                "endpoint": sub["endpoint"],
                                "keys": {"p256dh": sub["p256dh"], "auth": sub["auth"]}
                            },
                            data=payload,
                            vapid_private_key=vapid_private_key,
                            vapid_claims=vapid_claims
                        )
                    except Exception as sub_err:
                        logger.debug(f"Web push error for sub: {sub_err}")
            except ImportError:
                logger.debug("pywebpush not installed; skipping browser push delivery.")
    except Exception as e:
        logger.debug(f"Web push dispatch error: {e}")
