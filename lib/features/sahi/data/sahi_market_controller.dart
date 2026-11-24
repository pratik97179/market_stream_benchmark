import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:isolate';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../app/server_address.dart';
import '../../../generated/sahi_marketdata.pb.dart';
import '../../trading/data/benchmark_feed.dart';
import '../../trading/data/trading_feed_client.dart';
import '../domain/sahi_store.dart';
import '../domain/sahi_universe.dart';
import 'sahi_delta.dart';
import 'sahi_feed_worker.dart';
import 'sahi_json_codec.dart';

/// Drives the Sahi-style feed: subscribes like a broker app, decodes each
/// frame (one tick) with the chosen decoder, and applies it to [store].
///
/// With [offUiThread], a background isolate owns the socket, decodes and
/// coalesces ticks, and the UI applies one compact delta per frame.
class SahiMarketController implements BenchmarkFeedController {
  SahiMarketController({SahiStore? store, this.offUiThread = false})
    : store = store ?? SahiStore();

  final SahiStore store;
  final bool offUiThread;

  Isolate? _worker;
  ReceivePort? _workerReplies;
  SendPort? _workerCommands;
  Timer? _pullTimer;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<bool> _connectionUpdates =
      StreamController<bool>.broadcast();
  bool _connected = false;
  bool _disposed = false;
  bool _flushScheduled = false;

  @override
  Stream<bool> get connectionUpdates => _connectionUpdates.stream;

  @override
  bool notifyUi = true;

  @override
  void flushUi() => store.flush();

  @override
  Future<void> connect({
    required ServerAddress server,
    required TradingDecoder decoder,
    TradingLoad load = TradingLoad.normal,
    void Function(TradingBatchMetrics metrics)? onBatchMetrics,
    void Function(Object error, StackTrace stackTrace)? onBatchError,
  }) async {
    await disconnect();
    store.reset();

    if (offUiThread) {
      return _connectWorker(
        server: server,
        decoder: decoder,
        load: load,
        onBatchMetrics: onBatchMetrics,
        onBatchError: onBatchError,
      );
    }

    final json = decoder == TradingDecoder.json;
    final uri = server.websocketUri(
      '/sahi/${json ? 'json' : 'protobuf'}',
      query: load == TradingLoad.normal ? null : {'load': load.name},
    );
    debugPrint('[SahiClient] Connecting to $uri');

    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    try {
      await channel.ready.timeout(const Duration(seconds: 12));
    } catch (error) {
      if (identical(_channel, channel)) _channel = null;
      debugPrint('[SahiClient] CONNECTION ERROR: $error');
      rethrow;
    }
    if (!identical(_channel, channel)) {
      await channel.sink.close();
      throw StateError('Connection cancelled');
    }

    _subscription = channel.stream.listen(
      (message) {
        if (_disposed) return;
        try {
          final payloadBytes = message is String
              // The JSON is ASCII-only, so length equals UTF-8 byte size.
              ? message.length
              : (message as List<int>).length;

          final decodeWatch = Stopwatch()..start();
          final decoded = json
              ? SahiJsonCodec.decodeServerMessage(
                  jsonDecode(message as String) as Map<String, dynamic>,
                )
              : ServerMessage.fromBuffer(
                  message is Uint8List
                      ? message
                      : Uint8List.fromList(message as List<int>),
                );
          decodeWatch.stop();

          final applyWatch = Stopwatch()..start();
          final isTick = store.apply(decoded);
          applyWatch.stop();

          if (decoded.hasError()) {
            onBatchError?.call(
              StateError('${decoded.error.code}: ${decoded.error.message}'),
              StackTrace.current,
            );
            return;
          }
          if (!isTick) return;

          onBatchMetrics?.call(
            TradingBatchMetrics(
              eventCount: 1,
              payloadBytes: payloadBytes,
              decodeMicroseconds: decodeWatch.elapsedMicroseconds,
              applyMicroseconds: applyWatch.elapsedMicroseconds,
            ),
          );
          if (notifyUi) _scheduleFlush();
        } catch (error, stackTrace) {
          debugPrint('[SahiClient] DECODE ERROR: $error');
          onBatchError?.call(error, stackTrace);
        }
      },
      onError: (Object error) {
        debugPrint('[SahiClient] SOCKET ERROR: $error');
        _setConnected(false);
      },
      onDone: () => _setConnected(false),
    );

    // Subscribe the way a broker app does: one request per mode.
    final scenario = SahiScenario.forLoad(load.name);
    for (final (mode, ids) in [
      (Mode.MODE_DEPTH, scenario.depth),
      (Mode.MODE_QUOTE, scenario.quote),
      (Mode.MODE_LTP, scenario.ltp),
    ]) {
      channel.sink.add(
        json
            ? jsonEncode(SahiJsonCodec.encodeSubscribe(mode, ids))
            : ClientMessage(
                subscribe: Subscribe(
                  mode: mode,
                  instrumentIds: ids.map(Int64.new),
                ),
              ).writeToBuffer(),
      );
    }

    _setConnected(true);
    debugPrint('[SahiClient] Subscribed: ${scenario.description}');
  }

