from flask import Blueprint, jsonify, request, current_app, g

try:
    from auth_utils import authenticated_user_id, require_auth
    from db import get_db_connection, table_exists, column_exists
except ImportError:
    from backend.auth_utils import authenticated_user_id, require_auth
    from backend.db import get_db_connection, table_exists, column_exists

requests_bp = Blueprint("requests", __name__)

def _build_request_select_sql(cursor, include_user_details=True):
    has_meta = table_exists(cursor, "subject_catalogue_metadata")
    has_title = column_exists(cursor, "requests", "request_title")
    has_fulfill = (
        column_exists(cursor, "requests", "fulfilled_by")
        and column_exists(cursor, "requests", "fulfilled_resource_id")
    )
    title_sql = "COALESCE(req.request_title, s.subject_name) AS title," if has_title else "s.subject_name AS title,"
    if has_fulfill:
        fulfill_cols = """
            {fulfilled_by}
            {fulfilled_by_name}
            req.fulfilled_resource_id,
            fulfilled_resource.title AS fulfilled_resource_title,
            fulfilled_resource.resource_url AS fulfilled_resource_url,
        """.format(
            fulfilled_by="req.fulfilled_by," if include_user_details else "NULL AS fulfilled_by,",
            fulfilled_by_name="fulfiller.name AS fulfilled_by_name," if include_user_details else "NULL AS fulfilled_by_name,",
        )
        fulfill_joins = """
            LEFT JOIN users fulfiller ON req.fulfilled_by = fulfiller.user_id
            LEFT JOIN resources fulfilled_resource
                ON req.fulfilled_resource_id = fulfilled_resource.resource_id
        """
    else:
        fulfill_cols = """
            NULL AS fulfilled_by,
            NULL AS fulfilled_by_name,
            NULL AS fulfilled_resource_id,
            NULL AS fulfilled_resource_title,
            NULL AS fulfilled_resource_url,
        """
        fulfill_joins = """
        """

    meta_code = "COALESCE(meta.catalogue_code, s.subject_code) AS subject_code," if has_meta else "s.subject_code AS subject_code,"
    meta_join = "LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id" if has_meta else ""
    user_cols = (
        "u.user_id,\n            u.name AS user_name,\n            u.role AS user_role,"
        if include_user_details
        else "NULL AS user_id,\n            NULL AS user_name,\n            NULL AS user_role,"
    )

    base_query = f"""
        SELECT
            req.request_id AS id,
            {title_sql}
            req.request_description AS description,
            req.status,
            {fulfill_cols}
            req.created_at,
            {user_cols}
            s.subject_id,
            s.subject_name AS subject,
            {meta_code}
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
        {meta_join}
        {fulfill_joins}
    """
    return base_query, has_meta



@requests_bp.route("/requests", methods=["GET"])
def get_requests():
    branch = request.args.get("branch")
    semester = request.args.get("semester")
    subject = request.args.get("subject")
    status = request.args.get("status")

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
        base_query, has_meta = _build_request_select_sql(
            cursor,
            include_user_details=authenticated_user_id() is not None,
        )

        if subject:
            if has_meta:
                conditions.append("""
                    (
                        LOWER(s.subject_name) = LOWER(%s)
                        OR LOWER(s.subject_code) = LOWER(%s)
                        OR LOWER(COALESCE(meta.catalogue_code, s.subject_code)) = LOWER(%s)
                    )
                """)
                values.extend([subject.strip(), subject.strip(), subject.strip()])
            else:
                conditions.append("""
                    (
                        LOWER(s.subject_name) = LOWER(%s)
                        OR LOWER(s.subject_code) = LOWER(%s)
                    )
                """)
                values.extend([subject.strip(), subject.strip()])

        query = base_query
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


