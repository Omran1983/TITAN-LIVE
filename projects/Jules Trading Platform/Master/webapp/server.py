from flask import Flask, render_template, jsonify
import json
import sqlite3
import pandas as pd
import os
from finance.ledger import LedgerManager

app = Flask(__name__)

DATABASE_PATH = 'database/trades.db'

# ---
# Note to the user:
# This is a simple web server using the Flask framework.
# Its purpose is to serve the HTML dashboard and provide a JSON API endpoint
# for the frontend to fetch real-time data from the bot.
# ---

@app.route('/')
def index():
    """Serves the main dashboard HTML page."""
    return render_template('index.html')

@app.route('/trade_log')
def trade_log_page():
    """Serves the trade history page."""
    return render_template('trade_log.html')

@app.route('/analytics')
def analytics_page():
    """Serves the analytics dashboard page."""
    return render_template('analytics.html')

@app.route('/optimizer')
def optimizer_page():
    """Serves the optimizer results page."""
    return render_template('optimizer.html')

@app.route('/api/status')
def api_status():
    """
    Provides the bot's status as a JSON object.
    It reads the state files that the bot writes to.
    """
    try:
        # We will create this file in the next step
        with open('live/dashboard_state.json', 'r') as f:
            dashboard_data = json.load(f)
    except FileNotFoundError:
        dashboard_data = {"status": "NOT RUNNING", "pnl": 0, "market_data": {}}
    except (IOError, json.JSONDecodeError):
        dashboard_data = {"status": "ERROR READING STATE", "pnl": 0, "market_data": {}}

    try:
        with open('live/bot_state.json', 'r') as f:
            positions_data = json.load(f)
            # The file stores positions as a dict of dicts, we need a list
            dashboard_data['positions'] = list(positions_data.values())
    except FileNotFoundError:
        dashboard_data['positions'] = []
    except (IOError, json.JSONDecodeError):
        dashboard_data['positions'] = []
        
    return jsonify(dashboard_data)

@app.route('/api/decision_log')
def get_decision_log():
    """Returns the last 50 entries from the Black Box recorder."""
    log_file = "live/decision_log.jsonl"
    entries = []
    try:
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                # Read last 50 lines efficiently
                lines = f.readlines()[-50:]
                for line in lines:
                    try:
                        entries.append(json.loads(line))
                    except: pass
        return jsonify(entries)
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route('/api/council')
def get_council_status():
    """Returns the health status of the Council of Agents."""
    # aggregated view, potentially reading from multiple health files
    # For now, we already pipe this into 'dashboard_state.json', 
    # but this endpoint can be used for more detailed logs per agent later.
    return jsonify({"status": "ACTIVE"}) 

@app.route('/api/trade_history')
def trade_history():
    """Provides the full trade history from the database."""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        # Use pandas for easy conversion to a list of dicts
        df = pd.read_sql_query("SELECT * FROM trades ORDER BY entry_time DESC", conn)
        conn.close()
        return jsonify(df.to_dict(orient='records'))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/analytics_summary')
def analytics_summary():
    """Provides processed analytics data for charting."""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        df = pd.read_sql_query("SELECT * FROM trades ORDER BY exit_time ASC", conn)
        conn.close()
        
        if df.empty:
            return jsonify({
                "equity_curve": [], "win_loss_count": [0, 0], 
                "pnl_histogram": {"labels": [], "data": []}
            })

        # --- Equity Curve ---
        df['cumulative_pnl'] = df['pnl'].cumsum()
        equity_curve = df[['exit_time', 'cumulative_pnl']].to_dict(orient='records')

        # --- Win/Loss Count ---
        win_count = int((df['pnl'] > 0).sum())
        loss_count = int((df['pnl'] <= 0).sum())

        # --- PnL Histogram ---
        pnl_bins = pd.cut(df['pnl'], bins=10)
        pnl_histogram_data = df['pnl'].groupby(pnl_bins).count()
        
        # Format for Chart.js
        pnl_histogram = {
            "labels": [str(interval) for interval in pnl_histogram_data.index],
            "data": pnl_histogram_data.values.tolist()
        }

        return jsonify({
            "equity_curve": equity_curve,
            "win_loss_count": [win_count, loss_count],
            "pnl_histogram": pnl_histogram
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/ledger')
def get_ledger_statement():
    """Provides full financial ledger history."""
    try:
        manager = LedgerManager() # Connects to data/ledger.csv
        history = manager.get_history()
        summary = manager.get_summary()
        return jsonify({"history": history, "summary": summary})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/optimizer_results')
def optimizer_results():
    """Provides the latest optimization results from the JSON file."""
    try:
        with open('optimization/results.json', 'r') as f:
            results = json.load(f)
        return jsonify(results)
    except FileNotFoundError:
        return jsonify([]) # Return empty list if no results exist yet
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Running in debug mode is convenient for development.
    # For a real deployment, you would use a production-grade server like Gunicorn.
    app.run(debug=True, port=8081)