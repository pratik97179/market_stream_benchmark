import 'package:flutter/widgets.dart';

import '../../../app/server_address.dart';
import 'trading_feed_client.dart';

/// One version of the app the benchmark can run. The broker-style variants
/// are the three rounds of the findings, in order.
enum BenchmarkVariant {
  /// Synthetic feed (`/trading/*`): small events batched per message,
  /// decoded on the UI thread.
  synthetic(
    'synthetic',
    'Synthetic Feed',
    'Small per-change events (quotes, trades, order-book levels, candles) '
        'batched into each message. Decoded on the UI thread.',
  ),

  /// Round 1: broker-style feed decoded on the UI thread, tables built from
  /// Text widgets.
  brokerUiThread(
    'broker-ui-thread',
    'Broker Feed · typical app',
    'Sahi-shaped ticks, one per message. Decoded on the UI thread; '
        'tables built from Text widgets.',
  ),

  /// Round 2: decoded on a background isolate, coalesced per instrument,
  /// one update per frame; tables still built from Text widgets.
  brokerIsolate(
    'broker-isolate',
    'Broker Feed · background decoding',
    'Decoded on a background isolate that keeps the newest tick per '
        'instrument and hands the UI one update per frame.',
  ),

  /// Round 3: as round 2, with the busy tables painted from a glyph atlas.
  brokerOptimised(
    'broker-optimised',
    'Broker Feed · optimised',
    'Background decoding plus painted tables: no widget rebuilds or text '
        'layout per frame.',
  );

  const BenchmarkVariant(this.id, this.title, this.description);

  /// Name used on the command line and in result files.
  final String id;
  final String title;
  final String description;

  bool get brokerFeed => this != synthetic;
  bool get decodeOnIsolate => this == brokerIsolate || this == brokerOptimised;
  bool get paintedTables => this == brokerOptimised;

  static BenchmarkVariant? byId(String id) {
    for (final variant in values) {
      if (variant.id == id) return variant;
    }
    return null;
  }
}

/// Timings for one received WebSocket message.
class TradingBatchMetrics {
  const TradingBatchMetrics({
    required this.eventCount,
    required this.payloadBytes,
    required this.decodeMicroseconds,
    required this.applyMicroseconds,
    this.decodeSamples,
    this.workerBusyMicroseconds,
    this.stalenessMicroseconds,
  });

  final int eventCount;
  final int payloadBytes;

  /// Total decode time for the [eventCount] events.
  final int decodeMicroseconds;

  /// UI-thread time to apply them to state.
  final int applyMicroseconds;

  /// Per-event decode times, when decoding happened elsewhere and arrives
  /// in bulk (background isolate).
  final List<int>? decodeSamples;

  /// Background-isolate time spent on these events (decode + coalescing).
  final int? workerBusyMicroseconds;

  /// How old the oldest event was when the UI applied it.
  final int? stalenessMicroseconds;
}

/// What the benchmark harness needs from a feed: connect with a decoder,
/// report per-message timings, and gate UI notifications.
abstract interface class BenchmarkFeedController {
  Stream<bool> get connectionUpdates;

  /// When false, messages update state but the UI is not notified
  /// (decode-only measurements). [flushUi] catches the UI up.
  bool get notifyUi;
  set notifyUi(bool value);

  Future<void> connect({
    required ServerAddress server,
    required TradingDecoder decoder,
    TradingLoad load = TradingLoad.normal,
    void Function(TradingBatchMetrics metrics)? onBatchMetrics,
    void Function(Object error, StackTrace stackTrace)? onBatchError,
  });

  Future<void> disconnect();

  Future<void> dispose();

  /// Notifies listeners of everything applied since the last notification.
  void flushUi();
}

/// The market panels for a feed, created once and reused by identity.
abstract interface class BenchmarkDashboard {
  List<Widget> panels({required bool wide});

  void dispose();
}
