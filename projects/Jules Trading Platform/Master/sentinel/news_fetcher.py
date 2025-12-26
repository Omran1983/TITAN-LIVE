import requests
import os
import random
import logging
from datetime import datetime, timedelta

# Configure logging
log = logging.getLogger(__name__)

class NewsFetcher:
    """
    Fetches crypto-related news from NewsAPI or returns simulated data if no key is provided.
    Designed for the 'Zero-budget' architecture.
    """
    def __init__(self, api_key=None):
        self.api_key = api_key
        self.base_url = "https://newsapi.org/v2/everything"
        self.simulation_mode = False
        
        if not self.api_key:
            log.warning("No NewsAPI Key provided. Switching to SIMULATION MODE.")
            self.simulation_mode = True

    def fetch_crypto_news(self, lookback_hours=24):
        """
        Fetches news for 'Bitcoin', 'Ethereum', 'Crypto', 'Regulation'.
        Fetches news for 'Bitcoin', 'Ethereum', 'Crypto', 'Regulation'.
        Returns a list of dicts: {'title', 'url', 'source', 'publishedAt'}
        """
        if self.simulation_mode:
            return self._generate_simulated_news()

        # Real API Call
        try:
            from_date = (datetime.now() - timedelta(hours=lookback_hours)).strftime('%Y-%m-%d')
            params = {
                'q': 'Bitcoin OR Ethereum OR Crypto OR SEC OR Regulation',
                'from': from_date,
                'sortBy': 'publishedAt',
                'language': 'en',
                'apiKey': self.api_key
            }
            response = requests.get(self.base_url, params=params)
            data = response.json()

            if data.get('status') != 'ok':
                log.error(f"NewsAPI Error: {data.get('message')}")
                return self._generate_simulated_news()

            headlines = []
            for article in data.get('articles', [])[:20]:
                headlines.append({
                    "title": article['title'],
                    "url": article['url'],
                    "source": article['source']['name'],
                    "publishedAt": article['publishedAt']
                })
            return headlines

        except Exception as e:
            log.error(f"Failed to fetch news: {e}")
            return self._generate_simulated_news()

    def _generate_simulated_news(self):
        """
        Returns fake headlines for testing/demo purposes.
        Mixes positive and negative news to test the engine.
        """
        log.info("Generating SIMULATED news headlines...")
        market_conditions = [
            "Bitcoin breaks $100k barrier as institutions flood in.",
            "SEC approves new crypto ETF, market rallies.",
            "Ethereum network upgrade lowers fees significantly.",
            "Major crypto exchange hack: 10,000 BTC stolen.",
            "Regulatory crackdown in EU fears cause market dip.",
            "Inflation data worse than expected, risk assets sell off.",
            "Analysts predict massive bull run for Solana.",
            "DeFi protocol suffers exploit, token dumps 50%.",
            "Fed signals rate cuts, bullish for crypto.",
            "Global uncertainty drives investors to safe havens like Gold and BTC."
        ]
        # Randomly pick 5-10 headlines
        return [
            {"title": h, "url": "#", "source": "Simulated Feed", "publishedAt": datetime.now().isoformat()} 
            for h in random.sample(market_conditions, k=random.randint(5, 8))
        ]
