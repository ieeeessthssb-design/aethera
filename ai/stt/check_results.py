"""Consistency check for the FarukSTT test (task #35). No model, no GPU, no internet.

Run from the repo root:   python ai/stt/check_results.py
Needs: pip install pandas
"""
import math, re, sys, unicodedata
from pathlib import Path
import pandas as pd

HERE = Path(__file__).resolve().parent
CSV = HERE / "FarukSTT_experiments_A_B.csv"
AUDIO = HERE / "audio"

_VARIANTS = {"اليوم": "ليوم", "هاذي": "هذي", "هاذا": "هذا", "برشه": "برشا", "برشة": "برشا"}
_PUNCT = re.compile(r"[^\w\s]", re.UNICODE)

def normalize(text):
    t = unicodedata.normalize("NFKD", str(text or "")).lower()
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    t = t.replace("ـ", "")
    t = (t.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
           .replace("ى", "ي").replace("ة", "ه").replace("ؤ", "و").replace("ئ", "ي"))
    t = _PUNCT.sub(" ", t)
    return " ".join(_VARIANTS.get(w, w) for w in t.split())

def wer(ref, hyp):
    r, h = normalize(ref).split(), normalize(hyp).split()
    if not r:
        return 0.0 if not h else 1.0
    d = list(range(len(h) + 1))
    for i in range(1, len(r) + 1):
        prev, d[0] = d[0], i
        for j in range(1, len(h) + 1):
            cur = d[j]
            d[j] = min(d[j] + 1, d[j - 1] + 1, prev + (r[i - 1] != h[j - 1]))
            prev = cur
    return d[len(h)] / len(r)

def has_hebrew(text):
    return bool(re.search(r"[֐-׿]", str(text)))

problems = []
df = pd.read_csv(CSV, encoding="utf-8-sig")
if len(df) != 20:
    problems.append(f"expected 20 rows, found {len(df)}")
for col in ["id", "question_derja", "model_heard", "model_heard_ar", "wer", "wer_ar"]:
    if col not in df.columns:
        problems.append(f"missing column: {col}")
if problems:
    print("PROBLEMS:", *problems, sep="\n- "); sys.exit(1)

# 1) recompute WER from the texts and compare with the stored columns
for _, r in df.iterrows():
    for hyp, stored, tag in ((r.model_heard, r.wer, "A"), (r.model_heard_ar, r.wer_ar, "B")):
        if not str(hyp).strip() or str(hyp) == "nan":
            problems.append(f"{r.id}: empty transcript ({tag})")
        elif not math.isclose(wer(r.question_derja, hyp), stored, abs_tol=0.01):
            problems.append(f"{r.id}: stored WER {stored:.2f} != recomputed {wer(r.question_derja, hyp):.2f} ({tag})")

# 2) recordings present (if the audio folder is in the repo)
if AUDIO.exists():
    for i in df["id"]:
        if not list(AUDIO.glob(f"{i}.*")):
            problems.append(f"{i}: no audio file in {AUDIO.name}/")
else:
    print("note: audio/ folder not found, skipping audio check")

# 3) summary numbers (these must match the README)
A, B = df.wer.mean() * 100, df.wer_ar.mean() * 100
hebA = sum(has_hebrew(t) for t in df.model_heard)
hebB = sum(has_hebrew(t) for t in df.model_heard_ar)
better = int((df.wer_ar < df.wer - 1e-9).sum()); worse = int((df.wer_ar > df.wer + 1e-9).sum())
print(f"rows: {len(df)}")
print(f"mean WER  A: {A:.2f}%   B: {B:.2f}%   (relative change {(A - B) / A * 100:.1f}%)")
print(f"Hebrew letters  A: {hebA}/20   B: {hebB}/20")
print(f"B better: {better}   equal: {len(df) - better - worse}   worse: {worse}")
n, k = better + worse, min(better, worse)
p = min(1.0, 2 * sum(math.comb(n, i) for i in range(k + 1)) / 2 ** n) if n else 1.0
print(f"sign test p = {p:.2f}")
if "correct" in df.columns:
    done = df["correct"].astype(str).str.lower().isin(["yes", "no", "borderline"]).sum()
    print(f"meaning-level grades filled in: {done}/20")

print("\nPROBLEMS:" if problems else "\nOK: no problems found")
for p_ in problems: print("-", p_)
sys.exit(1 if problems else 0)
