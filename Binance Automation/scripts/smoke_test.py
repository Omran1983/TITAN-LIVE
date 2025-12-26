from infra.binance_client import spot
from core.config import settings
from binance.error import ClientError

def main():
    print('Base URL:', settings.BINANCE_BASE_URL)
    print('Mode:', settings.MODE)
    print('Ping:', spot.ping())
    try:
        acct = spot.account(recvWindow=settings.RECV_WINDOW)  # works on testnet
        can_trade = acct.get('canTrade', True)
        bals = [b for b in acct.get('balances', []) if float(b['free'])>0 or float(b['locked'])>0]
        sample = [f"{b['asset']}={b['free']}" for b in bals[:5]]
        print('Account OK. canTrade:', can_trade)
        print('Non-zero assets (sample):', sample, '... total', len(bals))
    except ClientError as e:
        print('ClientError:', e.status_code, e.error_code, e.error_message)

if __name__ == '__main__':
    main()
