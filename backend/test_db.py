import sys
import traceback

from db import get_db_connection

print("Starting connection test...", flush=True)

try:
    conn = get_db_connection()
    print("CONNECTED SUCCESSFULLY!", flush=True)
    conn.close()

except BaseException:
    print("CONNECTION ERROR:", flush=True)
    traceback.print_exc()

finally:
    print("Test completed.", flush=True)

print("Python version:", sys.version, flush=True)