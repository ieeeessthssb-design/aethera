"""Idempotent demo seed: 1 farmer, 1 expert, 1 farm, 1 device, 7 days of readings, cases."""
import asyncio, json, math, random
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.core.security import hash_password
from app.models import Device, ExpertCase, ExpertReview, Farm, Reading, User

CASES = [
    ("Ahmed (Demo)", "Tomato", "Nabeul", "Early blight (Alternaria solani)", 0.52, "Brown concentric spots on lower leaves, yellow halo", "pending"),
    ("Salma Trabelsi", "Olive", "Sfax", "Olive peacock spot (Spilocaea oleagina)", 0.48, "Dark circular spots on leaf upper side, leaf drop", "pending"),
    ("Mourad Jlassi", "Wheat", "Béja", "Possible yellow rust (Puccinia striiformis)", 0.41, "Yellow stripes along leaf veins after rain", "pending"),
    ("Hela Gharbi", "Potato", "Kairouan", "Late blight (Phytophthora infestans)", 0.58, "Water-soaked patches, white mold underside", "pending"),
    ("Karim Ayari", "Pepper", "Gabès", "Aphid infestation", 0.66, "Sticky leaves, curled young shoots", "confirmed"),
]


async def seed() -> None:
    async with AsyncSessionLocal() as db:
        if (await db.execute(select(User).where(User.email == "demo@aethera.tn"))).scalar_one_or_none():
            return
        farmer = User(name="Ahmed (Demo)", email="demo@aethera.tn", hashed_password=hash_password("123456"),
                      role="farmer", phone="+21698765432", region="Sfax")
        expert = User(name="Dr. Leila Ben Salah", email="expert@aethera.tn", hashed_password=hash_password("123456"),
                      role="expert", region="Tunis")
        db.add_all([farmer, expert]); await db.flush()
        farm = Farm(owner_id=farmer.id, name="Ferme Ben Ali", crop="Tomato", region="Sfax", lat=34.74, lng=10.76,
                    plant_age_days=45, irrigation_type="drip", area_hectares=1.5)
        db.add(farm); await db.flush()
        dev = Device(farm_id=farm.id, name="Parcelle Nord")
        db.add(dev); await db.flush()
        now = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
        rnd = random.Random(7)
        for h in range(7 * 24, -1, -1):
            t = now - timedelta(hours=h)
            x = t.timestamp() / 3600
            vals = {"soil_moisture": 40 + 18 * math.sin(x / 7) + rnd.random(),
                    "temperature": 26 + 7 * math.sin((x - 9) / 3.82) + rnd.random(),
                    "humidity": 58 + 14 * math.cos(x / 4.5) + rnd.random()}
            for m, v in vals.items():
                db.add(Reading(device_id=dev.id, farm_id=farm.id, metric=m, value=round(v, 1),
                               recorded_at=t, source="simulated"))
        for i, (n, crop, reg, diag, conf, sym, st) in enumerate(CASES):
            c = ExpertCase(farm_id=farm.id, farmer_name=n, crop=crop, region=reg, ai_diagnosis=diag,
                           ai_confidence=conf, symptoms=sym, original_question=sym,
                           ai_sources=json.dumps(["INRAT crop protection guide"]), status=st,
                           created_at=datetime.now(timezone.utc) - timedelta(hours=3 * i))
            db.add(c); await db.flush()
            if st == "confirmed":
                db.add(ExpertReview(case_id=c.id, expert_id=expert.id, expert_name=expert.name,
                                    decision="confirm", comment="Confirmed. Use insecticidal soap.",
                                    reviewed_at=datetime.now(timezone.utc)))
        await db.commit()


if __name__ == "__main__":
    asyncio.run(seed())
