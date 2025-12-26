import pandas as pd
import pandas_ta as ta
from enum import Enum

class MarketRegime(Enum):
    TRENDING = 1
    RANGING = 2

def get_market_regime(data: pd.DataFrame, adx_threshold: int = 25) -> MarketRegime:
    """
    Determines the market regime based on the Average Directional Index (ADX).

    Args:
        data (pd.DataFrame): OHLCV data. Must contain 'high', 'low', and 'close' columns.
        adx_threshold (int): The ADX value above which the market is considered trending.

    Returns:
        MarketRegime: An enum indicating if the market is TRENDING or RANGING.
    """
    if len(data) < 20: # ADX typically needs a longer lookback
        return MarketRegime.RANGING # Default to ranging if not enough data

    # Calculate the ADX using the pandas-ta library
    # The adx() method automatically calculates ADX, +DI, and -DI
    adx_data = data.ta.adx()
    
    if adx_data is None or 'ADX_14' not in adx_data:
        return MarketRegime.RANGING # Calculation failed

    # Get the latest ADX value
    latest_adx = adx_data['ADX_14'].iloc[-1]
    
    if latest_adx > adx_threshold:
        return MarketRegime.TRENDING
    else:
        return MarketRegime.RANGING

if __name__ == '__main__':
    # --- Self-Test Block ---
    print("\n--- Testing Market Regime Filter ---")
    
    # Create sample data representing a ranging market
    ranging_data = {
        'high': [101, 102, 101, 102, 101, 102, 101, 102, 101, 102] * 3,
        'low':  [99, 98, 99, 98, 99, 98, 99, 98, 99, 98] * 3,
        'close':[100, 100, 100, 100, 100, 100, 100, 100, 100, 100] * 3
    }
    ranging_df = pd.DataFrame(ranging_data)
    
    regime = get_market_regime(ranging_df, adx_threshold=25)
    print(f"Regime for ranging data: {regime.name}")
    assert regime == MarketRegime.RANGING

    # Create sample data representing a trending market
    trending_data = {
        'high': [101, 102, 103, 104, 105, 106, 107, 108, 109, 110] * 3,
        'low':  [100, 101, 102, 103, 104, 105, 106, 107, 108, 109] * 3,
        'close':[101, 102, 103, 104, 105, 106, 107, 108, 109, 110] * 3
    }
    trending_df = pd.DataFrame(trending_data)
    
    regime = get_market_regime(trending_df, adx_threshold=25)
    print(f"Regime for trending data: {regime.name}")
    assert regime == MarketRegime.TRENDING
    
    print("\n--- Market Regime Filter self-tests passed successfully! ---")