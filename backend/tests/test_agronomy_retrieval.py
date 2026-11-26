from app.services.agronomy_retrieval import retrieve_agronomy_context


def test_retrieval_returns_passages_with_source_and_page():
    passages, sources = retrieve_agronomy_context("olive irrigation water productivity", limit=3)
    assert passages
    assert sources
    assert all(p["citation"] and p["text"] for p in passages)


def test_retrieval_returns_empty_for_unmatched_query():
    passages, sources = retrieve_agronomy_context("zzzqqq xxyyww", limit=3)
    assert passages == []
    assert sources == []
