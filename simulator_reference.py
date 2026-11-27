"""AETHERA - sensor simulator (task 13)

Sends fake readings to  POST /devices/{device_id}/readings  exactly like the
ESP32 does (same JSON body, same X-Device-Key header, as in the OpenAPI file).

Install:  pip install requests
Run:      python simulator.py            (one reading every few seconds)
          python simulator.py --once     (send one reading and stop)

WARNING: do not point this at the shared production database until the team
has decided how simulated data is flagged. Otherwise fake readings look real.
"""
import argparse
import math
import random
import time
from datetime import datetime, timezone

import requests

# ---------------- SETTINGS: change these ----------------
BASE_URL = "http://localhost:8000"   # production: https://aethera-backend.onrender.com
DEVICE_ID = "00000000-0000-0000-0000-000000000000"   # UUID of a TEST device
DEVICE_KEY = "***"               # shown only once when the device is created
INTERVAL_SECONDS = 5

# Extra header, NOT in the contract. The backend ignores it unless the team
# decides to use it to flag simulated data. Confirm with the backend squad.
SEND_SIMULATED_HEADER = True
# --------------------------------------------------------

DRY_LIMIT = 20.0          # below this soil %, simulate a watering
AFTER_WATERING = 70.0     # soil % right after watering (the value jumps)

state = {"soil": 45.0, "step": 0}


def next_reading():
    """Build one fake reading. Values change smoothly, like a real field."""
    state["step"] += 1

    # Soil slowly dries. When too dry, a watering event makes it jump up.
    state["soil"] -= random.uniform(0.5, 1.2)
    if state["soil"] < DRY_LIMIT:
        state["soil"] = AFTER_WATERING
        print(">>> watering event: soil moisture jumps up")

    # Air temperature: slow wave around 26 C, with a little noise.
    temperature = 26 + 4 * math.sin(state["step"] / 20) + random.uniform(-0.2, 0.2)
    # Air humidity moves in the opposite direction of the temperature.
    humidity = 60 - 1.5 * (temperature - 26) + random.uniform(-0.5, 0.5)

    return {
        "soil_moisture": round(max(0.0, min(100.0, state["soil"])), 1),
        "temperature": round(temperature, 1),
        "humidity": round(max(0.0, min(100.0, humidity)), 1),
        "recorded_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


def send(reading):
    url = f"{BASE_URL}/devices/{DEVICE_ID}/readings"
    headers = {"X-Device-Key": DEVICE_KEY}
    if SEND_SIMULATED_HEADER:
        headers["X-Simulated"] = "true"
    try:
        response = requests.post(url, json=reading, headers=headers, timeout=10)
        print(response.status_code, reading, response.text)
    except requests.RequestException as error:
        print("Send failed:", error)


def main():
    parser = argparse.ArgumentParser(description="AETHERA sensor simulator")
    parser.add_argument("--once", action="store_true", help="send one reading and stop")
    args = parser.parse_args()

    if args.once:
        send(next_reading())
        return

    print(f"Sending a reading every {INTERVAL_SECONDS} s to {BASE_URL}. Ctrl+C to stop.")
    while True:
        send(next_reading())
        time.sleep(INTERVAL_SECONDS)


if __name__ == "__main__":
    main()