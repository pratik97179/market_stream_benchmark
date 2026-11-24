import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// One benchmark run: the raw result lines the app uploaded (`raw.jsonl`)
/// and the environment the runner recorded (`environment.json`).
class RunData {
  RunData({
    required this.name,
    required this.environment,
    required this.suiteStart,
    required this.runs,
  });

  /// Folder name, e.g. `2026-11-24_redmi-9a_broker-optimised`.
  final String name;
  final Map<String, dynamic> environment;
  final Map<String, dynamic> suiteStart;
  final List<Map<String, dynamic>> runs;

  static RunData load(Directory dir) {
    final env = File('${dir.path}/environment.json');
    final suiteStart = <String, dynamic>{};
    final runs = <Map<String, dynamic>>[];
    for (final line in File('${dir.path}/raw.jsonl').readAsLinesSync()) {
      final space = line.indexOf(' ');
      if (space < 0) continue;
      final kind = line.substring(0, space);
      final body = line.substring(space + 1);
      if (kind == 'BENCH_SUITE_START') {
        suiteStart.addAll(jsonDecode(body) as Map<String, dynamic>);
      } else if (kind == 'BENCH_RUN') {
        runs.add(jsonDecode(body) as Map<String, dynamic>);
      }
    }
    return RunData(
      name: dir.uri.pathSegments.where((s) => s.isNotEmpty).last,
      environment: env.existsSync()
          ? jsonDecode(env.readAsStringSync()) as Map<String, dynamic>
          : const {},
      suiteStart: suiteStart,
      runs: runs,
    );
  }

  String get variant =>
      (environment['variant'] ?? suiteStart['variant'] ?? 'unknown') as String;

  String get deviceName {
    final device = environment['device'];
    if (device is Map && device['name'] != null) {
      return device['name'] as String;
    }
    return suiteStart['os'] as String? ?? 'unknown device';
  }

  /// Runs for one configuration and format.
  List<Map<String, dynamic>> select(String config, String decoder) => [
    for (final run in runs)
      if (normaliseConfig(run['config'] as String) == config &&
          run['decoder'] == decoder)
        run,
  ];

  List<String> get configs => [
    for (final config in const [
      'normal/live-ui',
      'heavy/live-ui',
      'heavy/decode-only',
    ])
      if (runs.any((r) => normaliseConfig(r['config'] as String) == config))
        config,
  ];
}

/// Older result files prefixed the config with a feed name.
String normaliseConfig(String config) {
  final match = RegExp(r'(normal|heavy)/(live-ui|decode-only)$')
      .firstMatch(config);
  return match?.group(0) ?? config;
}

// ---- Metrics ---------------------------------------------------------------

/// A row in a results table: how to read it from one run, and how to show it.
class _Metric {
  const _Metric(this.label, this.value, this.format, {this.ratio = false});

  final String label;
  final double? Function(Map<String, dynamic> run) value;
  final String Function(double value) format;

  /// Show a JSON ÷ Protobuf column.
  final bool ratio;
}

double? _num(Map<String, dynamic> run, String key) =>
    (run[key] as num?)?.toDouble();

String _ms(double us) => '${(us / 1000).toStringAsFixed(1)} ms';
String _us(double us) => '${us.toStringAsFixed(1)} µs';
String _pct(double p) => '${p.toStringAsFixed(1)} %';
String _fps(double f) => f.toStringAsFixed(0);
String _bytes(double b) => '${b.toStringAsFixed(0)} B';
String _mbps(double b) => '${(b / 1e6).toStringAsFixed(2)} MB/s';
String _perSec(double n) => n.toStringAsFixed(0);

final _fpsMetric = _Metric(
  'Frames per second',
  (r) => _num(r, 'frames')! / _num(r, 'elapsedSeconds')!,
  _fps,
);
final _slow = _Metric(
  'Frames that missed the deadline',
  (r) => _num(r, 'slowFramePercent'),
  _pct,
);
final _build = _Metric(
  'Frame build time (UI thread), average',
  (r) => _num(r, 'buildAvgUs'),
  _ms,
);
final _raster = _Metric(
  'Frame raster time (GPU thread), p95',
  (r) => _num(r, 'rasterP95Us'),
  _ms,
);
final _vsync = _Metric(
  'UI thread still busy when a frame was due, p95',
  (r) => _num(r, 'vsyncOverheadP95Us'),
  _ms,
);
final _size = _Metric(
  'Size per message on the wire',
  (r) => _num(r, 'payloadBytes')! / _num(r, 'events')!,
  _bytes,
  ratio: true,
);
final _bandwidth = _Metric(
  'Data received',
  (r) => _num(r, 'payloadBytes')! / _num(r, 'elapsedSeconds')!,
  _mbps,
  ratio: true,
);
final _decode = _Metric(
  'Decode time per message',
  (r) => _num(r, 'decodeUsPerEvent'),
  _us,
  ratio: true,
);
final _uiDecode = _Metric(
  'UI thread time spent decoding',
  (r) =>
      r.containsKey('workerBusyPercent') ? null : _num(r, 'decodeBusyPercent'),
  _pct,
  ratio: true,
);
final _worker = _Metric(
  'Background isolate CPU (share of one core)',
  (r) => _num(r, 'workerBusyPercent'),
  _pct,
  ratio: true,
);
final _ageMedian = _Metric(
  'Tick age when shown, median',
  (r) => _num(r, 'stalenessP50Us'),
  _ms,
);
final _ageP99 = _Metric(
  'Tick age when shown, p99',
  (r) => _num(r, 'stalenessP99Us'),
  _ms,
);
final _rate = _Metric(
  'Messages received per second',
  (r) => _num(r, 'eventsPerSecond'),
  _perSec,
);

