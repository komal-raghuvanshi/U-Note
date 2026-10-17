
from flask import Flask
from routes.home import home_bp
from routes.branches import branches_bp
from routes.subjects import subjects_bp

app = Flask(__name__)

app.register_blueprint(home_bp)
app.register_blueprint(branches_bp)
app.register_blueprint(subjects_bp)


if __name__ == "__main__":
    app.run(debug=True)
