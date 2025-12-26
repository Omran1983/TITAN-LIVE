import pandas as pd
import asyncio
from logging_config import log

# --- Import our custom modules ---
from data.binance_client import BinanceDataClient
from strategy.orchestrator import StrategyOrchestrator
from risk.risk_manager import RiskManager

class BacktestRunner:
    """
    Runs a backtest of a given strategy on historical data.
    """

    def __init__(self, strategy_config: dict, capital: float):
        """
        Initializes the Backtest Runner.

        Args:
            strategy_config (dict): Configuration for the strategy module.
            capital (float): The initial starting capital for the backtest.
        """
        self.strategy = StrategyOrchestrator()
        self.risk_manager = RiskManager(client=None)
        self.risk_manager.total_capital = capital # Manually set for backtest
        self.risk_manager.risk_per_trade_usd = capital * self.risk_manager.risk_per_trade_percent
        self.initial_capital = capital
        self.data_client = BinanceDataClient()
        self.trades = [] # List to store details of each simulated trade

    def _simulate_trade(self, data: pd.DataFrame, entry_index: int, signal: str):
        """
        Simulates the execution and outcome of a single trade.
        """
        entry_candle = data.iloc[entry_index]
        entry_price = entry_candle['close']
        
        is_long = signal == "GO_LONG"
        stop_loss_price = entry_candle['low'] if is_long else entry_candle['high']
        
        risk_per_share = abs(entry_price - stop_loss_price)
        reward_per_share = risk_per_share * 2.0
        take_profit_price = entry_price + reward_per_share if is_long else entry_price - reward_per_share

        position_size = self.risk_manager.calculate_position_size(
            entry_price=entry_price,
            stop_loss_price=stop_loss_price,
            is_long=is_long,
            history_df=data.iloc[:entry_index+1], # Pass history for Volatility Valve
            min_trade_size=0.001,
            trade_size_step=0.001
        )

        if position_size <= 0:
            return

        log.info(f"SIMULATING TRADE: Entry at ${entry_price:.4f}, Size: {position_size}, SL: {stop_loss_price:.4f}, TP: {take_profit_price:.4f}")

        for exit_index in range(entry_index + 1, len(data)):
            current_candle = data.iloc[exit_index]
            exit_reason = None
            pnl = 0

            if is_long and current_candle['low'] <= stop_loss_price:
                exit_price = stop_loss_price
                exit_reason = "Stop-Loss"
            elif not is_long and current_candle['high'] >= stop_loss_price:
                exit_price = stop_loss_price
                exit_reason = "Stop-Loss"
            
            elif is_long and current_candle['high'] >= take_profit_price:
                exit_price = take_profit_price
                exit_reason = "Take-Profit"
            elif not is_long and current_candle['low'] <= take_profit_price:
                exit_price = take_profit_price
                exit_reason = "Take-Profit"

            if exit_reason:
                if is_long:
                    pnl = (exit_price - entry_price) * position_size
                else:
                    pnl = (entry_price - exit_price) * position_size
                
                self.trades.append({
                    "entry_time": entry_candle.name,
                    "exit_time": current_candle.name,
                    "direction": "LONG" if is_long else "SHORT",
                    "entry_price": entry_price,
                    "exit_price": exit_price,
                    "pnl": pnl,
                    "exit_reason": exit_reason
                })
                return

    def run(self, historical_data: pd.DataFrame):
        """
        Executes the backtest over the entire historical dataset.
        """
        log.info(f"Running backtest on {len(historical_data)} candles...")
        
        start_index = self.strategy.lookback_period
        
        for i in range(start_index, len(historical_data)):
            data_slice = historical_data.iloc[:i+1]
            data_slice.symbol = historical_data.symbol
            
            # Backtest Simulation: We use a static Neutral sentiment (0.0) for now.
            # In a robust backtest, we would load historical sentiment data here.
            signal = self.strategy.get_signal(data_slice, sentiment_score=0.0)
            
            if signal.name in ["GO_LONG", "GO_SHORT"]:
                self._simulate_trade(historical_data, i, signal.name)
        
        log.info("Backtest complete.")

    def get_results(self) -> dict:
        """
        Calculates performance metrics from the executed trades.
        """
        if not self.trades:
            return {
                "total_trades": 0, "total_pnl": 0, "win_rate": 0,
                "profit_factor": 0, "avg_win": 0, "avg_loss": 0
            }

        results_df = pd.DataFrame(self.trades)
        total_trades = len(results_df)
        total_pnl = results_df['pnl'].sum()
        
        winners = results_df[results_df['pnl'] > 0]
        losers = results_df[results_df['pnl'] <= 0]
        
        win_rate = (len(winners) / total_trades) * 100 if total_trades > 0 else 0
        avg_win = winners['pnl'].mean() if len(winners) > 0 else 0
        avg_loss = losers['pnl'].mean() if len(losers) > 0 else 0
        profit_factor = abs(winners['pnl'].sum() / losers['pnl'].sum()) if losers['pnl'].sum() != 0 else float('inf')

        return {
            "total_trades": total_trades,
            "total_pnl": total_pnl,
            "win_rate": win_rate,
            "profit_factor": profit_factor,
            "avg_win": avg_win,
            "avg_loss": avg_loss,
            "equity_curve": results_df['pnl'].cumsum() + self.initial_capital
        }

    def print_results(self):
        """
        Prints the performance metrics of the backtest.
        """
        results = self.get_results()
        if results['total_trades'] == 0:
            log.warning("--- No trades were executed during the backtest. ---")
            return

        log.info("--- Backtest Results ---")
        log.info(f"Initial Capital:      ${self.initial_capital:,.2f}")
        log.info(f"Total Net PnL:        ${results['total_pnl']:,.2f}")
        log.info(f"Total Trades:         {results['total_trades']}")
        log.info(f"Win Rate:             {results['win_rate']:.2f}%")
        log.info(f"Average Win:          ${results['avg_win']:,.2f}")
        log.info(f"Average Loss:         ${results['avg_loss']:,.2f}")
        log.info(f"Profit Factor:        {results['profit_factor']:.2f}")
        
        # Advanced Metrics
        if not results['equity_curve'].empty:
            equity = results['equity_curve']
            peak = equity.cummax()
            drawdown = (equity - peak) / peak
            max_drawdown = drawdown.min() * 100
            
            # Simple Sharpe (assuming daily trades, risk-free=0)
            returns = equity.pct_change().dropna()
            sharpe = (returns.mean() / returns.std()) * (252**0.5) if returns.std() != 0 else 0

            log.info(f"Max Drawdown:         {max_drawdown:.2f}%")
            log.info(f"Sharpe Ratio:         {sharpe:.2f}")

        log.info("\n--- Trade Log ---")
        # For dataframes, using print is still the cleanest way to display
        print(pd.DataFrame(self.trades))

async def main():
    """Main function to run the backtest."""
    
    symbol_to_test = "SOLUSDT"
    timeframe = "1m"
    data_start_date = "3 days ago UTC"
    local_data_file = "data/SOLUSDT-1m-data.csv"
    
    initial_capital = 100.0
    strategy_params = {
        "lookback_period": 5,
        "volume_multiplier": 3.0,
        "price_move_multiplier": 2.5
    }

    runner = BacktestRunner(strategy_params, initial_capital)
    
    historical_data = None
    try:
        log.info(f"Attempting to load data from local file: {local_data_file}...")
        historical_data = pd.read_csv(local_data_file, index_col='open_time', parse_dates=True)
        log.info("Local data loaded successfully.")
    except FileNotFoundError:
        log.warning("Local data file not found. Falling back to Binance API.")
        historical_data = await runner.data_client.get_historical_klines(
            symbol_to_test, timeframe, data_start_date
        )

    if historical_data is not None and not historical_data.empty:
        historical_data.symbol = symbol_to_test
        runner.run(historical_data)
        runner.print_results()
    else:
        log.error("Could not obtain historical data. Backtest cannot run.")

if __name__ == "__main__":
    asyncio.run(main())