final _liveMetrics = [
  _fpsMetric,
  _slow,
  _build,
  _raster,
  _vsync,
  _size,
  _bandwidth,
  _decode,
  _uiDecode,
  _worker,
  _ageMedian,
  _ageP99,
  _rate,
];

/// With the UI frozen only decoding and its knock-on effects matter.
final _frozenMetrics = [
  _vsync,
  _decode,
  _uiDecode,
  _worker,
  _ageMedian,
  _ageP99,
  _rate,
];

final _headline = [_fpsMetric, _slow, _size, _decode, _uiDecode, _worker];

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Median (min–max) across rounds, or null when the metric is absent.
({double median, double min, double max})? _stat(
  List<Map<String, dynamic>> runs,
  _Metric metric,
) {
  final values = [for (final run in runs) ?metric.value(run)];
  if (values.isEmpty) return null;
  return (
    median: _median(values),
    min: values.reduce(math.min),
    max: values.reduce(math.max),
  );
}

String _table(RunData data, String config, List<_Metric> metrics) {
  final json = data.select(config, 'json');
  final proto = data.select(config, 'protobuf');
  final out = StringBuffer()
    ..writeln('| | JSON | Protobuf | JSON ÷ Protobuf |')
    ..writeln('|---|---|---|---|');
  for (final metric in metrics) {
    final j = _stat(json, metric);
    final p = _stat(proto, metric);
    if (j == null || p == null) continue;
    final ratio = metric.ratio && p.median > 0
        ? '${(j.median / p.median).toStringAsFixed(1)}×'
        : '';
    out.writeln(
      '| ${metric.label} | ${metric.format(j.median)} '
      '| ${metric.format(p.median)} | $ratio |',
    );
  }
  return out.toString();
}

const _configTitles = {
  'normal/live-ui': 'Normal load, live UI',
  'heavy/live-ui': 'Heavy load, live UI',
  'heavy/decode-only': 'Heavy load, UI frozen (decoding only)',
};

// ---- Report ----------------------------------------------------------------

/// Readable Markdown report for one run.
String renderReport(RunData data) {
  final env = data.environment;
  final device = (env['device'] as Map?) ?? const {};
  final flutter = (env['flutter'] as Map?) ?? const {};
  final suite = data.suiteStart;
  final rounds = suite['rounds'];
  final duration = suite['durationSeconds'];
  final out = StringBuffer()
    ..writeln('# ${data.deviceName} · ${data.variant}')
    ..writeln()
    ..writeln(
      '_Generated by `tool/report.dart` from `raw.jsonl` and '
      '`environment.json` in this folder._',
    )
    ..writeln();

  if (env['variantDescription'] != null) {
    out
      ..writeln('**App version:** ${env['variantDescription']}')
      ..writeln();
  }

  out
    ..writeln('## Headline: heavy load, live UI')
    ..writeln()
    ..write(
      data.configs.contains('heavy/live-ui')
          ? _table(data, 'heavy/live-ui', _headline)
          : '_Not run._\n',
    )
    ..writeln()
    ..writeln('Medians of $rounds rounds per format, $duration s each.')
    ..writeln();

  out
    ..writeln('## Environment')
    ..writeln()
    ..writeln('| | |')
    ..writeln('|---|---|');
  void row(String label, Object? value) {
    if (value == null || '$value'.isEmpty) return;
    out.writeln('| $label | $value |');
  }

  row('Device', device['name']);
  row('Model', device['model']);
  row('Chip', device['chip']);
  row('OS', device['os'] ?? suite['osVersion']);
  row('CPU cores', suite['cpus']);
  row(
    'Screen refresh',
    suite['refreshRate'] == null
        ? null
        : '${(suite['refreshRate'] as num).round()} Hz',
  );
  row('Build mode', suite['mode']);
  row('Flutter', flutter['version']);
  row('Dart', flutter['dart']);
  row('Feed server host', env['host']);
  row('Connection', env['connection']);
  row('Variant', data.variant);
  row(
    'Suite',
    '$rounds rounds × 2 formats × $duration s per configuration, '
        'format order alternating',
  );
  row('Date', env['date']);
  row('Git commit', env['gitCommit']);
  row('Command', env['command'] == null ? null : '`${env['command']}`');
  row('Notes', env['notes']);
  out.writeln();

  for (final config in data.configs) {
    out
      ..writeln('## ${_configTitles[config] ?? config}')
      ..writeln()
      ..write(
        _table(
          data,
          config,
          config.endsWith('decode-only') ? _frozenMetrics : _liveMetrics,
        ),
      )
      ..writeln();
  }

  out
    ..writeln('## Checks')
    ..writeln();
  for (final check in _checks(data)) {
    out.writeln('- $check');
  }
  out
    ..writeln()
    ..writeln('## What the rows mean')
    ..writeln()
    ..writeln(
      '- **Frames per second:** 60 is perfectly smooth on a 60 Hz screen. '
      'Frames are drawn only when data changes, so a very quiet feed can '
      'show fewer frames without anything being wrong.',
    )
    ..writeln(
      '- **Frames that missed the deadline:** took longer than one screen '
      'refresh (16.7 ms at 60 Hz) on the UI or GPU thread.',
    )
    ..writeln(
      '- **UI thread still busy when a frame was due:** time the frame had to '
      'wait. Decoding on the UI thread shows up here.',
    )
    ..writeln(
      '- **Background isolate CPU:** present when decoding runs off the UI '
      'thread. It is the JSON or Protobuf cost moved to another core.',
    )
    ..writeln(
      '- **Tick age when shown:** from the message arriving to the frame that '
      'shows it.',
    );
  return out.toString();
}

