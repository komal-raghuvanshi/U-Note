import os
import mysql.connector
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))


def get_db_connection():
    ca_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ca.pem")
    host = os.getenv("UNOTE_DB_HOST")
    use_aiven_ssl = bool(host and host.lower().endswith("aivencloud.com"))
    ssl_options = {}
    if use_aiven_ssl or os.getenv("VERCEL"):
        if not os.path.isfile(ca_path):
            raise FileNotFoundError(
                f"Aiven CA certificate is required for SSL database connections: {ca_path}"
            )
        ssl_options = {
            "ssl_ca": ca_path,
            "ssl_verify_cert": True,
            "ssl_verify_identity": True,
        }

    return mysql.connector.connect(
        host=host,
        port=int(os.getenv("UNOTE_DB_PORT", "3306")),
        user=os.getenv("UNOTE_DB_USER"),
        password=os.getenv("UNOTE_DB_PASSWORD"),
        database=os.getenv("UNOTE_DB_NAME"),
        **ssl_options
    )