  Future<void> _connectWorker({
    required ServerAddress server,
    required TradingDecoder decoder,
    required TradingLoad load,
    void Function(TradingBatchMetrics metrics)? onBatchMetrics,
    void Function(Object error, StackTrace stackTrace)? onBatchError,
  }) async {
    final json = decoder == TradingDecoder.json;
    final uri = server.websocketUri(
      '/sahi/${json ? 'json' : 'protobuf'}',
      query: load == TradingLoad.normal ? null : {'load': load.name},
    );
    debugPrint('[SahiWorker] Connecting to $uri');

    final replies = ReceivePort();
    _workerReplies = replies;
    final connected = Completer<void>();

    replies.listen((message) {
      if (_disposed || !identical(_workerReplies, replies)) return;
      if (message is Int64List) {
        _onDelta(message, onBatchMetrics, onBatchError);
      } else if (message is SendPort) {
        _workerCommands = message;
      } else if (message == 'connected') {
        _setConnected(true);
        if (!connected.isCompleted) connected.complete();
        _pull();
      } else if (message is String) {
        debugPrint('[SahiWorker] $message');
        _setConnected(false);
        if (!connected.isCompleted) {
          connected.completeError(StateError(message));
        }
      }
    });

    _worker = await Isolate.spawn(
      sahiFeedWorkerMain,
      SahiWorkerConfig(
        uri: uri.toString(),
        json: json,
        load: load.name,
        chartInstrumentId: store.chartInstrumentId,
        replyTo: replies.sendPort,
      ),
      debugName: 'sahi-feed-worker',
    );

    try {
      await connected.future.timeout(const Duration(seconds: 15));
    } catch (_) {
      await disconnect();
      rethrow;
    }
    debugPrint(
      '[SahiWorker] Subscribed: ${SahiScenario.forLoad(load.name).description}',
    );
  }

  void _pull() {
    if (_disposed) return;
    _workerCommands?.send(SahiWorkerCommand.pull);
  }

  void _onDelta(
    Int64List delta,
    void Function(TradingBatchMetrics metrics)? onBatchMetrics,
    void Function(Object error, StackTrace stackTrace)? onBatchError,
  ) {
    final applyWatch = Stopwatch()..start();
    store.applyDelta(delta);
    applyWatch.stop();

    final ticks = delta[SahiDelta.hTicks];
    final errors = delta[SahiDelta.hDecodeErrors];
    for (var i = 0; i < errors; i++) {
      onBatchError?.call(StateError('Worker decode error'), StackTrace.empty);
    }
    if (ticks > 0) {
      final samples = Int64List.sublistView(
        delta,
        SahiDelta.headerLength,
        SahiDelta.headerLength + delta[SahiDelta.hDecodeSamples],
      );
      var decodeTotal = 0;
      for (final sample in samples) {
        decodeTotal += sample;
      }
      onBatchMetrics?.call(
        TradingBatchMetrics(
          eventCount: ticks,
          payloadBytes: delta[SahiDelta.hPayloadBytes],
          decodeMicroseconds: decodeTotal,
          applyMicroseconds: applyWatch.elapsedMicroseconds,
          decodeSamples: samples,
          workerBusyMicroseconds: delta[SahiDelta.hWorkerBusyMicros],
          stalenessMicroseconds:
              Timeline.now - delta[SahiDelta.hOldestReceiveMicros],
        ),
      );
    }

    if (notifyUi) {
      // Render this delta, then ask for the next one: at most one delta
      // per displayed frame, however fast ticks arrive.
      _scheduleFlush();
      SchedulerBinding.instance.addPostFrameCallback((_) => _pull());
    } else {
      // UI frozen (decode-only runs): keep collecting stats without frames.
      _pullTimer = Timer(const Duration(milliseconds: 100), _pull);
    }
  }

  /// Ticks arrive one per frame, often many per display frame. Notify the
  /// UI once per display frame, at its start, with everything applied so
  /// far, instead of once per tick.
  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _flushScheduled = false;
      if (notifyUi && !_disposed) store.flush();
    });
  }

  void _setConnected(bool connected) {
    if (_connected == connected || _disposed) return;
    _connected = connected;
    _connectionUpdates.add(connected);
  }

  @override
  Future<void> disconnect() async {
    _pullTimer?.cancel();
    _pullTimer = null;
    _workerCommands?.send(SahiWorkerCommand.close);
    _workerCommands = null;
    _workerReplies?.close();
    _workerReplies = null;
    // The worker closes its socket on 'close'; kill it shortly after in
    // case the close handshake stalls.
    final worker = _worker;
    _worker = null;
    if (worker != null) {
      Timer(const Duration(milliseconds: 500), worker.kill);
    }

    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setConnected(false);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    _disposed = true;
    await _connectionUpdates.close();
  }
}
