import csv, os, datetime as dt

FIELDS = [
 "Date","TimeUTC","Symbol","Session","Bias","Setup",
 "Entry","Stop","TP","Size","ATR14","Fees","Slip",
 "Outcome","Exit","PnL","R","MAE","MFE","Notes"
]

def log_trade(path, row):
    exists = os.path.isfile(path)
    with open(path, "a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        if not exists: w.writeheader()
        w.writerow(row)

def make_row(now, **k):
    return {
      "Date": now.strftime("%Y-%m-%d"),
      "TimeUTC": now.strftime("%H:%M"),
      **k
    }
