
from flask import Flask
from routes.home import home_bp
from routes.branches import branches_bp
from routes.subjects import subjects_bp
from routes.resources import resources_bp
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

app.register_blueprint(home_bp)
app.register_blueprint(branches_bp)
app.register_blueprint(subjects_bp)
app.register_blueprint(resources_bp)


if __name__ == "__main__":
    app.run(debug=True)
