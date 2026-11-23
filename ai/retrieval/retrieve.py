"""Keyword retrieval (BM25) over ai/retrieval/chunks.json, no external packages.

    from ai.retrieval.retrieve import retrieve
    hits = retrieve("quand irriguer l'olivier en été ?", k=3)
    hits[0] -> {"source_id", "title", "year", "page", "text", "score", "citation"}

Arabic/Derja words are expanded to French + English keywords (EXPAND below),
because most Tunisian reports are in French. Returns [] when nothing matches:
callers must then say "no source found" instead of inventing one.
"""
import json, math, re, unicodedata
from collections import Counter
from pathlib import Path

INDEX = Path(__file__).resolve().parent / "chunks.json"
K1, B = 1.5, 0.75

# Derja / Arabic farming words -> French + English search terms (extend freely).
EXPAND = {
    "سقي": "irrigation irriguer arrosage", "نسقي": "irrigation irriguer", "ري": "irrigation",
    "زيتون": "olivier olive", "الزيتون": "olivier olive", "طماطم": "tomate tomato",
    "قمح": "ble wheat", "القمح": "ble wheat", "شعير": "orge barley", "بطاطا": "pomme terre potato",
    "ماء": "eau water", "الماء": "eau water", "تربة": "sol soil", "التربة": "sol soil",
    "جفاف": "secheresse drought deficit", "عطش": "stress hydrique water stress",
    "سخانة": "chaleur heat temperature", "حرارة": "chaleur heat temperature",
    "تنقيط": "goutte drip goutte-a-goutte", "قطرة": "goutte drip", "رطوبة": "humidite moisture soil",
    "مردود": "rendement yield", "ملوحة": "salinite salinity",
}
STOP = set("""le la les un une des de du et en au aux ce ces est sont que qui dans pour par sur
avec the a an of and or to in is are be for on with as by at from this that it its quand comment
quel quelle faut-il il y a ou what when how should i do""".split())

def norm(t):
    t = unicodedata.normalize("NFKD", t.lower())
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return t.replace("’", "'")

def stem(w):
    for suf in ("ement", "ations", "ation", "ing", "es", "s", "x"):
        if len(w) > len(suf) + 3 and w.endswith(suf):
            return w[: -len(suf)]
    return w

def tokens(text, expand=False):
    out = []
    for w in re.findall(r"[\w؀-ۿ-]+", norm(text)):
        if expand and w in EXPAND:
            out += [stem(x) for x in EXPAND[w].split()]
        elif w not in STOP and len(w) > 1:
            out.append(stem(w))
    return out

_idx = None
def _load():
    global _idx
    if _idx is None:
        chunks = json.loads(INDEX.read_text(encoding="utf-8"))
        toks = [Counter(tokens(c["text"])) for c in chunks]
        df = Counter(t for c in toks for t in c)
        avg = sum(sum(c.values()) for c in toks) / max(len(toks), 1)
        _idx = (chunks, toks, df, avg)
    return _idx

def retrieve(query, k=3):
    chunks, toks, df, avg = _load()
    q = tokens(query, expand=True)
    if not q:
        return []
    n, scored = len(chunks), []
    for i, tf in enumerate(toks):
        dl, s = sum(tf.values()), 0.0
        for t in set(q):
            if t in tf:
                idf = math.log(1 + (n - df[t] + 0.5) / (df[t] + 0.5))
                s += idf * tf[t] * (K1 + 1) / (tf[t] + K1 * (1 - B + B * dl / avg))
        if s > 0:
            scored.append((s, i))
    scored.sort(reverse=True)
    hits = []
    for s, i in scored[:k]:
        c = chunks[i]
        hits.append({**c, "score": round(s, 3),
                     "citation": f"{c['title']} ({c['year']}), p. {c['page']}"})
    return hits

if __name__ == "__main__":
    import sys
    for h in retrieve(" ".join(sys.argv[1:]) or "irrigation olivier", k=3):
        print(f"[{h['score']}] {h['citation']}\n    {h['text'][:200]}...\n")
