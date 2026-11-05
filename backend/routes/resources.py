import os
from urllib.parse import urlparse
from uuid import uuid4
from flask import Blueprint, request, jsonify, current_app, send_from_directory, g
from werkzeug.utils import secure_filename

try:
    from auth_utils import authenticated_user_id, require_auth
    from db import get_db_connection
except ImportError:
    from backend.auth_utils import authenticated_user_id, require_auth
    from backend.db import get_db_connection

resources_bp = Blueprint("resources", __name__)
ALLOWED_EXTENSIONS = {"pdf", "png", "jpg", "jpeg"}
MAX_FILE_SIZE = 25 * 1024 * 1024  # 25 MB

if os.environ.get("VERCEL"):
    UPLOAD_FOLDER = "/tmp/unote_uploads"
else:
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


def _normalize_type(rtype):
    if not rtype:
        return ""
    t = rtype.strip().lower()
    if t in ("previous year papers", "previous year question papers", "pyq", "pyqs"):
        return "pyq"
    if t in ("youtube lectures", "youtube resources", "youtube videos", "youtube"):
        return "youtube"
    return t


def _text_input(json_data, name, default=""):
    value = request.form.get(name)
    if value is None:
        value = json_data.get(name, default)
    return value.strip() if isinstance(value, str) else ""


