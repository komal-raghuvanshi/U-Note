"""
U-NOTE Admin Promotion Utility
Promote or demote a user account to/from 'admin' role.
Usage:
    python backend/promote_admin.py <email> [--demote]
"""
import sys
import os

if len(sys.argv) < 2:
    print("Usage: python backend/promote_admin.py <email> [--demote]")
    sys.exit(1)

email = sys.argv[1].strip().lower()
demote = "--demote" in sys.argv
new_role = "student" if demote else "admin"

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db import get_db_connection

conn = None
cursor = None
try:
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT user_id, name, email, role FROM users WHERE LOWER(email) = %s", (email,))
    user = cursor.fetchone()
    if not user:
        print(f"Error: User with email '{email}' not found.")
        sys.exit(1)

    cursor.execute("UPDATE users SET role = %s WHERE user_id = %s", (new_role, user["user_id"]))
    conn.commit()
    action = "demoted to 'student'" if demote else "promoted to 'admin'"
    print(f"Success: User '{user['name']}' ({user['email']}) has been {action}.")
finally:
    if cursor:
        cursor.close()
    if conn:
        conn.close()
