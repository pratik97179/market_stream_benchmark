import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../../generated/sahi_marketdata.pb.dart';
import '../domain/sahi_universe.dart';
import 'sahi_delta.dart';
import 'sahi_json_codec.dart';

/// Messages from the UI isolate to the worker.
abstract final class SahiWorkerCommand {
  /// Send the next delta as soon as there is something in it.
  static const String pull = 'pull';
  static const String close = 'close';
}

/// Startup parameters for [sahiFeedWorkerMain].
class SahiWorkerConfig {
  const SahiWorkerConfig({
    required this.uri,
    required this.json,
    required this.load,
    required this.chartInstrumentId,
    required this.replyTo,
  });

  final String uri;
  final bool json;
  final String load;
  final int chartInstrumentId;

  /// Receives: the worker's command [SendPort], then `'connected'` or an
  /// error string, then one [Int64List] delta per pull, then `'closed'`.
  final SendPort replyTo;
}

/// Background isolate entry point: owns the WebSocket, decodes every tick,
/// coalesces per instrument, and hands the UI one delta per pull.
Future<void> sahiFeedWorkerMain(SahiWorkerConfig config) async {
  final commands = ReceivePort();
  final replyTo = config.replyTo..send(commands.sendPort);

  final WebSocket socket;
  try {
    socket = await WebSocket.connect(config.uri)
        .timeout(const Duration(seconds: 12));
  } catch (error) {
    replyTo.send('error: $error');
    commands.close();
    return;
  }

  final coalescer = SahiCoalescer(chartInstrumentId: config.chartInstrumentId);
  var uiWaiting = false;

  void sendDeltaIfWaiting() {
    if (!uiWaiting || !coalescer.hasPending) return;
    uiWaiting = false;
    replyTo.send(coalescer.takeDelta());
  }

  socket.listen(
    (message) {
      final receive = Timeline.now;
      final watch = Stopwatch()..start();
      try {
        final ServerMessage decoded;
        final int bytes;
        if (config.json) {
          final text = message as String;
          bytes = text.length; // ASCII-only JSON
          decoded = SahiJsonCodec.decodeServerMessage(
            jsonDecode(text) as Map<String, dynamic>,
          );
        } else {
          final data = message is Uint8List
              ? message
              : Uint8List.fromList(message as List<int>);
          bytes = data.length;
          decoded = ServerMessage.fromBuffer(data);
        }
        final decodeMicros = watch.elapsedMicroseconds;
        coalescer.add(
          decoded,
          payloadBytes: bytes,
          decodeMicros: decodeMicros,
          receiveMicros: receive,
        );
      } catch (_) {
        coalescer.recordError();
      }
      coalescer.addBusy(watch.elapsedMicroseconds);
      sendDeltaIfWaiting();
    },
    onDone: () => replyTo.send('closed'),
    onError: (Object error) => replyTo.send('error: $error'),
    cancelOnError: true,
  );

  // Subscribe like a broker app: one request per mode.
  final scenario = SahiScenario.forLoad(config.load);
  for (final (mode, ids) in [
    (Mode.MODE_DEPTH, scenario.depth),
    (Mode.MODE_QUOTE, scenario.quote),
    (Mode.MODE_LTP, scenario.ltp),
  ]) {
    socket.add(
      config.json
          ? jsonEncode(SahiJsonCodec.encodeSubscribe(mode, ids))
          : ClientMessage(
              subscribe: Subscribe(
                mode: mode,
                instrumentIds: ids.map(Int64.new),
              ),
            ).writeToBuffer(),
    );
  }
  replyTo.send('connected');

  await for (final command in commands) {
    if (command == SahiWorkerCommand.pull) {
      uiWaiting = true;
      sendDeltaIfWaiting();
    } else if (command == SahiWorkerCommand.close) {
      break;
    }
  }
  await socket.close();
  commands.close();
}
