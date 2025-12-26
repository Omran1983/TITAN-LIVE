import csv, decimal, os
path = "scalp_trades.csv"
cap = decimal.Decimal(os.getenv("LOSS_CAP_USDT","-3"))   # stop if running P&L < -3 USDT
pnl = decimal.Decimal("0")
buys, sells = [], []
with open(path) as f:
    r = csv.DictReader(f)
    for row in r:
        if row["leg"]=="BUY" and row["status"] in ("FILLED","PARTIALLY_FILLED"):
            buys.append(decimal.Decimal(row["quoteQty"] or "0"))
        if row["leg"]=="SELL" and row["status"] in ("FILLED","PARTIALLY_FILLED"):
            sells.append(decimal.Decimal(row["quoteQty"] or "0"))
spent = sum(buys) if buys else decimal.Decimal("0")
realized = sum(sells) if sells else decimal.Decimal("0")
pnl = realized - spent
print({"spent": str(spent), "realized": str(realized), "pnl_usdt": str(pnl), "breach": pnl < cap})
