import os
import asyncio
from typing import Optional
from dotenv import load_dotenv
from binance import AsyncClient
from .order_model import Order
from .execution_interface import ExecutionInterface
from .paper_adapter import PaperAdapter
from .binance_adapter import BinanceAdapter
from logging_config import log

class ExecutionEngine:
    """
    The Router. Decides if we are in 'Simulation' or 'Real World'.
    Also handles Crash Recovery (Reconciliation).
    """

    def __init__(self, client: Optional[AsyncClient] = None):
        load_dotenv()
        self.mode = os.getenv("EXECUTION_MODE", "PAPER").upper()
        self.adapter: ExecutionInterface = None
        
        if self.mode == "LIVE":
            if not client:
                raise ValueError("Execution Engine set to LIVE but no Binance Client provided.")
            log.warning("⚠️ EXECUTION ENGINE: RUNNING IN LIVE MODE. REAL MONEY AT RISK.")
            self.adapter = BinanceAdapter(client)
        else:
            log.info("Execution Engine: Running in PAPER mode.")
            self.adapter = PaperAdapter()

    async def submit_order(self, order: Order) -> Order:
        """
        Routes the order to the active adapter.
        """
        log.info(f"ExecutionEngine: Routing order {order.id} to {self.mode} adapter.")
        return await self.adapter.submit_order(order)

    async def startup_reconcile(self):
        """
        Crash Recovery.
        """
        log.info("ExecutionEngine: Starting Crash Recovery / Reconciliation...")
        # 1. Fetch open orders from Adapter (Binance or Paper)
        # 2. Compare with DB (Not implemented yet, but placeholders ready)
        open_orders = await self.adapter.get_open_orders()
        if open_orders:
            log.warning(f"Found {len(open_orders)} Orphan Orders during startup: {open_orders}")
            # TODO: logic to adopt these orders into local state
        else:
            log.info("No orphan orders found. Clean start.")

    async def get_execution_mode(self) -> str:
        return self.mode
