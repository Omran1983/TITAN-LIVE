import os
import pandas as pd
from datetime import datetime
from logging_config import log

# ---
# Note to the user:
# This module is the heart of the bot's user interface.
# ---

class Dashboard:
    """
    A class to create and display a real-time terminal dashboard.
    """

    def _clear_screen(self):
        """Clears the terminal screen."""
        os.system('cls' if os.name == 'nt' else 'clear')

    def display(self, status: str, pnl: float, loss_limit: float, market_data: dict, positions: list):
        """
        Renders the full dashboard.
        """
        self._clear_screen()
        
        # NOTE: We use print() here intentionally. The logger would add timestamps
        # and other formatting that would break the clean dashboard layout.
        
        print("--- Jules' Intelligent Trading Bot ---")
        print(f"Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("-" * 35)

        status_color = "\033[92m" # Green
        if "STOPPED" in status:
            status_color = "\033[91m" # Red
        
        pnl_color = "\033[92m" if pnl >= 0 else "\033[91m"
        
        print(f"STATUS: {status_color}{status.upper()}\033[0m")
        print(f"SESSION PnL: {pnl_color}${pnl:,.2f}\033[0m (Limit: ${loss_limit:,.2f})")
        print("-" * 35)

        print("MARKET PRICES:")
        if not market_data:
            print("  Waiting for market data...")
        else:
            for symbol, price in market_data.items():
                print(f"  - {symbol:<10}: ${price:,.4f}")
        print("-" * 35)

        print("OPEN POSITIONS:")
        if not positions:
            print("  No open positions.")
        else:
            pos_data = [{
                "Symbol": p.symbol, "Direction": p.direction, "Qty": p.quantity,
                "Entry": f"${p.entry_price:,.4f}", "Stop": f"${p.stop_loss_price:,.4f}"
            } for p in positions]
            
            df = pd.DataFrame(pos_data)
            print(df.to_string(index=False))
        
        print("-" * 35)
        print("Press CTRL+C to stop the bot.")

if __name__ == '__main__':
    from execution.position_manager import Position
    import time

    dashboard = Dashboard()
    
    test_status = "RUNNING"
    test_pnl = 125.50
    test_limit = -250.0
    test_market_data = {"SOLUSDT": 150.1234, "DOGEUSDT": 0.1567}
    test_positions = [
        Position("SOLUSDT", "LONG", 148.5, 1.5, 147.0, datetime.now().isoformat()),
        Position("DOGEUSDT", "SHORT", 0.16, 1000, 0.165, datetime.now().isoformat())
    ]

    log.info("--- Testing Dashboard ---")
    log.info("Displaying dashboard for 5 seconds...")
    
    start_time = time.time()
    while time.time() - start_time < 5:
        dashboard.display(test_status, test_pnl, test_limit, test_market_data, test_positions)
        test_pnl += 1.1
        time.sleep(1)

    # Clear the screen one last time so the test output is clean
    os.system('cls' if os.name == 'nt' else 'clear')
    log.info("--- Dashboard test complete. ---")
