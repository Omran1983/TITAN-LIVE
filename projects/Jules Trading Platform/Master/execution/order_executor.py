import os
from dotenv import load_dotenv
from binance import AsyncClient
from binance.exceptions import BinanceAPIException, BinanceOrderException
from logging_config import log

# ---
# Note to the user:
# This module is the bridge between our internal logic and the live market.
# ---

class OrderExecutor:
    """
    Handles the placement and management of orders on the Binance exchange.
    """

    def __init__(self):
        """Initializes the Order Executor."""
        load_dotenv()
        self.api_key = os.getenv("BINANCE_API_KEY")
        self.api_secret = os.getenv("BINANCE_API_SECRET")
        self.dry_run = os.getenv("DRY_RUN", "True").lower() in ('true', '1', 't')
        self.async_client = None

        if not self.api_key or not self.api_secret:
            raise ValueError("API key and secret are not set for the Order Executor.")

        if self.dry_run:
            log.warning("--- INITIALIZING IN DRY RUN MODE (ASYNC) ---")
        else:
            log.warning("--- !!! INITIALIZING IN LIVE TRADING MODE (ASYNC) !!! ---")

    async def _get_client(self):
        """Initializes and returns the async client, creating it if it doesn't exist."""
        if self.async_client is None and not self.dry_run:
            self.async_client = await AsyncClient.create(self.api_key, self.api_secret)
        return self.async_client

    async def create_market_order(self, symbol: str, quantity: float, is_buy: bool) -> dict:
        """Creates a market order asynchronously."""
        side = 'BUY' if is_buy else 'SELL'
        order_type = 'MARKET'
        
        log.info(f"Attempting to place {side} {order_type} order for {quantity} {symbol}...")

        if self.dry_run:
            log.info(f"DRY RUN: Simulating {side} of {quantity} {symbol}.")
            return {
                'symbol': symbol, 'orderId': 'DRY_RUN_ORDER', 'status': 'FILLED',
                'origQty': str(quantity), 'executedQty': str(quantity), 'side': side,
            }

        try:
            client = await self._get_client()
            if is_buy:
                order = await client.order_market_buy(symbol=symbol, quantity=quantity)
            else:
                order = await client.order_market_sell(symbol=symbol, quantity=quantity)
            
            log.info("LIVE MODE: Order successfully placed.")
            log.debug(order)
            return order
        except BinanceAPIException as e:
            log.error(f"Binance API Error placing order for {symbol}: {e}")
            raise
        except BinanceOrderException as e:
            log.error(f"Binance Order Error placing order for {symbol}: {e}")
            raise

    async def close_connection(self):
        """Closes the connection to the Binance async client."""
        if self.async_client:
            await self.async_client.close_connection()
            log.info("Order executor connection closed.")


if __name__ == '__main__':
    import asyncio

    async def main():
        executor = OrderExecutor()
        try:
            buy_response = await executor.create_market_order(symbol="SOLUSDT", quantity=0.1, is_buy=True)
            log.info("\n--- Buy Order Response ---")
            log.info(buy_response)
            assert buy_response['status'] == 'FILLED'
            assert buy_response['side'] == 'BUY'
        finally:
            await executor.close_connection()

    asyncio.run(main())
