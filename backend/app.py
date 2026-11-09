import os
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))
from flask import Flask
from routes.home import home_bp
from routes.branches import branches_bp
from routes.subjects import subjects_bp
from routes.resources import resources_bp
from routes.requests import requests_bp
from flask_cors import CORS
from routes.auth import auth_bp
from routes.contact import contact_bp
from routes.notifications import notifications_bp
from routes.admin import admin_bp
from routes.reports import reports_bp

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("UNOTE_SECRET_KEY")
app.config["MAX_CONTENT_LENGTH"] = (
    4_500_000 if os.getenv("VERCEL") else 26 * 1024 * 1024
)
allowed_origins = os.getenv(
    "UNOTE_CORS_ORIGINS",
    "http://localhost:5173,http://127.0.0.1:5173"
)
CORS(app, origins=[origin.strip() for origin in allowed_origins.split(",") if origin.strip()])

app.register_blueprint(home_bp)
app.register_blueprint(branches_bp)
app.register_blueprint(subjects_bp)
app.register_blueprint(resources_bp)
app.register_blueprint(requests_bp)
app.register_blueprint(auth_bp)
app.register_blueprint(contact_bp)
app.register_blueprint(notifications_bp)
app.register_blueprint(admin_bp)
app.register_blueprint(reports_bp)


if __name__ == "__main__":
    app.run(debug=os.getenv("FLASK_DEBUG") == "1")
