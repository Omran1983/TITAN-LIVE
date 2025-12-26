import os
from binance.spot import Spot
from binance.error import ClientError
from dotenv import load_dotenv

load_dotenv(os.getenv("ENV_FILE", ".env"))
client = Spot(
    base_url=os.getenv("BINANCE_BASE_URL", "https://testnet.binance.vision"),
    api_key=os.getenv("BINANCE_API_KEY"),
    api_secret=os.getenv("BINANCE_API_SECRET"),
)

symbol = os.getenv("SYMBOL", "BTCUSDT")
quote_qty = os.getenv("QUOTE_QTY", "12")
recv = int(os.getenv("RECV_WINDOW","5000"))

try:
    order = client.new_order(symbol=symbol, side="BUY", type="MARKET",
                             quoteOrderQty=str(quote_qty), recvWindow=recv)
    print({"status": "OK", "orderId": order.get("orderId"), "symbol": symbol, "side": "BUY"})
except ClientError as e:
    print({"status": "ERROR", "code": e.error_code, "msg": e.error_message})
