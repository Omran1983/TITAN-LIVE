$env:ENV_FILE = ".env.testnet"
& .\.venv\Scripts\python.exe -m scripts.smoke_test
