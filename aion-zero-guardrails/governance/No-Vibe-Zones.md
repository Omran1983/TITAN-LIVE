# No-Vibe Zones
These areas MUST NOT be auto-patched or shipped without human review + tests:
- Cryptography, authentication, authorization
- Payments/invoicing processors, key management
- Database schema/migrations
- Trading core logic, position sizing, risk limits
- Any code handling secrets or PII/PCI
CI must block changes touching these paths from auto-merge.
