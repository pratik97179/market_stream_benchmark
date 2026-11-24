# Benchmark runs

One folder per run: `REPORT.md` (readable), `raw.jsonl` (what the app measured) and `environment.json` (device, Flutter version, command). Regenerate the reports and this table with `dart run tool/report.dart`.

| Run | Device | App version | fps, heavy load (JSON / Protobuf) | Decode per message (JSON / Protobuf) | Size ratio |
|---|---|---|---|---|---|
| [2026-11-24T13-29_iphone-13_synthetic](2026-11-24T13-29_iphone-13_synthetic/REPORT.md) | iPhone 13 | synthetic | 48 / 50 | 12.3 µs / 4.1 µs | 5.0× |
| [2026-11-24T18-09_redmi-9a_synthetic](2026-11-24T18-09_redmi-9a_synthetic/REPORT.md) | Redmi 9A | synthetic | 28 / 34 | 43.4 µs / 15.0 µs | 5.0× |
| [2026-11-24T19-04_redmi-9a_broker-ui-thread](2026-11-24T19-04_redmi-9a_broker-ui-thread/REPORT.md) | Redmi 9A | broker-ui-thread | 13 / 14 | 56.5 µs / 21.9 µs | 6.1× |
| [2026-11-24T19-25_redmi-9a_broker-isolate](2026-11-24T19-25_redmi-9a_broker-isolate/REPORT.md) | Redmi 9A | broker-isolate | 21 / 17 | 63.2 µs / 31.5 µs | 6.1× |
| [2026-11-24T19-50_redmi-9a_broker-optimised](2026-11-24T19-50_redmi-9a_broker-optimised/REPORT.md) | Redmi 9A | broker-optimised | 57 / 59 | 56.0 µs / 28.2 µs | 6.1× |
| [2026-11-24T20-16_iphone-13_broker-optimised](2026-11-24T20-16_iphone-13_broker-optimised/REPORT.md) | iPhone 13 | broker-optimised | 60 / 60 | 16.4 µs / 6.0 µs | 6.1× |
