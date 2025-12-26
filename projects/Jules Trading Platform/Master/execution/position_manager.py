import uuid
import json
from dataclasses import dataclass, asdict, field
from typing import Literal
from logging_config import log

# ---
# Note to the user:
# This module introduces the concept of "state" to our trading bot.
# ---

@dataclass
class Position:
    """
    A data class to represent a single, open trading position.
    """
    symbol: str
    direction: Literal['LONG', 'SHORT']
    entry_price: float
    quantity: float
    stop_loss_price: float
    entry_time: str # ISO format string
    
    trailing_stop_price: float = 0.0
    activation_price: float = 0.0

    position_id: str = field(default_factory=lambda: str(uuid.uuid4()))

class PositionManager:
    """
    Manages all open trading positions for the bot.
    """
    def __init__(self):
        """Initializes the Position Manager."""
        self.open_positions = {}
        log.info("Position Manager initialized.")

    def add_position(self, position: Position) -> bool:
        """
        Adds a new open position to the manager.
        """
        if position.position_id in self.open_positions:
            log.warning(f"Attempted to add a position with a duplicate ID: {position.position_id}")
            return False
        
        self.open_positions[position.position_id] = position
        log.info(f"Position added: {position.direction} {position.quantity} {position.symbol} "
                 f"(ID: {position.position_id})")
        return True

    def remove_position(self, position_id: str) -> Position | None:
        """
        Removes a position from the manager.
        """
        if position_id in self.open_positions:
            closed_position = self.open_positions.pop(position_id)
            log.info(f"Position removed: {closed_position.direction} {closed_position.symbol} "
                     f"(ID: {position_id})")
            return closed_position
        
        log.warning(f"Attempted to remove a non-existent position ID: {position_id}")
        return None

    def get_position(self, position_id: str) -> Position | None:
        """
        Retrieves a single position by its ID.
        """
        return self.open_positions.get(position_id)

    def get_all_positions(self) -> list[Position]:
        """
        Returns a list of all currently open positions.
        """
        return list(self.open_positions.values())

    def get_positions_by_symbol(self, symbol: str) -> list[Position]:
        """
        Returns a list of all open positions for a specific symbol.
        """
        return [p for p in self.open_positions.values() if p.symbol == symbol]

    def save_state(self, filepath: str):
        """
        Saves the current open positions to a JSON file.
        """
        try:
            with open(filepath, 'w') as f:
                data_to_save = {pid: asdict(pos) for pid, pos in self.open_positions.items()}
                json.dump(data_to_save, f, indent=4)
            log.info(f"Successfully saved state to {filepath}")
        except IOError as e:
            log.error(f"Error saving state to {filepath}: {e}")

    def load_state(self, filepath: str):
        """
        Loads open positions from a JSON file.
        """
        try:
            with open(filepath, 'r') as f:
                data_from_file = json.load(f)
                self.open_positions = {pid: Position(**data) for pid, data in data_from_file.items()}
            log.info(f"Successfully loaded {len(self.open_positions)} positions from {filepath}")
        except FileNotFoundError:
            log.info(f"State file not found at {filepath}. Starting with a clean state.")
        except (IOError, json.JSONDecodeError) as e:
            log.error(f"Error loading state from {filepath}: {e}. Starting fresh.")


if __name__ == '__main__':
    import datetime
    log.info("\n--- Testing Position Manager ---")
    
    manager = PositionManager()
    
    entry_time = datetime.datetime.now().isoformat()
    pos1 = Position("SOLUSDT", "LONG", 150.0, 0.5, 148.0, entry_time, 0.0, 0.0)
    manager.add_position(pos1)
    
    assert len(manager.get_all_positions()) == 1
    
    test_state_file = "test_positions.json"
    manager.save_state(test_state_file)
    
    new_manager = PositionManager()
    new_manager.load_state(test_state_file)
    assert len(new_manager.get_all_positions()) == 1
    retrieved_pos = new_manager.get_position(pos1.position_id)
    assert retrieved_pos.symbol == "SOLUSDT"
    
    import os
    os.remove(test_state_file)
    
    log.info("\n--- Position Manager self-tests, including state persistence, passed successfully! ---")
