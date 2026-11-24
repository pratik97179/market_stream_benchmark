// Command-line tool: printing to stdout is intended.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'src/report.dart';
import 'src/server.dart';

const _usage = '''
Runs the JSON vs Protobuf benchmark on a connected phone and writes a report.

  dart run tool/bench.dart -d <device-id> [options]

Options:
  -d, --device <id>     Flutter device id (see `flutter devices`). Required
                        when more than one device is connected.
  --variant <id>        synthetic | broker-ui-thread | broker-isolate |
                        broker-optimised (default) | all
                        "all" runs the three broker variants in turn.
  --duration <s>        Seconds per run (default 20).
  --rounds <n>          Rounds per format and configuration (default 5).
  --quick               Shorthand for --rounds 1 --duration 10 (a smoke
                        test, not a result to publish).
  --host <ip>           Address the phone uses to reach this machine.
                        Default: 127.0.0.1 over adb for Android, this
                        machine's LAN address for iOS.
  --name <text>         Device name for the report (default: detected).
  --chip <text>         Chip for the report (default: detected if possible).
  --notes <text>        Anything worth recording (battery, thermal, ...).
  --out <dir>           Results folder (default results).

Each run is saved to <out>/<date>_<device>_<variant>/ with REPORT.md,
raw.jsonl and environment.json.
''';

const _variants = [
  'synthetic',
  'broker-ui-thread',
  'broker-isolate',
  'broker-optimised',
];

const _descriptions = {
  'synthetic':
      'Synthetic feed: small events batched per message, decoded on the UI '
      'thread, tables built from Text widgets.',
  'broker-ui-thread':
      'Broker-style (Sahi-shaped) feed, one tick per message, decoded on the '
      'UI thread; tables built from Text widgets.',
  'broker-isolate':
      'Broker-style feed decoded on a background isolate that keeps the '
      'newest tick per instrument and hands the UI one update per frame; '
      'tables built from Text widgets.',
  'broker-optimised':
      'Broker-style feed decoded on a background isolate, one coalesced '
      'update per frame; option chain, depth and watchlist painted from a '
      'glyph atlas.',
};

const _port = 8080;