def _resolve_academic_scope(cursor, branch, semester, subject, unit):
    try:
        sem_num = int(str(semester).replace("Semester", "").strip())
        if not 1 <= sem_num <= 8:
            raise ValueError
    except (ValueError, TypeError):
        return None, None, "Semester must be between 1 and 8."

    has_meta = table_exists(cursor, "subject_catalogue_metadata")
    if has_meta:
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
    else:
        cursor.execute("""
            SELECT s.subject_id, s.subject_name
            FROM subjects s
            JOIN semesters sem ON s.semester_id = sem.semester_id
            JOIN branches b ON sem.branch_id = b.branch_id
            WHERE LOWER(b.branch_name) = LOWER(%s)
              AND sem.semester_name = %s
              AND (
                  LOWER(s.subject_name) = LOWER(%s)
                  OR LOWER(s.subject_code) = LOWER(%s)
              )
        """, (branch, f"Semester {sem_num}", subject, subject))
    subject_row = cursor.fetchone()
    if not subject_row:
        return None, None, (
            f"Subject '{subject}' not found for {branch} Semester {sem_num}."
        )

    unit_id = None
    if unit and str(unit).strip().lower() not in ("all", "all units"):
        try:
            unit_number = int(str(unit).replace("Unit", "").strip())
            if unit_number < 1:
                raise ValueError
        except (ValueError, TypeError):
            return None, None, "Unit must be a positive number or 'all'."
        cursor.execute(
            "SELECT unit_id FROM units WHERE subject_id = %s AND unit_number = %s",
            (subject_row["subject_id"], unit_number)
        )
        unit_row = cursor.fetchone()
        if not unit_row:
            return None, None, "Selected unit is not available for this subject."
        unit_id = unit_row["unit_id"]

    return subject_row["subject_id"], unit_id, None


