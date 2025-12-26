import csv, argparse, datetime as dt
from core.risk.risk_manager import RiskState, can_trade_today, position_size
from core.strategy.breakout_pb import detect_breakout_pullback, plan_trade, atr
from core.exec.lifecycle import on_fill
from services.journal.journal import log_trade, make_row
import numpy as np

def load_klines_csv(path):
    import csv
    rows = []
    with open(path, newline="") as f:
        r = csv.DictReader(f)
        for x in r:
            # accept snake_case or camelCase columns
            ot = x.get("open_time") or x.get("openTime") or "0"
            rows.append({
                "timestamp": int(float(ot))//1000 if ot else 0,
                "open":   float(x.get("open")),
                "high":   float(x.get("high")),
                "low":    float(x.get("low")),
                "close":  float(x.get("close")),
                "volume": float(x.get("volume", 1))
            })
    return rows

def main(symbol, csv_path, account_balance=10000.0):
    candles = load_klines_csv(csv_path)
    state = RiskState()
    cfg = {
      "sessions":{"enable_session_filter": False,"allowed_sessions_utc":[]},
      "risk":{"max_trades_per_day":3,"max_daily_loss_pct":0.02,"max_weekly_drawdown_pct":0.06}
    }

    highs=[c["high"] for c in candles]; lows=[c["low"] for c in candles]; closes=[c["close"] for c in candles]
    a = atr(highs,lows,closes,14)

    trades=[]
    for i in range(60,len(candles)):
        window = candles[i-60:i]
        sig = detect_breakout_pullback(window)
        if not (sig["long"] or sig["short"]):
            continue
        side = "long" if sig["long"] else "short"
        entry = window[-1]["close"]
        invalid = sig["range_high"] if side=="long" else sig["range_low"]
        plan = plan_trade(side, entry, invalid, a[i-1], rr_primary=2.0, atr_mult=1.1)
        size = position_size(account_balance, plan["entry"], plan["stop"], symbol, 0.0075)
        if size <= 0: 
            continue
        trade = {"side":side, "entry":plan["entry"], "stop":plan["stop"], "tp1":plan["tp1"], "tp2":plan["tp2"], "size":size, "tp1_hit":False, "closed":False}

        # simulate forward a few bars
        j=i
        def px(): 
            return candles[j]["close"]
        while j < len(candles) and not trade["closed"]:
            # stop hit?
            if (candles[j]["low"] <= trade["stop"] and side=="long") or (candles[j]["high"] >= trade["stop"] and side=="short"):
                trade["exit"]=trade["stop"]; trade["closed"]=True
                break
            trade = on_fill(trade, px)
            j+=1

        r = abs(trade["entry"]-trade["stop"])
        pnl = (trade["exit"]-trade["entry"])*trade["size"] if "exit" in trade else 0.0
        R = (pnl / (r*trade["size"])) if r>0 else 0.0
        row = make_row(dt.datetime.utcnow(),
            Symbol=symbol, Session="Sim", Bias="Trend", Setup="Breakout-PB",
            Entry=round(trade["entry"],6), Stop=round(trade["stop"],6), TP=round(trade["tp2"],6),
            Size=round(trade["size"],6), ATR14=round(a[i-1],6), Fees=0, Slip=0,
            Outcome="Win" if R>0 else "Loss", Exit=round(trade.get("exit",trade["entry"]),6),
            PnL=round(pnl,2), R=round(R,3), MAE="", MFE="", Notes=""
        )
        log_trade("./live_trade_log.csv", row)
        trades.append(row)

    print(f"Simulated trades: {len(trades)}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--symbol", default="BTCUSDT")
    p.add_argument("--csv", default="./klines_BTCUSDT_1m.csv")
    args = p.parse_args()
    main(args.symbol, args.csv)


