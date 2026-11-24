import 'package:flutter/material.dart';

import '../../data/benchmark_feed.dart';
import '../../domain/market_store.dart';
import 'live_candle_chart.dart';

/// Symbols shown in the watchlist, mapped to feed instrument ids.
const List<({String symbol, int id})> kWatchlist = [
  (symbol: 'RELIANCE', id: 0),
  (symbol: 'HDFCBANK', id: 1),
  (symbol: 'INFY', id: 2),
  (symbol: 'TCS', id: 3),
  (symbol: 'ICICIBANK', id: 4),
  (symbol: 'TATAMOTORS', id: 5),
  (symbol: 'SBIN', id: 6),
];

const List<String> kIndexNames = ['NIFTY 50', 'SENSEX', 'BANK NIFTY'];

String symbolFor(int id) =>
    kWatchlist.firstWhere((entry) => entry.id == id).symbol;

String formatCents(int cents) => (cents / 100).toStringAsFixed(2);

const _tabular = [FontFeature.tabularFigures()];
const _green = Color(0xFF26A69A);
const _red = Color(0xFFEF5350);

/// Builds the market panels. Each panel subscribes only to the store slices
/// it displays, so a batch rebuilds just the widgets whose data changed.
///
/// Create one instance and keep it: the panels are reused by identity so a
/// rebuild of the surrounding screen never rebuilds them.
class MarketDashboard implements BenchmarkDashboard {
  MarketDashboard({required this.store}) : selection = ValueNotifier<int>(0);

  final MarketStore store;

  /// Instrument id selected in the watchlist.
  final ValueNotifier<int> selection;

  late final Widget indices = IndicesPanel(store: store);
  late final Widget watchlist = WatchlistPanel(
    store: store,
    selection: selection,
  );
  late final Widget header = InstrumentHeader(
    store: store,
    selection: selection,
  );
  late final Widget chart = ChartPanel(store: store, selection: selection);
  late final Widget orderBook = OrderBookPanel(
    store: store,
    selection: selection,
  );
  late final Widget trades = TradesPanel(store: store, selection: selection);

  /// Three-column layout for wide screens.
  late final Widget wideLayout = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 260, child: watchlist),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          children: [
            header,
            const SizedBox(height: 12),
            chart,
            const SizedBox(height: 12),
            trades,
          ],
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(width: 260, child: orderBook),
    ],
  );

  /// Panels in reading order for narrow screens, built lazily by a sliver.
  late final List<Widget> narrowPanels = [
    header,
    chart,
    watchlist,
    orderBook,
    trades,
  ];

  @override
  List<Widget> panels({required bool wide}) => [
    indices,
    if (wide) wideLayout else ...narrowPanels,
  ];

  @override
  void dispose() => selection.dispose();
}

/// Card chrome shared by all panels. Each panel gets its own layer so its
/// repaints do not repaint neighbours.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF141A21),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF252D36)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Rebuilds [builder] for the selected instrument whenever the selection or
/// the given slice of that instrument changes.
class _SelectedSlice extends StatelessWidget {
  const _SelectedSlice({
    required this.store,
    required this.selection,
    required this.signalOf,
    required this.builder,
  });

  final MarketStore store;
  final ValueNotifier<int> selection;
  final MarketSignal Function(InstrumentState state) signalOf;
  final Widget Function(BuildContext context, InstrumentState state) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selection,
      builder: (context, id, _) {
        final state = store.instruments[id];
        return ListenableBuilder(
          listenable: signalOf(state),
          builder: (context, _) => builder(context, state),
        );
      },
    );
  }
}

class IndicesPanel extends StatelessWidget {
  const IndicesPanel({super.key, required this.store});

  final MarketStore store;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'MARKET INDICES',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final index in store.indices)
            SizedBox(width: 190, child: _IndexTile(index: index)),
        ],
      ),
    );
  }
}

class _IndexTile extends StatelessWidget {
  const _IndexTile({required this.index});

