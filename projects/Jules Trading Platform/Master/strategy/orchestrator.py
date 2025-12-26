import pandas as pd
import pandas_ta as ta
from enum import Enum
from logging_config import log
from .base_strategy import Signal
from .volatility_breakout import VolatilityBreakoutStrategy

class MarketRegime(Enum):
    BULL_TREND = "BULL_TREND"
    BEAR_TREND = "BEAR_TREND"
    SIDEWAYS = "SIDEWAYS"
    EXTREME_VOLATILITY = "EXTREME_VOLATILITY"

class StrategyOrchestrator:
    """
    The 'Brain' of the operation.
    It decides WHICH strategy to use based on Market Regime and Sentiment.
    """
    def __init__(self):
        # Initialize strategies
        self.vol_breakout = VolatilityBreakoutStrategy(config={
            "lookback_period": 20, "volume_multiplier": 3.0, "price_move_multiplier": 2.5
        })
        
        # In the future, we can add 'MeanReversionStrategy' or 'TrendFollowingStrategy' here.
        # For now, we use VolatilityBreakout as the primary weapon, but we change its aggression.
        
        self.current_regime = MarketRegime.SIDEWAYS

    def detect_regime(self, history_df: pd.DataFrame) -> MarketRegime:
        """
        Determines the current market regime using technical indicators.
        """
        if len(history_df) < 200:
            return MarketRegime.SIDEWAYS # Not enough data
            
        current_price = history_df['close'].iloc[-1]
        
        # SMA 200 for Trend
        sma200 = history_df['close'].rolling(window=200).mean().iloc[-1]
        
        # ATR for Volatility
        atr = ta.atr(history_df['high'], history_df['low'], history_df['close'], length=14).iloc[-1]
        vol_pct = (atr / current_price) * 100
        
        # Regime Logic
        if vol_pct > 3.0:
            return MarketRegime.EXTREME_VOLATILITY
        elif current_price > sma200:
            return MarketRegime.BULL_TREND
        elif current_price < sma200:
            return MarketRegime.BEAR_TREND
        else:
            return MarketRegime.SIDEWAYS

    def get_signal(self, history_df: pd.DataFrame, sentiment_score: float) -> Signal:
        """
        Selects the strategy and gets the signal.
        """
        self.current_regime = self.detect_regime(history_df)
        
        # --- Logic Layer 1: The Regime Check ---
        if self.current_regime == MarketRegime.BEAR_TREND:
            # In a Bear Market, we are Defensive.
            # We only take SHORTS or very strong LONGS.
            # For this simple version, we will just use the standard strategy but log the regime.
            # (Future: Switch to 'ShortOnlyStrategy')
            pass

        if self.current_regime == MarketRegime.EXTREME_VOLATILITY:
            # In extreme volatility, standard strategies fail.
            log.warning("Orchestrator: Extreme Volatility detected. Holding position.")
            return Signal.NO_TRADE

        # --- Logic Layer 2: The Sentiment Check ---
        # Sentiment acts as a filter.
        # If Sentiment is Super Bullish (> 0.5), we ignore Sell signals? (Maybe too risky).
        # If Sentiment is Super Bearish (< -0.5), we ignore Buy signals.
        
        raw_signal = self.vol_breakout.get_signal(historical_data=history_df)
        
        if raw_signal == Signal.GO_LONG and sentiment_score < -0.2:
            log.info("Orchestrator: BLOCKED Buy Signal due to Negative Sentiment (%.2f)", sentiment_score)
            return Signal.NO_TRADE

        if raw_signal == Signal.GO_SHORT and sentiment_score > 0.2:
            log.info("Orchestrator: BLOCKED Sell Signal due to Positive Sentiment (%.2f)", sentiment_score)
            return Signal.NO_TRADE
            
        if raw_signal != Signal.NO_TRADE:
            log.info(f"Orchestrator: Approved {raw_signal.name} in {self.current_regime.name} regime.")

        return raw_signal
