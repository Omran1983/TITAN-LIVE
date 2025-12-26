def kpis(rows):
    if not rows: return {}
    Rs = [float(r.get("R",0)) for r in rows]
    wins = sum(1 for x in Rs if x>0)
    expR = sum(Rs)/len(Rs)
    winrate = wins/len(Rs)
    return {"expectancy_R": round(expR,3), "winrate": round(winrate,3)}
