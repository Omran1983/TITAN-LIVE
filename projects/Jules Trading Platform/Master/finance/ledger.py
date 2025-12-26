import os
import csv
import logging
from datetime import datetime
from typing import List, Dict, Optional

log = logging.getLogger(__name__)

class LedgerManager:
    """
    Manages the financial ledger of the trading bot.
    Tracks all money movements: Deposits, Withdrawals, Realized PnL.
    Source of Truth for 'Net Capital'.
    """

    def __init__(self, data_dir="data"):
        self.file_path = os.path.join(data_dir, "ledger.csv")
        self._ensure_file_exists()

    def _ensure_file_exists(self):
        if not os.path.exists(self.file_path):
            with open(self.file_path, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(["id", "timestamp", "type", "amount", "balance_after", "description", "symbol"])
            log.info("Initialized new Ledger at %s", self.file_path)
            # Add initial capital if empty (Simulation Genesis)
            self.add_transaction("DEPOSIT", 100.00, "Genesis Capital")

    def get_current_balance(self) -> float:
        """Returns the latest balance from the ledger."""
        try:
            with open(self.file_path, 'r') as f:
                reader = csv.DictReader(f)
                rows = list(reader)
                if not rows:
                    return 0.0
                return float(rows[-1]['balance_after'])
        except Exception as e:
            log.error("Failed to read balance: %s", e)
            return 0.0

    def add_transaction(self, tx_type: str, amount: float, description: str, symbol: str = "") -> float:
        """
        Records a transaction and returns the new balance.
        tx_type: DEPOSIT, WITHDRAWAL, REALIZED_PNL, FEE
        """
        current_bal = self.get_current_balance()
        new_bal = current_bal + amount
        
        tx_id = datetime.now().strftime('%Y%m%d%H%M%S%f')
        timestamp = datetime.now().isoformat()
        
        try:
            with open(self.file_path, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([tx_id, timestamp, tx_type, amount, new_bal, description, symbol])
            log.info(f"Ledger: {tx_type} | ${amount:.2f} | New Bal: ${new_bal:.2f}")
            return new_bal
        except Exception as e:
            log.error("Failed to write to ledger: %s", e)
            return current_bal

    def get_history(self) -> List[Dict]:
        """Returns full transaction history."""
        try:
            with open(self.file_path, 'r') as f:
                reader = csv.DictReader(f)
                return list(reader)
        except Exception as e:
            log.error("Failed to read ledger history: %s", e)
            return []

    def get_summary(self) -> Dict:
        """Returns financial stats."""
        history = self.get_history()
        total_pnl = sum(float(x['amount']) for x in history if x['type'] in ['REALIZED_PNL', 'FEE'])
        return {
            "current_balance": self.get_current_balance(),
            "transaction_count": len(history),
            "total_realized_pnl": total_pnl
        }
