
"""Adapter for Task #33 agronomy BM25 index."""

from pathlib import Path
import sys
import logging

logger = logging.getLogger(__name__)

# Find the project root locally or inside the Docker container.
_REPO_ROOT = next(
    (
        parent
        for parent in Path(__file__).resolve().parents
        if (parent / "ai" / "retrieval" / "retrieve.py").is_file()
    ),
    None,
)

retrieve = None

if _REPO_ROOT is not None:
    if str(_REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(_REPO_ROOT))

    try:
        from ai.retrieval.retrieve import retrieve
    except ImportError:
        logger.exception("Unable to import the local BM25 retrieval module")
        retrieve = None


def retrieve_agronomy_context(question: str, limit: int = 3):
    """Return relevant prompt passages and their citations."""
    if not question or retrieve is None:
        return [], []

    hits = retrieve(question, k=limit)
    passages = []
    citations = []

    for hit in hits:
        text = str(hit.get("text", "")).strip()
        citation = str(hit.get("citation", "")).strip()

        if not text or not citation:
            continue

        passages.append({
            "citation": citation,
            "text": text[:1200],
        })

        if citation not in citations:
            citations.append(citation)

    return passages, citations
