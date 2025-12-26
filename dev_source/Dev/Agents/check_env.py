from dotenv import load_dotenv
import os
load_dotenv()
k = os.getenv('OPENAI_API_KEY','')
print('Loaded:', bool(k), 'Len:', len(k), 'Preview:', (k[:4] + '…') if k else '')