Future<void> main(List<String> argv) async {
  final args = _parseArgs(argv);
  if (args.containsKey('help')) {
    print(_usage);
    return;
  }

  final quick = args.containsKey('quick');
  final duration = int.parse(args['duration'] ?? (quick ? '10' : '20'));
  final rounds = int.parse(args['rounds'] ?? (quick ? '1' : '5'));
  final variantArg = args['variant'] ?? 'broker-optimised';
  final variants = variantArg == 'all' ? _variants.sublist(1) : [variantArg];
  for (final variant in variants) {
    if (!_variants.contains(variant)) _fail('Unknown --variant "$variant".');
  }

  final device = await _pickDevice(args['device']);
  final isAndroid = '${device['targetPlatform']}'.startsWith('android');
  final isIos = '${device['targetPlatform']}' == 'ios';
  if (device['emulator'] == true) {
    print(
      'Warning: ${device['name']} is an emulator or simulator; its '
      'timings do not represent a real phone.',
    );
  }

  final info = await _deviceInfo(device, isAndroid: isAndroid, isIos: isIos);
  if (args['name'] != null) info['name'] = args['name'];
  if (args['chip'] != null) info['chip'] = args['chip'];

  final host = args['host'] ?? (isAndroid ? '127.0.0.1' : await _lanAddress());
  final connection = isAndroid && host == '127.0.0.1'
      ? 'USB cable (adb reverse tcp:$_port tcp:$_port), app connects to '
            '127.0.0.1'
      : 'Network (Wi-Fi/LAN): app connects to this machine';

  final flutter = await _flutterVersion();
  final environmentBase = {
    'device': info,
    'connection': connection,
    'host': await _hostOs(),
    'flutter': flutter,
    'gitCommit': await _gitCommit(),
    // Device ids and addresses identify someone's phone and network;
    // keep them out of results that may be published.
    'command': 'dart run tool/bench.dart ${_redact(argv).join(' ')}',
    if (args['notes'] != null) 'notes': args['notes'],
  };

  print('Device:     ${info['name']} (${info['os']})');
  print('Connection: $connection');
  print('Flutter:    ${flutter['version']}');
  print(
    'Suite:      $rounds rounds × 2 formats × ${duration}s × 3 '
    'configurations, per variant: ${variants.join(', ')}',
  );
  print('');

  if (isAndroid) {
    await _run('adb', [
      '-s',
      '${device['id']}',
      'reverse',
      'tcp:$_port',
      'tcp:$_port',
    ]);
  }

  serverLog = (_) {};
  final results = _ResultsRouter();
  final HttpServer server;
  try {
    server = await startFeedServer(port: _port, onResults: results.accept);
  } on SocketException catch (error) {
    _fail(
      'Port $_port is busy (${error.message}). Stop the other feed '
      'server and try again.',
    );
  }

  final outDir = Directory(args['out'] ?? 'results');
  final written = <Directory>[];
  try {
    for (final variant in variants) {
      final folder = await _runVariant(
        variant: variant,
        device: device,
        deviceSlug: _slug('${info['name']}'),
        host: host,
        duration: duration,
        rounds: rounds,
        outDir: outDir,
        results: results,
        environment: {
          'variant': variant,
          'variantDescription': _descriptions[variant],
          ...environmentBase,
          'date': DateTime.now().toIso8601String().split('T').first,
        },
      );
      written.add(folder);
    }
  } finally {
    await server.close(force: true);
    if (isAndroid) {
      await _run('adb', [
        '-s',
        '${device['id']}',
        'reverse',
        '--remove',
        'tcp:$_port',
      ]);
    }
  }

  if (outDir.existsSync()) {
    final all = [for (final f in runFolders(outDir)) RunData.load(f)];
    File('${outDir.path}/README.md').writeAsStringSync(renderIndex(all));
  }
  print('');
  for (final folder in written) {
    print('Report: ${folder.path}/REPORT.md');
  }
  exit(0);
}

