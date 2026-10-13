
from flask import Blueprint

branches_bp = Blueprint("branches", __name__)


@branches_bp.route("/branches")
def get_branches():
    return {
        "message": "Branches route is working!",
        "branches": []
    }
