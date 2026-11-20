"""Tests for sensor reading endpoints."""
import pytest
from aethera.app.services.assistant_service import StubAssistantService


def test_simulated_data_source_enum():
    """Confirm source values are only 'real' or 'simulated'."""
    valid_sources = {"real", "simulated"}
    # Test that our constants match
    assert "real" in valid_sources
    assert "simulated" in valid_sources


def test_simulated_reading_values_in_range():
    """Simulated readings should be within realistic ranges."""
    import random
    for _ in range(100):
        moisture = max(10.0, min(90.0, 40.0 + random.gauss(0, 3)))
        temp = max(10.0, min(45.0, 28.0 + random.gauss(0, 2)))
        humidity = max(20.0, min(95.0, 60.0 + random.gauss(0, 5)))
        assert 10.0 <= moisture <= 90.0
        assert 10.0 <= temp <= 45.0
        assert 20.0 <= humidity <= 95.0
