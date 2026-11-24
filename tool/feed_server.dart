// Command-line server: printing to stdout is intended.
// ignore_for_file: avoid_print

import 'dart:io';

import 'src/server.dart';

/// Runs the feed server on its own, for running the app by hand.
/// `tool/bench.dart` starts the same server itself.
///
/// Result lines uploaded by the app are saved to `benchmark_results/`.
Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.first);
  await startFeedServer(port: port, onResults: _saveResults);

  print('Feed server listening on port $port');
  print('  Synthetic: /trading/json | /trading/protobuf  (?load=heavy)');
  print('  Broker:    /sahi/json | /sahi/protobuf  (?load=heavy)');
  print('  Results:   /results -> benchmark_results/*.jsonl');
}

void _saveResults(WebSocket socket) {
  final dir = Directory('benchmark_results')..createSync(recursive: true);
  final stamp = DateTime.now().toIso8601String().split('.').first;
  final file = File('${dir.path}/results-${stamp.replaceAll(':', '-')}.jsonl');
  final sink = file.openWrite(mode: FileMode.append);
  var count = 0;
  print('Results -> ${file.path}');

  socket.listen(
    (message) {
      if (message is! String) return;
      sink.writeln(message);
      count++;
      print('Result #$count: ${message.split(' ').first}');
    },
    onDone: () async {
      await sink.close();
      print('Saved $count result lines to ${file.path}');
    },
    onError: (Object error) => print('Results socket error: $error'),
  );
}
