import os
from functools import wraps

from flask import current_app, g, jsonify, request
from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer

try:
    from db import get_db_connection, column_exists
except ImportError:
    from backend.db import get_db_connection, column_exists


TOKEN_MAX_AGE = 60 * 60 * 24 * 7
TOKEN_SALT = "u-note-auth"


def _serializer():
    secret_key = current_app.config.get("SECRET_KEY")
    if not secret_key:
        raise RuntimeError("UNOTE_SECRET_KEY is not configured")
    return URLSafeTimedSerializer(secret_key, salt=TOKEN_SALT)


def create_auth_token(user_id):
    return _serializer().dumps({"user_id": int(user_id)})


def authenticated_user_id():
    if not current_app.config.get("SECRET_KEY"):
        return None
    header = request.headers.get("Authorization", "")
    scheme, separator, token = header.partition(" ")
    if not separator or scheme.lower() != "bearer" or not token.strip():
        return None

    try:
        payload = _serializer().loads(token.strip(), max_age=TOKEN_MAX_AGE)
        user_id = int(payload["user_id"])
    except (BadSignature, SignatureExpired, KeyError, TypeError, ValueError):
        return None
    return user_id if user_id > 0 else None


def _get_admin_emails():
    raw = os.getenv("UNOTE_ADMIN_EMAILS", "")
    return {email.strip().lower() for email in raw.split(",") if email.strip()}


def is_admin_user(cursor, user_id):
    if not user_id:
        return False
    try:
        cursor.execute("SELECT role, email FROM users WHERE user_id = %s", (user_id,))
        row = cursor.fetchone()
        if not row:
            return False
        if row.get("role") == "admin":
            return True
        admin_emails = _get_admin_emails()
        if (row.get("email") or "").strip().lower() in admin_emails:
            return True
        return False
    except Exception:
        return False


def check_user_blocked(cursor, user_id):
    if not user_id:
        return False
    try:
        if column_exists(cursor, "users", "is_blocked"):
            cursor.execute("SELECT is_blocked FROM users WHERE user_id = %s", (user_id,))
            row = cursor.fetchone()
            if row and row.get("is_blocked"):
                return True
        return False
    except Exception:
        return False


def require_auth(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not current_app.config.get("SECRET_KEY"):
            return jsonify({
                "success": False,
                "message": "Authentication is not configured on this server."
            }), 503

        user_id = authenticated_user_id()
        if user_id is None:
            return jsonify({
                "success": False,
                "message": "A valid login is required."
            }), 401

        # Check if user is blocked (skip DB call in testing unless flag set)
        if not (current_app.testing and os.environ.get("UNOTE_CHECK_BLOCKED_IN_TEST") != "1"):
            conn = None
            cursor = None
            try:
                conn = get_db_connection()
                cursor = conn.cursor(dictionary=True)
                if check_user_blocked(cursor, user_id):
                    return jsonify({
                        "success": False,
                        "message": "Your account has been restricted by an administrator."
                    }), 403
            except Exception:
                pass
            finally:
                if cursor:
                    try: cursor.close()
                    except Exception: pass
                if conn:
                    try: conn.close()
                    except Exception: pass

        g.user_id = user_id
        return view(*args, **kwargs)

    return wrapped


def require_admin(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not current_app.config.get("SECRET_KEY"):
            return jsonify({
                "success": False,
                "message": "Authentication is not configured on this server."
            }), 503

        user_id = authenticated_user_id()
        if user_id is None:
            return jsonify({
                "success": False,
                "message": "A valid login is required."
            }), 401

        conn = None
        cursor = None
        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            if check_user_blocked(cursor, user_id):
                return jsonify({
                    "success": False,
                    "message": "Your account has been restricted by an administrator."
                }), 403
            if not is_admin_user(cursor, user_id):
                return jsonify({
                    "success": False,
                    "message": "Admin privileges are required to access this resource."
                }), 403
        except Exception:
            return jsonify({
                "success": False,
                "message": "Unable to verify administrative authorization."
            }), 500
        finally:
            if cursor:
                try: cursor.close()
                except Exception: pass
            if conn:
                try: conn.close()
                except Exception: pass

        g.user_id = user_id
        g.is_admin = True
        return view(*args, **kwargs)

    return wrapped
