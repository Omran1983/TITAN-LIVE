from typing import Tuple
from decimal import Decimal, ROUND_DOWN
from core.config import settings
from infra.binance_client import spot, exchange_info, ticker_price

def _symbol_info(symbol: str):
    info = exchange_info()
    for s in info['symbols']:
        if s['symbol'] == symbol:
            return s
    raise ValueError(f'No exchangeInfo for {symbol}')

def _filters_for(s):
    lot = next(f for f in s['filters'] if f['filterType'] == 'LOT_SIZE')
    pricef = next(f for f in s['filters'] if f['filterType'] == 'PRICE_FILTER')
    nf = next((f for f in s['filters'] if f['filterType'] in ('NOTIONAL','MIN_NOTIONAL')), None)
    min_notional = Decimal(nf.get('minNotional')) if nf and nf.get('minNotional') else Decimal('5')
    return {
        'stepSize': Decimal(lot['stepSize']),
        'minQty': Decimal(lot['minQty']),
        'tickSize': Decimal(pricef['tickSize']),
        'minNotional': min_notional,
    }

def _floor_qty(qty: Decimal, step: Decimal) -> Decimal:
    return (qty // step) * step if step != 0 else qty

def _floor_price(px: Decimal, tick: Decimal) -> Decimal:
    return (px // tick) * tick if tick != 0 else px

def _post_buy_free_qty(base_asset: str, step: Decimal) -> Decimal:
    acct = spot.account(recvWindow=settings.RECV_WINDOW)
    bal = next((b for b in acct['balances'] if b['asset'] == base_asset), None)
    free = Decimal(bal['free']) if bal else Decimal('0')
    sell_qty = _floor_qty(free, step)
    # shave one step for safety vs fees/precision
    if sell_qty > 0 and step > 0:
        sell_qty = max(Decimal('0'), sell_qty - step)
    return sell_qty

def _free(asset: str) -> Decimal:
    from binance.error import ClientError
    try:
        acct = spot.account(recvWindow=settings.RECV_WINDOW)
    except ClientError as e:
        if getattr(e, 'error_code', None) == -2015:
            raise RuntimeError("Binance -2015: Signed request blocked. Check API key, IP whitelist, and permissions (Enable Reading + Spot/Margin) for the mainnet key in .env.mainnet.") from e
        raise
    acct = spot.account(recvWindow=settings.RECV_WINDOW)
    bal = next((b for b in acct['balances'] if b['asset'] == asset), {'free':'0'})['free']
    return Decimal(bal)

def place_oco_sell_v3(symbol: str, qty: Decimal, take_profit: Decimal, stop_price: Decimal, stop_limit_price: Decimal):
    # binance-connector v3+ requires aboveType/belowType
    return spot.new_oco_order(
        symbol=symbol,
        side="SELL",
        aboveType="LIMIT",
        belowType="STOP_LOSS_LIMIT",
        price=str(take_profit),
        quantity=str(qty),
        stopPrice=str(stop_price),
        stopLimitPrice=str(stop_limit_price),
        stopLimitTimeInForce="GTC"
    )

def tiny_test_trade(symbol: str, quote_usdt: float, tp_pct: float, sl_pct: float) -> dict:
    s = _symbol_info(symbol)
    f = _filters_for(s)

    last = Decimal(ticker_price(symbol)['price'])
    tp = _floor_price(last * Decimal(1 + tp_pct), f['tickSize'])
    stop = _floor_price(last * Decimal(1 - sl_pct), f['tickSize'])
    stop_limit = _floor_price(stop * (Decimal(1) - Decimal(str(settings.OCO_STOP_LIMIT_BUFFER))), f['tickSize'])

    # size notional safely and round to quote precision
    free_usdt = _free('USDT')
    target = Decimal(str(quote_usdt))
    qprec = s.get('quotePrecision') or s.get('quoteAssetPrecision') or 2
    quant = Decimal('1').scaleb(-int(qprec))
    notional = min(target, free_usdt * Decimal('0.98')) * Decimal('0.998')
    if notional < f['minNotional']:
        raise ValueError(f'Not enough USDT. Need >= {f["minNotional"]} USDT, have ~{free_usdt:.2f}.')
    notional = notional.quantize(quant, rounding=ROUND_DOWN)

    # BUY using quoteOrderQty
    buy_res = spot.new_order(symbol=symbol, side='BUY', type='MARKET', quoteOrderQty=str(notional))

    # exits via ONE OCO order (prevents double-reserving balance)
    base_asset = s['baseAsset']
    step = f['stepSize']
    sell_qty = _post_buy_free_qty(base_asset, step)
    if sell_qty <= 0:
        raise ValueError('Post-buy free qty is zero; cannot place exits.')

    oco_res = place_oco_sell_v3(symbol, sell_qty, tp, stop, stop_limit)
    return {'buy': buy_res, 'oco': oco_res}
def place_oco_sell_v3(symbol: str, qty, take_profit, stop_price, stop_limit_price):
    # binance-connector v3: no aboveType/belowType params
    return spot.new_oco_order(
        symbol=symbol,
        side="SELL",
        price=str(take_profit),
        quantity=str(qty),
        stopPrice=str(stop_price),
        stopLimitPrice=str(stop_limit_price),
        stopLimitTimeInForce="GTC"
    )


