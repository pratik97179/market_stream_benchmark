# Market Stream Benchmark

Does sending real-time market data as **Protobuf** instead of **JSON** make a
Flutter trading app better? This project measures it on a real trading screen
(option chain, 20-level market depth, live candles, watchlist) on real phones,
with a feed shaped like an Indian broker's.

**What I found** ([details and every number](FINDINGS.md)): Protobuf was 2–3×
faster to decode and 5–6× smaller on every phone. In a typical app, a busy feed
made a budget phone stutter with *either* format. Engineering changes took the
same phone from 13 to 58 fps without changing the format, and after that the
formats looked the same on screen. Protobuf's remaining advantage was less data
and less CPU.

| Redmi 9A (budget phone), ~4,000 messages/s | JSON | Protobuf |
|---|---|---|
| Typical app: decode on the UI thread | 13 fps | 14 fps |
| + decode on a background isolate, newest tick per instrument | 21 fps | 17 fps |
| + paint the busy tables instead of rebuilding widgets | 57 fps | 59 fps |

Don't take my word for it: run it on your own phones.

## Reproducing

### What you need

- Flutter (my runs used **3.47.9**; check with `flutter --version`)
- A **physical** phone. Simulators and emulators don't represent real phone
  performance, and profile builds don't run on simulators.
- Android: USB debugging on, phone connected by USB.
- iPhone: Xcode, the phone connected and trusted, signing set up (open
  `ios/Runner.xcworkspace` and pick your team under *Signing & Capabilities*),
  and the phone on the same Wi-Fi as your computer.

### Run it

```bash
git clone <this repo>
cd market_stream_benchmark
flutter pub get
flutter devices                      # find your phone's id
dart run tool/bench.dart -d <device-id> --variant all
```

This starts the feed server on your computer, connects the phone (`adb reverse`
over USB for Android, your LAN address for iPhone), builds the app in profile
mode, and runs the full suite for each app version. It prints progress and a
summary, and writes one folder per version to `results/`:

```
results/<date>_<device>_<variant>/
  REPORT.md          readable report: headline, environment, every configuration
  raw.jsonl          what the app measured, one line per run
  environment.json   device, OS, chip, Flutter version, connection, git commit
```

`results/README.md` is regenerated as an index of all runs, so your results sit
next to mine.

`--variant all` takes about 40 minutes (three versions × ~13 minutes, plus
builds). Useful options:

| Option | |
|---|---|
| `--variant <id>` | Run one version: `synthetic`, `broker-ui-thread`, `broker-isolate`, `broker-optimised` (default) |
| `--quick` | 1 round of 10 s instead of 5 × 20 s. A smoke test, not a result to publish |
| `--notes "..."` | Recorded in the report, e.g. battery level or thermal state |
| `--name`, `--chip` | Override the detected device name or chip |
| `--host <ip>` | Address the phone should use to reach your computer |

`dart run tool/bench.dart --help` lists everything.

**For results you can compare:** keep the phone plugged in and cool, close other
apps, don't touch it during the run, and leave the screen on. The runner records
what it can detect. Add anything else with `--notes`.

### What a run measures

Each version is run under three configurations: normal load (~200 messages/s,
100 instruments) and heavy load (~4,000 messages/s, 1,000 instruments) with the
live dashboard, plus heavy load with the UI frozen to isolate decoding. Each
configuration runs 5 rounds × 2 formats × 20 s, alternating which format goes
first, and the reports show medians.

| Variant | Feed | Decoding | Tables |
|---|---|---|---|
| `synthetic` | Small events batched per message | UI thread | Text widgets |
| `broker-ui-thread` | Sahi-shaped snapshots, one per message | UI thread | Text widgets |
| `broker-isolate` | Sahi-shaped snapshots | Background isolate, newest tick per instrument, one update per frame | Text widgets |
| `broker-optimised` | Sahi-shaped snapshots | Background isolate, as above | Painted from a glyph atlas |

Both formats get the identical, seeded message sequence. The JSON side of the
broker feed is the same ticks written as snake_case JSON with numeric paise,
since Sahi itself streams Protobuf only.

### Troubleshooting

- **iPhone can't reach the server.** The phone and computer must be on the same
  network. Pass `--host <your computer's IP>` if the detected address is wrong.
- **Port 8080 is busy.** Stop the other feed server (`tool/feed_server.dart`).

### Running by hand

You can also start the server and drive the app yourself:

```bash
dart run tool/feed_server.dart        # saves uploaded results to benchmark_results/
flutter run --profile --dart-define=SERVER_HOST=<your computer's IP>
```

Pick a version on the home screen and tap *Run JSON vs Protobuf*. For an
Android phone on USB, run `adb reverse tcp:8080 tcp:8080` and use the default
host (`127.0.0.1`). Turn a saved file into a report by putting it in a folder
as `raw.jsonl` and running `dart run tool/report.dart <folder>`.

## Project layout

```
tool/
  bench.dart              one-command benchmark runner
  report.dart             regenerates REPORT.md files and the results index
  feed_server.dart        standalone feed server
  src/                    server, feed generators, report rendering
proto/                    message schemas (synthetic and Sahi-shaped)
lib/
  app/                    app shell, home screen, server address
  features/trading/       benchmark harness, synthetic feed client and UI
  features/sahi/          broker feed: universe, JSON codec, background
                          isolate, per-instrument coalescing, store, dashboard
results/                  my runs (see results/README.md)
test/                     unit and widget tests
```

## Tests

```bash
flutter test
```

They cover the stores, both decoders (JSON and Protobuf produce identical
messages), the feed generator, that coalesced background updates give exactly
the same state as applying every message, and that dashboard rows redraw only
for instruments on screen, for both table versions.

## Regenerating protobuf code

Requires `protoc` and `dart pub global activate protoc_plugin`:

```bash
protoc --dart_out=lib/generated -Iproto proto/market.proto proto/sahi_marketdata.proto
rm lib/generated/*.pbjson.dart   # descriptor constants; the app doesn't use them
```
