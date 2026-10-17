from flask import Blueprint, jsonify

subjects_bp = Blueprint("subjects", __name__)


@subjects_bp.route("/subjects", methods=["GET"])
def get_subjects():
    subjects = [
        {
            "id": 1,
            "name": "Artificial Intelligence",
            "semester": 4
        },
        {
            "id": 2,
            "name": "Machine Learning",
            "semester": 4
        },
        {
            "id": 3,
            "name": "Software Engineering",
            "semester": 4
        }
    ]

    return jsonify(subjects), 200