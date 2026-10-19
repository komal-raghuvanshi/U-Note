from flask import Blueprint, jsonify, request

subjects_bp = Blueprint("subjects", __name__)


@subjects_bp.route("/subjects", methods=["GET"])
def get_subjects():
    subjects = [
        {
            "id": 1,
            "name": "Artificial Intelligence",
            "branch": "AIML",
            "semester": 4
        },
        {
            "id": 2,
            "name": "Machine Learning",
            "branch": "AIML",
            "semester": 4
        },
        {
            "id": 3,
            "name": "Software Engineering",
            "branch": "AIML",
            "semester": 4
        },
        {
            "id": 4,
            "name": "Data Structures",
            "branch": "CSE",
            "semester": 3
        },
        {
            "id": 5,
            "name": "Database Management System",
            "branch": "CSE",
            "semester": 3
        },
        {
            "id": 6,
            "name": "Computer Networks",
            "branch": "CSE",
            "semester": 4
        }
    ]

    branch = request.args.get("branch")
    semester = request.args.get("semester")

    if branch:
        subjects = [
            subject for subject in subjects
            if subject["branch"].lower() == branch.lower()
        ]

    if semester:
        try:
            semester = int(semester)
        except ValueError:
            return jsonify({
                "error": "Semester must be a valid number"
            }), 400

        subjects = [
            subject for subject in subjects
            if subject["semester"] == semester
        ]

    return jsonify(subjects), 200