from abc import ABC, abstractmethod
from typing import List, Optional
from .order_model import Order

class ExecutionInterface(ABC):
    """
    Abstract Base Class for Execution Adapters.
    Ensures that PaperTrading and LiveTrading have the exact same API.
    """

    @abstractmethod
    async def submit_order(self, order: Order) -> Order:
        """
        Submits an order to the exchange (or simulator).
        Returns the updated Order object (e.g., with exchange_id).
        """
        pass

    @abstractmethod
    async def cancel_order(self, order_id: str, symbol: str) -> bool:
        """
        Cancels an order.
        """
        pass

    @abstractmethod
    async def get_order_status(self, order_id: str, symbol: str) -> Order:
        """
        Fetches the latest status of an order.
        """
        pass

    @abstractmethod
    async def get_open_orders(self, symbol: Optional[str] = None) -> List[Order]:
        """
        Returns a list of all open orders.
        """
        pass
