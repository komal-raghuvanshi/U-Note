import os
import mysql.connector
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))


def get_db_connection():
    is_vercel = bool(os.getenv("VERCEL"))
    host = os.getenv("UNOTE_DB_HOST")
    database = os.getenv("UNOTE_DB_NAME")
    use_aiven_ssl = bool(host and host.lower().endswith("aivencloud.com"))
    required_variables = [
        "UNOTE_DB_HOST",
        "UNOTE_DB_USER",
        "UNOTE_DB_NAME",
    ]
    if is_vercel:
        required_variables.extend(("UNOTE_DB_PORT", "UNOTE_DB_PASSWORD"))
    elif use_aiven_ssl:
        required_variables.append("UNOTE_DB_PASSWORD")
    missing_variables = [
        name for name in required_variables if not os.getenv(name)
    ]
    if missing_variables:
        raise RuntimeError(
            "Missing required database configuration: "
            + ", ".join(missing_variables)
        )

    if (
        (use_aiven_ssl or is_vercel)
        and database != "defaultdb"
    ):
        raise RuntimeError("Aiven database connections must use UNOTE_DB_NAME=defaultdb.")

    try:
        port = int(os.getenv("UNOTE_DB_PORT", "3306"))
    except ValueError as error:
        raise RuntimeError("UNOTE_DB_PORT must be a valid port number.") from error
    if not 1 <= port <= 65535:
        raise RuntimeError("UNOTE_DB_PORT must be a valid port number.")

    ssl_options = {}
    if use_aiven_ssl or is_vercel:
        ca_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ca.pem")
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
        port=port,
        user=os.getenv("UNOTE_DB_USER"),
        password=os.getenv("UNOTE_DB_PASSWORD"),
        database=database,
        **ssl_options
    )
