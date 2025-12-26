from dotenv import load_dotenv, dotenv_values, find_dotenv
import os, pathlib

env_path = find_dotenv(usecwd=True)
print('Found .env at:', env_path or '(none)')
print('Exists:', os.path.exists(env_path) if env_path else False)

vals = dotenv_values(env_path) if env_path else {}
print('Keys in file:', list(vals.keys()))

loaded = load_dotenv(env_path, override=True)
k = os.getenv('OPENAI_API_KEY','')
print('Loaded flag:', loaded, 'HasKey:', bool(k), 'Len:', len(k), 'Preview:', (k[:4] + '…') if k else '')
