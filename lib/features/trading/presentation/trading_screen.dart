import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:market_stream_benchmark/app/server_address.dart';
import 'package:market_stream_benchmark/app/server_settings.dart';
import 'package:market_stream_benchmark/features/sahi/data/sahi_market_controller.dart';
import 'package:market_stream_benchmark/features/sahi/presentation/sahi_dashboard.dart';
import 'package:market_stream_benchmark/features/trading/presentation/widgets/market_dashboard.dart';

import '../data/benchmark_feed.dart';
import '../data/trading_feed_client.dart';
import '../data/trading_market_controller.dart';

/// One configuration of the automated benchmark suite.
class BenchmarkSuiteConfig {
  const BenchmarkSuiteConfig({required this.load, required this.liveUi});

  final TradingLoad load;
  final bool liveUi;

  String get label => '${load.name}/${liveUi ? 'live-ui' : 'decode-only'}';
}

class TradingScreen extends StatefulWidget {
  const TradingScreen({
    super.key,
    this.variant = BenchmarkVariant.synthetic,
    this.suite = const [],
    this.suiteDurationSeconds = 20,
    this.suiteRounds = 5,
  });

  /// When non-empty, the screen runs each configuration in turn on open,
  /// printing `BENCH_RUN` / `BENCH_SUMMARY` JSON lines to the log.
  final List<BenchmarkSuiteConfig> suite;

  /// Which version of the app to run: feed, decoding and table rendering.
  final BenchmarkVariant variant;
  final int suiteDurationSeconds;
  final int suiteRounds;

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  late final BenchmarkFeedController _controller;

  StreamSubscription<bool>? _connectionSubscription;

  /// Market panels, created once and reused by identity so harness
  /// rebuilds (progress, status, results) never rebuild the market UI.
  late final BenchmarkDashboard _dashboard;

  TradingDecoder _decoder = TradingDecoder.json;
  bool _connected = false;
  bool _connecting = false;

  ServerAddress? _server;

  int _durationSeconds = 30;
  int _rounds = 3;
  TradingLoad _load = TradingLoad.normal;

  /// Rebuild the dashboard on every batch during runs, as a real trading UI
  /// would. When false, only decode/apply are exercised (UI frozen).
  bool _liveUi = true;
  bool _benchmarkRunning = false;
  bool _stopRequested = false;
  int _completedRuns = 0;
  int _totalPlannedRuns = 0;
  String _currentRunLabel = '';
  String _benchmarkStatus = 'Ready';
  Stopwatch? _activeRunWatch;
  Timer? _benchmarkUiTimer;
  Completer<void>? _benchmarkStopCompleter;
  final List<_TradingRunResult> _runResults = [];
  final Map<TradingDecoder, _TradingProtocolSummary> _summaries = {};

  /// Recompute the per-format summaries. Call only when [_runResults]
  /// changes, never from build().
  void _refreshSummaries() {
    _summaries.clear();
    for (final decoder in TradingDecoder.values) {
      final summary = _summaryFor(decoder);
      if (summary != null) _summaries[decoder] = summary;
    }
  }

  @override
  void initState() {
    super.initState();

    final variant = widget.variant;
    if (variant.brokerFeed) {
      final controller = SahiMarketController(
        offUiThread: variant.decodeOnIsolate,
      );
      _controller = controller;
      _dashboard = SahiDashboard(
        store: controller.store,
        paintedTables: variant.paintedTables,
      );
    } else {
      final controller = TradingMarketController();
      _controller = controller;
      _dashboard = MarketDashboard(store: controller.store);
    }

    if (widget.suite.isNotEmpty) {
      _durationSeconds = widget.suiteDurationSeconds;
      _rounds = widget.suiteRounds;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSuite());
    }

