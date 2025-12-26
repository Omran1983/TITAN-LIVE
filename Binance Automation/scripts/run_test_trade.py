# scripts\run_test_trade.py
import argparse
from scripts.market_buy import place_market_order

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--symbol", required=True)
    ap.add_argument("--side", default="BUY")
    ap.add_argument("--qty", type=float)
    ap.add_argument("--quoteQty", type=float)
    args = ap.parse_args()
    place_market_order(
        symbol=args.symbol,
        side=args.side,
        qty=args.qty,
        quote_qty=args.quoteQty,
        test=True
    )

if __name__ == "__main__":
    main()
