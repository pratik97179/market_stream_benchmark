import 'dart:async';

import '../../../app/server_address.dart';
import '../domain/market_store.dart';
import 'benchmark_feed.dart';
import 'trading_feed_client.dart';

class TradingMarketController implements BenchmarkFeedController {
  TradingMarketController({MarketStore? store})
    : _client = TradingFeedClient(),
      store = store ?? MarketStore();

  final TradingFeedClient _client;

  /// Market state the UI listens to, slice by slice.
  final MarketStore store;

  final StreamController<bool> _connectionUpdates =
      StreamController<bool>.broadcast();

  StreamSubscription<DecodedTradingBatch>? _batchSubscription;
  StreamSubscription<bool>? _clientConnectionSubscription;

  bool _connected = false;
  bool _disposed = false;

  @override
  Stream<bool> get connectionUpdates => _connectionUpdates.stream;

  /// When false, batches update the store but listeners are not notified,
  /// so the UI stays frozen (decode-only measurements). Call
  /// [MarketStore.flush] to catch the UI up afterwards.
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

    _batchSubscription = _client.batches.listen(
      (decoded) {
        if (_disposed) return;

        final applyWatch = Stopwatch()..start();
        store.apply(decoded.batch);
        applyWatch.stop();

        onBatchMetrics?.call(
          TradingBatchMetrics(
            eventCount: decoded.batch.events.length,
            payloadBytes: decoded.payloadBytes,
            decodeMicroseconds: decoded.decodeMicroseconds,
            applyMicroseconds: applyWatch.elapsedMicroseconds,
          ),
        );

        // Notify only the slices this batch touched. Flutter coalesces the
        // resulting rebuilds into at most one frame.
        if (notifyUi) store.flush();
      },
      onError: (Object error, StackTrace stackTrace) {
        onBatchError?.call(error, stackTrace);
      },
    );

    _clientConnectionSubscription = _client.connectionUpdates.listen((
      connected,
    ) {
      if (_disposed) return;

      _connected = connected;
      _connectionUpdates.add(connected);
    });

    try {
      await _client.connect(server: server, decoder: decoder, load: load);
    } catch (error) {
      await _batchSubscription?.cancel();
      _batchSubscription = null;

      await _clientConnectionSubscription?.cancel();
      _clientConnectionSubscription = null;
      await _client.disconnect();

      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _batchSubscription?.cancel();
    _batchSubscription = null;

    await _clientConnectionSubscription?.cancel();
    _clientConnectionSubscription = null;

    await _client.disconnect();

    if (_connected && !_disposed) {
      _connected = false;
      _connectionUpdates.add(false);
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;

    await _batchSubscription?.cancel();
    await _clientConnectionSubscription?.cancel();

    await _client.dispose();

    await _connectionUpdates.close();
  }
}
