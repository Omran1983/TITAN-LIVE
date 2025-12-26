from dotenv import dotenv_values
v = dotenv_values('.env.mainnet')
for k in ('BINANCE_API_KEY','BINANCE_API_SECRET','BINANCE_BASE_URL'):
    s=v.get(k,'') or ''
    print(k, 'set=', bool(s), 'len=', len(s), 'head=', (s[:4] if s else ''))
