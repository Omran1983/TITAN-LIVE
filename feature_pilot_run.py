import os
import psycopg2
from dotenv import load_dotenv
from titan_scanner import TitanScanner
from titan_brief_generator import run_brief_pipeline
from titan_decision import DecisionManager

load_dotenv()
DB_DSN = os.environ.get("JARVIS_DB_CONN")

if not DB_DSN:
    print("❌ Error: JARVIS_DB_CONN not found in environment.")
    exit(1)

def run_pilot():
    print("TITAN Executive Pilot: Initiating Sequence...")
    
    conn = psycopg2.connect(DB_DSN)
    cur = conn.cursor()
    
    print(" [1/5] Deploying Governance Layer (SQL)...")
    try:
        # DROP legacy table to force fresh schema from user v1 bundle
        cur.execute("DROP TABLE IF EXISTS az_decision_ledger CASCADE;")
        conn.commit()
        
        with open(r"f:\AION-ZERO\sql\20251219_init_decision_ledger.sql", "r") as f:
            sql = f.read()
            cur.execute(sql)
            conn.commit()
            print("   [OK] az_decision_ledger ready.")
    except Exception as e:
        print(f"   [WARN] Migration Warning: {e}")
        conn.rollback()

    # 2. Ensure Signal Source Exists (az_agent_runs)
    print(" [2/5] Verifying Signal Source (az_agent_runs)...")
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS az_agent_runs (
                id SERIAL PRIMARY KEY,
                agent_name VARCHAR(100),
                status VARCHAR(50),
                severity VARCHAR(50),
                started_at TIMESTAMP DEFAULT NOW(),
                finished_at TIMESTAMP DEFAULT NOW(),
                created_at TIMESTAMP DEFAULT NOW()
            );
        """)
        conn.commit()
        
        # Add constraint if missing (idempotent-ish check)
        # In a real migration we'd do this cleaner, but for pilot we just ensure it works.
        try:
             cur.execute("ALTER TABLE az_agent_runs ADD CONSTRAINT chk_az_agent_runs_status CHECK (status IN ('success', 'soft_fail', 'hard_fail'));")
             cur.execute("ALTER TABLE az_agent_runs ADD CONSTRAINT chk_az_agent_runs_severity CHECK (severity IN ('info', 'warning', 'error'));")
             conn.commit()
        except:
             conn.rollback() # Constraint likely exists

    except Exception as e:
        print(f"   [WARN] Signal Table Warning: {e}")
        conn.rollback()

    # 3. Seed Test Data
    print(" [3/5] Seeding Anomaly (Agent-Smith Failures)...")
    try:
        # Clear old test data
        cur.execute("DELETE FROM az_agent_runs WHERE agent_name = 'Agent-Smith' AND created_at > NOW() - INTERVAL '1 hour'")
        
        # Insert Failures
        for _ in range(15):
             cur.execute("INSERT INTO az_agent_runs (agent_name, status, severity, started_at, finished_at) VALUES ('Agent-Smith', 'hard_fail', 'error', NOW(), NOW())")
        # Insert Successes
        for _ in range(5):
             cur.execute("INSERT INTO az_agent_runs (agent_name, status, severity, started_at, finished_at) VALUES ('Agent-Smith', 'success', 'info', NOW(), NOW())")
        conn.commit()
        print("   [OK] Injected 20 runs for Agent-Smith (75% Failure Rate).")
    except Exception as e:
        print(f"   [FAIL] Seed Failed: {e}")
        conn.rollback()

    cur.close()
    conn.close()

    # 4. Run Scanner (The Eye)
    print(" [4/5] Running TitanScanner...")
    scanner = TitanScanner()
    signals = scanner.scan()
    print(f"   [OK] Detected {len(signals)} signals.")

    # 5. Generate Briefing (The Brain)
    print(" [5/5] Synthesizing Morning Briefing...")
    result = run_brief_pipeline(signals, llm_client=None, out_dir=".")
    
    print(f"\n[SUCCESS] Briefing generated at: {os.path.abspath(result['artifact_path'])}")
    
    # 6. Log to Decision Ledger (Governance)
    print(" [6/6] Logging Pending Decision to Ledger...")
    dm = DecisionManager()
    row = dm.create_decision(
        context={"generated_at": result["brief_json"].get("generated_at"), "signals": signals},
        options=result["brief_json"].get("options", []),
        decision={"status": "pending", "selected_option": None},
        user="omran"
    )
    print(f"   [OK] Decision logged with ID: {row.id}")

    # Read and print the content
    print("\n--- PREVIEW ---")
    with open(result['artifact_path'], "r", encoding="utf-8") as f:
        print(f.read())
    print("---------------\n")

if __name__ == "__main__":
    run_pilot()
