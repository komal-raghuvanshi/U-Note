from flask import Blueprint, current_app, jsonify, request

try:
    from db import get_db_connection, table_exists
except ImportError:
    from backend.db import get_db_connection, table_exists


BRANCH_ALIASES = {
    'electronics and communication engineering': 'EC',
    'electronics and communication': 'EC',
    'electronics & communication engineering': 'EC',
    'mechanical engineering': 'ME',
    'computer science engineering': 'CSE',
    'computer science and engineering': 'CSE',
    'information technology': 'IT',
    'artificial intelligence and machine learning': 'AIML',
    'data science': 'DS',
    'civil engineering': 'Civil',
}

def resolve_branch_name(branch_name):
    if not branch_name:
        return branch_name
    normalized = branch_name.strip().lower()
    return BRANCH_ALIASES.get(normalized, branch_name.strip())

subjects_bp = Blueprint("subjects", __name__)


def _semester_number(value):
    try:
        number = int(str(value).replace("Semester", "").strip())
    except (TypeError, ValueError):
        return None
    return number if 1 <= number <= 8 else None


@subjects_bp.route("/subjects", methods=["GET"])
def get_subjects():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        has_meta = table_exists(cursor, "subject_catalogue_metadata")

        if has_meta:
            query = """
                SELECT
                    s.subject_id AS id,
                    COALESCE(meta.catalogue_code, s.subject_code) AS code,
                    s.subject_name AS name,
                    b.branch_name AS branch,
                    sem.semester_name AS semester,
                    meta.subject_category AS category,
                    meta.elective_group,
                    COALESCE(meta.is_selectable, 1) AS is_selectable,
                    COALESCE(meta.is_provisional, 0) AS is_provisional
                FROM subjects s
                JOIN semesters sem ON s.semester_id = sem.semester_id
                JOIN branches b ON sem.branch_id = b.branch_id
                LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
            """
        else:
            query = """
                SELECT
                    s.subject_id AS id,
                    s.subject_code AS code,
                    s.subject_name AS name,
                    b.branch_name AS branch,
                    sem.semester_name AS semester,
                    NULL AS category,
                    NULL AS elective_group,
                    1 AS is_selectable,
                    0 AS is_provisional
                FROM subjects s
                JOIN semesters sem ON s.semester_id = sem.semester_id
                JOIN branches b ON sem.branch_id = b.branch_id
            """

        conditions = []
        values = []
        branch = resolve_branch_name(request.args.get("branch"))
        semester = request.args.get("semester")

        if branch:
            conditions.append("LOWER(b.branch_name) = LOWER(%s)")
            values.append(branch.strip())
        if semester:
            sem_number = _semester_number(semester)
            if sem_number is None:
                return jsonify({
                    "error": "Semester must be between 1 and 8",
                    "message": "Semester must be between 1 and 8"
                }), 400
            conditions.append("sem.semester_name = %s")
            values.append(f"Semester {sem_number}")
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        query += " ORDER BY s.subject_name ASC"

        cursor.execute(query, values)
        return jsonify(cursor.fetchall()), 200
    except Exception:
        current_app.logger.exception("Failed to fetch subjects")
        return jsonify({
            "error": "Unable to fetch subjects from the database.",
            "message": "Unable to fetch subjects from the database."
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@subjects_bp.route("/subjects/<int:subject_id>", methods=["GET"])
def get_subject_by_id(subject_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        has_meta = table_exists(cursor, "subject_catalogue_metadata")

        if has_meta:
            cursor.execute("""
                SELECT
                    s.subject_id AS id,
                    COALESCE(meta.catalogue_code, s.subject_code) AS code,
                    s.subject_name AS name,
                    b.branch_name AS branch,
                    sem.semester_name AS semester,
                    meta.subject_category AS category,
                    meta.elective_group,
                    COALESCE(meta.is_selectable, 1) AS is_selectable,
                    COALESCE(meta.is_provisional, 0) AS is_provisional
                FROM subjects s
                JOIN semesters sem ON s.semester_id = sem.semester_id
                JOIN branches b ON sem.branch_id = b.branch_id
                LEFT JOIN subject_catalogue_metadata meta ON meta.subject_id = s.subject_id
                WHERE s.subject_id = %s
            """, (subject_id,))
        else:
            cursor.execute("""
                SELECT
                    s.subject_id AS id,
                    s.subject_code AS code,
                    s.subject_name AS name,
                    b.branch_name AS branch,
                    sem.semester_name AS semester,
                    NULL AS category,
                    NULL AS elective_group,
                    1 AS is_selectable,
                    0 AS is_provisional
                FROM subjects s
                JOIN semesters sem ON s.semester_id = sem.semester_id
                JOIN branches b ON sem.branch_id = b.branch_id
                WHERE s.subject_id = %s
            """, (subject_id,))

        subject = cursor.fetchone()
        if not subject:
            return jsonify({
                "error": "Subject not found",
                "message": "Subject not found"
            }), 404

        cursor.execute("""
            SELECT unit_id AS id, unit_number, unit_name AS name
            FROM units
            WHERE subject_id = %s
            ORDER BY unit_number ASC
        """, (subject_id,))
        subject["units"] = cursor.fetchall()
        return jsonify(subject), 200
    except Exception:
        current_app.logger.exception("Failed to fetch subject details")
        return jsonify({
            "error": "Unable to fetch subject details.",
            "message": "Unable to fetch subject details."
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@subjects_bp.route("/units", methods=["GET"])
def get_units():
    subject_id_raw = request.args.get("subject_id")
    subject_name = request.args.get("subject")
    branch = resolve_branch_name(request.args.get("branch"))
    semester = request.args.get("semester")

    subject_id = None
    if subject_id_raw:
        try:
            subject_id = int(subject_id_raw)
            if subject_id < 1:
                raise ValueError
        except ValueError:
            return jsonify({
                "error": "Subject ID must be a positive number",
                "message": "Subject ID must be a positive number"
            }), 400

    sem_number = None
    if semester:
        sem_number = _semester_number(semester)
        if sem_number is None:
            return jsonify({
                "error": "Semester must be between 1 and 8",
                "message": "Semester must be between 1 and 8"
            }), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        query = """
            SELECT
                u.unit_id AS id,
                u.unit_number,
                u.unit_name AS name,
                s.subject_id,
                s.subject_name,
                s.subject_code
            FROM units u
            JOIN subjects s ON u.subject_id = s.subject_id
            JOIN semesters sem ON s.semester_id = sem.semester_id
            JOIN branches b ON sem.branch_id = b.branch_id
        """
        conditions = []
        values = []
        if subject_id:
            conditions.append("s.subject_id = %s")
            values.append(subject_id)
        elif subject_name:
            conditions.append("(LOWER(s.subject_name) = LOWER(%s) OR LOWER(s.subject_code) = LOWER(%s))")
            values.extend([subject_name.strip(), subject_name.strip()])
        if branch:
            conditions.append("LOWER(b.branch_name) = LOWER(%s)")
            values.append(branch.strip())
        if sem_number:
            conditions.append("sem.semester_name = %s")
            values.append(f"Semester {sem_number}")
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        query += " ORDER BY u.unit_number ASC"

        cursor.execute(query, values)
        return jsonify(cursor.fetchall()), 200
    except Exception:
        current_app.logger.exception("Failed to fetch units")
        return jsonify({
            "error": "Unable to fetch units from the database.",
            "message": "Unable to fetch units from the database."
        }), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
