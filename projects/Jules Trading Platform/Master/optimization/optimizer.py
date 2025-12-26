import pandas as pd
import asyncio
import itertools
import json

from backtest.backtest_runner import BacktestRunner
from logging_config import log

# ---
# Note to the user:
# This is a research tool to find the best strategy parameters.
# ---

class Optimizer:
    """
    A tool to run backtests over a range of strategy parameters.
    """

    def __init__(self, symbol: str, timeframe: str, start_date: str, initial_capital: float):
        """Initializes the Optimizer."""
        self.symbol = symbol
        self.timeframe = timeframe
        self.start_date = start_date
        self.initial_capital = initial_capital
        self.results = []

    async def run_optimization(self, parameter_space: dict):
        """
        Runs the optimization process.
        """
        log.info("--- Starting Parameter Optimization ---")
        
        keys, values = zip(*parameter_space.items())
        param_combinations = [dict(zip(keys, v)) for v in itertools.product(*values)]
        
        log.info(f"Testing {len(param_combinations)} unique parameter combinations...")

        historical_data = None
        try:
            local_data_file = f"data/{self.symbol}-1m-data.csv"
            log.info(f"Optimizer attempting to load data from {local_data_file}...")
            historical_data = pd.read_csv(local_data_file, index_col='open_time', parse_dates=True)
            log.info("Local data loaded successfully for optimizer.")
        except FileNotFoundError:
            log.warning("Local data not found. Falling back to Binance API for optimizer.")
            from data.binance_client import BinanceDataClient
            data_client = BinanceDataClient()
            historical_data = await data_client.get_historical_klines(
                self.symbol, self.timeframe, self.start_date
            )
            await data_client.close_connection()

        if historical_data is None or historical_data.empty:
            log.error("Could not fetch historical data. Aborting optimization.")
            return

        for i, params in enumerate(param_combinations):
            log.info(f"\n[{i+1}/{len(param_combinations)}] Testing parameters: {params}")
            
            data_copy = historical_data.copy()
            data_copy.symbol = self.symbol
            
            runner = BacktestRunner(strategy_config=params, capital=self.initial_capital)
            runner.run(data_copy)
            
            report = runner.get_results()
            report['parameters'] = params
            self.results.append(report)

        log.info("\n--- Optimization Complete ---")

    def print_report(self):
        """
        Prints a summary report and saves the results.
        """
        if not self.results:
            log.warning("No results to report.")
            return

        results_df = pd.DataFrame(self.results)
        sorted_results = results_df.sort_values(by='profit_factor', ascending=False)
        
        log.info("\n--- Optimization Results (Top 10) ---")
        # Use print for dataframes for better formatting
        print(sorted_results.head(10).to_string())

        try:
            sorted_results['parameters'] = sorted_results['parameters'].astype(str)
            with open("optimization/results.json", "w") as f:
                json.dump(sorted_results.to_dict(orient='records'), f, indent=4)
            log.info("\nSuccessfully saved optimization results to optimization/results.json")
        except Exception as e:
            log.error(f"Error saving optimization results: {e}")


async def main():
    parameter_grid = {
        "lookback_period": [10, 20, 30],
        "volume_multiplier": [2.0, 3.0, 4.0],
        "price_move_multiplier": [2.0, 2.5, 3.0]
    }

    optimizer = Optimizer(
        symbol="SOLUSDT",
        timeframe="1m",
        start_date="7 days ago UTC",
        initial_capital=100.0
    )

    await optimizer.run_optimization(parameter_grid)
    optimizer.print_report()

if __name__ == "__main__":
    asyncio.run(main())