  final IndexState index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kIndexNames[index.id],
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: index.signal,
          builder: (context, _) {
            final value = index.valueCents;
            final change = index.changeCents;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value == null ? '--' : formatCents(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFeatures: _tabular,
                  ),
                ),
                Text(
                  value == null
                      ? 'Waiting for feed'
                      : '${change >= 0 ? '+' : ''}${formatCents(change)}',
                  style: TextStyle(
                    color: value == null
                        ? Colors.white38
                        : change >= 0
                        ? Colors.green
                        : Colors.red,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class WatchlistPanel extends StatelessWidget {
  const WatchlistPanel({
    super.key,
    required this.store,
    required this.selection,
  });

  final MarketStore store;
  final ValueNotifier<int> selection;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'MARKET WATCH',
      child: Column(
        children: [
          for (final entry in kWatchlist)
            _WatchRow(
              symbol: entry.symbol,
              state: store.instruments[entry.id],
              selection: selection,
            ),
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({
    required this.symbol,
    required this.state,
    required this.selection,
  });

  final String symbol;
  final InstrumentState state;
  final ValueNotifier<int> selection;

  @override
  Widget build(BuildContext context) {
    // Selection highlight and price update independently.
    return ValueListenableBuilder<int>(
      valueListenable: selection,
      builder: (context, selectedId, child) {
        return InkWell(
          onTap: () => selection.value = state.id,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selectedId == state.id
                  ? const Color(0xFF202B36)
                  : Colors.transparent,
              border: const Border(
                bottom: BorderSide(color: Color(0xFF252D36)),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Text(symbol, style: const TextStyle(color: Colors.white)),
          ),
          ListenableBuilder(
            listenable: state.priceSignal,
            builder: (context, _) {
              final price = state.displayPriceCents;
              return Text(
                price == null ? '--' : formatCents(price),
                style: const TextStyle(
                  color: Colors.white70,
                  fontFeatures: _tabular,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class InstrumentHeader extends StatelessWidget {
  const InstrumentHeader({
    super.key,
    required this.store,
    required this.selection,
  });

  final MarketStore store;
  final ValueNotifier<int> selection;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: _SelectedSlice(
        store: store,
        selection: selection,
        signalOf: (state) => state.priceSignal,
        builder: (context, state) {
          final bid = state.bidCents;
          final ask = state.askCents;
          final price = state.displayPriceCents;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbolFor(state.id),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bid == null || ask == null
                          ? 'Waiting for quote'
                          : 'Bid ${formatCents(bid)}  ·  '
                                'Ask ${formatCents(ask)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price == null ? '--' : formatCents(price),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFeatures: _tabular,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChartPanel extends StatelessWidget {
  const ChartPanel({super.key, required this.store, required this.selection});

  final MarketStore store;
  final ValueNotifier<int> selection;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'LIVE PRICE CHART',
      child: ValueListenableBuilder<int>(
        valueListenable: selection,
        builder: (context, id, _) {
          final state = store.instruments[id];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The chart repaints from the candle signal without rebuilding.
              LiveCandleChart(
                candles: state.candles,
                repaint: state.candlesSignal,
              ),
              const Divider(color: Color(0xFF252D36)),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: state.candlesSignal,
                builder: (context, _) => _OhlcRow(candles: state.candles),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OhlcRow extends StatelessWidget {
  const _OhlcRow({required this.candles});

  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final last = candles.isEmpty ? null : candles.last;
    String cents(int Function(Candle c) pick) =>
        last == null ? '--' : formatCents(pick(last));

    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _Metric(label: 'OPEN', value: cents((c) => c.open)),
        _Metric(label: 'HIGH', value: cents((c) => c.high)),
        _Metric(label: 'LOW', value: cents((c) => c.low)),
        _Metric(label: 'CLOSE', value: cents((c) => c.close)),
        _Metric(label: 'VOLUME', value: last == null ? '--' : '${last.volume}'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontFeatures: _tabular),
        ),
      ],
    );
  }
}

class OrderBookPanel extends StatelessWidget {
  const OrderBookPanel({
    super.key,
    required this.store,
    required this.selection,
  });

  final MarketStore store;
  final ValueNotifier<int> selection;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'ORDER BOOK',
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('BID', style: TextStyle(color: Colors.green)),
              ),
              Expanded(
                child: Text(
                  'QTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              Expanded(
                child: Text(
                  'ASK',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SelectedSlice(
            store: store,
            selection: selection,
            signalOf: (state) => state.bookSignal,
            builder: (context, state) => Column(
              children: [
                for (var level = 0; level < store.bookDepth; level++)
                  _BookRow(bids: state.bids, asks: state.asks, level: level),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.bids, required this.asks, required this.level});

  final OrderBookSide bids;
  final OrderBookSide asks;
  final int level;

  @override
  Widget build(BuildContext context) {
    final hasBid = bids.present[level];
    final hasAsk = asks.present[level];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasBid ? formatCents(bids.prices[level]) : '--',
              style: const TextStyle(
                color: Colors.green,
                fontFeatures: _tabular,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hasBid ? '${bids.quantities[level]}' : '0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontFeatures: _tabular,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hasAsk ? formatCents(asks.prices[level]) : '--',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.red, fontFeatures: _tabular),
            ),
          ),
        ],
      ),
    );
  }
}

class TradesPanel extends StatelessWidget {
  const TradesPanel({super.key, required this.store, required this.selection});

  static const int visibleTrades = 10;

  final MarketStore store;
  final ValueNotifier<int> selection;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'RECENT TRADES',
      child: _SelectedSlice(
        store: store,
        selection: selection,
        signalOf: (state) => state.tradesSignal,
        builder: (context, state) => Column(
          children: [
            for (final trade in state.trades.take(visibleTrades))
              _TradeRow(trade: trade),
          ],
        ),
      ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade});

  final TradePrint trade;

  @override
  Widget build(BuildContext context) {
    final color = trade.isBuy ? _green : _red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatCents(trade.priceCents),
              style: TextStyle(color: color, fontFeatures: _tabular),
            ),
          ),
          Text(
            '${trade.quantity}',
            style: const TextStyle(
              color: Colors.white70,
              fontFeatures: _tabular,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 36,
            child: Text(
              trade.isBuy ? 'BUY' : 'SELL',
              textAlign: TextAlign.end,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
