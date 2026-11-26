# AETHERA firmware workspace

This folder is reserved for the project's ESP32 and IoT sensor work. In the supplied source archive, the actual ESP32 firmware and wiring diagrams had not yet been added. The following directories are retained as placeholders:

- `firmware/src/` — intended location for ESP32 firmware source.
- `firmware/wiring/` — intended location for wiring diagrams and hardware documentation.
- `firmware/simulator/` — reserved for simulator-related assets or code.

The currently implemented simulator is `simulator.py` at this folder's root. It generates sample soil-moisture, temperature, and humidity readings and sends them to the backend device-reading endpoint. It requires the Python `requests` package. Configure a test device ID, device key, and API URL before running it. Do not send simulated readings to production unless they are explicitly identified as simulated.

`render.yaml` is a deployment blueprint that was present in this folder in the supplied archive. It is retained unchanged; verify its environment variable names and deployment settings against the backend before using it.
