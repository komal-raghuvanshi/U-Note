
from flask import Blueprint, request

resources_bp = Blueprint("resources", __name__)

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

