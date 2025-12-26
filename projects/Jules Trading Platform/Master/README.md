# Jules' Intelligent Trading Bot - Project Guide

This document serves as a comprehensive guide to the architecture, features, and operation of the automated trading bot platform.

## 1. Project Overview

This project is a professional-grade, automated trading bot for the Binance exchange. It is designed to be **risk-aware, autonomous, and transparent**. The core philosophy is **"Survive first, grow later."**

The system is architected with several layers of intelligence:
- **Self-Healing:** The bot can recover from crashes and restarts without losing track of open trades.
- **Self-Learning:** The bot has tools to analyze its own performance and research better strategy configurations.
- **Adaptive:** The bot can analyze market conditions and adjust its strategy accordingly.
- **Transparent:** The bot's actions, performance, and history are fully visible through a comprehensive web-based user interface.

## 2. System Architecture

The project is organized into a modular structure to ensure a clean separation of concerns.

| Directory | Purpose |
| :--- | :--- |
| `analysis/` | Contains logic for market analysis, such as the Market Regime Filter. |
| `backtest/`| The backtesting engine for simulating strategy performance on historical data. |
| `config/` | *(Reserved for future use, e.g., static configuration files)* |
| `data/` | The `BinanceDataClient` for connecting to the exchange for market data. |
| `database/`| The `DatabaseManager` and the SQLite database (`trades.db`) for storing trade history. |
| `execution/`| Modules for executing and managing trades (`OrderExecutor`, `PositionManager`). |
| `live/` | The main `LiveTradingLoop`, which is the heart of the running bot. |
| `logs/` | Contains rotating log files that provide a persistent audit trail of the bot's actions. |
| `optimization/`| The `Optimizer` script for running strategy parameter research. |
| `risk/` | The `RiskManager`, which governs all position sizing and capital protection rules. |
| `strategy/` | The pluggable strategy framework, including the `VolatilityBreakoutStrategy`. |
| `ui/` | The terminal-based dashboard for a simple, real-time console view. |
| `webapp/` | The Flask web server and HTML templates for the multi-page Command & Analytics Center. |

## 3. How to Run the Application

The application is composed of several components that can be run independently.

### 3.1. Running the Full System (Demonstration)

This is the recommended way to see all features in action. You will need **two separate terminals**.

**In Terminal 1 - Start the Web Server:**
This command starts the Flask web server, which serves the Command & Analytics Center UI.
```bash
python3 -m webapp.server
```
*The server will be available at `http://127.0.0.1:8080`.*

**In Terminal 2 - Run the Demo Script:**
This script simulates the bot's trading activity, which populates the web dashboard with live data and generates trade history for the analytics pages.
```bash
python3 demo.py
```
*Once this is running, you can open your web browser to the address above to see the full UI in action.*

### 3.2. Running the Strategy Optimizer

To run the bot's self-learning research tool, execute the following command. This will run multiple backtests and generate the `optimization/results.json` file, which is then viewable on the "Optimizer" page of the web UI.
```bash
python3 -m optimization.optimizer
```

### 3.3. Running the Backtester

To run a single backtest with the default parameters, you can use the backtester script directly. This is useful for quickly evaluating a strategy idea.
```bash
python3 -m backtest.backtest_runner
```

## 4. Live Trading Configuration

To run the bot with real capital on the Binance exchange, you must configure your API credentials and set the bot to "live" mode.

**⚠️ WARNING: Live trading involves real financial risk. Always test your strategies and configurations in `DRY_RUN` mode before committing real capital.**

Follow these steps to enable live trading:

**Step 1: Create Your `.env` file**

The bot uses a `.env` file to manage sensitive information like API keys. This file is **not** committed to the repository for security reasons.

Make a copy of the example file and name it `.env`:
```bash
cp .env.example .env
```

**Step 2: Add Your Binance API Keys**

Open the new `.env` file in a text editor. You will see the following lines:
```
BINANCE_API_KEY="YOUR_API_KEY_HERE"
BINANCE_API_SECRET="YOUR_API_SECRET_HERE"
```
Replace `"YOUR_API_KEY_HERE"` and `"YOUR_API_SECRET_HERE"` with your actual Binance API key and secret.

**Step 3: Set the Bot to Live Mode**

In the same `.env` file, find the `DRY_RUN` variable and change its value from `"True"` to `"False"`:
```
# From:
DRY_RUN="True"

# To:
DRY_RUN="False"
```

**Step 4: Configure Your Trading Parameters**

You can also adjust other settings in the `.env` file:

| Variable | Description |
| :--- | :--- |
| `TRADING_UNIVERSE`| A comma-separated list of symbols to trade (e.g., "BTCUSDT,ETHUSDT"). |
| `RISK_PER_TRADE` | The percentage of capital to risk per trade (e.g., "0.01" for 1%). |
| `DAILY_LOSS_LIMIT`| A negative dollar value that acts as a kill-switch (e.g., "-25.0"). |

---
*This guide was generated by Jules, your AI Software Engineer.*
