"""Container entrypoint that runs the existing, read-only firmware simulator."""
from __future__ import annotations

import importlib.util
import os
import sys
import time
from pathlib import Path

SCRIPT_PATH = Path("/opt/aethera/simulator.py")


def required(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def main() -> None:
    if not SCRIPT_PATH.is_file():
        raise FileNotFoundError(
            f"Simulator script was not mounted at {SCRIPT_PATH}. "
            "Check SIMULATOR_SCRIPT_PATH in the root .env file."
        )

    spec = importlib.util.spec_from_file_location("aethera_firmware_simulator", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load simulator script: {SCRIPT_PATH}")

    simulator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(simulator)

    # Configure the existing simulator at runtime; do not edit firmware source.
    simulator.BASE_URL = os.getenv("SIMULATOR_BASE_URL", "http://backend:8000").rstrip("/")
    simulator.DEVICE_ID = required("SIMULATOR_DEVICE_ID")
    simulator.DEVICE_KEY = required("SIMULATOR_DEVICE_KEY")
    simulator.INTERVAL_SECONDS = max(1, int(os.getenv("SIMULATOR_INTERVAL_SECONDS", "5")))
    simulator.SEND_SIMULATED_HEADER = True

    print(
        f"AETHERA simulator starting: device={simulator.DEVICE_ID}, "
        f"api={simulator.BASE_URL}, interval={simulator.INTERVAL_SECONDS}s",
        flush=True,
    )
    simulator.main()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Simulator startup failed: {exc}", file=sys.stderr, flush=True)
        raise