def _fetch_all_resources(owner_id=None):
    """
    Fetch study resources from the MySQL database with complete foreign key joins.
    Only returns resources that have valid database records AND whose physical file
    exists in the uploads folder (or is a valid external URL).
    """
    db_resources = []
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        query = """
            SELECT
                r.resource_id AS id,
                r.title,
                r.resource_url,
                r.resource_type AS type,
                r.description,
                b.branch_name AS branch,
                sem.semester_name AS semester,
                s.subject_name AS subject,
                COALESCE(meta.catalogue_code, s.subject_code) AS subject_code,
                u.unit_number AS unit,
                u.unit_name AS unit_name,
                r.unit_scope AS unit_scope,
                r.created_at AS uploaded_at,
                r.uploaded_by,
                uploader.name AS uploader_name,
                uploader.role AS uploader_role,
                rating_stats.avg_rating,
                COALESCE(rating_stats.rating_count, 0) AS rating_count
            FROM resources r
            LEFT JOIN subjects s ON r.subject_id = s.subject_id
            LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
            LEFT JOIN semesters sem ON s.semester_id = sem.semester_id
            LEFT JOIN branches b ON sem.branch_id = b.branch_id
            LEFT JOIN units u ON r.unit_id = u.unit_id
            LEFT JOIN users uploader ON r.uploaded_by = uploader.user_id
            LEFT JOIN (
                SELECT
                    resource_id,
                    ROUND(AVG(rating), 1) AS avg_rating,
                    COUNT(rating_id) AS rating_count
                FROM ratings
                GROUP BY resource_id
            ) rating_stats ON r.resource_id = rating_stats.resource_id
        """
        values = ()
        if owner_id is not None:
            query = query.rstrip() + "\n WHERE r.uploaded_by = %s"
            values = (owner_id,)
        query += "\n ORDER BY r.resource_id DESC"
        cursor.execute(query, values)
        rows = cursor.fetchall()

        for row in rows:
            url = (row.get("resource_url") or "").strip()
            filename = None
            is_external = url.startswith("http://") or url.startswith("https://")

            if url.startswith("/uploads/"):
                candidate = url[len("/uploads/"):]
                if candidate and secure_filename(candidate) == candidate:
                    filename = candidate
            elif url and secure_filename(url) == url:
                filename = url

           # Keep database records even if the uploaded file is missing
            if not is_external and not filename:
                continue

            sem_val = None
            if row["semester"]:
                try:
                    sem_val = int(str(row["semester"]).replace("Semester", "").strip())
                except (ValueError, TypeError):
                    sem_val = row["semester"]

            unit_scope = row.get("unit_scope") or "unit"
            unit_value = "all" if unit_scope == "all" else row["unit"]
            if unit_scope == "all":
                unit_label = "All Units"
            elif row["unit"] is not None:
                unit_label = f"Unit {row['unit']}"
                if row.get("unit_name"):
                    unit_label += f": {row['unit_name']}"
            else:
                unit_label = "Not specified"

            uploaded_at = row.get("uploaded_at")
            if hasattr(uploaded_at, "isoformat"):
                uploaded_at = uploaded_at.isoformat()

            db_resources.append({
                "id": row["id"],
                "title": row["title"],
                "branch": row["branch"] or "",
                "semester": sem_val,
                "subject": row["subject"] or "",
                "subject_code": row.get("subject_code") or "",
                "unit": unit_value,
                "unit_name": row.get("unit_name") or "",
                "unit_label": unit_label,
                "unit_scope": unit_scope,
                "type": row["type"] or "PDF Notes",
                "filename": filename,
                "resource_url": url,
                "is_external": is_external,
                "description": row["description"] or "",
                "uploaded_at": uploaded_at,
                "uploaded_by": row.get("uploaded_by"),
                "uploader_name": row.get("uploader_name") or "Community Contributor",
                "uploader_role": row.get("uploader_role") or "student",
                "avg_rating": float(row["avg_rating"]) if row.get("avg_rating") is not None else None,
                "rating_count": int(row.get("rating_count") or 0)
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
    semester_raw = request.args.get("semester")
    try:
        semester = int(semester_raw) if semester_raw else None
        if semester is not None and not 1 <= semester <= 8:
            raise ValueError
    except ValueError:
        return jsonify({"success": False, "message": "Semester must be between 1 and 8."}), 400
    subject = request.args.get("subject")
    unit_param = request.args.get("unit")
    search = request.args.get("search")
    resource_type = request.args.get("type")
    target_unit = None
    all_units = False
    if unit_param:
        normalized_unit = unit_param.strip().lower()
        all_units = normalized_unit in ("all", "all units")
        if not all_units:
            try:
                target_unit = int(normalized_unit.replace("unit", "").strip())
                if not 1 <= target_unit <= 5:
                    raise ValueError
            except ValueError:
                return jsonify({"success": False, "message": "Unit must be between 1 and 5, or 'all'."}), 400

    try:
        all_resources = _fetch_all_resources()
    except Exception:
        try:
            current_app.logger.exception("Failed to fetch resources from database")
        except Exception:
            pass
        return jsonify({
            "success": False,
            "message": "Unable to fetch resources from the database.",
            "count": 0,
            "resources": []
        }), 500

    filtered_resources = []

    for resource in all_resources:
        if branch and str(resource.get("branch", "")).lower() != branch.lower():
            continue

        if semester is not None and resource.get("semester") != semester:
            continue

        if subject:
            subj_val = str(resource.get("subject", "")).lower()
            code_val = str(resource.get("subject_code", "")).lower()
            search_subj = subject.strip().lower()
            if search_subj != subj_val and search_subj != code_val:
                continue

        if unit_param:
            if all_units:
                if resource.get("unit_scope") != "all" and str(resource.get("unit")).lower() != "all":
                    continue
            elif target_unit is not None:
                if resource.get("unit") != target_unit:
                    continue

        if search:
            query_str = search.lower()
            title_match = query_str in str(resource.get("title", "")).lower()
            subj_match = query_str in str(resource.get("subject", "")).lower()
            desc_match = query_str in str(resource.get("description", "")).lower()
            if not (title_match or subj_match or desc_match):
                continue

        if resource_type:
            r_type_norm = _normalize_type(resource.get("type"))
            q_type_norm = _normalize_type(resource_type)
            if r_type_norm != q_type_norm:
                continue

        filtered_resources.append(resource)

    filtered_resources.sort(key=lambda item: item["title"].lower())

    return jsonify({
        "message": "Resources fetched successfully",
        "count": len(filtered_resources),
        "resources": filtered_resources
    }), 200


@resources_bp.route("/resources/shared")
@require_auth
def get_shared_resources():
    try:
        shared_resources = _fetch_all_resources(owner_id=g.user_id)
    except Exception:
        current_app.logger.exception("Failed to fetch shared resources")
        return jsonify({
            "success": False,
            "message": "Unable to fetch shared resources",
            "count": 0,
            "resources": []
        }), 500

    return jsonify({
        "success": True,
        "message": "Shared resources fetched successfully",
        "count": len(shared_resources),
        "resources": shared_resources
    }), 200


@resources_bp.route("/resources/saved")
@require_auth
def get_saved_resources():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "SELECT resource_id FROM saved_resources WHERE user_id = %s",
            (g.user_id,)
        )
        saved_ids = {row["resource_id"] for row in cursor.fetchall()}
        all_resources = _fetch_all_resources()
        saved = [resource for resource in all_resources if resource["id"] in saved_ids]
        return jsonify({"success": True, "count": len(saved), "resources": saved}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch saved resources")
        return jsonify({
            "success": False,
            "message": "Unable to fetch saved resources.",
            "resources": []
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@resources_bp.route("/resources/<int:resource_id>/saved", methods=["GET", "POST", "DELETE"])
@require_auth
def saved_resource(resource_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "SELECT resource_id FROM resources WHERE resource_id = %s",
            (resource_id,)
        )
        if not cursor.fetchone():
            return jsonify({"success": False, "message": "Resource not found."}), 404

        if request.method == "GET":
            cursor.execute(
                "SELECT 1 FROM saved_resources WHERE user_id = %s AND resource_id = %s",
                (g.user_id, resource_id)
            )
            return jsonify({"success": True, "saved": cursor.fetchone() is not None}), 200

        if request.method == "POST":
            cursor.execute(
                "INSERT IGNORE INTO saved_resources (user_id, resource_id) VALUES (%s, %s)",
                (g.user_id, resource_id)
            )
        else:
            cursor.execute(
                "DELETE FROM saved_resources WHERE user_id = %s AND resource_id = %s",
                (g.user_id, resource_id)
            )
        connection.commit()
        return jsonify({
            "success": True,
            "saved": request.method == "POST",
            "message": "Saved resource updated."
        }), 200
    except Exception:
        if connection:
            connection.rollback()
        current_app.logger.exception("Saved resource update failed")
        return jsonify({"success": False, "message": "Unable to update saved resources."}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@resources_bp.route("/resources/<int:resource_id>")
def get_resource_by_id(resource_id):
    try:
        all_resources = _fetch_all_resources()
    except Exception:
        try:
            current_app.logger.exception("Failed to fetch resource from database")
        except Exception:
            pass
        return jsonify({
            "success": False,
            "message": "Unable to fetch the resource."
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


@resources_bp.route("/resources/<int:resource_id>", methods=["PUT"])
@require_auth
def update_resource(resource_id):
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({
            "success": False,
            "message": "Invalid request payload."
        }), 400

    title = data.get("title")
    description = data.get("description", "")
    resource_type = data.get("resource_type")

    if not isinstance(title, str) or not title.strip():
        return jsonify({"success": False, "message": "Title is required."}), 400

    if not isinstance(description, str) or not isinstance(resource_type, str):
        return jsonify({"success": False, "message": "Invalid resource details."}), 400

    title = title.strip()
    description = description.strip()
    resource_type = resource_type.strip()

    if len(title) > 200 or len(resource_type) > 50:
        return jsonify({"success": False, "message": "Title or resource type is too long."}), 400

    if not resource_type:
        return jsonify({"success": False, "message": "Resource type is required."}), 400

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT uploaded_by FROM resources WHERE resource_id = %s",
            (resource_id,)
        )
        resource_row = cursor.fetchone()

        if not resource_row:
            return jsonify({"success": False, "message": "Resource not found."}), 404

        if int(resource_row["uploaded_by"]) != int(g.user_id):
            return jsonify({
                "success": False,
                "message": "You are not authorized to edit this resource."
            }), 403

        cursor.execute(
            """
            UPDATE resources
            SET title = %s, description = %s, resource_type = %s
            WHERE resource_id = %s
            """,
            (title, description, resource_type, resource_id)
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Resource updated successfully."
        }), 200

    except Exception:
        if connection:
            connection.rollback()

        current_app.logger.exception("Resource update failed")

        return jsonify({
            "success": False,
            "message": "Unable to update the resource."
        }), 500

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

@resources_bp.route("/resources/<int:resource_id>", methods=["DELETE"])
@require_auth
def delete_resource(resource_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "SELECT resource_id, resource_url, uploaded_by FROM resources WHERE resource_id = %s",
            (resource_id,)
        )
        res = cursor.fetchone()
        if not res:
            return jsonify({"success": False, "message": "Resource not found"}), 404

        if res["uploaded_by"] != g.user_id:
            return jsonify({
                "success": False,
                "message": "You are not authorized to delete this resource"
            }), 403

        url = (res.get("resource_url") or "").strip()
        fname = secure_filename(url[len("/uploads/"):]) if url.startswith("/uploads/") else ""

        cursor.execute("DELETE FROM ratings WHERE resource_id = %s", (resource_id,))
        cursor.execute("DELETE FROM resources WHERE resource_id = %s", (resource_id,))
        connection.commit()
        if fname:
            fpath = os.path.join(UPLOAD_FOLDER, fname)
            if os.path.isfile(fpath):
                try:
                    os.remove(fpath)
                except OSError:
                    current_app.logger.exception("Unable to remove deleted resource file")

        return jsonify({
            "success": True,
            "message": "Resource deleted successfully"
        }), 200
    except Exception:
        if connection:
            try:
                connection.rollback()
            except Exception:
                pass
        current_app.logger.exception("Resource deletion failed")
        return jsonify({
            "success": False,
            "message": "Unable to delete the resource."
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@resources_bp.route("/resource-types")
def get_resource_types():
    try:
        all_resources = _fetch_all_resources()
    except Exception:
        try:
            current_app.logger.exception("Failed to fetch resource types")
        except Exception:
            pass
        return jsonify({
            "success": False,
            "message": "Unable to fetch resource types.",
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
@require_auth
def upload_resource():
    req_json = request.get_json(silent=True) or {}
    if not isinstance(req_json, dict):
        return jsonify({"success": False, "message": "Invalid request payload."}), 400

    title = _text_input(req_json, "title")
    branch = _text_input(req_json, "branch")
    semester = request.form.get("semester") or req_json.get("semester")
    subject = _text_input(req_json, "subject")
    unit = request.form.get("unit") or req_json.get("unit")
    resource_type = _text_input(req_json, "type", "PDF Notes") or "PDF Notes"
    description = _text_input(req_json, "description")
    youtube_url = (
        _text_input(req_json, "youtube_url")
        or _text_input(req_json, "url")
    )

    file = request.files.get("file")

    parsed_url = urlparse(youtube_url)
    is_link_upload = parsed_url.scheme in ("http", "https") and bool(parsed_url.netloc)
    if youtube_url and not is_link_upload:
        return jsonify({"success": False, "message": "Enter a valid http or https resource URL."}), 400
    if _normalize_type(resource_type) == "youtube" and is_link_upload:
        host = (parsed_url.hostname or "").lower()
        if host not in ("youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"):
            return jsonify({"success": False, "message": "Enter a valid YouTube video or channel URL."}), 400

    if not file and not is_link_upload:
        if _normalize_type(resource_type) == "youtube":
            return jsonify({
                "success": False,
                "message": "Please provide a valid YouTube / web link (e.g., https://youtube.com/...)"
            }), 400
        return jsonify({
            "success": False,
            "message": "Please select a file or provide a valid external URL"
        }), 400

    if not title:
        return jsonify({"success": False, "message": "Resource title is required"}), 400
    if len(title) > 200 or len(resource_type) > 50:
        return jsonify({"success": False, "message": "Title or resource type is too long."}), 400
    if not branch:
        return jsonify({"success": False, "message": "Branch is required"}), 400
    if not semester:
        return jsonify({"success": False, "message": "Semester is required"}), 400
    if not subject:
        return jsonify({"success": False, "message": "Subject is required"}), 400
    if not unit:
        return jsonify({"success": False, "message": "Select a valid unit"}), 400
    try:
        sem_num = int(str(semester).replace("Semester", "").strip())
        if sem_num < 1 or sem_num > 8:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid semester number"}), 400

    unit_scope = "all" if str(unit).lower() == "all" else "unit"
    unit_num = None
    if unit_scope == "unit":
        try:
            unit_num = int(str(unit).replace("Unit", "").strip())
            if unit_num < 1 or unit_num > 5:
                raise ValueError
        except (ValueError, TypeError):
            return jsonify({"success": False, "message": "Invalid unit number"}), 400

    uploaded_by = g.user_id

    # Validate against MySQL database
    file_path = None
    saved_filename = None
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
            SELECT s.subject_id, s.subject_name, s.subject_code
            FROM subjects s
            LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
            WHERE s.semester_id = %s
              AND COALESCE(meta.is_selectable, 1) = 1
              AND (
                  LOWER(s.subject_name) = LOWER(%s)
                  OR LOWER(s.subject_code) = LOWER(%s)
                  OR LOWER(COALESCE(meta.catalogue_code, s.subject_code)) = LOWER(%s)
              )
            """,
            (semester_id, subject, subject, subject)
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
        unit_id = None
        if unit_scope == "unit":
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

        # Confirm user exists and check role
        cursor.execute("SELECT user_id, name, role FROM users WHERE user_id = %s", (uploaded_by,))
        user_row = cursor.fetchone()
        if not user_row:
            return jsonify({
                "success": False,
                "message": "The logged-in user could not be found"
            }), 401
        uploaded_by = user_row["user_id"]
        uploader_role = user_row.get("role") or "student"

        if file:
            if not file.filename or not file.filename.strip():
                return jsonify({
                    "success": False,
                    "message": "No file selected"
                }), 400

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

            file_size = os.path.getsize(file_path)
            if file_size == 0:
                if os.path.exists(file_path):
                    os.remove(file_path)
                return jsonify({
                    "success": False,
                    "message": "Empty files are not allowed"
                }), 400

            if file_size > MAX_FILE_SIZE:
                if os.path.exists(file_path):
                    os.remove(file_path)
                return jsonify({
                    "success": False,
                    "message": "File size exceeds the 25MB limit"
                }), 400

            final_resource_url = f"/uploads/{saved_filename}"
        else:
            final_resource_url = youtube_url

        res_desc = description or (
            f"Uploaded study resource for {subject_name} "
            f"{'All Units' if unit_scope == 'all' else f'Unit {unit_num}'}"
        )

        cursor.execute(
            """
            INSERT INTO resources
                (title, resource_url, resource_type, subject_id, uploaded_by, unit_id, unit_scope, description)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                title,
                final_resource_url,
                resource_type,
                subject_id,
                uploaded_by,
                unit_id,
                unit_scope,
                res_desc
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
            "unit_label": "All Units" if unit_scope == "all" else f"Unit {unit_num}",
            "unit_scope": unit_scope,
            "type": resource_type,
            "filename": saved_filename,
            "resource_url": final_resource_url,
            "is_external": is_link_upload,
            "description": res_desc,
            "uploader_role": uploader_role,
            "avg_rating": None,
            "rating_count": 0
        }

        return jsonify({
            "success": True,
            "message": "Resource uploaded and registered successfully",
            "filename": saved_filename,
            "resource": created_resource
        }), 201

    except Exception:
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
            "message": "Unable to upload the resource. Please try again."
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


@resources_bp.route("/resources/<int:resource_id>/ratings", methods=["GET"])
def get_resource_ratings(resource_id):
    current_user_id = authenticated_user_id()

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("SELECT resource_id, title FROM resources WHERE resource_id = %s", (resource_id,))
        res = cursor.fetchone()
        if not res:
            return jsonify({"success": False, "message": "Resource not found"}), 404

        cursor.execute("""
            SELECT
                rt.rating_id,
                rt.rating,
                rt.review,
                rt.created_at,
                rt.user_id,
                u.name AS user_name,
                u.role AS user_role
            FROM ratings rt
            JOIN users u ON rt.user_id = u.user_id
            WHERE rt.resource_id = %s
            ORDER BY rt.created_at DESC
        """, (resource_id,))
        ratings = cursor.fetchall()

        for r in ratings:
            if r.get("created_at") and hasattr(r["created_at"], "isoformat"):
                r["created_at"] = r["created_at"].isoformat()

        cursor.execute("""
            SELECT
                ROUND(AVG(rating), 1) AS avg_rating,
                COUNT(rating_id) AS rating_count
            FROM ratings
            WHERE resource_id = %s
        """, (resource_id,))
        stats = cursor.fetchone() or {"avg_rating": None, "rating_count": 0}

        user_rating = None
        if current_user_id:
            for r in ratings:
                if r["user_id"] == current_user_id:
                    user_rating = {
                        "rating": r["rating"],
                        "review": r["review"],
                        "created_at": r["created_at"]
                    }
                    break

        return jsonify({
            "success": True,
            "resource_id": resource_id,
            "avg_rating": float(stats["avg_rating"]) if stats["avg_rating"] is not None else None,
            "rating_count": int(stats["rating_count"] or 0),
            "user_rating": user_rating,
            "ratings": ratings
        }), 200

    except Exception:
        current_app.logger.exception("Failed to fetch resource ratings")
        return jsonify({"success": False, "message": "Unable to load resource ratings."}), 500
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


@resources_bp.route("/resources/<int:resource_id>/ratings", methods=["POST"])
@require_auth
def submit_resource_rating(resource_id):
    data = request.get_json(silent=True) or request.form
    if not hasattr(data, "get"):
        return jsonify({"success": False, "message": "Invalid request payload."}), 400
    rating_raw = data.get("rating")
    review_raw = data.get("review") or ""
    if not isinstance(review_raw, str):
        return jsonify({"success": False, "message": "Review must be text."}), 400
    review = review_raw.strip()

    try:
        rating = int(rating_raw)
        if rating < 1 or rating > 5:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Rating must be an integer between 1 and 5."}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        if len(review) > 1000:
            return jsonify({"success": False, "message": "Review must be 1000 characters or fewer."}), 400

        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (g.user_id,))
        if not cursor.fetchone():
            return jsonify({"success": False, "message": "User not found."}), 401

        cursor.execute("SELECT resource_id FROM resources WHERE resource_id = %s", (resource_id,))
        if not cursor.fetchone():
            return jsonify({"success": False, "message": "Resource not found."}), 404

        cursor.execute("""
            INSERT INTO ratings (user_id, resource_id, rating, review)
            VALUES (%s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                rating = VALUES(rating),
                review = VALUES(review),
                created_at = CURRENT_TIMESTAMP
        """, (g.user_id, resource_id, rating, review or None))
        connection.commit()

        cursor.execute("""
            SELECT
                ROUND(AVG(rating), 1) AS avg_rating,
                COUNT(rating_id) AS rating_count
            FROM ratings
            WHERE resource_id = %s
        """, (resource_id,))
        stats = cursor.fetchone() or {"avg_rating": rating, "rating_count": 1}

        return jsonify({
            "success": True,
            "message": "Rating submitted successfully.",
            "avg_rating": float(stats["avg_rating"]) if stats["avg_rating"] is not None else rating,
            "rating_count": int(stats["rating_count"] or 1)
        }), 200

    except Exception:
        if connection:
            try:
                connection.rollback()
            except Exception:
                pass
        current_app.logger.exception("Rating submission failed")
        return jsonify({"success": False, "message": "Unable to submit the rating."}), 500
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
    filename = secure_filename(filename)
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    if not (os.path.isfile(file_path) and os.path.getsize(file_path) > 0):
        return jsonify({"success": False, "message": "File not found"}), 404
    return send_from_directory(UPLOAD_FOLDER, filename)


@resources_bp.route("/download/<filename>")
def download_uploaded_file(filename):
    filename = secure_filename(filename)
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    if not (os.path.isfile(file_path) and os.path.getsize(file_path) > 0):
        return jsonify({"success": False, "message": "File not found"}), 404
    return send_from_directory(UPLOAD_FOLDER, filename, as_attachment=True)
