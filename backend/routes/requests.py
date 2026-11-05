from flask import Blueprint, jsonify, request, current_app, g

try:
    from auth_utils import require_auth
    from db import get_db_connection
except ImportError:
    from backend.auth_utils import require_auth
    from backend.db import get_db_connection

requests_bp = Blueprint("requests", __name__)


@requests_bp.route("/requests", methods=["GET"])
@require_auth
def get_requests():
    branch = request.args.get("branch")
    semester = request.args.get("semester")
    subject = request.args.get("subject")
    status = request.args.get("status")

    query = """
        SELECT
            req.request_id AS id,
            req.request_description AS description,
            req.status,
            req.fulfilled_by,
            fulfiller.name AS fulfilled_by_name,
            req.fulfilled_resource_id,
            fulfilled_resource.title AS fulfilled_resource_title,
            fulfilled_resource.resource_url AS fulfilled_resource_url,
            req.created_at,
            u.user_id,
            u.name AS user_name,
            u.role AS user_role,
            s.subject_id,
            s.subject_name AS subject,
            COALESCE(meta.catalogue_code, s.subject_code) AS subject_code,
            sem.semester_name AS semester,
            b.branch_name AS branch,
            un.unit_number AS unit,
            un.unit_name AS unit_name
        FROM requests req
        JOIN users u ON req.user_id = u.user_id
        JOIN subjects s ON req.subject_id = s.subject_id
        JOIN semesters sem ON s.semester_id = sem.semester_id
        JOIN branches b ON sem.branch_id = b.branch_id
        LEFT JOIN units un ON req.unit_id = un.unit_id
        LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
        LEFT JOIN users fulfiller ON req.fulfilled_by = fulfiller.user_id
        LEFT JOIN resources fulfilled_resource
            ON req.fulfilled_resource_id = fulfilled_resource.resource_id
    """
    conditions = []
    values = []

    if branch:
        conditions.append("LOWER(b.branch_name) = LOWER(%s)")
        values.append(branch.strip())

    if semester:
        try:
            sem_int = int(str(semester).replace("Semester", "").strip())
            if not 1 <= sem_int <= 8:
                raise ValueError
            conditions.append("sem.semester_name = %s")
            values.append(f"Semester {sem_int}")
        except (ValueError, TypeError):
            return jsonify({"success": False, "message": "Semester must be between 1 and 8."}), 400

    if subject:
        conditions.append("""
            (
                LOWER(s.subject_name) = LOWER(%s)
                OR LOWER(s.subject_code) = LOWER(%s)
                OR LOWER(COALESCE(meta.catalogue_code, s.subject_code)) = LOWER(%s)
            )
        """)
        values.extend([subject.strip(), subject.strip(), subject.strip()])

    if status and status.lower() != "all":
        if status.lower() not in ("pending", "fulfilled", "rejected"):
            return jsonify({"success": False, "message": "Invalid request status."}), 400
        conditions.append("LOWER(req.status) = LOWER(%s)")
        values.append(status.strip())

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        query += " ORDER BY req.request_id DESC"
        cursor.execute(query, values)
        rows = cursor.fetchall()

        for row in rows:
            if row.get("created_at") and hasattr(row["created_at"], "isoformat"):
                row["created_at"] = row["created_at"].isoformat()
            if row["semester"]:
                row["semester_num"] = _semester_number(row["semester"])
        return jsonify({"success": True, "count": len(rows), "requests": rows}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch resource requests")
        return jsonify({"success": False, "message": "Unable to fetch resource requests."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


def _semester_number(value):
    try:
        return int(str(value).replace("Semester", "").strip())
    except (TypeError, ValueError):
        return value


@requests_bp.route("/requests", methods=["POST"])
@require_auth
def create_request():
    data = request.get_json(silent=True) or request.form
    if not hasattr(data, "get"):
        return jsonify({"success": False, "message": "Invalid request payload."}), 400
    branch_raw = data.get("branch")
    subject_raw = data.get("subject")
    description_raw = data.get("description")
    if not all(isinstance(value, str) for value in (branch_raw, subject_raw, description_raw)):
        return jsonify({"success": False, "message": "Branch, subject, and description must be text."}), 400
    branch = branch_raw.strip()
    semester = data.get("semester")
    subject = subject_raw.strip()
    unit = data.get("unit")
    description = description_raw.strip()

    if not description:
        return jsonify({"success": False, "message": "Request description is required."}), 400
    if len(description) > 2000:
        return jsonify({"success": False, "message": "Request description must be 2000 characters or fewer."}), 400

    if not branch or not semester or not subject:
        return jsonify({"success": False, "message": "Branch, semester, and subject are required."}), 400

    try:
        sem_num = int(str(semester).replace("Semester", "").strip())
        if not 1 <= sem_num <= 8:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid user or semester value."}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        # Validate user
        cursor.execute("SELECT user_id, name FROM users WHERE user_id = %s", (g.user_id,))
        user_row = cursor.fetchone()
        if not user_row:
            return jsonify({"success": False, "message": "User not found."}), 401

        # Validate subject
        cursor.execute("""
            SELECT s.subject_id, s.subject_name
            FROM subjects s
            JOIN semesters sem ON s.semester_id = sem.semester_id
            JOIN branches b ON sem.branch_id = b.branch_id
            LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
            WHERE LOWER(b.branch_name) = LOWER(%s)
              AND sem.semester_name = %s
              AND COALESCE(meta.is_selectable, 1) = 1
              AND (
                  LOWER(s.subject_name) = LOWER(%s)
                  OR LOWER(s.subject_code) = LOWER(%s)
                  OR LOWER(COALESCE(meta.catalogue_code, s.subject_code)) = LOWER(%s)
              )
        """, (branch, f"Semester {sem_num}", subject, subject, subject))
        subj_row = cursor.fetchone()
        if not subj_row:
            return jsonify({
                "success": False,
                "message": f"Subject '{subject}' not found for {branch} Semester {sem_num}."
            }), 400

        subject_id = subj_row["subject_id"]

        # Optional unit validation
        unit_id = None
        if unit and str(unit).lower() not in ("all", "all units", ""):
            try:
                unit_num = int(str(unit).replace("Unit", "").strip())
                if not 1 <= unit_num <= 5:
                    raise ValueError
                cursor.execute(
                    "SELECT unit_id FROM units WHERE subject_id = %s AND unit_number = %s",
                    (subject_id, unit_num)
                )
                unit_row = cursor.fetchone()
                if not unit_row:
                    return jsonify({"success": False, "message": "Selected unit is not available for this subject."}), 400
                unit_id = unit_row["unit_id"]
            except (ValueError, TypeError):
                return jsonify({"success": False, "message": "Unit must be between 1 and 5, or 'all'."}), 400

        cursor.execute("""
            INSERT INTO requests (user_id, subject_id, unit_id, request_description, status)
            VALUES (%s, %s, %s, %s, 'Pending')
        """, (g.user_id, subject_id, unit_id, description))
        connection.commit()
        new_id = cursor.lastrowid

        return jsonify({
            "success": True,
            "message": "Study resource request submitted successfully.",
            "request_id": new_id
        }), 201

    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("Resource request creation failed")
        return jsonify({"success": False, "message": "Unable to submit the resource request."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@requests_bp.route("/requests/my", methods=["GET"])
@require_auth
def get_my_requests():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
        SELECT
            req.request_id AS id,
            req.request_description AS description,
            req.status,
            req.fulfilled_by,
            fulfiller.name AS fulfilled_by_name,
            req.fulfilled_resource_id,
            fulfilled_resource.title AS fulfilled_resource_title,
            fulfilled_resource.resource_url AS fulfilled_resource_url,
            req.created_at,
            u.user_id,
            u.name AS user_name,
            u.role AS user_role,
            s.subject_id,
            s.subject_name AS subject,
            COALESCE(meta.catalogue_code, s.subject_code) AS subject_code,
            sem.semester_name AS semester,
            b.branch_name AS branch,
            un.unit_number AS unit,
            un.unit_name AS unit_name
        FROM requests req
        JOIN users u ON req.user_id = u.user_id
        JOIN subjects s ON req.subject_id = s.subject_id
        JOIN semesters sem ON s.semester_id = sem.semester_id
        JOIN branches b ON sem.branch_id = b.branch_id
        LEFT JOIN units un ON req.unit_id = un.unit_id
        LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
        LEFT JOIN users fulfiller ON req.fulfilled_by = fulfiller.user_id
        LEFT JOIN resources fulfilled_resource
            ON req.fulfilled_resource_id = fulfilled_resource.resource_id
        WHERE req.user_id = %s
        ORDER BY req.request_id DESC
        """, (g.user_id,))
        rows = cursor.fetchall()

        for row in rows:
            if row.get("created_at") and hasattr(row["created_at"], "isoformat"):
                row["created_at"] = row["created_at"].isoformat()
            if row.get("semester"):
                row["semester_num"] = _semester_number(row["semester"])

        return jsonify({"success": True, "count": len(rows), "requests": rows}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch a user's resource requests")
        return jsonify({"success": False, "message": "Unable to fetch your resource requests."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@requests_bp.route("/requests/<int:request_id>/status", methods=["PATCH"])
@require_auth
def update_request_status(request_id):
    data = request.get_json(silent=True) or {}
    if not isinstance(data, dict):
        return jsonify({"success": False, "message": "Invalid request payload."}), 400
    new_status = data.get("status")

    if new_status == "Fulfilled":
        return jsonify({
            "success": False,
            "message": "Requests can only be fulfilled by sharing a linked resource."
        }), 409
    if new_status not in ("Pending", "Rejected"):
        return jsonify({"success": False, "message": "Invalid status value."}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT req.request_id, req.user_id, req.status
            FROM requests req
            WHERE req.request_id = %s
            """,
            (request_id,)
        )
        req = cursor.fetchone()
        if not req:
            return jsonify({"success": False, "message": "Request not found."}), 404
        if req["user_id"] != g.user_id:
            return jsonify({"success": False, "message": "You are not authorized to update this request."}), 403
        if req["status"] == "Fulfilled":
            return jsonify({
                "success": False,
                "message": "A fulfilled request cannot be manually changed."
            }), 409
        if req["status"] == new_status:
            return jsonify({
                "success": True,
                "message": f"Request status is already '{new_status}'."
            }), 200

        cursor.execute(
            """
            UPDATE requests
            SET status = %s
            WHERE request_id = %s
              AND status <> 'Fulfilled'
            """,
            (new_status, request_id)
        )
        if cursor.rowcount != 1:
            connection.rollback()
            return jsonify({
                "success": False,
                "message": "The request status changed before this update could be saved."
            }), 409
        connection.commit()

        return jsonify({
            "success": True,
            "message": f"Request status updated to '{new_status}'."
        }), 200

    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("Request status update failed")
        return jsonify({"success": False, "message": "Unable to update the request status."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@requests_bp.route("/requests/<int:request_id>", methods=["GET"])
@require_auth
def get_request(request_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT
                req.request_id AS id,
                req.request_description AS description,
                req.status,
                req.user_id,
                req.unit_id,
                req.fulfilled_by,
                fulfiller.name AS fulfilled_by_name,
                req.fulfilled_resource_id,
                fulfilled_resource.title AS fulfilled_resource_title,
                fulfilled_resource.resource_url AS fulfilled_resource_url,
                s.subject_id,
                s.subject_name AS subject,
                COALESCE(meta.catalogue_code, s.subject_code) AS subject_code,
                sem.semester_name AS semester,
                b.branch_name AS branch,
                un.unit_number AS unit,
                un.unit_name AS unit_name
            FROM requests req
            JOIN subjects s ON req.subject_id = s.subject_id
            JOIN semesters sem ON s.semester_id = sem.semester_id
            JOIN branches b ON sem.branch_id = b.branch_id
            LEFT JOIN units un ON req.unit_id = un.unit_id
            LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
            LEFT JOIN users fulfiller ON req.fulfilled_by = fulfiller.user_id
            LEFT JOIN resources fulfilled_resource
                ON req.fulfilled_resource_id = fulfilled_resource.resource_id
            WHERE req.request_id = %s
        """, (request_id,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"success": False, "message": "Request not found."}), 404
        if row.get("semester"):
            row["semester_num"] = _semester_number(row["semester"])
        return jsonify({"success": True, "request": row}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch resource request details")
        return jsonify({"success": False, "message": "Unable to fetch request details."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