@requests_bp.route("/requests", methods=["POST"])
@require_auth
def create_request():
    data = request.get_json(silent=True) or request.form
    if not hasattr(data, "get"):
        return jsonify({"success": False, "message": "Invalid request payload."}), 400
    branch_raw = data.get("branch")
    subject_raw = data.get("subject")
    description_raw = data.get("description")
    title_raw = data.get("title", subject_raw)
    if not all(isinstance(value, str) for value in (branch_raw, subject_raw, description_raw, title_raw)):
        return jsonify({"success": False, "message": "Title, branch, subject, and description must be text."}), 400
    branch = branch_raw.strip()
    semester = data.get("semester")
    subject = subject_raw.strip()
    unit = data.get("unit")
    title = title_raw.strip()
    description = description_raw.strip()

    if not title:
        return jsonify({"success": False, "message": "Request title is required."}), 400
    if len(title) > 200:
        return jsonify({"success": False, "message": "Request title must be 200 characters or fewer."}), 400
    if not description:
        return jsonify({"success": False, "message": "Request description is required."}), 400
    if len(description) > 2000:
        return jsonify({"success": False, "message": "Request description must be 2000 characters or fewer."}), 400

    if not branch or not semester or not subject:
        return jsonify({"success": False, "message": "Branch, semester, and subject are required."}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        # Validate user
        cursor.execute(
            "SELECT user_id, name FROM users WHERE user_id = %s FOR UPDATE",
            (g.user_id,)
        )
        user_row = cursor.fetchone()
        if not user_row:
            return jsonify({"success": False, "message": "User not found."}), 401

        subject_id, unit_id, validation_error = _resolve_academic_scope(
            cursor, branch, semester, subject, unit
        )
        if validation_error:
            return jsonify({"success": False, "message": validation_error}), 400

        has_title = column_exists(cursor, "requests", "request_title")
        duplicate_query = """
            SELECT request_id
            FROM requests
            WHERE user_id = %s
              AND subject_id = %s
              AND unit_id <=> %s
              AND LOWER(TRIM(request_description)) = LOWER(%s)
              AND status = 'Pending'
        """
        duplicate_values = [g.user_id, subject_id, unit_id, description]
        if has_title:
            duplicate_query += " AND LOWER(TRIM(request_title)) = LOWER(%s)"
            duplicate_values.append(title)
        duplicate_query += " LIMIT 1"
        cursor.execute(duplicate_query, duplicate_values)
        if cursor.fetchone():
            return jsonify({
                "success": False,
                "message": "An identical pending request already exists for this subject and unit."
            }), 409

        if has_title:
            cursor.execute("""
                INSERT INTO requests
                    (user_id, subject_id, unit_id, request_title, request_description, status)
                VALUES (%s, %s, %s, %s, %s, 'Pending')
            """, (g.user_id, subject_id, unit_id, title, description))
        else:
            cursor.execute("""
                INSERT INTO requests
                    (user_id, subject_id, unit_id, request_description, status)
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


@requests_bp.route("/requests/<int:request_id>", methods=["PATCH"])
@require_auth
def edit_request(request_id):
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"success": False, "message": "Invalid request payload."}), 400

    title = data.get("title")
    description = data.get("description")
    branch = data.get("branch")
    semester = data.get("semester")
    subject = data.get("subject")
    unit = data.get("unit")
    if not all(isinstance(value, str) for value in (title, description, branch, subject)):
        return jsonify({
            "success": False,
            "message": "Title, description, branch, and subject must be text."
        }), 400
    if "unit" not in data:
        return jsonify({"success": False, "message": "Unit selection is required."}), 400

    title = title.strip()
    description = description.strip()
    branch = branch.strip()
    subject = subject.strip()
    if not title or len(title) > 200:
        return jsonify({
            "success": False,
            "message": "Request title must be between 1 and 200 characters."
        }), 400
    if not description or len(description) > 2000:
        return jsonify({
            "success": False,
            "message": "Request description must be between 1 and 2000 characters."
        }), 400
    if not branch or not subject or semester in (None, ""):
        return jsonify({
            "success": False,
            "message": "Branch, semester, and subject are required."
        }), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT request_id, user_id, status
            FROM requests
            WHERE request_id = %s
            FOR UPDATE
        """, (request_id,))
        req = cursor.fetchone()
        if not req:
            return jsonify({"success": False, "message": "Request not found."}), 404
        if req["user_id"] != g.user_id:
            return jsonify({
                "success": False,
                "message": "You are not authorized to edit this request."
            }), 403
        if req["status"] != "Pending":
            return jsonify({
                "success": False,
                "message": "Only pending requests can be edited."
            }), 409

        subject_id, unit_id, validation_error = _resolve_academic_scope(
            cursor, branch, semester, subject, unit
        )
        if validation_error:
            return jsonify({"success": False, "message": validation_error}), 400

        has_title = column_exists(cursor, "requests", "request_title")
        if has_title:
            cursor.execute("""
                UPDATE requests
                SET request_title = %s,
                    request_description = %s,
                    subject_id = %s,
                    unit_id = %s
                WHERE request_id = %s
                  AND user_id = %s
                  AND status = 'Pending'
            """, (title, description, subject_id, unit_id, request_id, g.user_id))
        else:
            cursor.execute("""
                UPDATE requests
                SET request_description = %s,
                    subject_id = %s,
                    unit_id = %s
                WHERE request_id = %s
                  AND user_id = %s
                  AND status = 'Pending'
            """, (description, subject_id, unit_id, request_id, g.user_id))
        if cursor.rowcount != 1:
            connection.rollback()
            return jsonify({
                "success": False,
                "message": "The request changed before your edit could be saved."
            }), 409

        connection.commit()
        return jsonify({
            "success": True,
            "message": "Request updated successfully."
        }), 200
    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("Resource request update failed")
        return jsonify({
            "success": False,
            "message": "Unable to update the resource request."
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@requests_bp.route("/requests/<int:request_id>", methods=["DELETE"])
@require_auth
def delete_request(request_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT request_id, user_id
            FROM requests
            WHERE request_id = %s
            FOR UPDATE
        """, (request_id,))
        req = cursor.fetchone()
        if not req:
            return jsonify({"success": False, "message": "Request not found."}), 404
        if req["user_id"] != g.user_id:
            return jsonify({
                "success": False,
                "message": "You are not authorized to delete this request."
            }), 403

        cursor.execute(
            "DELETE FROM requests WHERE request_id = %s AND user_id = %s",
            (request_id, g.user_id)
        )
        if cursor.rowcount != 1:
            connection.rollback()
            return jsonify({
                "success": False,
                "message": "The request could not be deleted."
            }), 409

        connection.commit()
        return jsonify({
            "success": True,
            "message": "Request deleted successfully."
        }), 200
    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("Resource request deletion failed")
        return jsonify({
            "success": False,
            "message": "Unable to delete the resource request."
        }), 500
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
        base_query, _ = _build_request_select_sql(cursor)
        cursor.execute(base_query + " WHERE req.user_id = %s ORDER BY req.request_id DESC", (g.user_id,))
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
                "message": "This request status cannot be manually changed."
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
        base_query, _ = _build_request_select_sql(cursor)
        cursor.execute(base_query + " WHERE req.request_id = %s", (request_id,))
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
