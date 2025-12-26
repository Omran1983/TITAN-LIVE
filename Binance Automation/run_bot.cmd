@echo off
pushd "%~dp0"
".\.venv\Scripts\dotenv.exe" -f ".\.env.mainnet" run -- python -m autobot.agent >> "runtime\bot_streamlit.log" 2>&1
