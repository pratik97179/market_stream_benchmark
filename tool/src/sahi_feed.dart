import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'server.dart' show serverLog;

import 'package:market_stream_benchmark/features/sahi/data/sahi_json_codec.dart';
import 'package:market_stream_benchmark/features/sahi/domain/sahi_universe.dart';
import 'package:market_stream_benchmark/generated/sahi_marketdata.pb.dart';

/// Per-connection tick generator shaped like Sahi's tick stream: every tick
/// is a full snapshot of one instrument at its subscribed mode.
///
/// The sequence is seeded and depends only on the subscription, so a JSON
/// and a Protobuf connection with the same subscription receive exactly the
/// same ticks in the same order.
class SahiTickGenerator {
  SahiTickGenerator(Map<int, Mode> modes, {required this.ticksPerSecond})
    : _random = Random(42) {
    final universe = SahiUniverse();
    // Stable order (by id) so the sequence never depends on map order.
    final ids = modes.keys.toList()..sort();
    var total = 0.0;
    for (final id in ids) {
      final info = universe.byId[id];
      if (info == null) continue;
      _subscribed.add(
        _LiveInstrument(
          info,
          modes[id]!,
          prevOi: 50000 + _random.nextInt(5000000),
        ),
      );
      total += info.tickWeight;
      _cumulativeWeights.add(total);
    }
  }

  final int ticksPerSecond;
  final Random _random;
  final List<_LiveInstrument> _subscribed = [];
  final List<double> _cumulativeWeights = [];

  /// Simulated exchange clock: 2026-11-24 09:15:00 IST, in epoch ms.
  static const int _sessionStartMs = 1795496700000;
  int _ticksGenerated = 0;

  bool get isEmpty => _subscribed.isEmpty;

  _LiveInstrument _pick() {
    final target = _random.nextDouble() * _cumulativeWeights.last;
    var low = 0;
    var high = _cumulativeWeights.length - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_cumulativeWeights[mid] < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return _subscribed[low];
  }

  ServerMessage next() {
    final live = _pick();
    final info = live.info;
    final nowMs = _sessionStartMs + _ticksGenerated++ * 1000 ~/ ticksPerSecond;

    // Random walk in exchange tick sizes, never below one tick.
    live.ltp = max(
      SahiUniverse.tickSize,
      live.ltp + (_random.nextInt(7) - 3) * SahiUniverse.tickSize,
    );
    if (!info.isIndex) {
      live.volume += (1 + _random.nextInt(40)) * (info.isDerivative ? 75 : 1);
      if (info.isDerivative) {
        live.oi = max(0, live.oi + (_random.nextInt(21) - 10) * 75);
      }
    }

    final segment = info.segment;
    final type = info.type;
    final price = Int64(live.ltp);
    final time = info.isIndex ? null : Int64(nowMs);

    switch (live.mode) {
      case Mode.MODE_DEPTH:
        final tick = DepthTick(
          instrumentId: Int64(info.id),
          exchangeSegment: segment,
          instrumentType: type,
          lastTradePrice: price,
          lastTradeTime: time,
          volumeToday: Int64(live.volume),
          dprUpper: Int64(live.dprUpper),
          dprLower: Int64(live.dprLower),
          prevOpenInterest: info.isDerivative ? Int64(live.prevOi) : null,
          openInterest: info.isDerivative ? Int64(live.oi) : null,
        );
        _fillBook(tick, live);
        return ServerMessage(depthTick: tick);
      case Mode.MODE_QUOTE:
        return ServerMessage(
          quoteTick: QuoteTick(
            instrumentId: Int64(info.id),
            exchangeSegment: segment,
            instrumentType: type,
            lastTradePrice: price,
            lastTradeTime: time,
            volumeToday: Int64(live.volume),
            dprUpper: Int64(live.dprUpper),
            dprLower: Int64(live.dprLower),
            prevOpenInterest: info.isDerivative ? Int64(live.prevOi) : null,
            openInterest: info.isDerivative ? Int64(live.oi) : null,
          ),
        );
      default:
        return ServerMessage(
          ltpTick: LtpTick(
            instrumentId: Int64(info.id),
            exchangeSegment: segment,
            instrumentType: type,
            lastTradePrice: price,
            lastTradeTime: time,
          ),
        );
    }
  }

