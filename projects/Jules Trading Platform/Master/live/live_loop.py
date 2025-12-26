import os
import json
import asyncio
import pandas as pd
import datetime
from dotenv import load_dotenv
from collections import deque

# --- Import our custom modules ---
from data.binance_client import BinanceDataClient
from strategy.orchestrator import StrategyOrchestrator
from risk.risk_manager import RiskManager
from execution.order_executor import OrderExecutor
from execution.position_manager import PositionManager, Position
from database.database_manager import DatabaseManager
from ui.dashboard import Dashboard
from logging_config import log
from sentinel import NewsFetcher, SentimentEngine

# --- Phase 5a: Control Plane Imports ---
from execution.execution_engine import ExecutionEngine
from execution.order_model import Order, OrderSide
from data.price_oracle import PriceOracle
from risk.health_monitor import HealthMonitor
from governance.sharia_policy import ShariaPolicy
from agents.doom_watcher import DoomWatcher
from agents.strategist import Strategist
from audit.decision_logger import DecisionLogger
from finance.ledger import LedgerManager

# ---
# Note to the user:
# This is the main orchestrator of the trading bot.
# ---

class LiveTradingLoop:
    """
    The main application loop for the trading bot.
    """

    def __init__(self):
        """Initializes the main trading loop."""
        load_dotenv()
        
        self.trading_universe = os.getenv("TRADING_UNIVERSE", "SOLUSDT,DOGEUSDT").split(',')
        self.risk_per_trade = float(os.getenv("RISK_PER_TRADE", "0.01"))
        self.daily_loss_limit = float(os.getenv("DAILY_LOSS_LIMIT", "-10.0"))
        
        self.risk_per_trade = float(os.getenv("RISK_PER_TRADE", "0.01"))
        self.daily_loss_limit = float(os.getenv("DAILY_LOSS_LIMIT", "-10.0"))
        
        # self.total_capital is now derived from Ledger
        self.daily_pnl = 0.0
        
        self.data_client = BinanceDataClient()
        self.db_manager = DatabaseManager()
        self.risk_manager = RiskManager(client=self.data_client.async_client)
        self.position_manager = PositionManager()
        
        # --- Phase 5a: The Control Plane (Council of Agents) ---
        self.execution_engine = ExecutionEngine(client=self.data_client.async_client)
        self.price_oracle = PriceOracle()
        self.health_monitor = HealthMonitor()
        self.sharia_policy = ShariaPolicy()
        self.decision_logger = DecisionLogger()
        self.ledger = LedgerManager() # The Bank
        self.doom_watcher = DoomWatcher(data_client=self.data_client)
        self.strategist = Strategist(db_manager=self.db_manager)
        self.position_manager = PositionManager()
        
        # --- Phase 3: The Orchestrator (Strategy Brain) ---
        self.orchestrator = StrategyOrchestrator()
        self.position_manager.load_state(self.state_file_path)

        # --- Phase 1: Sentinel Initialization ---
        self.news_fetcher = NewsFetcher(api_key=os.getenv("NEWS_API_KEY"))
        self.sentiment_engine = SentimentEngine()
        self.last_sentiment_check = datetime.datetime.min
        self.last_sentiment_check = datetime.datetime.min
        self.current_sentiment_score = 0.0
        self.latest_news = [] # Store full news objects for UI

        self.dashboard = Dashboard()
        self.market_data = {symbol: 0.0 for symbol in self.trading_universe}
        self.historical_data = {symbol: deque(maxlen=100) for symbol in self.trading_universe}
        
        log.info("Live Trading Loop initialized with symbols: %s", self.trading_universe)
        self._update_dashboard_state("STARTING") # Force file creation immediately

    async def _initialize_history(self):
        """
        Loads initial historical data from local CSV files.
        """
        log.info("Initializing historical data from local files...")
        for symbol in self.trading_universe:
            try:
                local_data_file = f"data/{symbol}-1m-data.csv"
                df = pd.read_csv(local_data_file, index_col='open_time', parse_dates=True)
                
                df = df[['open', 'high', 'low', 'close', 'volume']]
                
                records = df.tail(self.historical_data[symbol].maxlen).to_dict('records')
                
                self.historical_data[symbol].extend(records)
                log.info("Initialized %s with %d historical candles from CSV.", symbol, len(self.historical_data[symbol]))
            except FileNotFoundError:
                log.error("CRITICAL: Local data file not found for %s. Cannot initialize history.", symbol)
            except Exception as e:
                log.error("CRITICAL: Error loading history for %s: %s", symbol, e)
        
        log.info("Historical data initialization complete.")

    def _update_dashboard_state(self, status: str):
        """Writes the current bot state to a JSON file for the web UI."""
        state = {
            "status": status,
            "pnl": self.daily_pnl,
            "market_data": self.market_data,
            # --- Phase 5b: Citadel Data ---
            # --- Phase 5b: Citadel Data ---
            "sentinel": {
                "score": self.current_sentiment_score,
                "label": self.sentiment_engine.get_mood_label(self.current_sentiment_score),
                "news_feed": self.latest_news
            },
            "shield": {
                "daily_loss_limit": self.daily_loss_limit,
                "current_capital": self.ledger.get_current_balance(),
                "is_circuit_breaker_active": not self.risk_manager.check_risk_before_trade()
            },
            "council": {
                "oracle": "ONLINE", 
                "doom_watcher": "WATCHING",
                "strategist": "ANALYZING"
            },
            # --- Phase 5c: Market Intel ---
            "scanner": self._generate_market_scanner_data(),
            "timestamp": datetime.datetime.now().isoformat()
        }
        try:
            with open(self.dashboard_state_file, 'w') as f:
                json.dump(state, f)
        except IOError as e:
            log.warning(f"Could not write to dashboard state file: {e}")

    def _generate_market_scanner_data(self):
        """Generates a snapshot of the trading universe for the UI Scanner."""
        scanner_data = []
        for symbol in self.trading_universe:
            data = {
                "symbol": symbol,
                "price": self.market_data.get(symbol, 0.0),
                "is_whitelisted": self.sharia_policy.is_compliant(symbol),
                "volume": 0.0,
                "change_24h": 0.0
            }
            # Calculate 24h stats from history if available
            if len(self.historical_data[symbol]) > 0:
                latest = self.historical_data[symbol][-1]
                data["volume"] = latest.get('volume', 0.0)
                # Simple approximation if full 24h history isn't loaded (opens at index 0)
                open_price = self.historical_data[symbol][0].get('open', 0.0)
                if open_price > 0:
                    data["change_24h"] = ((data['price'] - open_price) / open_price) * 100
            
            scanner_data.append(data)
        return scanner_data
    async def _check_and_manage_positions(self, symbol: str, current_price: float):
        """
        Checks open positions for a symbol and closes them if the stop-loss is hit.
        """
        positions_for_symbol = self.position_manager.get_positions_by_symbol(symbol)
        if not positions_for_symbol:
            return

        for pos in positions_for_symbol:
            
            is_activated = (pos.direction == 'LONG' and current_price >= pos.activation_price) or \
                           (pos.direction == 'SHORT' and current_price <= pos.activation_price)

            if is_activated:
                risk_distance = abs(pos.entry_price - pos.stop_loss_price)
                new_trailing_stop = current_price - risk_distance if pos.direction == 'LONG' else current_price + risk_distance
                
                if (pos.direction == 'LONG' and new_trailing_stop > pos.trailing_stop_price) or \
                   (pos.direction == 'SHORT' and new_trailing_stop < pos.trailing_stop_price):
                    log.info("TRAILING STOP UPDATED for %s. New stop: %.4f", pos.symbol, new_trailing_stop)
                    pos.trailing_stop_price = new_trailing_stop

            effective_stop_price = max(pos.stop_loss_price, pos.trailing_stop_price) if pos.direction == 'LONG' else min(pos.stop_loss_price, pos.trailing_stop_price)

            should_close = False
            if pos.direction == 'LONG' and current_price <= effective_stop_price:
                log.info("STOP-LOSS HIT for LONG %s at %f", pos.symbol, current_price)
                should_close = True
            elif pos.direction == 'SHORT' and current_price >= effective_stop_price:
                log.info("STOP-LOSS HIT for SHORT %s at %f", pos.symbol, current_price)
                should_close = True

            if should_close:
                try:
                    exit_price = effective_stop_price
                    pnl = (exit_price - pos.entry_price) * pos.quantity if pos.direction == 'LONG' else (pos.entry_price - exit_price) * pos.quantity
                    self.daily_pnl += pnl
                    log.info("Trade PnL: %.2f | Daily PnL: %.2f", pnl, self.daily_pnl)

                    await self.order_executor.create_market_order(
                        symbol=pos.symbol,
                        quantity=pos.quantity,
                        is_buy=False
                    )
                    closed_pos = self.position_manager.remove_position(pos.position_id)
                    
                    if closed_pos:
                        if pnl < 0:
                            self.risk_manager.record_loss()

                        # Log to Ledger (The Money Flow)
                        self.ledger.add_transaction(
                            tx_type="REALIZED_PNL", 
                            amount=pnl, 
                            description=f"Closed {pos.direction} {pos.symbol}", 
                            symbol=pos.symbol
                        )

                        self.db_manager.log_trade(
                            position=closed_pos, exit_price=exit_price, pnl=pnl,
                            entry_time=pd.to_datetime(closed_pos.entry_time).isoformat(),
                            exit_time=datetime.datetime.now(datetime.timezone.utc).isoformat()
                        )
                        self.position_manager.save_state(self.state_file_path)
                        self._update_dashboard_state("RUNNING") # Update state after PnL change
                except Exception as e:
                    log.error("CRITICAL: Failed to close position %s. Reason: %s", pos.position_id, e)

    async def _update_sentiment(self):
        """
        Polls for news every 15 minutes and updates the global sentiment score.
        """
        now = datetime.datetime.now()
        if (now - self.last_sentiment_check).total_seconds() > 900: # 15 minutes
            log.info("Sentinel: Polling for news...")
            # Run blocking web request in a separate thread to keep the bot fast
            loop = asyncio.get_event_loop()
            headlines_data = await loop.run_in_executor(None, self.news_fetcher.fetch_crypto_news)
            
            # Extract just titles for sentiment analysis
            titles = [h['title'] for h in headlines_data]
            score = self.sentiment_engine.analyze_sentiment(titles)
            
            self.current_sentiment_score = score
            self.latest_news = headlines_data # Save for UI export
            self.last_sentiment_check = now
            
            mood = self.sentiment_engine.get_mood_label(score)
            log.info("Sentinel: Market Sentiment Updated -> %s (%.2f)", mood, score)

    async def process_kline_message(self, msg: dict):
        """Processes incoming WebSocket kline messages."""
        if msg.get('e') == 'error':
            log.error("WebSocket Error: %s", msg.get('m'))
            return

        candle_data = msg['k']
        symbol = candle_data['s']
        current_price = float(candle_data['c'])
        is_candle_closed = candle_data['x']

        self.market_data[symbol] = current_price
        await self._check_and_manage_positions(symbol, current_price)
        await self._update_sentiment()

        status = "RUNNING"
        if self.daily_pnl <= self.daily_loss_limit:
            status = "STOPPED - DAILY LOSS LIMIT REACHED"

        self._update_dashboard_state(status)
        self.dashboard.display(
            status=status, pnl=self.daily_pnl, loss_limit=self.daily_loss_limit,
            market_data=self.market_data, positions=self.position_manager.get_all_positions()
        )

        if is_candle_closed:
            new_row = {
                'open_time': pd.to_datetime(candle_data['t'], unit='ms'), 'open': float(candle_data['o']),
                'high': float(candle_data['h']), 'low': float(candle_data['l']),
                'close': float(candle_data['c']), 'volume': float(candle_data['v'])
            }
            self.historical_data[symbol].append(new_row)
            history_df = pd.DataFrame(list(self.historical_data[symbol]))
            history_df.symbol = symbol

            if self.daily_pnl <= self.daily_loss_limit:
                log.warning("Daily loss limit of %.2f reached. No new trades will be opened.", self.daily_loss_limit)
                return

            # --- Phase 5a: The Institutional Pipeline ---
            
            # 1. Oracle Integrity Check
            if not self.price_oracle.check_integrity(symbol, new_row['close']):
                 log.error("Pipeline HALT: Oracle Data Anomaly for %s", symbol)
                 return

            # 2. Sharia Compliance Check
            if not self.sharia_policy.validate_trade(symbol):
                 self.decision_logger.log_sharia_block(symbol, "Not Whitelisted")
                 return

            # 3. Orchestrator + Sentinel Signal
            signal = self.orchestrator.get_signal(history_df, self.current_sentiment_score)
            
            if signal.name in ["GO_LONG", "GO_SHORT"]:
                # 4. Risk Manager (Sizing + Shield)
                is_long = signal.name == "GO_LONG"
                entry_price = new_row['close']
                stop_loss_price = new_row['low'] if is_long else new_row['high']
                
                # Check Global Circuit Breaker First
                if not self.risk_manager.check_risk_before_trade():
                    self.decision_logger.log_context(symbol, signal.name, self.current_sentiment_score, 0, False, "Circuit Breaker Active")
                    return

                size = self.risk_manager.calculate_position_size(entry_price, stop_loss_price, is_long, history_df=history_df)
                
                if size <= 0:
                    self.decision_logger.log_context(symbol, signal.name, self.current_sentiment_score, 0, False, "Risk Sizing = 0")
                    return

                # 5. Execution Engine (Router)
                log.info(f"Pipeline Approved: Executing {signal.name} {size} {symbol}")
                try:
                    order = Order(
                        symbol=symbol,
                        side=OrderSide.BUY if is_long else OrderSide.SELL,
                        quantity=size
                    )
                    filled_order = await self.execution_engine.submit_order(order)
                    
                    self.decision_logger.log_context(symbol, signal.name, self.current_sentiment_score, 0, True, "Executed")
                    
                    # 6. Post-Trade Accounting
                    if filled_order.status == 'FILLED':
                        risk_distance = abs(entry_price - stop_loss_price)
                        new_position = Position(
                            symbol=symbol, 
                            direction="LONG" if is_long else "SHORT",
                            entry_price=entry_price, # Ideally usage filled_order.average_fill_price
                            quantity=filled_order.filled_quantity,
                            stop_loss_price=stop_loss_price,
                            entry_time=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                            activation_price=entry_price + risk_distance if is_long else entry_price - risk_distance,
                            trailing_stop_price=stop_loss_price
                        )
                        self.position_manager.add_position(new_position)
                        self.position_manager.save_state(self.state_file_path)

                except Exception as e:
                    log.error(f"Execution Failed: {e}")

    async def run(self):
        """
        Starts the main application loop.
        """
        await self.risk_manager.load_account_balance()
        await self._initialize_history()
        await self._start_background_agents() # Start the Council
        
        await self.data_client.start_kline_websocket(
            symbols=self.trading_universe,
            interval="1m",
            callback=self.process_kline_message
        )

    async def _start_background_agents(self):
        log.info("Starting Council of Agents...")
        asyncio.create_task(self.doom_watcher.run_loop())
        asyncio.create_task(self.strategist.run_loop())
        asyncio.create_task(self.health_monitor.run())

async def cleanup(loop):
    log.info("Closing connections...")
    log.info("Closing connections...")
    # Clean shutdown of agents would go here
    await loop.data_client.close_connection()
    loop.db_manager.close_connection()
    log.info("Bot shutdown complete.")

if __name__ == "__main__":
    log.info("Starting trading bot...")
    loop = LiveTradingLoop()
    
    try:
        asyncio.run(loop.run())
    except KeyboardInterrupt:
        log.info("Bot stopped manually.")
    finally:
        asyncio.run(cleanup(loop))
