"""Run: python ai/retrieval/test_retrieval.py  (after ingest.py)"""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from retrieve import retrieve

CASES = [  # (question, expected source id in the top 3)
    ("olive irrigation Tunisia water productivity", "olive_tunisia_wp"),
    ("quand irriguer l'olivier en été", "olive_tunisia_wp"),
    ("crop coefficient evapotranspiration Kc", "fao56_rev1"),
    ("productivité de l'eau des cultures en Tunisie", "tunisia_wp"),
    ("وقتاش نسقي الزيتون", "olive_tunisia_wp"),
]
bad = 0
for q, expected in CASES:
    ids = [h["source_id"] for h in retrieve(q, k=3)]
    ok = expected in ids
    bad += not ok
    print("OK  " if ok else "FAIL", q, "->", ids)
print("nonsense query ->", retrieve("zzzqqq xxyyww", k=3))
sys.exit(1 if bad else 0)
