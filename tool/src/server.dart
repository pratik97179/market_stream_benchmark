import 'dart:io';

import 'sahi_feed.dart';
import 'synthetic_feed.dart';

/// Where feed connection messages go. `tool/bench.dart` silences them and
/// prints its own progress instead.
void Function(String message) serverLog = _print;

// ignore: avoid_print
void _print(String message) => print(message);

/// Starts the benchmark feed server.
///
/// - `/trading/{json,protobuf}`: synthetic feed, small events batched per
///   message.
/// - `/sahi/{json,protobuf}`: feed shaped like Sahi's tick stream, one
///   full-snapshot tick per message.
/// - `/results`: the app uploads its result lines here; [onResults] gets
///   the socket.
///
/// Add `?load=heavy` to a feed URL for the high-rate scenario.
Future<HttpServer> startFeedServer({
  int port = 8080,
  required void Function(WebSocket socket) onResults,
}) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen((request) async {
    final path = request.uri.path;
    const paths = {
      '/trading/json',
      '/trading/protobuf',
      '/sahi/json',
      '/sahi/protobuf',
      '/results',
    };
    if (!paths.contains(path)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      final load = request.uri.queryParameters['load'] ?? 'normal';
      if (path == '/results') {
        onResults(socket);
      } else if (path.startsWith('/sahi/')) {
        serveSahiFeed(socket, json: path == '/sahi/json', load: load);
      } else {
        serveSyntheticFeed(
          socket,
          path,
          load == 'heavy' ? TradingLoad.heavy : TradingLoad.normal,
        );
      }
    } catch (error) {
      serverLog('Connection failed ($path): $error');
    }
  });
  return server;
}
