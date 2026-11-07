import os
from datetime import datetime
from flask import Blueprint, current_app, g, jsonify, request

try:
    from auth_utils import require_admin
    from db import get_db_connection, table_exists, column_exists
    from notifications_service import create_notification
except ImportError:
    from backend.auth_utils import require_admin
    from backend.db import get_db_connection, table_exists, column_exists
    from backend.notifications_service import create_notification

admin_bp = Blueprint("admin", __name__)


@admin_bp.route("/admin/stats", methods=["GET"])
@require_admin
def get_admin_stats():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # Total users
        cursor.execute("SELECT COUNT(*) AS total FROM users")
        total_users = cursor.fetchone()["total"]

        # Total resources
        cursor.execute("SELECT COUNT(*) AS total FROM resources")
        total_resources = cursor.fetchone()["total"]

        # Pending resource approvals
        pending_approvals = 0
        if column_exists(cursor, "resources", "approval_status"):
            cursor.execute("SELECT COUNT(*) AS total FROM resources WHERE approval_status = 'pending'")
            pending_approvals = cursor.fetchone()["total"]

        # Total resource requests
        total_requests = 0
        if table_exists(cursor, "requests"):
            cursor.execute("SELECT COUNT(*) AS total FROM requests")
            total_requests = cursor.fetchone()["total"]

        # Pending reports
        pending_reports = 0
        if table_exists(cursor, "resource_reports"):
            cursor.execute("SELECT COUNT(*) AS total FROM resource_reports WHERE status = 'pending'")
            pending_reports = cursor.fetchone()["total"]

        # Recent activities (recent uploads, reports, requests)
        activities = []
        cursor.execute("""
            SELECT r.resource_id AS id, r.title, r.created_at, u.name AS user_name, 'resource_upload' AS type
            FROM resources r
            LEFT JOIN users u ON r.uploaded_by = u.user_id
            ORDER BY r.created_at DESC
            LIMIT 5
        """)
        for row in cursor.fetchall():
            if row.get("created_at") and hasattr(row["created_at"], "isoformat"):
                row["created_at"] = row["created_at"].isoformat()
            row["text"] = f"{row.get('user_name') or 'User'} uploaded '{row['title']}'"
            activities.append(row)

        if table_exists(cursor, "resource_reports"):
            cursor.execute("""
                SELECT rep.report_id AS id, rep.reason, rep.created_at, u.name AS user_name, 'report' AS type
                FROM resource_reports rep
                LEFT JOIN users u ON rep.user_id = u.user_id
                ORDER BY rep.created_at DESC
                LIMIT 5
            """)
            for row in cursor.fetchall():
                if row.get("created_at") and hasattr(row["created_at"], "isoformat"):
                    row["created_at"] = row["created_at"].isoformat()
                row["text"] = f"{row.get('user_name') or 'User'} reported a resource: {row['reason']}"
                activities.append(row)

        activities.sort(key=lambda x: str(x.get("created_at") or ""), reverse=True)

        return jsonify({
            "success": True,
            "stats": {
                "total_users": total_users,
                "total_resources": total_resources,
                "pending_approvals": pending_approvals,
                "total_requests": total_requests,
                "pending_reports": pending_reports
            },
            "recent_activities": activities[:8]
        }), 200
    except Exception:
        current_app.logger.exception("Failed to load admin stats")
        return jsonify({"success": False, "message": "Unable to load dashboard stats."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/users", methods=["GET"])
@require_admin
def get_admin_users():
    search = (request.args.get("search") or "").strip()
    role_filter = (request.args.get("role") or "").strip()

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        has_blocked = column_exists(cursor, "users", "is_blocked")
        blocked_col = "u.is_blocked" if has_blocked else "0 AS is_blocked"

        query = f"""
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.role,
                u.is_verified,
                {blocked_col},
                b.branch_name AS branch,
                s.semester_name AS semester,
                COALESCE(res_count.total, 0) AS uploads_count
            FROM users u
            LEFT JOIN branches b ON u.branch_id = b.branch_id
            LEFT JOIN semesters s ON u.semester_id = s.semester_id
            LEFT JOIN (
                SELECT uploaded_by, COUNT(*) AS total
                FROM resources
                GROUP BY uploaded_by
            ) res_count ON u.user_id = res_count.uploaded_by
            WHERE 1=1
        """
        params = []
        if search:
            query += " AND (LOWER(u.name) LIKE LOWER(%s) OR LOWER(u.email) LIKE LOWER(%s))"
            params.extend([f"%{search}%", f"%{search}%"])
        if role_filter:
            query += " AND u.role = %s"
            params.append(role_filter)

        query += " ORDER BY u.user_id DESC"
        cursor.execute(query, params)
        users = cursor.fetchall()
        for u in users:
            u["is_blocked"] = bool(u.get("is_blocked", 0))
            u["is_verified"] = bool(u.get("is_verified", 1))

        return jsonify({"success": True, "count": len(users), "users": users}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch admin users")
        return jsonify({"success": False, "message": "Unable to load user accounts."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/users/<int:target_user_id>/block", methods=["PUT"])
@require_admin
def toggle_user_block(target_user_id):
    if target_user_id == g.user_id:
        return jsonify({"success": False, "message": "You cannot block your own admin account."}), 400

    data = request.get_json(silent=True) or {}
    block_state = data.get("is_blocked")

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT user_id, name, is_blocked, role FROM users WHERE user_id = %s", (target_user_id,))
        target_user = cursor.fetchone()
        if not target_user:
            return jsonify({"success": False, "message": "User not found."}), 404

        if block_state is None:
            new_blocked = 0 if target_user.get("is_blocked") else 1
        else:
            new_blocked = 1 if block_state else 0

        cursor.execute("UPDATE users SET is_blocked = %s WHERE user_id = %s", (new_blocked, target_user_id))
        conn.commit()

        action_msg = "blocked" if new_blocked else "unblocked"
        return jsonify({
            "success": True,
            "is_blocked": bool(new_blocked),
            "message": f"User '{target_user['name']}' has been {action_msg}."
        }), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to update user block status")
        return jsonify({"success": False, "message": "Unable to update user status."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/users/<int:target_user_id>/role", methods=["PUT"])
@require_admin
def update_user_role(target_user_id):
    data = request.get_json(silent=True) or {}
    new_role = (data.get("role") or "").strip().lower()

    if new_role not in ("student", "teacher", "admin"):
        return jsonify({"success": False, "message": "Role must be 'student', 'teacher', or 'admin'."}), 400

    if target_user_id == g.user_id and new_role != "admin":
        return jsonify({"success": False, "message": "You cannot demote yourself from admin role."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT user_id, name FROM users WHERE user_id = %s", (target_user_id,))
        target = cursor.fetchone()
        if not target:
            return jsonify({"success": False, "message": "User not found."}), 404

        cursor.execute("UPDATE users SET role = %s WHERE user_id = %s", (new_role, target_user_id))
        conn.commit()

        return jsonify({
            "success": True,
            "role": new_role,
            "message": f"Role for '{target['name']}' changed to {new_role}."
        }), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to update user role")
        return jsonify({"success": False, "message": "Unable to update role."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/resources", methods=["GET"])
@require_admin
def get_admin_resources():
    status_filter = (request.args.get("status") or "").strip()
    search = (request.args.get("search") or "").strip()

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        has_approval = column_exists(cursor, "resources", "approval_status")
        has_verified = column_exists(cursor, "resources", "is_verified")
        has_downloads = column_exists(cursor, "resources", "download_count")

        approval_col = "r.approval_status" if has_approval else "'approved' AS approval_status"
        verified_col = "r.is_verified" if has_verified else "0 AS is_verified"
        downloads_col = "r.download_count" if has_downloads else "0 AS download_count"

        query = f"""
            SELECT
                r.resource_id AS id,
                r.title,
                r.resource_url,
                r.resource_type AS type,
                {approval_col},
                {verified_col},
                {downloads_col},
                r.created_at AS uploaded_at,
                r.uploaded_by,
                u.name AS uploader_name,
                u.email AS uploader_email,
                b.branch_name AS branch,
                sem.semester_name AS semester,
                s.subject_name AS subject,
                COALESCE(rating_stats.avg_rating, NULL) AS avg_rating,
                COALESCE(rating_stats.rating_count, 0) AS rating_count,
                COALESCE(reports_count.total, 0) AS pending_reports
            FROM resources r
            LEFT JOIN users u ON r.uploaded_by = u.user_id
            LEFT JOIN subjects s ON r.subject_id = s.subject_id
            LEFT JOIN semesters sem ON s.semester_id = sem.semester_id
            LEFT JOIN branches b ON sem.branch_id = b.branch_id
            LEFT JOIN (
                SELECT resource_id, ROUND(AVG(rating), 1) AS avg_rating, COUNT(rating_id) AS rating_count
                FROM ratings
                GROUP BY resource_id
            ) rating_stats ON r.resource_id = rating_stats.resource_id
            LEFT JOIN (
                SELECT resource_id, COUNT(*) AS total
                FROM resource_reports
                WHERE status = 'pending'
                GROUP BY resource_id
            ) reports_count ON r.resource_id = reports_count.resource_id
            WHERE 1=1
        """
        params = []
        if status_filter:
            if has_approval:
                query += " AND r.approval_status = %s"
                params.append(status_filter)
        if search:
            query += " AND (LOWER(r.title) LIKE LOWER(%s) OR LOWER(s.subject_name) LIKE LOWER(%s))"
            params.extend([f"%{search}%", f"%{search}%"])

        query += " ORDER BY r.resource_id DESC"
        cursor.execute(query, params)
        resources = cursor.fetchall()

        for r in resources:
            r["is_verified"] = bool(r.get("is_verified", 0))
            if r.get("uploaded_at") and hasattr(r["uploaded_at"], "isoformat"):
                r["uploaded_at"] = r["uploaded_at"].isoformat()
            if r.get("avg_rating") is not None:
                r["avg_rating"] = float(r["avg_rating"])

        return jsonify({"success": True, "count": len(resources), "resources": resources}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch admin resources")
        return jsonify({"success": False, "message": "Unable to load resources."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/resources/<int:resource_id>/approval", methods=["PUT"])
@require_admin
def update_resource_approval(resource_id):
    data = request.get_json(silent=True) or {}
    new_status = (data.get("status") or data.get("approval_status") or "").strip().lower()

    if new_status not in ("approved", "rejected", "pending"):
        return jsonify({"success": False, "message": "Status must be 'approved', 'rejected', or 'pending'."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT resource_id, title, uploaded_by FROM resources WHERE resource_id = %s", (resource_id,))
        res = cursor.fetchone()
        if not res:
            return jsonify({"success": False, "message": "Resource not found."}), 404

        if column_exists(cursor, "resources", "approval_status"):
            cursor.execute("UPDATE resources SET approval_status = %s WHERE resource_id = %s", (new_status, resource_id))
            conn.commit()

        # Notify the resource uploader
        if res.get("uploaded_by"):
            msg_title = "Resource Approved" if new_status == "approved" else "Resource Status Updated"
            msg_body = f"Your study resource '{res['title']}' was marked as {new_status} by moderators."
            create_notification(cursor, res["uploaded_by"], msg_title, msg_body, f"resource_{new_status}", resource_id)
            conn.commit()

        return jsonify({
            "success": True,
            "approval_status": new_status,
            "message": f"Resource status updated to {new_status}."
        }), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to update resource approval")
        return jsonify({"success": False, "message": "Unable to update resource approval."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/resources/<int:resource_id>/verify", methods=["PUT"])
@require_admin
def toggle_resource_verification(resource_id):
    data = request.get_json(silent=True) or {}
    verify_val = data.get("is_verified")

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT resource_id, title, uploaded_by, is_verified FROM resources WHERE resource_id = %s", (resource_id,))
        res = cursor.fetchone()
        if not res:
            return jsonify({"success": False, "message": "Resource not found."}), 404

        if verify_val is None:
            new_verified = 0 if res.get("is_verified") else 1
        else:
            new_verified = 1 if verify_val else 0

        cursor.execute("UPDATE resources SET is_verified = %s WHERE resource_id = %s", (new_verified, resource_id))
        conn.commit()

        # Notify uploader if newly verified
        if new_verified and res.get("uploaded_by"):
            create_notification(
                cursor,
                res["uploaded_by"],
                "Resource Verified! ★",
                f"Your study resource '{res['title']}' has been officially verified by U-NOTE moderators.",
                "resource_verified",
                resource_id
            )
            conn.commit()

        return jsonify({
            "success": True,
            "is_verified": bool(new_verified),
            "message": f"Resource {'verified' if new_verified else 'unverified'} successfully."
        }), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to update verification status")
        return jsonify({"success": False, "message": "Unable to update verification status."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/resources/<int:resource_id>", methods=["DELETE"])
@require_admin
def admin_delete_resource(resource_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT resource_id, title, resource_url, uploaded_by FROM resources WHERE resource_id = %s", (resource_id,))
        res = cursor.fetchone()
        if not res:
            return jsonify({"success": False, "message": "Resource not found."}), 404

        # Clean up related records
        if table_exists(cursor, "ratings"):
            cursor.execute("DELETE FROM ratings WHERE resource_id = %s", (resource_id,))
        if table_exists(cursor, "saved_resources"):
            cursor.execute("DELETE FROM saved_resources WHERE resource_id = %s", (resource_id,))
        if table_exists(cursor, "resource_reports"):
            cursor.execute("DELETE FROM resource_reports WHERE resource_id = %s", (resource_id,))
        if table_exists(cursor, "resource_files"):
            cursor.execute("DELETE FROM resource_files WHERE resource_id = %s", (resource_id,))

        cursor.execute("DELETE FROM resources WHERE resource_id = %s", (resource_id,))
        conn.commit()

        if res.get("uploaded_by") and res["uploaded_by"] != g.user_id:
            create_notification(
                cursor,
                res["uploaded_by"],
                "Resource Removed",
                f"Your resource '{res['title']}' was removed by an administrator.",
                "resource_removed"
            )
            conn.commit()

        return jsonify({"success": True, "message": f"Resource '{res['title']}' has been removed."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to delete resource")
        return jsonify({"success": False, "message": "Unable to delete resource."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/reports", methods=["GET"])
@require_admin
def get_admin_reports():
    status_filter = (request.args.get("status") or "").strip()

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "resource_reports"):
            return jsonify({"success": True, "reports": []}), 200

        query = """
            SELECT
                rep.report_id,
                rep.resource_id,
                rep.user_id,
                rep.reason,
                rep.details,
                rep.status,
                rep.admin_notes,
                rep.created_at,
                rep.resolved_at,
                r.title AS resource_title,
                u.name AS reporter_name,
                u.email AS reporter_email
            FROM resource_reports rep
            LEFT JOIN resources r ON rep.resource_id = r.resource_id
            LEFT JOIN users u ON rep.user_id = u.user_id
            WHERE 1=1
        """
        params = []
        if status_filter:
            query += " AND rep.status = %s"
            params.append(status_filter)

        query += " ORDER BY rep.report_id DESC"
        cursor.execute(query, params)
        reports = cursor.fetchall()

        for r in reports:
            if r.get("created_at") and hasattr(r["created_at"], "isoformat"):
                r["created_at"] = r["created_at"].isoformat()
            if r.get("resolved_at") and hasattr(r["resolved_at"], "isoformat"):
                r["resolved_at"] = r["resolved_at"].isoformat()

        return jsonify({"success": True, "count": len(reports), "reports": reports}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch reports")
        return jsonify({"success": False, "message": "Unable to load resource reports."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/reports/<int:report_id>", methods=["PUT"])
@require_admin
def update_report(report_id):
    data = request.get_json(silent=True) or {}
    new_status = (data.get("status") or data.get("approval_status") or "").strip().lower()
    admin_notes = (data.get("admin_notes") or "").strip()

    if new_status not in ("resolved", "rejected", "pending"):
        return jsonify({"success": False, "message": "Status must be 'resolved', 'rejected', or 'pending'."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "resource_reports"):
            return jsonify({"success": False, "message": "Reports service not available."}), 503

        cursor.execute("""
            SELECT rep.*, r.title AS resource_title
            FROM resource_reports rep
            LEFT JOIN resources r ON rep.resource_id = r.resource_id
            WHERE rep.report_id = %s
        """, (report_id,))
        report = cursor.fetchone()
        if not report:
            return jsonify({"success": False, "message": "Report not found."}), 404

        cursor.execute(
            """
            UPDATE resource_reports
            SET status = %s, admin_notes = %s, resolved_at = %s, resolved_by = %s
            WHERE report_id = %s
            """,
            (
                new_status,
                admin_notes or None,
                datetime.utcnow() if new_status != "pending" else None,
                g.user_id if new_status != "pending" else None,
                report_id
            )
        )
        conn.commit()

        # Notify the reporter
        if report.get("user_id"):
            create_notification(
                cursor,
                report["user_id"],
                "Report Update",
                f"Your report regarding '{report.get('resource_title') or 'resource'}' has been reviewed and marked as {new_status}.",
                "report_update",
                report.get("resource_id")
            )
            conn.commit()

        return jsonify({
            "success": True,
            "status": new_status,
            "message": f"Report marked as {new_status}."
        }), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to update report")
        return jsonify({"success": False, "message": "Unable to update report."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/requests", methods=["GET"])
@require_admin
def get_admin_requests():
    status_filter = (request.args.get("status") or "").strip()

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        if not table_exists(cursor, "requests"):
            return jsonify({"success": True, "requests": []}), 200

        query = """
            SELECT
                req.request_id,
                COALESCE(req.request_title, s.subject_name) AS title,
                req.request_description AS description,
                req.status,
                req.created_at,
                req.user_id,
                u.name AS requester_name,
                u.email AS requester_email,
                b.branch_name AS branch,
                sem.semester_name AS semester,
                s.subject_name AS subject
            FROM requests req
            LEFT JOIN users u ON req.user_id = u.user_id
            LEFT JOIN subjects s ON req.subject_id = s.subject_id
            LEFT JOIN semesters sem ON s.semester_id = sem.semester_id
            LEFT JOIN branches b ON sem.branch_id = b.branch_id
            WHERE 1=1
        """
        params = []
        if status_filter:
            query += " AND req.status = %s"
            params.append(status_filter)

        query += " ORDER BY req.request_id DESC"
        cursor.execute(query, params)
        requests_list = cursor.fetchall()

        for req in requests_list:
            if req.get("created_at") and hasattr(req["created_at"], "isoformat"):
                req["created_at"] = req["created_at"].isoformat()

        return jsonify({"success": True, "count": len(requests_list), "requests": requests_list}), 200
    except Exception:
        current_app.logger.exception("Failed to fetch admin requests")
        return jsonify({"success": False, "message": "Unable to load requests."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass


@admin_bp.route("/admin/requests/<int:request_id>", methods=["PUT"])
@require_admin
def update_admin_request(request_id):
    data = request.get_json(silent=True) or {}
    new_status = (data.get("status") or "").strip()

    allowed = {"Pending", "In Progress", "Fulfilled", "Closed"}
    if new_status not in allowed:
        return jsonify({"success": False, "message": f"Status must be one of: {', '.join(sorted(allowed))}."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT req.*, COALESCE(req.request_title, s.subject_name) AS title
            FROM requests req
            LEFT JOIN subjects s ON req.subject_id = s.subject_id
            WHERE req.request_id = %s
        """, (request_id,))
        req = cursor.fetchone()
        if not req:
            return jsonify({"success": False, "message": "Request not found."}), 404

        cursor.execute("UPDATE requests SET status = %s WHERE request_id = %s", (new_status, request_id))
        conn.commit()

        # Notify student who requested it
        if req.get("user_id"):
            create_notification(
                cursor,
                req["user_id"],
                "Request Status Updated",
                f"Your request for '{req['title']}' is now {new_status}.",
                "request_status"
            )
            conn.commit()

        return jsonify({"success": True, "status": new_status, "message": f"Request status updated to {new_status}."}), 200
    except Exception:
        if conn:
            try: conn.rollback()
            except Exception: pass
        current_app.logger.exception("Failed to update request")
        return jsonify({"success": False, "message": "Unable to update request status."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception: pass
        if conn:
            try: conn.close()
            except Exception: pass
