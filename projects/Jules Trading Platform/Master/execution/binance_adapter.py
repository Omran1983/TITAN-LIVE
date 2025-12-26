from typing import List, Optional
from binance import AsyncClient
from binance.exceptions import BinanceAPIException
from .execution_interface import ExecutionInterface
from .order_model import Order, OrderStatus, OrderSide
from logging_config import log

class BinanceAdapter(ExecutionInterface):
    """
    Real execution on Binance.
    """
    def __init__(self, client: AsyncClient):
        self.client = client

    async def submit_order(self, order: Order) -> Order:
        try:
            side = client.SIDE_BUY if order.side == OrderSide.BUY else client.SIDE_SELL
            
            if order.order_type == "MARKET":
                response = await self.client.create_order(
                    symbol=order.symbol,
                    side=side,
                    type=client.ORDER_TYPE_MARKET,
                    quantity=order.quantity
                )
            else:
                # TODO: Implement LIMIT orders
                raise NotImplementedError("Limit orders not yet supported in Adapter")

            # Map Binance Response to Order Model
            order.exchange_order_id = str(response['orderId'])
            order.status = OrderStatus.FILLED if response['status'] == 'FILLED' else OrderStatus.SUBMITTED
            order.filled_quantity = float(response.get('executedQty', 0.0))
            
            log.info(f"Binance Execution: {order.symbol} {order.side.value} -> {order.status.value}")
            return order

        except BinanceAPIException as e:
            log.error(f"Binance Execution Failed: {e}")
            order.status = OrderStatus.ERROR
            order.error_message = str(e)
            return order

    async def cancel_order(self, order_id: str, symbol: str) -> bool:
        try:
            await self.client.cancel_order(symbol=symbol, orderId=order_id)
            return True
        except Exception as e:
            log.error(f"Failed to cancel order {order_id}: {e}")
            return False

    async def get_order_status(self, order_id: str, symbol: str) -> Order:
        # Implementation would fetch from API and map to Order object
        pass

    async def get_open_orders(self, symbol: Optional[str] = None) -> List[Order]:
        # Implementation would fetch from API
        pass
