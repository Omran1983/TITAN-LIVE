# auth_doctor.py
from dotenv import load_dotenv; load_dotenv(".env.mainnet")
import os, sys
print("ENV=", os.getenv("ENV", "MAINNET"))
AK=os.getenv("BINANCE_API_KEY"); SK=os.getenv("BINANCE_API_SECRET")
print("KEY?", bool(AK), "SECRET?", bool(SK))
if not AK or not SK: sys.exit("Missing BINANCE_API_KEY or BINANCE_API_SECRET in .env.mainnet")

from binance.spot import Spot as S
env=os.getenv("ENV","MAINNET").upper()
cli = S(api_key=AK, api_secret=SK) if env=="MAINNET" else S(base_url="https://testnet.binance.vision", api_key=AK, api_secret=SK)
try:
    cli.ping()
    acc = cli.account()
    nz = [b for b in acc.get("balances",[]) if float(b["free"])+float(b["locked"])>0]
    print("AUTH OK ✅  nonzero assets (top):", [(b["asset"], b["free"], b["locked"]) for b in nz[:6]])
except Exception as e:
    print("AUTH FAIL ❌", e)
    sys.exit(2)
