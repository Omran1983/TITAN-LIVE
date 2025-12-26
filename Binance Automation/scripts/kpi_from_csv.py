import csv, math
path = "trades_export.csv"
rows = []
with open(path) as f:
    r = csv.DictReader(f)
    for t in r:
        rows.append(t)
# naive pairwise PnL (BUY then SELL). For a bot, replace with your Excel logger.
pnls = []; side_seq = []
for t in rows:
    side_seq.append("BUY" if t.get("isBuyer") in ("True", True, "true") else "SELL")
# Just count trades
print({"total_trades": len(rows), "buy_count": side_seq.count("BUY"), "sell_count": side_seq.count("SELL")})
