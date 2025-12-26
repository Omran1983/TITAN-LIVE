from binance.spot import Spot
from core.config import settings

def make_client() -> Spot:
    return Spot(
        api_key=settings.BINANCE_API_KEY.get_secret_value(),
        api_secret=settings.BINANCE_API_SECRET.get_secret_value(),
        base_url=settings.BINANCE_BASE_URL
    )

spot = make_client()

def ping() -> dict:
    return spot.ping()

def account_status() -> dict:
    return spot.account(recvWindow=settings.RECV_WINDOW)

def exchange_info():
    return spot.exchange_info()

def ticker_price(symbol: str):
    return spot.ticker_price(symbol)
