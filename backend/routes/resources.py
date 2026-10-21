
import os
from uuid import uuid4
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename

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

resources_data = [
    {
        "id": 1,
        "title": "Python Notes",
        "branch": "AIML",
        "semester": 3,
        "subject": "Python",
        "unit": 1,
        "type": "PDF Notes"
    },
    {
        "id": 2,
        "title": "Machine Learning Notes",
        "branch": "AIML",
        "semester": 3,
        "subject": "Machine Learning",
        "unit": 2,
        "type": "Handwritten Notes"
    },
    {
        "id": 3,
        "title": "DBMS Notes",
        "branch": "CSE",
        "semester": 3,
        "subject": "DBMS",
        "unit": 1,
        "type": "PDF Notes"
    },
    {
        "id": 4,
        "title": "Python Unit 2 Notes",
        "branch": "AIML",
        "semester": 4,
        "subject": "Python",
        "unit": 2,
        "type": "Class Notes"
    }
]


@resources_bp.route("/resources")
def get_resources():
    branch = request.args.get("branch")
    semester = request.args.get("semester", type=int)
    subject = request.args.get("subject")
    unit = request.args.get("unit", type=int)
    search = request.args.get("search")
    resource_type = request.args.get("type")

    filtered_resources = []

    for resource in resources_data:
        if branch and resource["branch"].lower() != branch.lower():
            continue

        if semester is not None and resource["semester"] != semester:
            continue

        if subject and resource["subject"].lower() != subject.lower():
            continue

        if unit is not None and resource["unit"] != unit:
            continue

        if search and search.lower() not in resource["title"].lower():
            continue

        if resource_type and resource["type"].lower() != resource_type.lower():
            continue

        filtered_resources.append(resource)

    filtered_resources.sort(key=lambda resource: resource["title"].lower())

    return {
        "message": "Resources fetched successfully",
        "count": len(filtered_resources),
        "resources": filtered_resources
    }

@resources_bp.route("/resources/<int:resource_id>")
def get_resource_by_id(resource_id):
    for resource in resources_data:
        if resource["id"] == resource_id:
            return {
                "message": "Resource fetched successfully",
                "resource": resource
            }

    return {
        "message": "Resource not found"
    }, 404


@resources_bp.route("/resource-types")
def get_resource_types():
    resource_types = []

    for resource in resources_data:
        if resource["type"] not in resource_types:
            resource_types.append(resource["type"])

    return {
        "message": "Resource types fetched successfully",
        "resource_types": resource_types
    }

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

    # Generate a safe, unique filename
    original_name = secure_filename(file.filename)

    if not original_name:
        return jsonify({
            "success": False,
            "message": "Invalid filename"
        }), 400

    extension = original_name.rsplit(".", 1)[1].lower()
    saved_filename = f"{uuid4().hex}.{extension}"

    file_path = os.path.join(UPLOAD_FOLDER, saved_filename)

    try:
        file.save(file_path)

        if os.path.getsize(file_path) == 0:
            os.remove(file_path)
            return jsonify({
                "success": False,
                "message": "Empty files are not allowed"
            }), 400

    except OSError:
        current_app.logger.exception("File upload failed")
        return jsonify({
            "success": False,
            "message": "Unable to save uploaded file"
        }), 500

    return jsonify({
        "success": True,
        "message": "Resource uploaded successfully",
        "filename": saved_filename
    }), 201