  /// Fills only the levels holding orders (never zero-padded): liquid
  /// instruments show their full 5 or 20 levels, thin ones fewer.
  void _fillBook(DepthTick tick, _LiveInstrument live) {
    final maxLevels = live.info.depthLevels;
    final lot = live.info.isDerivative ? 75 : 1;
    int levels() =>
        live.info.tickWeight >= 1 ? maxLevels : 1 + _random.nextInt(maxLevels);

    var buyTotal = 0;
    final bestBid = live.ltp - SahiUniverse.tickSize;
    for (
      var i = 0, n = levels();
      i < n && bestBid - i * SahiUniverse.tickSize > 0;
      i++
    ) {
      final qty = (1 + _random.nextInt(400)) * lot;
      buyTotal += qty;
      tick.bestBuys.add(
        DepthLevel(
          price: Int64(bestBid - i * SahiUniverse.tickSize),
          qty: Int64(qty),
          numOrders: Int64(1 + _random.nextInt(60)),
        ),
      );
    }
    var sellTotal = 0;
    for (var i = 0, n = levels(); i < n; i++) {
      final qty = (1 + _random.nextInt(400)) * lot;
      sellTotal += qty;
      tick.bestSells.add(
        DepthLevel(
          price: Int64(live.ltp + i * SahiUniverse.tickSize),
          qty: Int64(qty),
          numOrders: Int64(1 + _random.nextInt(60)),
        ),
      );
    }
    // Totals cover the whole book, not just the visible levels.
    tick
      ..totalBuyQty = Int64(buyTotal * (3 + _random.nextInt(8)))
      ..totalSellQty = Int64(sellTotal * (3 + _random.nextInt(8)));
  }
}

class _LiveInstrument {
  _LiveInstrument(this.info, this.mode, {required this.prevOi})
    : ltp = info.prevClose,
      oi = prevOi,
      dprUpper = SahiUniverse.roundToTick(info.prevClose * 1.2),
      dprLower = SahiUniverse.roundToTick(info.prevClose * 0.8);

  final SahiInstrumentInfo info;
  final Mode mode;
  final int prevOi;
  final int dprUpper;
  final int dprLower;
  int ltp;
  int volume = 0;
  int oi;
}

/// Serves `/sahi/json` and `/sahi/protobuf`: waits for Subscribe requests,
/// acks each, then streams one tick per WebSocket frame at the scenario's
/// rate.
void serveSahiFeed(
  WebSocket socket, {
  required bool json,
  required String load,
}) {
  final scenario = SahiScenario.forLoad(load);
  final modes = <int, Mode>{};
  SahiTickGenerator? generator;
  Timer? timer;
  Timer? startFallback;
  var sent = 0;
  final clock = Stopwatch();

  serverLog(
    'Sahi client connected: ${json ? 'json' : 'protobuf'} | '
    '${scenario.description}',
  );

  void send(ServerMessage message) {
    if (json) {
      socket.add(jsonEncode(SahiJsonCodec.encodeServerMessage(message)));
    } else {
      socket.add(message.writeToBuffer());
    }
  }

  void start() {
    startFallback?.cancel();
    generator = SahiTickGenerator(
      modes,
      ticksPerSecond: scenario.ticksPerSecond,
    );
    clock.start();
    // Time-based pacing: both formats get the same ticks per second, no
    // matter how long encoding takes. A stall is not caught up beyond 100 ms.
    timer = Timer.periodic(const Duration(milliseconds: 4), (_) {
      if (socket.readyState != WebSocket.open) return;
      final due =
          clock.elapsedMicroseconds * scenario.ticksPerSecond ~/ 1000000;
      final backlog = min(due - sent, scenario.ticksPerSecond ~/ 10);
      for (var i = 0; i < backlog; i++) {
        send(generator!.next());
      }
      sent = max(sent + backlog, due - scenario.ticksPerSecond ~/ 10);
    });
  }

  void onSubscribe(Mode mode, List<int> ids) {
    for (final id in ids) {
      modes[id] = mode;
    }
    send(
      ServerMessage(
        ack: Ack(
          action: Action.ACTION_SUBSCRIBE,
          instrumentIds: ids.map(Int64.new),
        ),
      ),
    );
    // The app sends all its subscriptions at once; start streaming when the
    // full set has arrived so the tick sequence is reproducible.
    if (generator == null && modes.length >= scenario.instrumentCount) {
      start();
    } else {
      // A client with its own, smaller subscription still gets ticks.
      startFallback ??= Timer(const Duration(seconds: 1), () {
        if (generator == null && socket.readyState == WebSocket.open) start();
      });
    }
  }

  socket.listen(
    (message) {
      try {
        if (json && message is String) {
          final request = SahiJsonCodec.decodeSubscribe(
            jsonDecode(message) as Map<String, dynamic>,
          );
          if (request != null) onSubscribe(request.mode, request.ids);
        } else if (!json && message is List<int>) {
          final request = ClientMessage.fromBuffer(
            message is Uint8List ? message : Uint8List.fromList(message),
          );
          if (request.hasSubscribe()) {
            onSubscribe(request.subscribe.mode, [
              for (final id in request.subscribe.instrumentIds) id.toInt(),
            ]);
          }
        }
      } catch (error) {
        send(
          ServerMessage(
            error: StreamError(code: 'BAD_REQUEST', message: '$error'),
          ),
        );
      }
    },
    onDone: () {
      timer?.cancel();
      startFallback?.cancel();
      serverLog(
        'Sahi client disconnected: ${json ? 'json' : 'protobuf'} ($sent ticks)',
      );
    },
    onError: (Object error) {
      timer?.cancel();
      serverLog('Sahi socket error: $error');
    },
  );
}