Future<Directory> _runVariant({
  required String variant,
  required Map<String, dynamic> device,
  required String deviceSlug,
  required String host,
  required int duration,
  required int rounds,
  required Directory outDir,
  required _ResultsRouter results,
  required Map<String, dynamic> environment,
}) async {
  final stamp = DateTime.now()
      .toIso8601String()
      .substring(0, 16)
      .replaceAll(':', '-');
  final folder = Directory('${outDir.path}/${stamp}_${deviceSlug}_$variant')
    ..createSync(recursive: true);
  final rawFile = File('${folder.path}/raw.jsonl');
  final logFile = File(
    'build/bench/${folder.uri.pathSegments.where((s) => s.isNotEmpty).last}.log',
  )..createSync(recursive: true);
  final log = logFile.openWrite();
  final totalRuns = rounds * 2 * 3;

  print('── $variant ──');
  print('Building and launching (the first build takes a few minutes)...');

  final done = Completer<void>();
  var completedRuns = 0;
  final raw = rawFile.openWrite();
  results.target = (line) {
    raw.writeln(line);
    if (line.startsWith('BENCH_SUITE_START')) {
      print(
        'App connected. Running $totalRuns runs '
        '(~${(totalRuns * (duration + 3) / 60).ceil()} min).',
      );
    } else if (line.startsWith('BENCH_RUN ')) {
      completedRuns++;
      final run = jsonDecode(line.substring(10)) as Map<String, dynamic>;
      final config = normaliseConfig(run['config'] as String);
      final fps = (run['frames'] as num) / (run['elapsedSeconds'] as num);
      final screen = config.endsWith('decode-only')
          ? 'UI frozen'
          : '${fps.toStringAsFixed(0).padLeft(2)} fps';
      print(
        '  [${'$completedRuns'.padLeft(2)}/$totalRuns] '
        '${config.padRight(17)} ${(run['decoder'] as String).padRight(8)} '
        'round ${run['round']}: $screen, decode '
        '${(run['decodeUsPerEvent'] as num).toStringAsFixed(1)} µs/msg',
      );
    } else if (line.startsWith('BENCH_SUITE_DONE') && !done.isCompleted) {
      done.complete();
    }
  };

  final app = await Process.start('flutter', [
    'run',
    '--profile',
    '-d',
    '${device['id']}',
    '--dart-define=SERVER_HOST=$host',
    '--dart-define=BENCH_SUITE=true',
    '--dart-define=BENCH_VARIANT=$variant',
    '--dart-define=BENCH_DURATION=$duration',
    '--dart-define=BENCH_ROUNDS=$rounds',
  ]);
  app.stdout.transform(utf8.decoder).listen(log.write);
  app.stderr.transform(utf8.decoder).listen(log.write);
  final exited = app.exitCode;

  // Building, installing and the full suite; generous on purpose.
  final deadline = Duration(minutes: 15 + totalRuns * (duration + 10) ~/ 60);
  final outcome = await Future.any([
    done.future.then((_) => 'done'),
    exited.then((code) => 'exited $code'),
    Future<void>.delayed(deadline).then((_) => 'timeout'),
  ]);

  app.stdin.write('q');
  await app.exitCode.timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      app.kill();
      return -1;
    },
  );
  results.target = null;
  await raw.close();
  await log.close();

  if (outcome != 'done') {
    final tail = logFile.readAsLinesSync();
    print(tail.skip(tail.length > 30 ? tail.length - 30 : 0).join('\n'));
    _fail(
      'The app did not finish the suite ($outcome). Full log: '
      '${logFile.path}',
    );
  }

  File(
    '${folder.path}/environment.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(environment));
  final data = RunData.load(folder);
  File('${folder.path}/REPORT.md').writeAsStringSync(renderReport(data));
  print('');
  print(renderConsoleSummary(data));
  return folder;
}

/// Routes the app's `/results` connection to whichever run is active.
class _ResultsRouter {
  void Function(String line)? target;

  void accept(WebSocket socket) {
    socket.listen((message) {
      if (message is String) target?.call(message);
    });
  }
}

// ---- Device and environment -----------------------------------------------

Future<Map<String, dynamic>> _pickDevice(String? id) async {
  final result = await Process.run('flutter', ['devices', '--machine']);
  final text = '${result.stdout}';
  final start = text.indexOf('[');
  final devices = start < 0
      ? <Map<String, dynamic>>[]
      : (jsonDecode(text.substring(start)) as List)
            .cast<Map<String, dynamic>>()
            .where((d) {
              final platform = '${d['targetPlatform']}';
              return platform.startsWith('android') || platform == 'ios';
            })
            .toList();

  if (id != null) {
    for (final device in devices) {
      if (device['id'] == id || device['name'] == id) return device;
    }
    _fail('Device "$id" not found. Connected phones:\n${_list(devices)}');
  }
  if (devices.length == 1) return devices.single;
  _fail(
    devices.isEmpty
        ? 'No phone found. Connect one and check `flutter devices`.'
        : 'Several phones connected; pick one with -d:\n${_list(devices)}',
  );
}

String _list(List<Map<String, dynamic>> devices) => devices.isEmpty
    ? '  (none)'
    : devices.map((d) => '  ${d['id']}  ${d['name']} (${d['sdk']})').join('\n');

