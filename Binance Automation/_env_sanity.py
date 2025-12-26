from dotenv import dotenv_values
import string
v = dotenv_values('.env.mainnet')
def chk(k):
    s=v.get(k,'') or ''
    print(k, 'set=', bool(s), 'len=', len(s), 'head=', (s[:4] if s else ''))
    if s:
        bad = [c for c in s if c not in (string.ascii_letters+string.digits+'-_')]
        print(' non-ascii-or-space? ', any(ord(c)>127 for c in s or ''), ' whitespace? ', any(c.isspace() for c in s or ''), ' oddchars? ', bool(bad))
for k in ('BINANCE_API_KEY','BINANCE_API_SECRET','BINANCE_BASE_URL'):
    chk(k)
