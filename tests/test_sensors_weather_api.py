"""API tests for tasks 20 (sensor latest + history) and 21 (weather). No network: weather is faked."""
from datetime import datetime, timezone
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.routers import sensors as sensors_router
from app.routers import weather as weather_router
from app.services.locations import resolve_location
from app.services.weather_service import WeatherSnapshot


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:  # lifespan creates tables and seeds the demo farmer/farm
        yield c


def _login(client, email, password="123456"):
    r = client.post("/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}


@pytest.fixture(scope="module")
def farmer(client):
    h = _login(client, "demo@aethera.tn")
    return h, client.get("/farms/me", headers=h).json()["id"]


def test_latest_returns_all_metrics(client, farmer):
    h, fid = farmer
    r = client.get(f"/farms/{fid}/sensors/latest", headers=h)
    assert r.status_code == 200
    body = r.json()
    assert body["source"] in ("real", "simulated")
    assert all(body[k] is not None for k in ("soil_moisture", "temperature", "humidity"))


def test_history_ordering_and_limit(client, farmer):
    h, fid = farmer
    desc = client.get(f"/farms/{fid}/sensors/readings", params={"metric": "soil_moisture", "limit": 10}, headers=h).json()
    asc = client.get(f"/farms/{fid}/sensors/readings", params={"metric": "soil_moisture", "limit": 10, "order": "asc"}, headers=h).json()
    assert len(desc) == len(asc) == 10
    assert [r["timestamp"] for r in desc] == sorted([r["timestamp"] for r in desc], reverse=True)
    assert [r["timestamp"] for r in asc] == sorted([r["timestamp"] for r in asc])


def test_history_rejects_bad_input(client, farmer):
    h, fid = farmer
    assert client.get(f"/farms/{fid}/sensors/readings", params={"metric": "ph"}, headers=h).status_code == 422
    r = client.get(f"/farms/{fid}/sensors/readings",
                   params={"metric": "humidity", "from": "2026-11-20T10:00:00Z", "to": "2026-11-19T10:00:00Z"}, headers=h)
    assert r.status_code == 422


def test_history_time_window(client, farmer):
    h, fid = farmer
    r = client.get(f"/farms/{fid}/sensors/readings",
                   params={"metric": "temperature", "from": "2000-01-01T00:00:00Z", "to": "2000-01-02T00:00:00Z"}, headers=h)
    assert r.status_code == 200 and r.json() == []  # farm has data, none in that window


def test_other_users_farm_is_forbidden_expert_allowed(client, farmer):
    _, fid = farmer
    reg = client.post("/auth/register", json={"name": "Other", "email": "other-farmer@test.tn",
                                              "password": "123456", "role": "farmer"})
    h = _login(client, "other-farmer@test.tn") if reg.status_code in (200, 201, 409) else None
    assert client.get(f"/farms/{fid}/sensors/latest", headers=h).status_code == 403
    assert client.get(f"/farms/{fid}/weather", headers=h).status_code == 403
    assert client.get(f"/farms/{fid}/sensors/latest", headers=_login(client, "expert@aethera.tn")).status_code == 200


def test_unknown_farm_404_and_no_token_401(client, farmer):
    h, _ = farmer
    assert client.get("/farms/does-not-exist/sensors/latest", headers=h).status_code == 404
    assert client.get("/farms/x/sensors/latest").status_code in (401, 403)


def _snapshot():
    return WeatherSnapshot(
        fetched_at=datetime.now(timezone.utc), source="Open-Meteo", temp_now_c=30.0, temp_max_today_c=36.0,
        et0_today_mm=6.0, rain_yesterday_mm=0, rain_today_mm=0, rain_next_2d_mm=2.5, rain_prob_next_2d_pct=30,
        wind_kmh=11.0,
        daily=[{"date": "2026-11-20", "temp_max_c": 36, "temp_min_c": 21, "et0_mm": 6.0, "rain_mm": 0, "rain_prob_pct": 5}],
    )


def test_weather_endpoint(client, farmer, monkeypatch):
    h, fid = farmer
    seen = {}

    async def fake(lat, lng):
        seen["coords"] = (lat, lng)
        return _snapshot()

    monkeypatch.setattr(weather_router, "get_weather", fake)
    r = client.get(f"/farms/{fid}/weather", headers=h)
    assert r.status_code == 200
    b = r.json()
    assert b["location_source"] == "farm" and seen["coords"] == (34.74, 10.76)
    assert b["rain_next_2d_mm"] == 2.5 and b["daily"][0]["temp_min_c"] == 21


def test_weather_unavailable_is_503(client, farmer, monkeypatch):
    h, fid = farmer

    async def down(lat, lng):
        return None

    monkeypatch.setattr(weather_router, "get_weather", down)
    assert client.get(f"/farms/{fid}/weather", headers=h).status_code == 503


def test_sim_values_are_deterministic_and_in_range():
    ts = datetime(2026, 11, 20, 14, 30, tzinfo=timezone.utc)
    for m, lo, hi in (("soil_moisture", 10, 90), ("temperature", 10, 45), ("humidity", 20, 95)):
        a, b = sensors_router._sim_value(m, "farm-1", ts), sensors_router._sim_value(m, "farm-1", ts.replace(minute=5))
        assert a == b and lo <= a <= hi


def test_resolve_location():
    assert resolve_location(SimpleNamespace(lat=1.0, lng=2.0, region="Sfax")) == (1.0, 2.0, "farm")
    assert resolve_location(SimpleNamespace(lat=None, lng=None, region="Béja")) == (36.73, 9.18, "region")
    assert resolve_location(SimpleNamespace(lat=None, lng=None, region="صفاقس")) == (34.74, 10.76, "region")
    assert resolve_location(SimpleNamespace(lat=None, lng=None, region="Tunisia")) is None  # not Tunis
    assert resolve_location(SimpleNamespace(lat=None, lng=None, region=None)) is None