    _connectionSubscription = _controller.connectionUpdates.listen((connected) {
      if (!mounted) return;

      setState(() {
        _connected = connected;
        _connecting = false;
      });
    });
  }

  Future<void> _connect() async {
    if (_connecting || _connected) return;

    setState(() {
      _connecting = true;
      _server = null;
    });

    try {
      final server = AppSettingsScope.read(context).serverAddress;

      if (!mounted) return;

      setState(() {
        _server = server;
      });

      _controller.notifyUi = true;
      await _controller.connect(server: server, decoder: _decoder);

      if (!mounted) return;

      setState(() {
        _connecting = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _connecting = false;
        _connected = false;
        _server = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connection failed: $error')));
    }
  }

  Future<void> _disconnect() async {
    await _controller.disconnect();

    if (!mounted) return;

    setState(() {
      _connected = false;
      _server = null;
    });
  }

  @override
  void dispose() {
    _stopRequested = true;
    if (!(_benchmarkStopCompleter?.isCompleted ?? true)) {
      _benchmarkStopCompleter!.complete();
    }
    _benchmarkUiTimer?.cancel();
    _resultsChannel?.sink.close();
    _connectionSubscription?.cancel();
    _controller.dispose();
    _dashboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The dashboard uses hard-coded dark surfaces, so give its widgets
    // (dropdowns, segmented button, dialogs) a matching dark theme. Otherwise
    // they inherit the app's light theme and draw dark text on dark panels.
    return Theme(
      data: _darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E11),
        appBar: AppBar(
          backgroundColor: const Color(0xFF11161C),
          foregroundColor: Colors.white,
          title: Text(widget.variant.title),
          actions: [
            SegmentedButton<TradingDecoder>(
              segments: const [
                ButtonSegment(value: TradingDecoder.json, label: Text('JSON')),
                ButtonSegment(
                  value: TradingDecoder.protobuf,
                  label: Text('Protobuf'),
                ),
              ],
              selected: {_decoder},
              onSelectionChanged: _connected || _connecting || _benchmarkRunning
                  ? null
                  : (value) => setState(() => _decoder = value.first),
            ),
            const ServerSettingsAction(),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            // Harness panels are rebuilt from this state; dashboard panels
            // are the same instances every time, so Flutter skips them and
            // they update only from their own store subscriptions.
            final items = <Widget>[
              _benchmarkPanel(),
              _connectionPanel(),
              ..._dashboard.panels(wide: wide),
            ];

            // Built lazily: off-screen panels are neither built nor listening.
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    itemBuilder: (context, index) => items[index],
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  );

  Widget _connectionPanel() {
    return DashboardPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: _connected ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                _connecting
                    ? 'Connecting'
                    : _connected
                    ? 'Connected'
                    : 'Disconnected',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          if (_connected)
            FilledButton(
              onPressed: _benchmarkRunning ? null : _disconnect,
              child: const Text('Disconnect'),
            )
          else
            FilledButton(
              onPressed: _connecting || _benchmarkRunning ? null : _connect,
              child: Text(_connecting ? 'Connecting...' : 'Connect'),
            ),
          if (_server != null)
            Text(
              _server.toString(),
              style: const TextStyle(color: Colors.white54),
            ),
          Text(
            _decoder == TradingDecoder.json ? 'JSON' : 'Protobuf',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _benchmarkPanel() {
    // Cached: recomputing these sorts every sample collected so far, which
    // must not happen per frame or it pollutes the frame-time measurements.
    final jsonSummary = _summaries[TradingDecoder.json];
    final protobufSummary = _summaries[TradingDecoder.protobuf];
    final plannedSeconds = _durationSeconds * _rounds * 2;
    final plannedMinutes = plannedSeconds ~/ 60;
    final plannedRemainder = plannedSeconds % 60;
    final watch = _activeRunWatch;
    final progress = watch == null
        ? null
        : (watch.elapsedMilliseconds / (_durationSeconds * 1000))
              .clamp(0.0, 1.0)
              .toDouble();

    // While measuring, show only a compact status strip. The full controls
    // and results table are tall: on a phone they would push the market UI
    // off-screen (so it would not render at all), and rebuilding them every
    // second would add harness cost to the frames being measured.
    if (_benchmarkRunning) {
      return DashboardPanel(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run ${_completedRuns + 1} / $_totalPlannedRuns · '
                    '$_currentRunLabel',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _stopRequested ? null : _requestBenchmarkStop,
              child: const Text('Stop'),
            ),
          ],
        ),
      );
    }

    final suiteStatus = _suiteStatusPanel();
    if (suiteStatus != null) return suiteStatus;

    return DashboardPanel(
      title: 'BENCHMARK — JSON VS PROTOBUF',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Each round runs both formats against the same seeded server workload. '
            'Run order alternates to reduce order bias.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _durationSeconds,
                  decoration: const InputDecoration(
                    labelText: 'Duration / run',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: const Color(0xFF1B232C),
                  items: const [10, 20, 30, 60]
                      .map(
                        (seconds) => DropdownMenuItem(
                          value: seconds,
                          child: Text('$seconds sec'),
                        ),
                      )
                      .toList(),
                  onChanged: _benchmarkRunning
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _durationSeconds = value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _rounds,
                  decoration: const InputDecoration(
                    labelText: 'Runs / format',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: const Color(0xFF1B232C),
                  items: const [1, 3, 5, 10]
                      .map(
                        (count) => DropdownMenuItem(
                          value: count,
                          child: Text('$count ${count == 1 ? 'run' : 'runs'}'),
                        ),
                      )
                      .toList(),
                  onChanged: _benchmarkRunning
                      ? null
                      : (value) {
                          if (value != null) setState(() => _rounds = value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TradingLoad>(
                  // Keyed so the field follows programmatic changes (suite).
                  key: ValueKey(_load),
                  initialValue: _load,
                  decoration: const InputDecoration(
                    labelText: 'Server load',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: const Color(0xFF1B232C),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: TradingLoad.normal,
                      child: Text(
                        widget.variant.brokerFeed
                            ? 'Normal (100 instr, ~200 ticks/s)'
                            : 'Normal (~200 ev/s)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: TradingLoad.heavy,
                      child: Text(
                        widget.variant.brokerFeed
                            ? 'Heavy (1,000 instr, ~4k ticks/s)'
                            : 'Heavy (~6k ev/s)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: _benchmarkRunning
                      ? null
                      : (value) {
                          if (value != null) setState(() => _load = value);
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Live UI during runs',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  value: _liveUi,
                  onChanged: _benchmarkRunning
                      ? null
                      : (value) => setState(() => _liveUi = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Planned measurement time: ${plannedMinutes}m ${plannedRemainder}s '
            '($_rounds rounds × 2 formats × $_durationSeconds sec), '
            'plus connection setup.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _benchmarkRunning || _connecting
                    ? null
                    : _runComparison,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run JSON vs Protobuf'),
              ),
              OutlinedButton.icon(
                onPressed: _benchmarkRunning ? _requestBenchmarkStop : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop test'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Status: $_benchmarkStatus',
            style: const TextStyle(color: Colors.white),
          ),
          if (_benchmarkRunning) ...[
            const SizedBox(height: 8),
            Text(
              'Run $_completedRuns / $_totalPlannedRuns · $_currentRunLabel',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
          if (_runResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF303A45)),
            const SizedBox(height: 12),
            const Text(
              'RUN RESULTS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _resultsTable(),
            if (jsonSummary != null && protobufSummary != null) ...[
              const SizedBox(height: 20),
              const Text(
                'AGGREGATED COMPARISON',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 700
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _summaryCard('JSON', jsonSummary),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _summaryCard('PROTOBUF', protobufSummary),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                _decodeWinnerText(jsonSummary, protobufSummary),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _resultsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        columns: const [
          DataColumn(label: Text('ROUND')),
          DataColumn(label: Text('DURATION s'), numeric: true),
          DataColumn(label: Text('CONNECT ms'), numeric: true),
          DataColumn(label: Text('FORMAT')),
          DataColumn(label: Text('BATCHES'), numeric: true),
          DataColumn(label: Text('EVENTS'), numeric: true),
          DataColumn(label: Text('PAYLOAD'), numeric: true),
          DataColumn(label: Text('DECODE AVG µs'), numeric: true),
          DataColumn(label: Text('DECODE P95 µs'), numeric: true),
          DataColumn(label: Text('APPLY AVG µs'), numeric: true),
          DataColumn(label: Text('EVENTS / SEC'), numeric: true),
          DataColumn(label: Text('MiB / SEC'), numeric: true),
          DataColumn(label: Text('ERRORS'), numeric: true),
          DataColumn(label: Text('FRAMES'), numeric: true),
          DataColumn(label: Text('SLOW FRAMES %'), numeric: true),
        ],
        rows: _runResults.map((result) {
          return DataRow(
            cells: [
              DataCell(Text('${result.round}')),
              DataCell(Text(result.elapsedSeconds.toStringAsFixed(1))),
              DataCell(Text('${result.connectMilliseconds}')),
              DataCell(Text(result.decoderLabel)),
              DataCell(Text('${result.batches}')),
              DataCell(Text('${result.events}')),
              DataCell(Text(_formatBytes(result.payloadBytes))),
              DataCell(
                Text(result.averageDecodeMicroseconds.toStringAsFixed(1)),
              ),
              DataCell(Text('${result.p95DecodeMicroseconds}')),
              DataCell(
                Text(result.averageApplyMicroseconds.toStringAsFixed(1)),
              ),
              DataCell(Text(result.eventsPerSecond.toStringAsFixed(1))),
              DataCell(Text(result.megabytesPerSecond.toStringAsFixed(3))),
              DataCell(Text('${result.decodeErrors}')),
              DataCell(Text('${result.frames.count}')),
              DataCell(Text(result.frames.slowFramePercent.toStringAsFixed(1))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _summaryCard(String title, _TradingProtocolSummary summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10161D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303A45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _summaryMetric('Completed runs', '${summary.runCount}'),
          _summaryMetric('Total batches', '${summary.batches}'),
          _summaryMetric('Total events', '${summary.events}'),
          _summaryMetric(
            'Avg connect',
            '${summary.averageConnectMilliseconds.toStringAsFixed(1)} ms',
          ),
          _summaryMetric('Total payload', _formatBytes(summary.payloadBytes)),
          _summaryMetric(
            'Average decode',
            '${summary.averageDecodeMicroseconds.toStringAsFixed(2)} µs',
          ),
          _summaryMetric('P95 decode', '${summary.p95DecodeMicroseconds} µs'),
          _summaryMetric(
            'Average apply',
            '${summary.averageApplyMicroseconds.toStringAsFixed(2)} µs',
          ),
          _summaryMetric(
            'Throughput',
            '${summary.eventsPerSecond.toStringAsFixed(1)} events/sec',
          ),
          _summaryMetric(
            'Payload rate',
            '${summary.megabytesPerSecond.toStringAsFixed(3)} MiB/sec',
          ),
          _summaryMetric('Decode errors', '${summary.decodeErrors}'),
          _summaryMetric(
            'UI thread spent decoding',
            '${summary.json['decodeBusyPercent']} %',
          ),
          _summaryMetric('Frames rendered', '${summary.frames.count}'),
          _summaryMetric(
            'Slow frames',
            '${summary.frames.slowFrames} '
                '(${summary.frames.slowFramePercent.toStringAsFixed(1)} %)',
          ),
          _summaryMetric(
            'Frame p95 (vsync → raster)',
            '${(summary.json['frameTotalP95Us'] as int) / 1000} ms',
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _TradingProtocolSummary? _summaryFor(TradingDecoder decoder) {
    final results = _runResults
        .where((result) => result.decoder == decoder)
        .toList();
    if (results.isEmpty) return null;

    final decodeSamples = results
        .expand((result) => result.decodeSamples)
        .toList();
    final applySamples = results
        .expand((result) => result.applySamples)
        .toList();
    final totalDuration = results.fold<double>(
      0,
      (total, result) => total + result.elapsedSeconds,
    );
    final totalBatches = results.fold<int>(
      0,
      (total, result) => total + result.batches,
    );
    final totalEvents = results.fold<int>(
      0,
      (total, result) => total + result.events,
    );
    final totalBytes = results.fold<int>(
      0,
      (total, result) => total + result.payloadBytes,
    );
    final totalErrors = results.fold<int>(
      0,
      (total, result) => total + result.decodeErrors,
    );

    return _TradingProtocolSummary(
      runCount: results.length,
      batches: totalBatches,
      events: totalEvents,
      averageConnectMilliseconds:
          results.fold<int>(
            0,
            (total, result) => total + result.connectMilliseconds,
          ) /
          results.length,
      payloadBytes: totalBytes,
      decodeErrors: totalErrors,
      averageDecodeMicroseconds: _average(decodeSamples),
      p95DecodeMicroseconds: _percentile95(decodeSamples),
      averageApplyMicroseconds: _average(applySamples),
      eventsPerSecond: totalDuration == 0 ? 0 : totalEvents / totalDuration,
      megabytesPerSecond: totalDuration == 0
          ? 0
          : totalBytes / (1024 * 1024) / totalDuration,
      decodeSamples: decodeSamples,
      totalDurationSeconds: totalDuration,
      frames: results.fold(
        _FrameStats(results.first.frames.budgetMicros),
        (stats, result) => stats..addAll(result.frames),
      ),
    );
  }

  String _decodeWinnerText(
    _TradingProtocolSummary json,
    _TradingProtocolSummary protobuf,
  ) {
    final jsonTime = json.averageDecodeMicroseconds;
    final protobufTime = protobuf.averageDecodeMicroseconds;
    if (jsonTime <= 0 || protobufTime <= 0) {
      return 'Insufficient decode samples to compare formats.';
    }
    if ((jsonTime - protobufTime).abs() < 0.01) {
      return 'Average decode time is effectively tied.';
    }

    final protobufWins = protobufTime < jsonTime;
    final faster = protobufWins ? 'Protobuf' : 'JSON';
    final slowerTime = protobufWins ? jsonTime : protobufTime;
    final fasterTime = protobufWins ? protobufTime : jsonTime;
    final improvement = (slowerTime - fasterTime) / slowerTime * 100;

    return '$faster average decode time is ${improvement.toStringAsFixed(1)}% lower. '
        'This compares client-side decoding time, not end-to-end network latency.';
  }

  WebSocketChannel? _resultsChannel;

  /// Every line reported during the suite, kept so the results can be
  /// copied off the device if uploading to the server failed.
  final List<String> _reportLog = [];
  bool _suiteFinished = false;
  bool _uploadConnected = false;
  bool _uploadLost = false;

  /// Logs a result line and, during a suite, also sends it to the server's
  /// /results endpoint so it is saved even if the debug connection drops.
  void _report(String line) {
    debugPrint(line);
    _reportLog.add(line);
    _resultsChannel?.sink.add(line);
  }

  Future<void> _copyResults() async {
    await Clipboard.setData(ClipboardData(text: _reportLog.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${_reportLog.length} result lines')),
    );
  }

  /// Shown once a suite has finished: whether the results reached the
  /// server, and a button to copy them off the device either way.
  Widget? _suiteStatusPanel() {
    if (!_suiteFinished) return null;
    final uploaded = _uploadConnected && !_uploadLost;
    return DashboardPanel(
      title: 'BENCHMARK SUITE FINISHED',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uploaded
                ? 'Results were uploaded to the feed server.'
                : 'Results could NOT be uploaded to the feed server. '
                      'Tap Copy results and paste them into a message.',
            style: TextStyle(
              color: uploaded ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_reportLog.length} result lines',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _copyResults,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy results'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSuite() async {
    final refreshRate = View.of(context).display.refreshRate;
    final server = AppSettingsScope.read(context).serverAddress;
    try {
      final channel = WebSocketChannel.connect(server.websocketUri('/results'));
      await channel.ready.timeout(const Duration(seconds: 10));
      _resultsChannel = channel;
      _uploadConnected = true;
      channel.stream.listen(
        (_) {},
        onError: (_) => _uploadLost = true,
        onDone: () {
          if (!_suiteFinished) _uploadLost = true;
        },
      );
    } catch (error) {
      debugPrint('Results upload unavailable: $error');
    }

    _report(
      'BENCH_SUITE_START ${jsonEncode({'variant': widget.variant.id, 'configs': widget.suite.map((c) => c.label).toList(), 'durationSeconds': _durationSeconds, 'rounds': _rounds, 'refreshRate': refreshRate, 'os': Platform.operatingSystem, 'osVersion': Platform.operatingSystemVersion, 'cpus': Platform.numberOfProcessors, 'mode': kProfileMode
          ? 'profile'
          : kReleaseMode
          ? 'release'
          : 'debug'})}',
    );

    for (final config in widget.suite) {
      if (!mounted || _stopRequested) break;
      setState(() {
        _load = config.load;
        _liveUi = config.liveUi;
      });
      await _runComparison();
      if (!mounted) return;
      _printSummary(config.label);
    }
    _report('BENCH_SUITE_DONE');
    final channel = _resultsChannel;
    _resultsChannel = null;
    if (mounted) setState(() => _suiteFinished = true);
    await channel?.sink.close();
  }

  void _printSummary(String label) {
    for (final decoder in TradingDecoder.values) {
      final summary = _summaries[decoder];
      if (summary == null) continue;
      _report(
        'BENCH_SUMMARY ${jsonEncode({'variant': widget.variant.id, 'config': label, 'decoder': decoder.name, ...summary.json})}',
      );
    }
  }

  Future<void> _runComparison() async {
    if (_benchmarkRunning || _connecting) return;

    if (_connected) {
      await _controller.disconnect();
    }
    if (!mounted) return;

    final server = AppSettingsScope.read(context).serverAddress;
    final refreshRate = View.of(context).display.refreshRate;
    final configLabel = '${_load.name}/${_liveUi ? 'live-ui' : 'decode-only'}';

    setState(() {
      _benchmarkRunning = true;
      // Decode-only runs keep the market UI frozen; live runs update it.
      _controller.notifyUi = _liveUi;
      _stopRequested = false;
      _completedRuns = 0;
      _totalPlannedRuns = _rounds * 2;
      _currentRunLabel = 'Preparing';
      _benchmarkStatus = 'Starting comparison';
      _runResults.clear();
      _summaries.clear();
      _activeRunWatch = null;
      _server = server;
    });

    _benchmarkStopCompleter = Completer<void>();
    _benchmarkUiTimer?.cancel();
    _benchmarkUiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _benchmarkRunning) setState(() {});
    });

    try {
      for (var round = 1; round <= _rounds; round++) {
        final order = round.isOdd
            ? [TradingDecoder.json, TradingDecoder.protobuf]
            : [TradingDecoder.protobuf, TradingDecoder.json];

        for (final decoder in order) {
          if (_stopRequested) break;

          _currentRunLabel =
              'Round $round — ${_decoderLabel(decoder)} · $configLabel';
          setState(() {
            _benchmarkStatus = 'Connecting ${_decoderLabel(decoder)}';
            _activeRunWatch = null;
          });

          final result = await _runDecoder(
            server: server,
            decoder: decoder,
            round: round,
            refreshRate: refreshRate,
          );

          if (result != null) {
            _report(
              'BENCH_RUN ${jsonEncode({'variant': widget.variant.id, 'config': configLabel, ...result.toJson()})}',
            );
          }

          if (result != null && mounted) {
            setState(() {
              _runResults.add(result);
              _refreshSummaries();
              _completedRuns++;
              _benchmarkStatus =
                  'Completed $_completedRuns / $_totalPlannedRuns runs';
            });
          }
        }

        if (_stopRequested) break;
      }

      if (_stopRequested) {
        _benchmarkStatus = 'Stopped — incomplete run was discarded';
      } else {
        _benchmarkStatus = 'Completed — ${_runResults.length} runs recorded';
      }
    } catch (error) {
      _benchmarkStatus = 'Failed: $error';
    } finally {
      _benchmarkUiTimer?.cancel();
      _benchmarkUiTimer = null;
      _activeRunWatch = null;
      await _controller.disconnect();

      if (mounted) {
        setState(() {
          _benchmarkRunning = false;
          _controller.notifyUi = true;
          // Catch the market UI up with whatever a frozen run applied.
          _controller.flushUi();
          _connected = false;
          _connecting = false;
          _currentRunLabel = '';
        });
      }
    }
  }

  Future<_TradingRunResult?> _runDecoder({
    required ServerAddress server,
    required TradingDecoder decoder,
    required int round,
    required double refreshRate,
  }) async {
    var acceptingSamples = true;
    final accumulator = _TradingRunAccumulator(
      frameBudgetMicros: (Duration.microsecondsPerSecond / refreshRate).round(),
    );
    void onTimings(List<FrameTiming> timings) {
      // Only count frames rendered inside the measurement window.
      if (!acceptingSamples || accumulator.measurementWatch == null) return;
      timings.forEach(accumulator.recordFrame);
    }

    final firstBatch = Completer<void>();
    final connectWatch = Stopwatch()..start();
    SchedulerBinding.instance.addTimingsCallback(onTimings);

    try {
      await Future.any<void>([
        _controller
            .connect(
              server: server,
              decoder: decoder,
              load: _load,
              onBatchMetrics: (metrics) {
                if (!acceptingSamples || _stopRequested) return;

                if (accumulator.measurementWatch == null) {
                  accumulator.measurementWatch = Stopwatch()..start();
                  _activeRunWatch = accumulator.measurementWatch;
                  if (!firstBatch.isCompleted) firstBatch.complete();
                }

                accumulator.record(metrics);
              },
              onBatchError: (error, stackTrace) {
                if (acceptingSamples) accumulator.decodeErrors++;
              },
            )
            .timeout(const Duration(seconds: 12)),
        _benchmarkStopCompleter!.future,
      ]);
      connectWatch.stop();

      if (_stopRequested) return null;

      await Future.any<void>([
        firstBatch.future.timeout(const Duration(seconds: 10)),
        _benchmarkStopCompleter!.future,
      ]);

      if (_stopRequested) return null;

      if (mounted) {
        setState(() {
          _benchmarkStatus = 'Running ${_decoderLabel(decoder)}';
        });
      }

      await Future.any<void>([
        Future<void>.delayed(Duration(seconds: _durationSeconds)),
        _benchmarkStopCompleter!.future,
      ]);

      acceptingSamples = false;
      accumulator.measurementWatch?.stop();
      _activeRunWatch = null;

      if (_stopRequested) return null;
      if (accumulator.batches == 0) {
        throw StateError('No trading batches received');
      }

      final elapsedMicroseconds =
          accumulator.measurementWatch?.elapsedMicroseconds ?? 0;
      final elapsedSeconds =
          elapsedMicroseconds / Duration.microsecondsPerSecond;

      return _TradingRunResult(
        round: round,
        decoder: decoder,
        connectMilliseconds: connectWatch.elapsedMilliseconds,
        elapsedSeconds: elapsedSeconds,
        batches: accumulator.batches,
        events: accumulator.events,
        payloadBytes: accumulator.payloadBytes,
        decodeErrors: accumulator.decodeErrors,
        decodeSamples: List<int>.unmodifiable(accumulator.decodeSamples),
        applySamples: List<int>.unmodifiable(accumulator.applySamples),
        frames: accumulator.frames,
        refreshRate: refreshRate,
        workerBusyMicros: accumulator.workerBusyMicros,
        stalenessSamples: List<int>.unmodifiable(accumulator.stalenessSamples),
      );
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(onTimings);
      acceptingSamples = false;
      accumulator.measurementWatch?.stop();
      _activeRunWatch = null;
      await _controller.disconnect();
    }
  }

  void _requestBenchmarkStop() {
    if (!_benchmarkRunning || _stopRequested) return;

    _stopRequested = true;
    if (!(_benchmarkStopCompleter?.isCompleted ?? true)) {
      _benchmarkStopCompleter!.complete();
    }

    setState(() {
      _benchmarkStatus = 'Stopping — current partial run will be discarded';
    });
  }

  String _decoderLabel(TradingDecoder decoder) =>
      decoder == TradingDecoder.json ? 'JSON' : 'Protobuf';

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MiB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}

class _TradingRunAccumulator {
  _TradingRunAccumulator({required int frameBudgetMicros})
    : frames = _FrameStats(frameBudgetMicros);

  final _FrameStats frames;

  void recordFrame(FrameTiming timing) => frames.record(timing);

  int batches = 0;
  int events = 0;
  int payloadBytes = 0;
  int decodeErrors = 0;
  Stopwatch? measurementWatch;
  final List<int> decodeSamples = [];
  final List<int> applySamples = [];

  int workerBusyMicros = 0;
  final List<int> stalenessSamples = [];

  void record(TradingBatchMetrics metrics) {
    batches++;
    events += metrics.eventCount;
    payloadBytes += metrics.payloadBytes;
    final samples = metrics.decodeSamples;
    if (samples != null) {
      decodeSamples.addAll(samples);
    } else {
      decodeSamples.add(metrics.decodeMicroseconds);
    }
    applySamples.add(metrics.applyMicroseconds);
    workerBusyMicros += metrics.workerBusyMicroseconds ?? 0;
    final staleness = metrics.stalenessMicroseconds;
    if (staleness != null) stalenessSamples.add(staleness);
  }
}

class _TradingRunResult {
  _TradingRunResult({
    required this.round,
    required this.decoder,
    required this.connectMilliseconds,
    required this.elapsedSeconds,
    required this.batches,
    required this.events,
    required this.payloadBytes,
    required this.decodeErrors,
    required this.decodeSamples,
    required this.applySamples,
    required this.frames,
    required this.refreshRate,
    this.workerBusyMicros = 0,
    this.stalenessSamples = const [],
  });

  final _FrameStats frames;
  final double refreshRate;

  /// Background-isolate time (decode + coalescing); 0 when decoding on the
  /// UI isolate.
  final int workerBusyMicros;

  /// Age of the oldest tick in each UI update, when it was applied.
  final List<int> stalenessSamples;
  final int round;
  final TradingDecoder decoder;
  final double elapsedSeconds;
  final int connectMilliseconds;
  final int batches;
  final int events;
  final int payloadBytes;
  final int decodeErrors;
  final List<int> decodeSamples;
  final List<int> applySamples;

  String get decoderLabel =>
      decoder == TradingDecoder.json ? 'JSON' : 'Protobuf';

  // Computed once: the results table reads these on every rebuild.
  late final double averageDecodeMicroseconds = _average(decodeSamples);
  late final int p95DecodeMicroseconds = _percentile95(decodeSamples);
  late final double averageApplyMicroseconds = _average(applySamples);

  double get eventsPerSecond =>
      elapsedSeconds <= 0 ? 0 : events / elapsedSeconds;

  double get megabytesPerSecond =>
      elapsedSeconds <= 0 ? 0 : payloadBytes / (1024 * 1024) / elapsedSeconds;

  /// Share of wall-clock time the UI isolate spent decoding.
  double get decodeBusyPercent => elapsedSeconds <= 0
      ? 0
      : decodeSamples.fold<int>(0, (a, b) => a + b) /
            (elapsedSeconds * Duration.microsecondsPerSecond) *
            100;

  Map<String, Object?> toJson() => {
    'round': round,
    'decoder': decoder.name,
    'elapsedSeconds': _round2(elapsedSeconds),
    'connectMs': connectMilliseconds,
    'batches': batches,
    'events': events,
    'payloadBytes': payloadBytes,
    'decodeErrors': decodeErrors,
    'decodeAvgUs': _round2(averageDecodeMicroseconds),
    'decodeP50Us': _percentile(decodeSamples, 0.50),
    'decodeP95Us': p95DecodeMicroseconds,
    'decodeP99Us': _percentile(decodeSamples, 0.99),
    'decodeUsPerEvent': events == 0
        ? 0
        : _round2(decodeSamples.fold<int>(0, (a, b) => a + b) / events),
    'decodeBusyPercent': _round2(decodeBusyPercent),
    'applyAvgUs': _round2(averageApplyMicroseconds),
    'eventsPerSecond': _round2(eventsPerSecond),
    'refreshRate': refreshRate,
    if (workerBusyMicros > 0) ...{
      'workerBusyPercent': _round2(
        workerBusyMicros /
            (elapsedSeconds * Duration.microsecondsPerSecond) *
            100,
      ),
      'uiUpdatesPerSecond': _round2(batches / elapsedSeconds),
    },
    if (stalenessSamples.isNotEmpty) ...{
      'stalenessP50Us': _percentile(stalenessSamples, 0.50),
      'stalenessP95Us': _percentile(stalenessSamples, 0.95),
      'stalenessP99Us': _percentile(stalenessSamples, 0.99),
    },
    ...frames.toJson(),
  };
}

/// UI frame timings collected during one run.
class _FrameStats {
  _FrameStats(this.budgetMicros);

  final int budgetMicros;
  final List<int> buildMicros = [];
  final List<int> rasterMicros = [];
  final List<int> totalMicros = [];
  final List<int> vsyncOverheadMicros = [];
  int slowFrames = 0;

  int get count => totalMicros.length;

  void record(FrameTiming timing) {
    final build = timing.buildDuration.inMicroseconds;
    final raster = timing.rasterDuration.inMicroseconds;
    final overhead = timing.vsyncOverhead.inMicroseconds;
    buildMicros.add(build);
    rasterMicros.add(raster);
    totalMicros.add(timing.totalSpan.inMicroseconds);
    vsyncOverheadMicros.add(overhead);

    // A frame misses its deadline when the UI thread starts late (busy, e.g.
    // decoding) and/or builds slowly, or when rasterizing overruns.
    if (overhead + build > budgetMicros || raster > budgetMicros) {
      slowFrames++;
    }
  }

  void addAll(_FrameStats other) {
    buildMicros.addAll(other.buildMicros);
    rasterMicros.addAll(other.rasterMicros);
    totalMicros.addAll(other.totalMicros);
    vsyncOverheadMicros.addAll(other.vsyncOverheadMicros);
    slowFrames += other.slowFrames;
  }

  double get slowFramePercent => count == 0 ? 0 : slowFrames / count * 100;

  Map<String, Object?> toJson() => {
    'frames': count,
    'frameBudgetUs': budgetMicros,
    'slowFrames': slowFrames,
    'slowFramePercent': _round2(slowFramePercent),
    'buildAvgUs': _round2(_average(buildMicros)),
    'buildP95Us': _percentile(buildMicros, 0.95),
    'rasterP95Us': _percentile(rasterMicros, 0.95),
    'vsyncOverheadAvgUs': _round2(_average(vsyncOverheadMicros)),
    'vsyncOverheadP95Us': _percentile(vsyncOverheadMicros, 0.95),
    'frameTotalP95Us': _percentile(totalMicros, 0.95),
    'frameTotalP99Us': _percentile(totalMicros, 0.99),
  };
}

double _round2(double value) => (value * 100).roundToDouble() / 100;

class _TradingProtocolSummary {
  _TradingProtocolSummary({
    required this.runCount,
    required this.batches,
    required this.events,
    required this.averageConnectMilliseconds,
    required this.payloadBytes,
    required this.decodeErrors,
    required this.averageDecodeMicroseconds,
    required this.p95DecodeMicroseconds,
    required this.averageApplyMicroseconds,
    required this.eventsPerSecond,
    required this.megabytesPerSecond,
    required this.decodeSamples,
    required this.totalDurationSeconds,
    required this.frames,
  });

  final List<int> decodeSamples;
  final double totalDurationSeconds;
  final _FrameStats frames;
  final int runCount;
  final int batches;
  final int events;
  final double averageConnectMilliseconds;
  final int payloadBytes;
  final int decodeErrors;
  final double averageDecodeMicroseconds;
  final int p95DecodeMicroseconds;
  final double averageApplyMicroseconds;
  final double eventsPerSecond;
  final double megabytesPerSecond;

  int get totalDecodeMicros => decodeSamples.fold<int>(0, (a, b) => a + b);

  /// Cached [toJson]; it sorts every sample, so compute it once.
  late final Map<String, Object?> json = toJson();

  Map<String, Object?> toJson() => {
    'runs': runCount,
    'batches': batches,
    'events': events,
    'payloadBytes': payloadBytes,
    'bytesPerEvent': events == 0 ? 0 : _round2(payloadBytes / events),
    'decodeErrors': decodeErrors,
    'decodeAvgUs': _round2(averageDecodeMicroseconds),
    'decodeP50Us': _percentile(decodeSamples, 0.50),
    'decodeP95Us': p95DecodeMicroseconds,
    'decodeP99Us': _percentile(decodeSamples, 0.99),
    'decodeUsPerEvent': events == 0 ? 0 : _round2(totalDecodeMicros / events),
    'decodeBusyPercent': totalDurationSeconds <= 0
        ? 0
        : _round2(
            totalDecodeMicros /
                (totalDurationSeconds * Duration.microsecondsPerSecond) *
                100,
          ),
    'applyAvgUs': _round2(averageApplyMicroseconds),
    'eventsPerSecond': _round2(eventsPerSecond),
    ...frames.toJson(),
  };
}

double _average(List<int> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

int _percentile95(List<int> values) => _percentile(values, 0.95);

/// Nearest-rank percentile, [p] in 0..1.
int _percentile(List<int> values, double p) {
  if (values.isEmpty) return 0;
  final sorted = List<int>.of(values)..sort();
  final index = ((sorted.length * p).ceil() - 1)
      .clamp(0, sorted.length - 1)
      .toInt();
  return sorted[index];
}
