"""Build the retrieval index (task #33).  Run from the repo root:

    pip install pypdf
    python ai/retrieval/ingest.py

Reads ai/retrieval/docs_sources.csv, takes every row whose licence starts with
"CC BY" and whose PDF exists in ai/retrieval/docs/<id>.pdf, splits the text into
chunks (with page numbers) and writes ai/retrieval/chunks.json.
Documents with restricted licences are skipped on purpose, so no restricted text
is ever committed inside the index.
"""
import csv, json, re, sys
from pathlib import Path
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
DOCS = HERE / "docs"
OUT = HERE / "chunks.json"
CHUNK_CHARS, OVERLAP = 900, 150

def clean(t):
    t = t.replace("­", "").replace("\xa0", " ")
    t = re.sub(r"-\n(?=\w)", "", t)          # re-join hyphenated words at line ends
    t = re.sub(r"\s*\n\s*", " ", t)
    return re.sub(r"\s{2,}", " ", t).strip()

def split(text):
    out, start = [], 0
    while start < len(text):
        end = min(len(text), start + CHUNK_CHARS)
        if end < len(text):                   # cut at a sentence end when possible
            cut = text.rfind(". ", start + CHUNK_CHARS // 2, end)
            if cut != -1:
                end = cut + 1
        piece = text[start:end].strip()
        if len(piece) > 80:
            out.append(piece)
        if end >= len(text):
            break
        start = max(end - OVERLAP, start + 1)
    return out

def main():
    rows = list(csv.DictReader(open(HERE / "docs_sources.csv", encoding="utf-8-sig")))
    chunks, report = [], []
    for r in rows:
        doc_id, lic = r["id"].strip(), r["licence"].strip()
        pdf = DOCS / f"{doc_id}.pdf"
        if not lic.upper().startswith("CC BY"):
            report.append(f"skip  {doc_id}: licence not open ({lic[:40]}...)"); continue
        if not pdf.exists():
            report.append(f"skip  {doc_id}: {pdf.name} not found"); continue
        n_before = len(chunks)
        for page_no, page in enumerate(PdfReader(str(pdf)).pages, start=1):
            text = clean(page.extract_text() or "")
            for piece in split(text):
                chunks.append({"source_id": doc_id, "title": r["title"], "year": r["year"],
                               "language": r["language"], "page": page_no, "text": piece})
        report.append(f"index {doc_id}: {len(chunks) - n_before} chunks")
    OUT.write_text(json.dumps(chunks, ensure_ascii=False), encoding="utf-8")
    print(*report, sep="\n")
    print(f"\n{len(chunks)} chunks -> {OUT.relative_to(HERE.parent.parent)} ({OUT.stat().st_size/1e6:.1f} MB)")
    if not chunks:
        sys.exit("No chunks produced: check that the PDFs are in ai/retrieval/docs/")

if __name__ == "__main__":
    main()
