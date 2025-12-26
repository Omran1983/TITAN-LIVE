from decimal import Decimal, ROUND_DOWN
from core.config import settings
from infra.binance_client import spot, ticker_price
# helpers already defined in exec/trade.py
from exec.trade import (
    _symbol_info, _filters_for, _floor_price, _free, _post_buy_free_qty
)
from utils.trade_logger import log_order

def tiny_test_trade(symbol: str, quote_usdt: float, tp_pct: float, sl_pct: float) -> dict:
    s = _symbol_info(symbol)
    f = _filters_for(s)

    last = Decimal(ticker_price(symbol)['price'])
    tp = _floor_price(last * Decimal(1 + tp_pct), f['tickSize'])
    stop = _floor_price(last * Decimal(1 - sl_pct), f['tickSize'])
    stop_limit = _floor_price(
        stop * (Decimal(1) - Decimal(str(settings.OCO_STOP_LIMIT_BUFFER))),
        f['tickSize']
    )

    free_usdt = _free('USDT')
    target = Decimal(str(quote_usdt))
    qprec = s.get('quotePrecision') or s.get('quoteAssetPrecision') or 2
    quant = Decimal('1').scaleb(-int(qprec))
    notional = min(target, free_usdt * Decimal('0.98')) * Decimal('0.998')
    if notional < f['minNotional']:
        raise ValueError(f'Not enough USDT. Need >= {f["minNotional"]} USDT, have ~{free_usdt:.2f}.')
    notional = notional.quantize(quant, rounding=ROUND_DOWN)

    # ---- BUY (quoteOrderQty) ----
    buy_res = spot.new_order(symbol=symbol, side='BUY', type='MARKET', quoteOrderQty=str(notional))
    log_order(
        buy_res,
        context=dict(
            symbol=symbol, side='BUY', order_type='MARKET',
            qty_base=None, price=None, quote_amount=float(notional)
        )
    )

    # ---- OCO exits (try v4, fallback v3) ----
    base_asset = s['baseAsset']
    step = f['stepSize']
    sell_qty = _post_buy_free_qty(base_asset, step)
    if sell_qty <= 0:
        raise ValueError('Post-buy free qty is zero; cannot place exits.')

    try:
        oco_res = spot.new_oco_order(
            symbol=symbol, side='SELL',
            aboveType="LIMIT", belowType="STOP_LOSS_LIMIT",
            price=str(tp), quantity=str(sell_qty),
            stopPrice=str(stop), stopLimitPrice=str(stop_limit),
            stopLimitTimeInForce="GTC"
        )
    except TypeError:
        oco_res = spot.new_oco_order(
            symbol=symbol, side='SELL',
            price=str(tp), quantity=str(sell_qty),
            stopPrice=str(stop), stopLimitPrice=str(stop_limit),
            stopLimitTimeInForce="GTC"
        )

    log_order(
        oco_res if isinstance(oco_res, dict) else {"orderId": None},
        context=dict(
            symbol=symbol, side='SELL', order_type='OCO',
            qty_base=float(sell_qty), price=float(tp), quote_amount=None,
            ocoListId=(oco_res.get("orderListId") if isinstance(oco_res, dict) else None),
            tp_price=float(tp), sl_price=float(stop)
        )
    )

    return {'buy': buy_res, 'oco': oco_res}
