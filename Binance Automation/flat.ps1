param([string]$symbol="BTCUSDT",[double]$sellPct=25)
. .\init.ps1 -Mode (Test-Path .\.env.prod) ? "prod" : "testnet" -Symbol $symbol

$code = @"
import os, decimal
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c=Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
       api_key=os.getenv("BINANCE_API_KEY"),
       api_secret=os.getenv("BINANCE_API_SECRET"))
sym=os.getenv("SYMBOL","BTCUSDT")
base=sym.replace("USDT","")
acct=c.account()
free=next((float(b["free"]) for b in acct["balances"] if b["asset"]==base),0.0)
if free<=0: 
    print({"status":"ERROR","msg":f"No {base} to sell"}); raise SystemExit(1)
to_sell = free*{SELLFRAC}
# round to step
info=c.exchange_info(symbol=sym)["symbols"][0]
f={x["filterType"]:x for x in info["filters"]}
step=decimal.Decimal(f["LOT_SIZE"]["stepSize"])
def rstep(x): 
    x=decimal.Decimal(str(x))
    return str((x//step)*step)
qty=rstep(to_sell)
o=c.new_order(symbol=sym, side="SELL", type="MARKET", quantity=qty, recvWindow=int(os.getenv("RECV_WINDOW","5000")))
print({"status":"OK","symbol":sym,"qty":qty,"orderId":o.get("orderId")})
"@
$code = $code.Replace("{SELLFRAC}", ([string]($sellPct/100.0)))
python - << $code
