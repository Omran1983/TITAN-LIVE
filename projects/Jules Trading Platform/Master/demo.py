import asyncio
import pandas as pd
from live.live_loop import LiveTradingLoop
from logging_config import log

# ---
# Note to the user:
# This script is a dedicated tool for demonstrating the bot's UI.
# It simulates a live market feed using local data.
# ---

async def run_demo():
    """
    Runs the trading bot in a simulated "demonstration mode".
    """
    log.info("--- LAUNCHING TRADING BOT IN DEMONSTRATION MODE ---")
    
    loop = LiveTradingLoop()
    await loop._initialize_history()

    log.info("\n--- Simulating live feed from local CSV data for all symbols... ---")
    
    # --- Load and combine data for all symbols in the universe ---
    all_dfs = []
    for symbol in loop.trading_universe:
        try:
            demo_data_file = f"data/{symbol}-1m-data.csv"
            df = pd.read_csv(demo_data_file, index_col='open_time', parse_dates=True)
            df['symbol'] = symbol # Add symbol identifier
            all_dfs.append(df)
        except FileNotFoundError:
            log.error(f"Demo data file not found for {symbol} at {demo_data_file}. Skipping.")
    
    if not all_dfs:
        log.error("No demo data could be loaded. Aborting demonstration.")
        return

    # Combine all dataframes and sort by time to create a realistic interleaved feed
    combined_df = pd.concat(all_dfs).sort_index()

    # --- Loop through the combined data to simulate a live feed ---
    for index, row in combined_df.iterrows():
        mock_msg = {
            'e': 'kline',
            'k': {
                's': row['symbol'],
                't': int(index.timestamp() * 1000),
                'o': row['open'], 'h': row['high'], 'l': row['low'],
                'c': row['close'], 'v': row['volume'],
                'x': True # Mark every candle as "closed" for the demo
            }
        }
        
        await loop.process_kline_message(mock_msg)
        
        # Pause briefly to make the simulation visible
        await asyncio.sleep(0.25) # Shortened for a faster demo with two symbols
    
    # --- Force a trade for demonstration purposes ---
    log.info("\n--- Forcing a sample trade to demonstrate logging and analytics... ---")
    try:
        # Get the last known data for a symbol to make a realistic trade
        demo_symbol = "SOLUSDT"
        if demo_symbol in loop.historical_data and loop.historical_data[demo_symbol]:
            history_df = pd.DataFrame(list(loop.historical_data[demo_symbol]))
            last_price = history_df['close'].iloc[-1]
            entry_price = last_price
            stop_loss_price = entry_price * 0.99 # 1% stop loss
            exit_price = entry_price * 1.01 # 1% profit
            trade_size = 0.5 # 0.5 SOL

            log.info(f"Forcing LONG position on {demo_symbol} at {entry_price}")
            
            # Create a Position object
            from execution.position_manager import Position
            import datetime

            entry_time = datetime.datetime.now(datetime.timezone.utc).isoformat()
            
            demo_position = Position(
                symbol=demo_symbol,
                direction="LONG",
                quantity=trade_size,
                entry_price=entry_price,
                stop_loss_price=stop_loss_price,
                entry_time=entry_time
            )

            # Manually add the position
            loop.position_manager.add_position(demo_position)

            # Wait a tiny bit to simulate the trade being open
            await asyncio.sleep(0.5)

            log.info(f"Forcing position close on {demo_symbol} at {exit_price}")

            # Manually close the position by removing it and logging the trade
            closed_pos = loop.position_manager.remove_position(demo_position.position_id)
            if closed_pos:
                pnl = (exit_price - closed_pos.entry_price) * closed_pos.quantity
                loop.daily_pnl += pnl # Manually update the PnL
                loop.db_manager.log_trade(
                    position=closed_pos,
                    exit_price=exit_price,
                    pnl=pnl,
                    entry_time=closed_pos.entry_time,
                    exit_time=datetime.datetime.now(datetime.timezone.utc).isoformat()
                )
                # Save the final state with the updated PnL
                loop._update_dashboard_state("RUNNING")
            log.info("Forced trade executed and logged successfully.")

    except Exception as e:
        log.error(f"Failed to force a demonstration trade: {e}")

    log.info("\n--- DEMONSTRATION COMPLETE ---")
    await loop.order_executor.close_connection()
    await loop.data_client.close_connection()
    loop.db_manager.close_connection()


if __name__ == "__main__":
    try:
        asyncio.run(run_demo())
    except KeyboardInterrupt:
        log.info("\nDemonstration stopped manually.")
    finally:
        log.info("Shutdown complete.")
