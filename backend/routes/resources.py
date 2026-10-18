
from flask import Blueprint

resources_bp = Blueprint("resources", __name__)


@resources_bp.route("/resources")
def get_resources():
    return {
        "message": "Resources route is working!",
        "resources": []
    }
