import asyncio
from typing import List, Optional
from datetime import datetime
from .execution_interface import ExecutionInterface
from .order_model import Order, OrderStatus, OrderSide
from logging_config import log

class PaperAdapter(ExecutionInterface):
    """
    Simulates an exchange. 
    Maintains local state of orders and balances.
    """
    def __init__(self):
        self.orders = {} # id -> Order
        self.latency_ms = 100 # Simulate network lag
        log.info("PaperAdapter initialized (Simulation Mode)")

    async def submit_order(self, order: Order) -> Order:
        """
        Simulates order submission.
        """
        await asyncio.sleep(self.latency_ms / 1000.0) # Fake latency
        
        order.status = OrderStatus.SUBMITTED
        order.exchange_order_id = f"PAPER-{order.id}"
        
        # In Paper Mode, Market Orders fill instantly at 'current price'
        # For this version, we assume perfect fill. 
        # In V2, we can fetch real price to fill.
        
        # Here we just mark it as SUBMITTED, the 'ExecutionEngine' loop 
        # or a 'MarketSimulator' would fill it based on price.
        # For simplicity in this step, let's auto-fill market orders.
        
        if order.order_type == "MARKET":
             order.status = OrderStatus.FILLED
             order.filled_quantity = order.quantity
             # Note: Price needs to be set by the caller or fetched here.
             # We assume the order passed in MIGHT have a price attached from the Oracle, 
             # or we leave it 0 until the fill report.
             
        self.orders[order.id] = order
        log.info(f"PaperTrade: {order.side.value} {order.quantity} {order.symbol} -> {order.status.value}")
        return order

    async def cancel_order(self, order_id: str, symbol: str) -> bool:
        if order_id in self.orders:
            self.orders[order_id].status = OrderStatus.CANCELED
            return True
        return False

    async def get_order_status(self, order_id: str, symbol: str) -> Order:
        return self.orders.get(order_id)

    async def get_open_orders(self, symbol: Optional[str] = None) -> List[Order]:
        return [o for o in self.orders.values() if o.status in [OrderStatus.SUBMITTED, OrderStatus.PARTIALLY_FILLED]]
