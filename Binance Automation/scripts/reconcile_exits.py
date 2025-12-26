from infra.binance_client import spot
from core.config import settings

def reconcile(symbol: str):
    # Fetch open orders
    open_orders = spot.get_open_orders(symbol=symbol)
    # If there are exactly two sells (TP and SL), nothing to do
    sells = [o for o in open_orders if o['side'] == 'SELL']
    if len(sells) >= 2:
        print('Both exits present. OK.')
        return
    # If only one SELL left, decide which to cancel (if any stray)
    if len(sells) == 1:
        print('Single exit detected; keeping it:', sells[0]['type'], sells[0]['orderId'])
        return
    # If no SELL exits are open, nothing to do (maybe already closed)
    print('No open exits. Position may be flat or exits already filled.')
    return

if __name__ == "__main__":
    reconcile(settings.SYMBOL)
