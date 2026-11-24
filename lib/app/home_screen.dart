import 'package:flutter/material.dart';
import 'package:market_stream_benchmark/app/server_settings.dart';
import 'package:market_stream_benchmark/features/trading/data/benchmark_feed.dart';
import 'package:market_stream_benchmark/features/trading/data/trading_feed_client.dart';
import 'package:market_stream_benchmark/features/trading/presentation/trading_screen.dart';

/// Unattended suite, used by `tool/bench.dart`:
/// `--dart-define=BENCH_SUITE=true --dart-define=BENCH_VARIANT=<id>` opens
/// that variant (see [BenchmarkVariant.id]) and runs the full suite.
const bool _benchSuite = bool.fromEnvironment('BENCH_SUITE');
const String _benchVariant = String.fromEnvironment(
  'BENCH_VARIANT',
  defaultValue: 'broker-optimised',
);
const int _benchDuration = int.fromEnvironment(
  'BENCH_DURATION',
  defaultValue: 20,
);
const int _benchRounds = int.fromEnvironment('BENCH_ROUNDS', defaultValue: 5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!_benchSuite) return;

    final variant = BenchmarkVariant.byId(_benchVariant);
    if (variant == null) {
      throw ArgumentError('Unknown BENCH_VARIANT "$_benchVariant"');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TradingScreen(
            variant: variant,
            suite: const [
              BenchmarkSuiteConfig(load: TradingLoad.normal, liveUi: true),
              BenchmarkSuiteConfig(load: TradingLoad.heavy, liveUi: true),
              BenchmarkSuiteConfig(load: TradingLoad.heavy, liveUi: false),
            ],
            suiteDurationSeconds: _benchDuration,
            suiteRounds: _benchRounds,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Feed Benchmark'),
        actions: const [ServerSettingsAction(), SizedBox(width: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Text('Choose a version', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Each screen benchmarks JSON vs Protobuf on a live trading UI.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Server: ${settings.serverAddress}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 28),
          for (final (index, variant) in BenchmarkVariant.values.indexed) ...[
            if (index > 0) const SizedBox(height: 16),
            _ScenarioCard(
              number: '${index + 1}'.padLeft(2, '0'),
              title: variant.title,
              description: variant.description,
              icon: _icons[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TradingScreen(variant: variant),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _icons = [
    Icons.candlestick_chart,
    Icons.stacked_line_chart,
    Icons.memory,
    Icons.speed,
  ];
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String number;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [Icon(icon, size: 28), const Spacer(), Text(number)],
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open scenario',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
