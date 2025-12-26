import os
import psycopg2

def run_migration():
    db_url = os.environ.get("JARVIS_DB_CONN")
    if not db_url:
        print("Error: JARVIS_DB_CONN not set")
        return

    sql_file = r"f:\AION-ZERO\db\migrations.sql"
    try:
        with open(sql_file, "r") as f:
            sql = f.read()
        
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        conn.close()
        print("Migration applied successfully.")
    except Exception as e:
        print(f"Migration failed: {e}")

if __name__ == "__main__":
    run_migration()
