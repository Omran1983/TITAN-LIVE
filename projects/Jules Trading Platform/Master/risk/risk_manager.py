import os
import asyncio
import pandas as pd
import pandas_ta as ta
from datetime import datetime, timedelta
from decimal import Decimal, getcontext
from dotenv import load_dotenv
from binance import AsyncClient

# ---
# Note to the user:
# This module is the single most important part of the trading bot.
# Its logic for calculating position sizes based on a predefined risk percentage
# is what separates systematic trading from gambling.
# All trading decisions MUST pass through this risk check before execution.
# ---

# Fixed: Import from the root-level logging_config module
from logging_config import log

class RiskManager:
    """
    Manages risk, capital, and position sizing for all trades.
    Includes 'The Shield': Volatility Valve & Circuit Breaker.
    """

    def __init__(self, client: AsyncClient = None):
        """
        Initializes the Risk Manager.

        Args:
            client (AsyncClient, optional): An authenticated Binance async client. 
                                            If None, runs in demo/test mode.
        """
        load_dotenv()
        risk_per_trade_str = os.getenv("RISK_PER_TRADE", "0.01")
        
        self.client = client
        self.total_capital = 0.0 # Will be loaded asynchronously
        self.risk_per_trade_percent = float(risk_per_trade_str)
        self.risk_per_trade_usd = 0.0
        
        # Circuit Breaker State
        self.last_loss_time = None
        self.consecutive_losses = 0
        self.circuit_breaker_active = False
        self.breaker_reset_time = None

        if not (0 < self.risk_per_trade_percent <= 0.10):
             raise ValueError("RISK_PER_TRADE must be a value between 0 and 0.10 (10%).")

    async def load_account_balance(self):
        """
        Fetches the free USDT balance from the Binance account and updates capital.
        """
        try:
            # In dry-run/demo mode (no client), we use a default capital.
            if not self.client:
                log.info("No Binance client provided. Using default capital for testing.")
                self.total_capital = 100.0
            else:
                balance_info = await self.client.get_asset_balance(asset='USDT')
                self.total_capital = float(balance_info['free'])
            
            self.risk_per_trade_usd = self.total_capital * self.risk_per_trade_percent
            
            log.info("Risk Manager Initialized: Capital $%.2f, Risk/Trade $%.2f (%.2f%%)",
                     self.total_capital, self.risk_per_trade_usd, self.risk_per_trade_percent * 100)

        except Exception as e:
            log.error("Failed to load account balance: %s. Using default capital.", e)
            self.total_capital = 100.0 # Fallback
            self.risk_per_trade_usd = self.total_capital * self.risk_per_trade_percent

    def check_circuit_breaker(self):
        """
        Checks if the 'Circuit Breaker' is active.
        If active, NO TRADES are allowed.
        """
        if self.circuit_breaker_active:
            if datetime.now() > self.breaker_reset_time:
                log.info("🛡️ CIRCUIT BREAKER: Resetting... Trading resumed.")
                self.circuit_breaker_active = False
                self.consecutive_losses = 0
                return False # Not active anymore
            else:
                log.warning(f"🛡️ CIRCUIT BREAKER ACTIVE: Trading locked until {self.breaker_reset_time}")
                return True # Active
        return False

    def record_loss(self):
        """Call this when a trade hits stop-loss."""
        self.consecutive_losses += 1
        if self.consecutive_losses >= 3:
            self.circuit_breaker_active = True
            self.breaker_reset_time = datetime.now() + timedelta(hours=24)
            log.warning("🛡️ CIRCUIT BREAKER TRIGGERED: 3 Consecutive Losses. Trading halted for 24h.")

    def calculate_volatility_multiplier(self, history_df: pd.DataFrame) -> float:
        """
        Calculates a 'Volatility Multiplier' based on ATR.
        High Volatility -> Low Multiplier (Reduce Size).
        Low Volatility -> High Multiplier (Increase Size).
        """
        if history_df.empty or len(history_df) < 20:
            return 1.0

        # Calculate ATR
        atr = ta.atr(history_df['high'], history_df['low'], history_df['close'], length=14)
        current_atr = atr.iloc[-1]
        
        # Normalize ATR by price to get percentage volatility
        current_price = history_df['close'].iloc[-1]
        volatility_pct = (current_atr / current_price) * 100

        # Logic: Base volatility is 1%.
        # If vol is 2%, size is 0.5x. If vol is 0.5%, size is 2x.
        # Clamped between 0.2x and 2.0x for safety.
        multiplier = 1.0 / (volatility_pct + 1e-9) # Simple inverse
        
        # Dynamic Scaling against a baseline of 1% vol
        raw_mult = 1.0 / max(volatility_pct, 0.5) 
        
        # Clamp
        final_mult = max(min(raw_mult, 2.0), 0.2)
        
        log.info(f"Volatility Valve: ATR={current_atr:.4f} ({volatility_pct:.2f}%) -> Multiplier={final_mult:.2f}x")
        return final_mult

    def check_risk_before_trade(self) -> bool:
        """
        Performs pre-trade risk checks.
        """
        if self.total_capital <= 0:
            log.warning("Risk Check FAILED: No capital remaining.")
            return False
            
        if self.check_circuit_breaker():
            return False
        
        return True

    def calculate_position_size(
        self,
        entry_price: float,
        stop_loss_price: float,
        is_long: bool,
        history_df: pd.DataFrame = None,
        min_trade_size: float = 0.001,
        trade_size_step: float = 0.001
    ) -> float:
        """
        Calculates the appropriate position size to adhere to the risk-per-trade limit.
        Uses the Volatility Valve to adjust size dynamically.
        """
        getcontext().prec = 28

        if entry_price <= 0 or stop_loss_price <= 0:
            return 0.0
            
        # Volatility Adjustment
        vol_multiplier = 1.0
        if history_df is not None:
            vol_multiplier = self.calculate_volatility_multiplier(history_df)

        d_entry_price = Decimal(str(entry_price))
        d_stop_loss_price = Decimal(str(stop_loss_price))
        
        # Adjust Risk Amount by Volatility Multiplier
        adjusted_risk_usd = self.risk_per_trade_usd * vol_multiplier
        d_risk_per_trade_usd = Decimal(str(adjusted_risk_usd))
        
        d_trade_size_step = Decimal(str(trade_size_step))
        d_min_trade_size = Decimal(str(min_trade_size))

        distance_to_stop = abs(d_entry_price - d_stop_loss_price)
        
        if distance_to_stop == Decimal(0):
            log.warning("Stop loss cannot be the same as the entry price.")
            return 0.0
            
        raw_position_size = d_risk_per_trade_usd / distance_to_stop

        if raw_position_size < d_min_trade_size:
            log.warning(f"Calculated size {raw_position_size} is below minimum {d_min_trade_size}. Stop is likely too wide.")
            return 0.0

        quantized_size = (raw_position_size // d_trade_size_step) * d_trade_size_step

        if quantized_size < d_min_trade_size:
             return 0.0
        
        log.info(f"Risk Calculation: Base Risk=${self.risk_per_trade_usd:.2f} -> Vol Adjusted=${adjusted_risk_usd:.2f} (x{vol_multiplier:.2f})")

        return float(quantized_size)


async def main_test():
    """Asynchronous main function to run the self-test."""
    # --- Example Usage ---
    # The .env file should have RISK_PER_TRADE="0.01"
    
    # Create a dummy .env for testing if it doesn't exist
    if not os.path.exists(".env"):
        with open(".env", "w") as f:
            f.write('RISK_PER_TRADE="0.01"\n')
            f.write('BINANCE_API_KEY="test"\n')
            f.write('BINANCE_API_SECRET="test"\n')

    risk_manager = RiskManager(client=None) 
    await risk_manager.load_account_balance()
    
    # Mock DF for Volatility
    data = {'high': [102, 103, 104]*10, 'low': [98, 97, 96]*10, 'close': [100, 100, 100]*10}
    df = pd.DataFrame(data)

    print("\n--- Testing Volatility Valve ---")
    entry = 100.0
    stop = 95.0
    size = risk_manager.calculate_position_size(entry, stop, is_long=True, history_df=df)
    print(f"Calculated Position Size with Volatility Check: {size}")

    print("\n--- Testing Circuit Breaker ---")
    risk_manager.record_loss()
    risk_manager.record_loss()
    risk_manager.record_loss()
    if not risk_manager.check_risk_before_trade():
        print("SUCCESS: Circuit Breaker stopped the trade.")
    else:
        print("FAIL: Circuit Breaker did not engage.")

if __name__ == '__main__':
    asyncio.run(main_test())
