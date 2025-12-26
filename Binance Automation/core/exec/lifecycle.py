def on_fill(trade, current_price_fetcher):
    # trade: dict with keys entry, stop, tp1, tp2, size, tp1_hit
    price = current_price_fetcher()
    r = abs(trade["entry"] - trade["stop"])
    if not trade.get("tp1_hit") and ((price - trade["entry"])/r >= 1 if trade["side"]=="long" else (trade["entry"]-price)/r >= 1):
        trade["size"] *= 0.5
        trade["stop"] = trade["entry"]  # move to BE
        trade["tp1_hit"] = True
    if (price >= trade["tp2"] and trade["side"]=="long") or (price <= trade["tp2"] and trade["side"]=="short"):
        trade["exit"] = price
        trade["closed"] = True
    return trade
