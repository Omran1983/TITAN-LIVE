import os
from pathlib import Path
from scripts.env_loader import load_env

def main():
    load_env()
    final = Path("logs/trades.xlsx")
    pending = final.with_suffix(".pending.xlsx")
    if not pending.exists():
        print("No pending workbook to finalize.")
        return
    try:
        # If final exists, replace it atomically
        os.replace(pending, final)
        print(f"Finalized: {final}")
    except PermissionError:
        print("Still locked. Close Excel/preview/sync and try again.")

if __name__ == "__main__":
    main()
