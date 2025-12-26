from abc import ABC, abstractmethod
import pandas as pd
from enum import Enum

class Signal(Enum):
    """
    Represents the trading signals that a strategy can generate.
    """
    GO_LONG = 1
    GO_SHORT = -1
    CLOSE_POSITION = 0 # A signal to exit the current position, regardless of direction
    NO_TRADE = 99

class BaseStrategy(ABC):
    """
    Abstract base class for all trading strategies.

    This interface ensures that every strategy implemented in the system has a
    consistent structure, making them interchangeable and easier to manage.
    """

    def __init__(self, config: dict):
        """
        Initializes the base strategy.

        Args:
            config (dict): A dictionary containing strategy-specific parameters.
                           For example, {'ema_short': 10, 'ema_long': 50}.
        """
        self.config = config

    @abstractmethod
    def get_signal(self, historical_data: pd.DataFrame) -> Signal:
        """
        The core logic of the strategy resides here.

        This method analyzes historical market data (and potentially other indicators)
        to decide whether to enter, exit, or stay out of a trade.

        Args:
            historical_data (pd.DataFrame): A DataFrame containing OHLCV data.
                                            The most recent data is at the end of the frame.

        Returns:
            Signal: An enum representing the trading decision (GO_LONG, GO_SHORT, etc.).
        """
        pass
