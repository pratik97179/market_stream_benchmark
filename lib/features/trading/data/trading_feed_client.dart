import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../app/server_address.dart';
import '../../../generated/market.pb.dart';

enum TradingDecoder { json, protobuf }

/// Server feed intensity; must match the server's `?load=` values.
enum TradingLoad { normal, heavy }

class DecodedTradingBatch {
  const DecodedTradingBatch({
    required this.batch,
    required this.payloadBytes,
    required this.decodeMicroseconds,
  });

  final TradingBatch batch;
  final int payloadBytes;
  final int decodeMicroseconds;
}

class TradingFeedClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final StreamController<DecodedTradingBatch> _controller =
      StreamController<DecodedTradingBatch>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<DecodedTradingBatch> get batches => _controller.stream;
  Stream<bool> get connectionUpdates => _connectionController.stream;

  bool _connected = false;

  Future<void> connect({
    required ServerAddress server,
    required TradingDecoder decoder,
    TradingLoad load = TradingLoad.normal,
  }) async {
    await disconnect();

    final endpoint = decoder == TradingDecoder.json ? 'json' : 'protobuf';
    final uri = server.websocketUri(
      '/trading/$endpoint',
      query: load == TradingLoad.normal ? null : {'load': load.name},
    );

    debugPrint('[TradingClient] Connecting to $uri');

    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    try {
      await channel.ready.timeout(const Duration(seconds: 12));

      // disconnect() or a newer connect() may have run while we waited.
      // Don't revive a channel that has already been abandoned.
      if (!identical(_channel, channel)) {
        await channel.sink.close();
        throw StateError('Connection cancelled');
      }

      _connected = true;
      _connectionController.add(true);

      debugPrint('[TradingClient] WebSocket connected: $uri');

      _subscription = channel.stream.listen(
        (message) {
          try {
            final payloadBytes = _payloadByteLength(message);
            final decodeWatch = Stopwatch()..start();
            final batch = _decode(message, decoder);
            decodeWatch.stop();

            _controller.add(
              DecodedTradingBatch(
                batch: batch,
                payloadBytes: payloadBytes,
                decodeMicroseconds: decodeWatch.elapsedMicroseconds,
              ),
            );
          } catch (error, stackTrace) {
            debugPrint('[TradingClient] DECODE ERROR: $error');
            _controller.addError(error, stackTrace);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('[TradingClient] SOCKET ERROR: $error');
          _setDisconnected();
        },
        onDone: () {
          debugPrint('[TradingClient] SOCKET CLOSED');
          _setDisconnected();
        },
      );
    } catch (error) {
      debugPrint('[TradingClient] CONNECTION ERROR: $error');
      if (identical(_channel, channel)) {
        _channel = null;
        _setDisconnected();
      }
      rethrow;
    }
  }

  int _payloadByteLength(dynamic message) {
    // The feed's JSON is ASCII-only (numbers, field names, enum names), so
    // the string length equals its UTF-8 byte size. Re-encoding every
    // message just to count bytes would add main-thread work that only the
    // JSON path pays.
    if (message is String) return message.length;
    if (message is List<int>) return message.length;
    return 0;
  }

  TradingBatch _decode(dynamic message, TradingDecoder decoder) {
    if (decoder == TradingDecoder.protobuf) {
      final bytes = message is Uint8List
          ? message
          : Uint8List.fromList(message as List<int>);

      return TradingBatch.fromBuffer(bytes);
    }

    if (message is! String) {
      throw FormatException(
        'Expected JSON String, received ${message.runtimeType}',
      );
    }

    return TradingBatch()..mergeFromProto3Json(jsonDecode(message));
  }

  void _setDisconnected() {
    if (!_connected) return;

    _connected = false;
    _connectionController.add(false);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _setDisconnected();
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
    await _connectionController.close();
  }
}
