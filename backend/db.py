import os

import mysql.connector


def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("UNOTE_DB_HOST", "localhost"),
        port=int(os.getenv("UNOTE_DB_PORT", "3306")),
        user=os.getenv("UNOTE_DB_USER", "root"),
        password=os.getenv("UNOTE_DB_PASSWORD", ""),
        database=os.getenv("UNOTE_DB_NAME", "u_note"),
    )
