import logging
from logging.handlers import RotatingFileHandler
import sys

# ---
# Note to the user:
# This module establishes a professional-grade logging system.
# Instead of using `print()`, which is temporary and unstructured, we use
# Python's built-in `logging` framework.
#
# Key features:
# - Structured Format: Each log message includes a timestamp, the module it came from,
#   the severity level (e.g., INFO, WARNING, ERROR), and the message itself.
# - File Output: Logs are saved to a file (`logs/trading_bot.log`), providing a
#   permanent record of the bot's activity for debugging and auditing.
# - Rotating Files: The `RotatingFileHandler` automatically manages log files,
#   creating new ones when they reach a certain size to prevent them from
#   becoming too large.
# - Console Output: Logs are simultaneously streamed to the console for real-time
#   visibility, but without cluttering the main dashboard UI.
# ---

def setup_logging():
    """
    Configures the centralized logging system for the application.
    """
    # Create a logger object
    logger = logging.getLogger()
    logger.setLevel(logging.INFO) # Set the minimum level of messages to capture

    # --- Formatter ---
    # Defines the structure of our log messages
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # --- Console Handler ---
    # To stream logs to the console
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(formatter)
    
    # --- File Handler ---
    # To write logs to a rotating file
    file_handler = RotatingFileHandler(
        'logs/trading_bot.log',
        maxBytes=1024 * 1024 * 5, # 5 MB per file
        backupCount=5 # Keep up to 5 old log files
    )
    file_handler.setFormatter(formatter)

    # Add both handlers to the logger
    # Check if handlers are already added to prevent duplication in some environments
    if not logger.handlers:
        logger.addHandler(stdout_handler)
        logger.addHandler(file_handler)
    
    return logger

# Initialize the logger for any module that imports this
log = setup_logging()

# Example usage (can be run directly to test)
if __name__ == '__main__':
    log.info("This is an informational message.")
    log.warning("This is a warning message.")
    log.error("This is an error message.")
    print("\nTest log messages have been generated in the console and written to 'logs/trading_bot.log'")