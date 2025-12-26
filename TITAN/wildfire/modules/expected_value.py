def expected_value(outcomes: list) -> float:
    """
    Calculates Expected Value (EV) from a list of probabilistic outcomes.
    outcomes = [
        {"prob": 0.3, "gain": 200},
        {"prob": 0.5, "gain": 50},
        {"prob": 0.2, "gain": -20}
    ]
    Rule: If EV <= 0, action should be blocked.
    """
    total_ev = 0.0
    for o in outcomes:
        prob = float(o.get("prob", 0))
        gain = float(o.get("gain", 0))
        total_ev += prob * gain
    return total_ev
