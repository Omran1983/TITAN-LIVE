# Placeholder: implement walk-forward + time-series CV + costs/slippage
import json, sys, pathlib
out = pathlib.Path('out'); out.mkdir(exist_ok=True, parents=True)
(out / 'oos_metrics.json').write_text(json.dumps({"sharpe_oos": 0.0, "drawdown": 0.0}, indent=2))
print("Generated out/oos_metrics.json (placeholder)")
