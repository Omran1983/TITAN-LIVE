from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime
from typing import Optional

class OrderStatus(Enum):
    CREATED = "CREATED"
    SUBMITTED = "SUBMITTED"
    PARTIALLY_FILLED = "PARTIALLY_FILLED"
    FILLED = "FILLED"
    CANCELED = "CANCELED"
    REJECTED = "REJECTED"
    ERROR = "ERROR"

class OrderSide(Enum):
    BUY = "BUY"
    SELL = "SELL"

@dataclass
class Order:
    symbol: str
    side: OrderSide
    quantity: float
    order_type: str = "MARKET"
    price: Optional[float] = None # Only for LIMIT orders
    
    # System Fields
    id: str = field(default_factory=lambda: datetime.now().strftime("%Y%m%d%H%M%S%f"))
    status: OrderStatus = OrderStatus.CREATED
    exchange_order_id: Optional[str] = None
    filled_quantity: float = 0.0
    average_fill_price: float = 0.0
    commission: float = 0.0
    error_message: Optional[str] = None
    
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)

    def update_status(self, new_status: OrderStatus):
        self.status = new_status
        self.updated_at = datetime.now()
