import os
from uuid import uuid4
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from werkzeug.utils import secure_filename

try:
    from db import get_db_connection
except ImportError:
    from backend.db import get_db_connection

resources_bp = Blueprint("resources", __name__)
ALLOWED_EXTENSIONS = {"pdf", "png", "jpg", "jpeg"}

UPLOAD_FOLDER = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "uploads"
)

os.makedirs(UPLOAD_FOLDER, exist_ok=True)


def allowed_file(filename):
    return (
        "." in filename
        and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
    )


def _fetch_all_resources():
    """
    Fetch study resources from the MySQL database with complete foreign key joins.
    Only returns resources that have valid database records AND whose physical file
    exists in the uploads folder. Raises database exceptions so callers can return clear errors.
    """
    db_resources = []
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT
                r.resource_id AS id,
                r.title,
                r.resource_url,
                r.resource_type AS type,
                r.description,
                b.branch_name AS branch,
                sem.semester_name AS semester,
                s.subject_name AS subject,
                u.unit_number AS unit
            FROM resources r
            LEFT JOIN subjects s ON r.subject_id = s.subject_id
            LEFT JOIN semesters sem ON s.semester_id = sem.semester_id
            LEFT JOIN branches b ON sem.branch_id = b.branch_id
            LEFT JOIN units u ON r.unit_id = u.unit_id
            ORDER BY r.resource_id DESC
        """)
        rows = cursor.fetchall()

        for row in rows:
            url = (row.get("resource_url") or "").strip()
            filename = None

            if url.startswith("/uploads/"):
                filename = url.replace("/uploads/", "").strip()
            elif os.path.exists(os.path.join(UPLOAD_FOLDER, url)):
                filename = url

            # Verify that the referenced file physically exists in the uploads directory
            if not filename:
                continue

            file_path = os.path.join(UPLOAD_FOLDER, filename)
            if not (os.path.isfile(file_path) and os.path.getsize(file_path) > 0):
                continue

            sem_val = None
            if row["semester"]:
                try:
                    sem_val = int(str(row["semester"]).replace("Semester", "").strip())
                except (ValueError, TypeError):
                    sem_val = row["semester"]

            db_resources.append({
                "id": row["id"],
                "title": row["title"],
                "branch": row["branch"] or "",
                "semester": sem_val if sem_val is not None else 4,
                "subject": row["subject"] or "",
                "unit": row["unit"] if row["unit"] is not None else None,
                "type": row["type"] or "PDF Notes",
                "filename": filename,
                "resource_url": url,
                "description": row["description"] or ""
            })

        return db_resources

    finally:
        if cursor:
            try:
                cursor.close()
            except Exception:
                pass
        if connection:
            try:
                connection.close()
            except Exception:
                pass


@resources_bp.route("/resources")
def get_resources():
    branch = request.args.get("branch")
    semester = request.args.get("semester", type=int)
    subject = request.args.get("subject")
    unit = request.args.get("unit", type=int)
    search = request.args.get("search")
    resource_type = request.args.get("type")

    try:
        all_resources = _fetch_all_resources()
    except Exception as e:
        try:
            current_app.logger.exception("Failed to fetch resources from database")
        except Exception:
            pass
        return jsonify({
            "success": False,
            "message": f"Database error occurred: {str(e)}",
            "count": 0,
            "resources": []
        }), 500

    filtered_resources = []

    for resource in all_resources:
        if branch and str(resource.get("branch", "")).lower() != branch.lower():
            continue

        if semester is not None and resource.get("semester") != semester:
            continue

        if subject and str(resource.get("subject", "")).lower() != subject.lower():
            continue

        if unit is not None and resource.get("unit") != unit:
            continue

        if search and search.lower() not in str(resource.get("title", "")).lower():
            continue

        if resource_type and str(resource.get("type", "")).lower() != resource_type.lower():
            continue

        filtered_resources.append(resource)

    filtered_resources.sort(key=lambda item: item["title"].lower())

    return jsonify({
        "message": "Resources fetched successfully",
        "count": len(filtered_resources),
        "resources": filtered_resources
    }), 200


@resources_bp.route("/resources/<int:resource_id>")
def get_resource_by_id(resource_id):
    try:
        all_resources = _fetch_all_resources()
    except Exception as e:
        try:
            current_app.logger.exception("Failed to fetch resource from database")
        except Exception:
            pass
        return jsonify({
            "success": False,
            "message": f"Database error occurred: {str(e)}"
        }), 500

    for resource in all_resources:
        if resource["id"] == resource_id:
            return jsonify({
                "message": "Resource fetched successfully",
                "resource": resource
            }), 200

    return jsonify({
        "message": "Resource not found"
    }), 404


@resources_bp.route("/resource-types")
def get_resource_types():
    try:
        all_resources = _fetch_all_resources()
    except Exception as e:
        try:
            current_app.logger.exception("Failed to fetch resource types")
        except Exception:
            pass
        return jsonify({
            "success": False,
            "message": f"Database error occurred: {str(e)}",
            "resource_types": []
        }), 500

    resource_types = []

    for resource in all_resources:
        rtype = resource.get("type")
        if rtype and rtype not in resource_types:
            resource_types.append(rtype)

    return jsonify({
        "message": "Resource types fetched successfully",
        "resource_types": resource_types
    }), 200


@resources_bp.route("/resources/upload", methods=["POST"])
def upload_resource():
    if "file" not in request.files:
        return jsonify({
            "success": False,
            "message": "No file provided"
        }), 400

    file = request.files["file"]

    if not file.filename or not file.filename.strip():
        return jsonify({
            "success": False,
            "message": "No file selected"
        }), 400

    if not allowed_file(file.filename):
        return jsonify({
            "success": False,
            "message": "Only PDF, PNG, JPG and JPEG files are allowed"
        }), 400

    title = request.form.get("title", "").strip()
    branch = request.form.get("branch", "").strip()
    semester = request.form.get("semester")
    subject = request.form.get("subject", "").strip()
    unit = request.form.get("unit")
    resource_type = request.form.get("type", "PDF Notes").strip()
    uploaded_by_raw = request.form.get("uploaded_by")

    if not title:
        return jsonify({"success": False, "message": "Resource title is required"}), 400
    if not branch:
        return jsonify({"success": False, "message": "Branch is required"}), 400
    if not semester:
        return jsonify({"success": False, "message": "Semester is required"}), 400
    if not subject:
        return jsonify({"success": False, "message": "Subject is required"}), 400
    if not unit:
        return jsonify({"success": False, "message": "Unit is required"}), 400

    try:
        sem_num = int(str(semester).replace("Semester", "").strip())
        if sem_num < 1 or sem_num > 8:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid semester number"}), 400

    try:
        unit_num = int(str(unit).replace("Unit", "").strip())
        if unit_num < 1 or unit_num > 5:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid unit number"}), 400

    # Validate against MySQL database
    file_path = None
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 1. Validate Branch
        cursor.execute(
            "SELECT branch_id, branch_name FROM branches WHERE LOWER(branch_name) = LOWER(%s)",
            (branch,)
        )
        branch_row = cursor.fetchone()
        if not branch_row:
            return jsonify({
                "success": False,
                "message": f"Branch '{branch}' is not registered in the database."
            }), 400
        branch_id = branch_row["branch_id"]
        branch_name = branch_row["branch_name"]

        # 2. Validate Semester for this Branch
        cursor.execute(
            "SELECT semester_id, semester_name FROM semesters WHERE branch_id = %s AND semester_name = %s",
            (branch_id, f"Semester {sem_num}")
        )
        semester_row = cursor.fetchone()
        if not semester_row:
            return jsonify({
                "success": False,
                "message": f"Semester {sem_num} does not exist for branch '{branch_name}' in the database."
            }), 400
        semester_id = semester_row["semester_id"]

        # 3. Validate Subject for this Semester
        cursor.execute(
            """
            SELECT subject_id, subject_name, subject_code
            FROM subjects
            WHERE semester_id = %s
              AND (LOWER(subject_name) = LOWER(%s) OR LOWER(subject_code) = LOWER(%s))
            """,
            (semester_id, subject, subject)
        )
        subject_row = cursor.fetchone()
        if not subject_row:
            return jsonify({
                "success": False,
                "message": f"Subject '{subject}' does not exist for {branch_name} Semester {sem_num} in the database."
            }), 400
        subject_id = subject_row["subject_id"]
        subject_name = subject_row["subject_name"]

        # 4. Validate Unit for this Subject
        cursor.execute(
            "SELECT unit_id, unit_name FROM units WHERE subject_id = %s AND unit_number = %s",
            (subject_id, unit_num)
        )
        unit_row = cursor.fetchone()
        if not unit_row:
            return jsonify({
                "success": False,
                "message": f"Unit {unit_num} does not exist in the database for '{subject_name}'."
            }), 400
        unit_id = unit_row["unit_id"]

        # 5. Validate uploaded_by from authenticated user
        uploaded_by = None
        if uploaded_by_raw:
            try:
                user_pk = int(uploaded_by_raw)
                cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (user_pk,))
                user_row = cursor.fetchone()
                if user_row:
                    uploaded_by = user_row["user_id"]
            except (ValueError, TypeError):
                uploaded_by = None

        # Safe extension extraction and unique filename generation
        parts = file.filename.rsplit(".", 1)
        if len(parts) < 2 or not parts[1].strip():
            return jsonify({
                "success": False,
                "message": "Invalid filename"
            }), 400

        extension = parts[1].lower()
        if extension not in ALLOWED_EXTENSIONS:
            return jsonify({
                "success": False,
                "message": "Only PDF, PNG, JPG and JPEG files are allowed"
            }), 400

        saved_filename = f"{uuid4().hex}.{extension}"
        file_path = os.path.join(UPLOAD_FOLDER, saved_filename)

        file.save(file_path)

        if os.path.getsize(file_path) == 0:
            if os.path.exists(file_path):
                os.remove(file_path)
            return jsonify({
                "success": False,
                "message": "Empty files are not allowed"
            }), 400

        # Save metadata to MySQL resources table
        cursor.execute(
            """
            INSERT INTO resources (title, resource_url, resource_type, subject_id, uploaded_by, unit_id, description)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                title,
                f"/uploads/{saved_filename}",
                resource_type,
                subject_id,
                uploaded_by,
                unit_id,
                f"Uploaded study resource for {subject_name} Unit {unit_num}"
            )
        )
        connection.commit()
        new_resource_id = cursor.lastrowid

        created_resource = {
            "id": new_resource_id,
            "title": title,
            "branch": branch_name,
            "semester": sem_num,
            "subject": subject_name,
            "unit": unit_num,
            "type": resource_type,
            "filename": saved_filename,
            "resource_url": f"/uploads/{saved_filename}",
            "description": f"Uploaded study resource for {subject_name} Unit {unit_num}"
        }

        return jsonify({
            "success": True,
            "message": "Resource uploaded and registered successfully",
            "filename": saved_filename,
            "resource": created_resource
        }), 201

    except Exception as e:
        if connection:
            try:
                connection.rollback()
            except Exception:
                pass
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except OSError:
                pass
        current_app.logger.exception("Upload handling failed")
        return jsonify({
            "success": False,
            "message": f"Database error occurred: {str(e)}"
        }), 500

    finally:
        if cursor:
            try:
                cursor.close()
            except Exception:
                pass
        if connection:
            try:
                connection.close()
            except Exception:
                pass


@resources_bp.route("/uploads/<filename>")
def open_uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)
