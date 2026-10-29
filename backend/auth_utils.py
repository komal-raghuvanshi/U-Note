from functools import wraps

from flask import current_app, g, jsonify, request
from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer


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
        g.user_id = user_id
        return view(*args, **kwargs)

    return wrapped