List<String> _checks(RunData data) {
  final checks = <String>[];
  final errors = data.runs.fold<num>(
    0,
    (sum, r) => sum + ((r['decodeErrors'] as num?) ?? 0),
  );
  checks.add(
    errors == 0
        ? 'No decode errors in ${data.runs.length} runs.'
        : '**$errors decode errors.** The run is not valid.',
  );

  final expected =
      data.configs.length * 2 * ((data.suiteStart['rounds'] as num?) ?? 0);
  if (data.runs.length < expected) {
    checks.add(
      '**Only ${data.runs.length} of $expected runs completed.** The suite '
      'was stopped early.',
    );
  }

  for (final config in data.configs) {
    final builds = [
      for (final r in data.runs)
        if (normaliseConfig(r['config'] as String) == config)
          (r['buildAvgUs'] as num).toDouble(),
    ];
    final low = builds.reduce(math.min);
    final high = builds.reduce(math.max);
    if (high > 1.5 * low + 500) {
      checks.add(
        '$config: frame build time ranged ${_ms(low)}–${_ms(high)} across '
        'rounds. On phones this is usually CPU throttling after the first '
        'round; JSON and Protobuf alternate, so both are affected equally.',
      );
    }
  }
  return checks;
}

/// Short plain-text summary for the terminal.
String renderConsoleSummary(RunData data) {
  if (!data.configs.contains('heavy/live-ui')) return '';
  final json = data.select('heavy/live-ui', 'json');
  final proto = data.select('heavy/live-ui', 'protobuf');
  final out = StringBuffer()
    ..writeln('Heavy load, live UI (medians)')
    ..writeln(
      '${''.padRight(44)}${'JSON'.padLeft(12)}${'Protobuf'.padLeft(12)}',
    );
  for (final metric in _headline) {
    final j = _stat(json, metric);
    final p = _stat(proto, metric);
    if (j == null || p == null) continue;
    out.writeln(
      '${metric.label.padRight(44)}'
      '${metric.format(j.median).padLeft(12)}'
      '${metric.format(p.median).padLeft(12)}',
    );
  }
  return out.toString();
}

/// `results/README.md`: one row per run.
String renderIndex(List<RunData> runs) {
  final out = StringBuffer()
    ..writeln('# Benchmark runs')
    ..writeln()
    ..writeln(
      'One folder per run: `REPORT.md` (readable), `raw.jsonl` (what the app '
      'measured) and `environment.json` (device, Flutter version, command). '
      'Regenerate the reports and this table with `dart run tool/report.dart`.',
    )
    ..writeln()
    ..writeln(
      '| Run | Device | App version | fps, heavy load (JSON / Protobuf) '
      '| Decode per message (JSON / Protobuf) | Size ratio |',
    )
    ..writeln('|---|---|---|---|---|---|');
  for (final data in runs) {
    String pair(_Metric metric) {
      final j = _stat(data.select('heavy/live-ui', 'json'), metric);
      final p = _stat(data.select('heavy/live-ui', 'protobuf'), metric);
      if (j == null || p == null) return '–';
      return '${metric.format(j.median)} / ${metric.format(p.median)}';
    }

    final j = _stat(data.select('heavy/live-ui', 'json'), _size);
    final p = _stat(data.select('heavy/live-ui', 'protobuf'), _size);
    final ratio = j == null || p == null
        ? '–'
        : '${(j.median / p.median).toStringAsFixed(1)}×';
    out.writeln(
      '| [${data.name}](${data.name}/REPORT.md) | ${data.deviceName} '
      '| ${data.variant} | ${pair(_fpsMetric)} | ${pair(_decode)} | $ratio |',
    );
  }
  return out.toString();
}

/// Run folders under [resultsDir], oldest first.
List<Directory> runFolders(Directory resultsDir) =>
    resultsDir
        .listSync()
        .whereType<Directory>()
        .where((d) => File('${d.path}/raw.jsonl').existsSync())
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