Future<Map<String, dynamic>> _deviceInfo(
  Map<String, dynamic> device, {
  required bool isAndroid,
  required bool isIos,
}) async {
  final info = <String, dynamic>{'name': device['name'], 'os': device['sdk']};
  if (isAndroid) {
    Future<String> prop(String key) async {
      final r = await Process.run('adb', [
        '-s',
        '${device['id']}',
        'shell',
        'getprop',
        key,
      ]);
      return '${r.stdout}'.trim();
    }

    final marketName = await prop('ro.product.marketname');
    final manufacturer = await prop('ro.product.manufacturer');
    final model = await prop('ro.product.model');
    final soc = await prop('ro.soc.model');
    final platform = await prop('ro.board.platform');
    info
      ..['name'] = marketName.isNotEmpty ? marketName : '$manufacturer $model'
      ..['manufacturer'] = manufacturer
      ..['model'] = model
      ..['chip'] = soc.isNotEmpty ? soc : platform;
  } else if (isIos) {
    final file = File('${Directory.systemTemp.path}/bench_devices.json');
    await Process.run('xcrun', [
      'devicectl',
      'list',
      'devices',
      '--json-output',
      file.path,
    ]);
    if (file.existsSync()) {
      final json = jsonDecode(file.readAsStringSync());
      final list = (json['result']?['devices'] as List?) ?? const [];
      for (final d in list.cast<Map<String, dynamic>>()) {
        final hardware = d['hardwareProperties'] as Map? ?? const {};
        if (hardware['udid'] == device['id']) {
          info
            ..['name'] = hardware['marketingName'] ?? info['name']
            ..['manufacturer'] = 'Apple'
            ..['model'] = hardware['productType'];
        }
      }
      file.deleteSync();
    }
  }
  return info;
}

Future<Map<String, dynamic>> _flutterVersion() async {
  final result = await Process.run('flutter', ['--version', '--machine']);
  final text = '${result.stdout}';
  final json =
      jsonDecode(text.substring(text.indexOf('{'))) as Map<String, dynamic>;
  return {
    'version': json['frameworkVersion'],
    'dart': json['dartSdkVersion'],
    'engine': json['engineRevision'],
  };
}

Future<String> _hostOs() async {
  if (Platform.isMacOS) {
    final r = await Process.run('sw_vers', ['-productVersion']);
    return 'macOS ${'${r.stdout}'.trim()}';
  }
  return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
}

Future<String?> _gitCommit() async {
  try {
    final head = await Process.run('git', ['rev-parse', '--short', 'HEAD']);
    if (head.exitCode != 0) return null;
    final status = await Process.run('git', ['status', '--porcelain']);
    final dirty = '${status.stdout}'.trim().isNotEmpty;
    return '${'${head.stdout}'.trim()}${dirty ? ' (with uncommitted changes)' : ''}';
  } on ProcessException {
    return null;
  }
}

Future<String> _lanAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  interfaces.sort(
    (a, b) => (a.name == 'en0' ? 0 : 1) - (b.name == 'en0' ? 0 : 1),
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (!address.isLoopback) return address.address;
    }
  }
  _fail('Could not find this machine\'s LAN address; pass --host <ip>.');
}

// ---- Helpers ----------------------------------------------------------------

Map<String, String?> _parseArgs(List<String> argv) {
  final args = <String, String?>{};
  const flags = {'quick', 'help'};
  const aliases = {'d': 'device', 'h': 'help'};
  for (var i = 0; i < argv.length; i++) {
    final raw = argv[i];
    if (!raw.startsWith('-')) _fail('Unexpected argument "$raw".\n\n$_usage');
    final key =
        aliases[raw.replaceFirst(RegExp('^-+'), '')] ??
        raw.replaceFirst(RegExp('^-+'), '');
    if (flags.contains(key)) {
      args[key] = null;
    } else if (i + 1 < argv.length) {
      args[key] = argv[++i];
    } else {
      _fail('Missing value for $raw.');
    }
  }
  return args;
}

List<String> _redact(List<String> argv) => [
  for (var i = 0; i < argv.length; i++)
    if (i > 0 && const {'-d', '--device', '--host'}.contains(argv[i - 1]))
      argv[i - 1] == '--host' ? '<host>' : '<device>'
    else
      argv[i],
];

String _slug(String text) => text
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

Future<void> _run(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    _fail('$command ${args.join(' ')} failed:\n${result.stderr}');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
