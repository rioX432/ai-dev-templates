# IoT / Embedded Conventions

## General
- Memory-conscious: avoid unnecessary heap allocations
- Error handling: all hardware I/O must handle failure gracefully
- Logging: structured logs with severity levels

## Safety
- No unbounded loops without watchdog/timeout
- Validate all external input (serial, network, sensor data)
- Secrets (WiFi credentials, API keys) must not be hardcoded — use config files or environment
