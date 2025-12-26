import pandas as pd
from .base_strategy import BaseStrategy, Signal
from analysis.market_regime import get_market_regime, MarketRegime
from logging_config import log

# ---
# Note to the user:
# This is a simplified "proof-of-concept" scalping strategy.
# ---

class VolatilityBreakoutStrategy(BaseStrategy):
    """
    A strategy that aims to capitalize on sudden bursts of volatility.
    """

    def __init__(self, config: dict):
        """
        Initializes the volatility breakout strategy.
        """
        super().__init__(config)
        self.lookback_period = int(self.config.get("lookback_period", 20))
        self.volume_multiplier = float(self.config.get("volume_multiplier", 3.0))
        self.price_move_multiplier = float(self.config.get("price_move_multiplier", 2.5))

    def get_signal(self, historical_data: pd.DataFrame) -> Signal:
        """
        Analyzes the latest candle to detect a volatility breakout.
        """
        if len(historical_data) < self.lookback_period + 1:
            return Signal.NO_TRADE

        regime = get_market_regime(historical_data)
        if regime != MarketRegime.TRENDING:
            return Signal.NO_TRADE

        lookback_data = historical_data.iloc[-(self.lookback_period + 1):-1]

        average_body_size = (lookback_data['close'] - lookback_data['open']).abs().mean()
        average_volume = lookback_data['volume'].mean()

        latest_candle = historical_data.iloc[-1]
        
        current_body_size = abs(latest_candle['close'] - latest_candle['open'])
        current_volume = latest_candle['volume']

        is_volume_surge = current_volume > average_volume * self.volume_multiplier
        is_price_expansion = current_body_size > average_body_size * self.price_move_multiplier

        if is_volume_surge and is_price_expansion:
            if latest_candle['close'] > latest_candle['open']:
                log.info(f"[{latest_candle.name}] Bullish Breakout Detected on {historical_data.symbol}: "
                         f"Volume {current_volume:.2f} vs Avg {average_volume:.2f}, "
                         f"Body {current_body_size:.4f} vs Avg {average_body_size:.4f}")
                return Signal.GO_LONG
            elif latest_candle['close'] < latest_candle['open']:
                log.info(f"[{latest_candle.name}] Bearish Breakout Detected on {historical_data.symbol}: "
                         f"Volume {current_volume:.2f} vs Avg {average_volume:.2f}, "
                         f"Body {current_body_size:.4f} vs Avg {average_body_size:.4f}")
                return Signal.GO_SHORT

        return Signal.NO_TRADE

if __name__ == '__main__':
    data = {
        'open':  [100, 101, 102, 101, 103, 104, 105, 106, 105, 107, 108, 100],
        'high':  [102, 103, 103, 104, 105, 106, 107, 107, 108, 109, 110, 115],
        'low':   [99,  100, 101, 100, 102, 103, 104, 105, 104, 106, 107, 98],
        'close': [101, 102, 101, 103, 104, 105, 106, 105, 107, 108, 100, 112],
        'volume':[10,  12,  11,  13,  14,  15,  16,  15,  17,  18,  19,  60]
    }
    sample_df = pd.DataFrame(data)
    sample_df.symbol = "TESTUSDT"

    strategy_config = {
        "lookback_period": 10,
        "volume_multiplier": 3.0,
        "price_move_multiplier": 2.0
    }

    strategy = VolatilityBreakoutStrategy(strategy_config)
    signal = strategy.get_signal(sample_df)

    log.info(f"\nFinal Signal: {signal}")

    no_trade_data = sample_df.iloc[:-1]
    no_trade_signal = strategy.get_signal(no_trade_data)
    log.info(f"Signal on regular data: {no_trade_signal}")
