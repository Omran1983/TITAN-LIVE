from infra.binance_client import spot
from core.config import settings
from binance.error import ClientError

def main():
    print("Base URL:", settings.BINANCE_BASE_URL)
    print("Symbol:", settings.SYMBOL)
    try:
        perms = spot.api_key_permissions()
        print("api_key_permissions:", perms)
    except ClientError as e:
        print("api_key_permissions ERROR:", e.status_code, e.error_code, e.error_message)

    try:
        x = spot.exchange_info(symbol=settings.SYMBOL)
        s = x['symbols'][0]
        print("exchange_info:", {"status": s.get("status"), "permissions": s.get("permissions")})
    except ClientError as e:
        print("exchange_info ERROR:", e.status_code, e.error_code, e.error_message)

if __name__ == "__main__":
    main()
