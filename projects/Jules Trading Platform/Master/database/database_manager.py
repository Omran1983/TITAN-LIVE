import sqlite3
from execution.position_manager import Position
from logging_config import log

# ---
# Note to the user:
# This module provides the bot with a long-term memory.
# ---

class DatabaseManager:
    """
    Manages the SQLite database for storing trade history.
    """

    def __init__(self, db_path: str = "database/trades.db"):
        """
        Initializes the Database Manager.
        """
        self.db_path = db_path
        self.connection = None
        self._connect()
        self._create_trades_table()

    def _connect(self):
        """Establishes a connection to the SQLite database."""
        try:
            self.connection = sqlite3.connect(self.db_path)
            log.info(f"Successfully connected to database at {self.db_path}")
        except sqlite3.Error as e:
            log.error(f"Error connecting to database: {e}")
            raise

    def _create_trades_table(self):
        """
        Creates the 'trades' table if it doesn't already exist.
        """
        try:
            cursor = self.connection.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS trades (
                    position_id TEXT PRIMARY KEY,
                    symbol TEXT NOT NULL,
                    direction TEXT NOT NULL,
                    entry_price REAL NOT NULL,
                    exit_price REAL NOT NULL,
                    quantity REAL NOT NULL,
                    pnl REAL NOT NULL,
                    entry_time TEXT NOT NULL,
                    exit_time TEXT NOT NULL
                )
            """)
            self.connection.commit()
            log.info("'trades' table created or already exists.")
        except sqlite3.Error as e:
            log.error(f"Error creating 'trades' table: {e}")

    def log_trade(self, position: Position, exit_price: float, pnl: float, entry_time: str, exit_time: str):
        """
        Logs a completed trade to the database.
        """
        try:
            cursor = self.connection.cursor()
            cursor.execute("""
                INSERT INTO trades (position_id, symbol, direction, entry_price, exit_price, quantity, pnl, entry_time, exit_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                position.position_id,
                position.symbol,
                position.direction,
                position.entry_price,
                exit_price,
                position.quantity,
                pnl,
                entry_time,
                exit_time
            ))
            self.connection.commit()
            log.info(f"Successfully logged trade {position.position_id} to database.")
        except sqlite3.Error as e:
            log.error(f"Error logging trade {position.position_id}: {e}")

    def close_connection(self):
        """Closes the connection to the database."""
        if self.connection:
            self.connection.close()
            log.info("Database connection closed.")

if __name__ == '__main__':
    # --- Self-Test Block ---
    import datetime
    
    log.info("\n--- Testing Database Manager ---")
    
    db_manager = DatabaseManager(db_path=":memory:")
    
    entry_time_str = datetime.datetime.now().isoformat()
    pos = Position(
        symbol="TESTUSDT",
        direction="LONG",
        entry_price=100.0,
        quantity=1.0,
        stop_loss_price=99.0,
        entry_time=entry_time_str,
        position_id="test-pos-123"
    )
    
    entry_time = datetime.datetime.now().isoformat()
    exit_time = (datetime.datetime.now() + datetime.timedelta(minutes=5)).isoformat()
    db_manager.log_trade(pos, exit_price=101.0, pnl=1.0, entry_time=entry_time, exit_time=exit_time)
    
    cursor = db_manager.connection.cursor()
    cursor.execute("SELECT * FROM trades WHERE position_id = ?", ("test-pos-123",))
    row = cursor.fetchone()
    assert row is not None
    assert row[1] == "TESTUSDT"
    assert row[6] == 1.0
    
    db_manager.close_connection()
    
    log.info("\n--- Database Manager self-tests passed successfully! ---")
