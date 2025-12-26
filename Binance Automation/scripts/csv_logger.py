from pathlib import Path
import csv
from datetime import datetime

CSV_PATH = Path("logs/trades.csv")
CSV_HEADERS = ["DateUTC","DateLocal","Env","Symbol","Side","OrderType","OrderId","ClientOrderId",
               "OrigQty","FilledQty","AvgFillPrice","Fee","FeeAsset","Status","Price",
               "StopPrice","TimeInForce","IsMaker"]

def log_to_csv(row: list):
    CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    write_header = not CSV_PATH.exists()
    with CSV_PATH.open("a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if write_header:
            w.writerow(CSV_HEADERS)
        w.writerow(row)
