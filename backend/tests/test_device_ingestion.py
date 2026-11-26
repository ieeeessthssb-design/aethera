"""Tests for POST /devices/{device_id}/readings (ESP32 ingestion, X-Device-Key auth)."""
from datetime import datetime, timedelta, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select

from app.core.database import AsyncSessionLocal
from app.main import app
from app.models import Device, Farm, Reading, User


@pytest.fixture
async def device():
    """Create a user, farm and device; return (device_id, device_key, farm_id)."""
    async with AsyncSessionLocal() as db:
        user = User(name="T", email=f"t{datetime.now().timestamp()}@x.tn",
                    hashed_password="x", role="farmer", region="Sfax")
        db.add(user)
        await db.flush()
        farm = Farm(owner_id=user.id, name="F", crop="Tomato", region="Sfax")
        db.add(farm)
        await db.flush()
        dev = Device(farm_id=farm.id, name="ESP32-test")
        db.add(dev)
        await db.commit()
        return dev.id, dev.device_key, farm.id


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


def _now():
    return datetime.now(timezone.utc).replace(microsecond=0)


async def _count(device_id):
    async with AsyncSessionLocal() as db:
        return (await db.execute(
            select(func.count()).select_from(Reading).where(Reading.device_id == device_id)
        )).scalar_one()


async def test_ingest_ok_stores_three_real_readings(client, device):
    dev_id, key, farm_id = device
    ts = _now().isoformat()
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key},
                          json={"soil_moisture": 42.5, "temperature": 28.3, "humidity": 65.0,
                                "recorded_at": ts})
    assert r.status_code == 201
    assert r.json()["inserted"] == 3
    async with AsyncSessionLocal() as db:
        rows = (await db.execute(select(Reading).where(Reading.device_id == dev_id))).scalars().all()
        assert {x.metric for x in rows} == {"soil_moisture", "temperature", "humidity"}
        assert all(x.source == "real" and x.farm_id == farm_id for x in rows)
        d = (await db.execute(select(Device).where(Device.id == dev_id))).scalar_one()
        assert d.last_seen_at is not None


async def test_missing_key_is_401(client, device):
    r = await client.post(f"/devices/{device[0]}/readings", json={"soil_moisture": 40})
    assert r.status_code == 401


async def test_wrong_key_is_401(client, device):
    r = await client.post(f"/devices/{device[0]}/readings",
                          headers={"X-Device-Key": "dev_k_nope"}, json={"soil_moisture": 40})
    assert r.status_code == 401
    assert await _count(device[0]) == 0


async def test_key_of_another_device_is_rejected(client, device):
    _, key, _ = device
    r = await client.post("/devices/not-this-device/readings",
                          headers={"X-Device-Key": key}, json={"soil_moisture": 40})
    assert r.status_code == 401


async def test_failed_sensor_null_metric_still_stores_the_others(client, device):
    dev_id, key, _ = device
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key},
                          json={"soil_moisture": 33.0, "temperature": None, "humidity": None})
    assert r.status_code == 201
    assert r.json()["inserted"] == 1
    assert await _count(dev_id) == 1


async def test_all_metrics_null_is_422(client, device):
    dev_id, key, _ = device
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key}, json={})
    assert r.status_code == 422
    assert await _count(dev_id) == 0


@pytest.mark.parametrize("payload", [
    {"soil_moisture": 120},      # > 100 %
    {"soil_moisture": -5},
    {"humidity": 101},
    {"temperature": 200},        # e.g. wrong unit or garbage
    {"temperature": -999},       # typical "sensor error" sentinel
])
async def test_out_of_range_values_rejected(client, device, payload):
    dev_id, key, _ = device
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key}, json=payload)
    assert r.status_code == 422
    assert await _count(dev_id) == 0


async def test_future_timestamp_rejected(client, device):
    dev_id, key, _ = device
    future = (_now() + timedelta(days=1)).isoformat()
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key},
                          json={"soil_moisture": 40, "recorded_at": future})
    assert r.status_code == 422


async def test_recorded_at_defaults_to_server_time(client, device):
    dev_id, key, _ = device
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key},
                          json={"soil_moisture": 40})
    assert r.status_code == 201
    got = datetime.fromisoformat(r.json()["recorded_at"].replace("Z", "+00:00"))
    if got.tzinfo is None:
        got = got.replace(tzinfo=timezone.utc)
    assert abs((datetime.now(timezone.utc) - got).total_seconds()) < 30


async def test_naive_timestamp_is_treated_as_utc(client, device):
    dev_id, key, _ = device
    ts = (_now() - timedelta(minutes=1)).replace(tzinfo=None).isoformat()  # no "Z"
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key},
                          json={"soil_moisture": 40, "recorded_at": ts})
    assert r.status_code == 201


async def test_retry_of_same_payload_is_not_duplicated(client, device):
    dev_id, key, _ = device
    body = {"soil_moisture": 40, "temperature": 25, "humidity": 55,
            "recorded_at": (_now() - timedelta(minutes=2)).isoformat()}
    first = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key}, json=body)
    second = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key}, json=body)
    assert first.json()["inserted"] == 3
    assert second.status_code == 201
    assert second.json()["inserted"] == 0 and second.json()["skipped"] == 3
    assert await _count(dev_id) == 3


async def test_simulator_source_is_stored_as_simulated(client, device):
    dev_id, key, _ = device
    r = await client.post(f"/devices/{dev_id}/readings", headers={"X-Device-Key": key},
                          json={"soil_moisture": 40, "source": "simulated"})
    assert r.status_code == 201
    async with AsyncSessionLocal() as db:
        row = (await db.execute(select(Reading).where(Reading.device_id == dev_id))).scalar_one()
        assert row.source == "simulated"