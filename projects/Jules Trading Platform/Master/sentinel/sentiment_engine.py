from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from agents.ollama_client import OllamaClient
import logging

# Configure logging
log = logging.getLogger(__name__)

class SentimentEngine:
    """
    Analyzes list of headlines and produces a 'Market Mood' score.
    Uses VADER (Rule-based) + Ollama (LLM) for deep context.
    Score Range: -1.0 (Extreme Fear) to +1.0 (Extreme Greed).
    """
    def __init__(self):
        self.analyzer = SentimentIntensityAnalyzer()
        self.ollama = OllamaClient()

    def analyze_sentiment(self, headlines):
        """
        Input: List of strings (headlines).
        Output: Float (-1.0 to 1.0)
        """
        if not headlines:
            return 0.0

        total_score = 0.0
        count = 0

        for headline in headlines:
            # Get compound score: -1 (Most Negative) to +1 (Most Positive)
            vs = self.analyzer.polarity_scores(headline)
            compound = vs['compound']
            
            # Simple weighting: Give more weight to extremely strong headlines
            if abs(compound) > 0.5:
                compound *= 1.2 # Amplify strong signals
            
            total_score += compound
            count += 1
            
            # Log significant news
            if abs(compound) > 0.4:
                log.debug(f"Significant News: '{headline}' | Score: {compound:.2f}")

        if count == 0:
            return 0.0

        # Normalize average to -1 to 1 range (clamping)
        avg_score = total_score / count
        vader_score = max(min(avg_score, 1.0), -1.0)
        
        # --- Phase 5a: Ollama Deep Analysis ---
        # We pick the top 5 most impacting headlines for the LLM to read
        # In a generic way, we just pass all 
        try:
            top_headlines = headlines[:5]
            prompt = f"Analyze market sentiment from these crypto news headlines: {top_headlines}. Return a float between -1.0 (Extreme Fear/Bad News) and 1.0 (Extreme Greed/Good News). Return ONLY the number."
            
            ai_resp = self.ollama.generate(prompt, system_prompt="You are a crypto sentiment analyst.")
            
            import re
            match = re.search(r"[-+]?\d*\.\d+|\d+", ai_resp)
            if match:
                ollama_score = float(match.group())
                ollama_score = max(min(ollama_score, 1.0), -1.0)
                
                # Weighted Average: 70% VADER (Fast/Consistent), 30% LLM (Context)
                final_score = (vader_score * 0.7) + (ollama_score * 0.3)
                log.info(f"Sentiment Fusion: VADER={vader_score:.2f}, Ollama={ollama_score:.2f} -> Final={final_score:.2f}")
                return final_score
        except Exception as e:
            log.warning(f"Ollama Sentiment Failed: {e}. Using VADER only.")
            
        final_score = vader_score

    def get_mood_label(self, score):
        """Returns a human-readable label for the UI."""
        if score >= 0.5: return "🚀 EUPHORIA"
        if score >= 0.2: return "🟢 BULLISH"
        if score >= -0.2: return "⚪ NEUTRAL"
        if score >= -0.5: return "🟠 BEARISH"
        return "🔴 EXTREME FEAR"
