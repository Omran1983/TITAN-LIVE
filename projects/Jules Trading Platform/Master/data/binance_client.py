import os
import pandas as pd
from binance import AsyncClient, BinanceSocketManager
from dotenv import load_dotenv
import asyncio

# --- Import our custom logger ---
from logging_config import log

class BinanceDataClient:
    """
    A client to connect to Binance for market data.
    """
    def __init__(self):
        """
        Initializes the data client.
        """
        load_dotenv()
        self.api_key = os.getenv("BINANCE_API_KEY")
        self.api_secret = os.getenv("BINANCE_API_SECRET")

        if not self.api_key or not self.api_secret:
            raise ValueError(
                "API key and secret are not set. "
                "Please create a .env file with your BINANCE_API_KEY and BINANCE_API_SECRET."
            )
        
        self.async_client = None

    async def _get_client(self):
        """Initializes and returns the async client, creating it if it doesn't exist."""
        if self.async_client is None:
            self.async_client = await AsyncClient.create(self.api_key, self.api_secret)
        return self.async_client

    async def get_historical_klines(
        self, symbol: str, interval: str, start_str: str, end_str: str = None
    ) -> pd.DataFrame:
        """
        Fetches historical K-line (candlestick) data from Binance.
        """
        client = await self._get_client()
        
        log.info(f"Fetching historical data for {symbol} ({interval}) from {start_str}...")

        klines = await client.get_historical_klines(symbol, interval, start_str, end_str)

        columns = [
            "open_time", "open", "high", "low", "close", "volume",
            "close_time", "quote_asset_volume", "number_of_trades",
            "taker_buy_base_asset_volume", "taker_buy_quote_asset_volume", "ignore"
        ]
        
        df = pd.DataFrame(klines, columns=columns)

        df["open_time"] = pd.to_datetime(df["open_time"], unit="ms")
        df.set_index("open_time", inplace=True)

        numeric_cols = ["open", "high", "low", "close", "volume", "quote_asset_volume"]
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors="coerce")

        df = df[["open", "high", "low", "close", "volume"]]
        
        log.info(f"Successfully fetched {len(df)} data points for {symbol}.")
        
        return df

    async def start_kline_websocket(self, symbols: list[str], interval: str, callback):
        """
        Starts a WebSocket connection for live K-line data.
        """
        client = await self._get_client()
        bsm = BinanceSocketManager(client)
        
        sockets = [bsm.kline_socket(symbol=s, interval=interval) for s in symbols]
        
        log.info(f"Starting WebSocket streams for {symbols} on interval {interval}...")

        async def listen(socket):
            async with socket as stream:
                while True:
                    msg = await stream.recv()
                    await callback(msg)

        await asyncio.gather(*(listen(socket) for socket in sockets))

    async def close_connection(self):
        """Closes the connection to the Binance client."""
        if self.async_client:
            await self.async_client.close_connection()
            self.async_client = None
            log.info("Binance client connection closed.")

async def example_callback(msg):
    """A simple callback function to print received messages."""
    if msg['e'] == 'error':
        log.error(f"WebSocket Error: {msg['m']}")
    else:
        candle = msg['k']
        symbol = candle['s']
        is_closed = candle['x']
        close_price = candle['c']
        
        if is_closed:
            log.info(f"Candle closed for {symbol}: Close Price {close_price}")

async def main():
    """Main function for self-testing."""
    data_client = BinanceDataClient()
    
    try:
        historical_data = await data_client.get_historical_klines(
            symbol="BTCUSDT",
            interval="1m",
            start_str="1 day ago UTC"
        )
        log.info("\n--- Historical Data Sample ---")
        print(historical_data.tail())
        log.info("----------------------------\n")
    except Exception as e:
        log.error(f"Error fetching historical data: {e}")

    log.info("\n--- Live WebSocket Data ---")
    try:
        await asyncio.wait_for(
            data_client.start_kline_websocket(
                symbols=["BTCUSDT", "ETHUSDT"], 
                interval="1m", 
                callback=example_callback
            ), 
            timeout=20.0
        )
    except asyncio.TimeoutError:
        log.info("\nWebSocket example finished after 20 seconds.")
    except Exception as e:
        log.error(f"Error during WebSocket streaming: {e}")
    finally:
        await data_client.close_connection()

if __name__ == '__main__':
    asyncio.run(main())
