# Findings: JSON vs Protobuf on a live trading UI

These are the results I measured, on the devices and setup below. Every number
links to the run it came from in [`results/`](results/README.md); each run
folder has a readable report, the raw measurements and the recorded
environment. To check them on your own phones, see
[Reproducing](README.md#reproducing).

## Summary

**Protobuf makes the app cheaper to run, not smoother.**

1. **Protobuf saves data and CPU.** For the same feed it used 84 % less data
   (6× smaller messages), decoded each message 2–2.7× faster and spent 39–55 %
   less CPU on decoding. This held on every phone, feed and load tested.
2. **It did not change how smooth the app was.** Switching format moved the frame
   rate by 1–2 fps. In a typical app a busy feed made a budget phone stutter at
   13–14 fps with *either* format.
3. **How the app was built decided smoothness.** Decoding in the background and
   drawing the busy tables cheaply took the same phone from 13 to ~58 fps, with
   either format.

## Test environment

| | |
|---|---|
| Phones | Redmi 9A (MediaTek Helio G25, Android 10, 60 Hz), a budget phone · iPhone 13 (A15, iOS 27.2.1, 60 Hz) |
| Build | Flutter 3.47.9 (Dart 3.13.7), profile mode, Impeller |
| Server | `tool/feed_server.dart` on a Mac (macOS 27.2). Redmi over USB (`adb reverse`), iPhone over Wi-Fi |
| Suite | Per variant: normal and heavy load with the live UI, plus heavy load with the UI frozen; 5 rounds × 2 formats × 20 s each, format order alternating. Values are medians. |

**The broker-style feed** (used for the main results) copies the message shapes
of [Sahi's public tick stream](https://docs.sahi.com/api/v1/reference/market-data/):
`LtpTick`, `QuoteTick` and `DepthTick` (5 or 20 depth levels), with Sahi's field
names and numbers (`proto/sahi_marketdata.proto`). Every message is a full
snapshot of one instrument, one per WebSocket message, prices in paise. The
universe is 1,000 instruments (indices, NIFTY futures, 300 stocks, 96 stock
futures, a 300-strike NIFTY option chain), and liquid instruments tick more
often.

| Load | Instruments | Messages per second |
|---|---|---|
| Normal (a watchlist) | 100 | ~200 |
| Heavy (expiry-day stress) | 1,000 | ~4,000 |

Sahi streams Protobuf only, so the JSON side is the same ticks written the way a
REST API would (snake_case keys, numeric paise). Both decode into the same
objects, and both formats receive the identical, seeded tick sequence.

## 1. What Protobuf saves

The optimised app at heavy load (1,000 instruments, ~4,000 messages per second):

| | JSON | Protobuf | Protobuf saves |
|---|---|---|---|
| Data received | 1.07 MB/s (3.8 GB/hour) | 0.17 MB/s (0.6 GB/hour) | 84 % less data |
| Decode per message, [Redmi 9A](results/2026-11-24T19-50_redmi-9a_broker-optimised/REPORT.md) | 56.0 µs | 28.2 µs | 2.0× faster |
| Decode per message, [iPhone 13](results/2026-11-24T20-16_iphone-13_broker-optimised/REPORT.md) | 16.4 µs | 6.0 µs | 2.7× faster |
| CPU spent decoding (share of one core), Redmi 9A | 26.5 % | 16.1 % | 39 % less |
| CPU spent decoding (share of one core), iPhone 13 | 7.5 % | 3.4 % | 55 % less |
| Tick age when shown, p99, Redmi 9A | 32 ms | 28 ms | 4 ms sooner |

At normal load (a 100-instrument watchlist, ~200 messages per second) it is
202 MB vs 32 MB of data per hour. In practice: less mobile data, less battery
drain and heat, and headroom for more instruments.

The saving is consistent across every run, phone and feed shape:

| Run | Decode per message, JSON / Protobuf | Size per message, JSON / Protobuf |
|---|---|---|
| [iPhone 13, synthetic feed](results/2026-11-24T13-29_iphone-13_synthetic/REPORT.md) | 12.3 / 4.1 µs (3.0×) | 162 / 32 B (5.0×) |
| [Redmi 9A, synthetic feed](results/2026-11-24T18-09_redmi-9a_synthetic/REPORT.md) | 43.4 / 15.0 µs (2.9×) | 162 / 32 B (5.0×) |
| [Redmi 9A, broker feed](results/2026-11-24T19-04_redmi-9a_broker-ui-thread/REPORT.md) | 56.5 / 21.9 µs (2.6×) | 267 / 43 B (6.1×) |
| [iPhone 13, broker feed](results/2026-11-24T20-16_iphone-13_broker-optimised/REPORT.md) | 16.4 / 6.0 µs (2.7×) | 267 / 43 B (6.1×) |

Heavy load. The ratio held in every round of every run.

## 2. What Protobuf doesn't change: smoothness

### A typical app stutters with either format

[Redmi 9A, broker feed, decoded on the UI thread](results/2026-11-24T19-04_redmi-9a_broker-ui-thread/REPORT.md)
(variant `broker-ui-thread`), heavy load:

| | JSON | Protobuf |
|---|---|---|
| Frames per second | 13 | 14 |
| Frames that missed the deadline | 99 % | 99.6 % |
| UI thread time spent decoding | 23 % | 9 % |
| UI thread still busy when a frame was due, p95 | 23.6 ms | 8.7 ms |

JSON's decoding kept the UI thread busy longer, but neither format was usable:
the UI thread also handled 4,000 separate messages per second and rebuilt the
busy tables every frame. At normal load the two formats were identical (8.8 %
of frames missed the deadline with each).

### Engineering made it smooth, with either format

The same phone, feed and load, through three versions of the app:

| Variant | What changed | JSON fps | Protobuf fps |
|---|---|---|---|
| [`broker-ui-thread`](results/2026-11-24T19-04_redmi-9a_broker-ui-thread/REPORT.md) | Typical app: decode on the UI thread | 13 | 14 |
| [`broker-isolate`](results/2026-11-24T19-25_redmi-9a_broker-isolate/REPORT.md) | Decode on a background isolate; keep only the newest tick per instrument; one update to the UI per frame | 21 | 17 |
| [`broker-optimised`](results/2026-11-24T19-50_redmi-9a_broker-optimised/REPORT.md) | Also paint the option chain, depth and watchlist from a glyph atlas, with no widget rebuilds or text layout per frame | **57** | **59** |

**Read across a row for the format, down a column for the engineering.** The
format moves fps by a few frames in either direction; the engineering moves it
from 13 to ~58. In the last two rows decoding is no longer on the UI thread, so
the format cannot directly affect frames. The small differences there, such as
21 vs 17, are noise and sometimes favour JSON, most likely because the busier
JSON worker keeps the CPU clocked higher, which also speeds up drawing.

- **Background decoding** removed the format from the UI thread entirely: the
  time a frame waited for the UI thread fell to ~1.2 ms for both formats. Frames
  were still slow because building ~250 changing Text widgets took 33–43 ms per
  frame on this chip.
- **Painted tables** cut frame build time to ~5 ms. The remaining slow frames come
  from the GPU (raster p95 16.4–17.3 ms against a 16.7 ms budget), which no data
  format can change.

On the [iPhone 13](results/2026-11-24T20-16_iphone-13_broker-optimised/REPORT.md)
the optimised app rendered 60 fps with 0 % missed frames for both formats, using
about 2 ms of the 16.7 ms frame budget.

## Caveats

- **The Redmi's GPU is at its limit even at normal load.** In the
  `broker-optimised` run, 16–18 % of frames missed the deadline at ~200
  messages/s with either format (raster p95 17.4 ms). That is the phone, not the
  data.
- **The Redmi throttles.** After the first round it runs about 2.4× slower; decode
  time, a pure CPU measure, slows by the same factor. Formats alternate within
  each round, so both are affected equally and the ratios stay stable. Reports
  flag it under *Checks*.
- **The broker-style feed is synthetic data.** It copies Sahi's documented message
  shapes; it is not live market data. The JSON variant is my own encoding.
- **Battery was not measured directly**; it is inferred from CPU time.
- **No 120 Hz screens were tested.**
