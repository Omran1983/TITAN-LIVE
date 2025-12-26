import asyncio
import json
from datetime import datetime, timedelta
from database.database_manager import DatabaseManager
from logging_config import log
from .ollama_client import OllamaClient

class Strategist:
    """
    The 'Analyst' Agent.
    Runs in background. detailed post-game analysis of trades.
    """
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
        self.ollama = OllamaClient()
        self.last_run = datetime.min

    async def run_analysis(self):
        """
        Fetches recent trades and asks AI for improvement suggestions.
        """
        # In a real implementation, we would fetch from DB. 
        # For now, we mock fetching 'last 5 trades'.
        
        # mock_trades = self.db.get_recent_trades(limit=5) 
        mock_trades = [
            {"symbol": "SOLUSDT", "pnl": -15.0, "reason": "Stop Loss", "entry_time": "2023-10-27 10:00"},
            {"symbol": "BTCUSDT", "pnl": -50.0, "reason": "Stop Loss", "entry_time": "2023-10-27 12:00"},
            {"symbol": "ETHUSDT", "pnl": 10.0, "reason": "Take Profit", "entry_time": "2023-10-27 14:00"}
        ]
        
        # Calculate Win Rate
        wins = len([t for t in mock_trades if t['pnl'] > 0])
        total = len(mock_trades)
        if total == 0: return

        win_rate = (wins / total) * 100
        
        if win_rate < 40:
            log.info("Strategist: Win Rate is Low (%.2f%%). initiating AI Analysis...", win_rate)
            
            prompt = f"""
            Analyze these recent trades: {json.dumps(mock_trades)}
            The strategy is a Volatility Breakout.
            We are losing money. What parameter changes (Stop Loss, Lookback Period) would you suggest?
            Keep it brief.
            """
            
            suggestion = self.ollama.generate(prompt, system_prompt="You are a senior trading strategist.")
            
            log.info(f"Strategist AI Suggestion: {suggestion}")
            
            # Save suggestion to file
            with open("strategist_suggestions.log", "a") as f:
                f.write(f"[{datetime.now()}] {suggestion}\n")

    async def run_loop(self):
        log.info("Strategist Agent active.")
        while True:
            await self.run_analysis()
            # Run every 6 hours in reality, 1 min for demo
            await asyncio.sleep(600) 
