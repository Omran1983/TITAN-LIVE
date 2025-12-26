"""
JARVIS KNOWLEDGE AGENT
v1.0 - Core Intelligence Layer (Wikipedia + Finance)

Capabilities:
1. Search Wikipedia for definitions and summaries.
2. Fetch Real-time Market Data (Stocks, Forex) via Yahoo Finance.
3. (Future) RAG over local documents.
"""

import sys
import json
import logging
try:
    import wikipedia
    import yfinance as yf
except ImportError as e:
    logging.error(f"Missing libraries: {e}")
    # User needs: pip install wikipedia yfinance

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class KnowledgeBrain:
    def __init__(self):
        self.wiki_lang = "en"
        
    def query_wiki(self, topic, sentences=3):
        """Fetch summary from Wikipedia."""
        try:
            logging.info(f"Querying Wikipedia for: {topic}")
            summary = wikipedia.summary(topic, sentences=sentences)
            return {"source": "wikipedia", "topic": topic, "content": summary}
        except wikipedia.exceptions.DisambiguationError as e:
            return {"error": "Ambiguous topic", "options": e.options[:5]}
        except wikipedia.exceptions.PageError:
            return {"error": "Page not found"}
        except Exception as e:
            return {"error": str(e)}

    def get_market_data(self, ticker):
        """Fetch current price from Yahoo Finance."""
        try:
            logging.info(f"Fetching finance data for: {ticker}")
            stock = yf.Ticker(ticker)
            data = stock.history(period="1d")
            if not data.empty:
                latest = data.iloc[-1]
                return {
                    "source": "yahoo_finance",
                    "ticker": ticker,
                    "price": latest["Close"],
                    "volume": int(latest["Volume"]),
                    "currency": stock.info.get("currency", "USD")
                }
            else:
                return {"error": "No data found"}
        except Exception as e:
            return {"error": str(e)}

    def handle_command(self, cmd, arg):
        if cmd == "wiki":
            return self.query_wiki(arg)
        elif cmd == "finance":
            return self.get_market_data(arg)
        else:
            return {"error": "Unknown command. Use 'wiki' or 'finance'."}

if __name__ == "__main__":
    # Simple CLI Test: python jarvis_knowledge.py wiki "Artificial Intelligence"
    if len(sys.argv) < 3:
        print("Usage: python jarvis_knowledge.py [wiki|finance] [query]")
        sys.exit(1)
        
    mode = sys.argv[1]
    query = sys.argv[2]
    
    agent = KnowledgeBrain()
    result = agent.handle_command(mode, query)
    print(json.dumps(result, indent=2))
