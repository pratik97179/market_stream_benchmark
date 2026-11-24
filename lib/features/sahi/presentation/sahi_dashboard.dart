import 'package:flutter/material.dart';

import '../../trading/data/benchmark_feed.dart';
import '../../trading/presentation/widgets/live_candle_chart.dart';
import '../../trading/presentation/widgets/market_dashboard.dart'
    show DashboardPanel;
import '../domain/sahi_store.dart';
import '../domain/sahi_universe.dart';
import 'glyph_atlas.dart';
import 'sahi_widget_tables.dart';

const _tabular = [FontFeature.tabularFigures()];
const _green = Color(0xFF26A69A);
const _red = Color(0xFFEF5350);
const _muted = TextStyle(color: Colors.white54, fontSize: 11);
const _cell = TextStyle(
  color: Colors.white,
  fontSize: 12,
  fontFeatures: _tabular,
);

String formatPaise(int? paise) {
  if (paise == null) return '—';
  final rupees = paise ~/ 100;
  final fraction = (paise % 100).toString().padLeft(2, '0');
  return '${_groupIndian(rupees)}.$fraction';
}

/// 1,23,45,678 grouping.
String _groupIndian(int value) {
  final digits = value.abs().toString();
  if (digits.length <= 3) return value < 0 ? '-$digits' : digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  final grouped = '${groups.join(',')},$last3';
  return value < 0 ? '-$grouped' : grouped;
}

/// Lakh / crore shorthand for volume and open interest.
String formatCompact(int? value) {
  if (value == null) return '—';
  if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String formatChange(SahiInstrumentState state) {
  final percent = state.changePercent;
  if (percent == null) return '—';
  final sign = percent >= 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(2)}%';
}

Color changeColor(SahiInstrumentState state) =>
    (state.changePaise ?? 0) >= 0 ? _green : _red;

/// Panels for the broker-style feed. Create once and keep: panels are
/// reused by identity, and each widget listens only to the instruments it
/// shows.
///
/// With [paintedTables] the option chain, depth and watchlist are painted
/// from a glyph atlas; otherwise they are built from Text widgets.
class SahiDashboard implements BenchmarkDashboard {
  SahiDashboard({required this.store, this.paintedTables = true});

  final SahiStore store;
  final bool paintedTables;

  late final Widget indices = _IndicesStrip(store: store);
  late final Widget header = _FutureHeader(
    state: store.byId[store.chartInstrumentId]!,
  );
  late final Widget chart = DashboardPanel(
    title: '${store.universe.niftyFuture.symbol} · 1s',
    child: LiveCandleChart(
      candles: store.byId[store.chartInstrumentId]!.candles,
      repaint: store.byId[store.chartInstrumentId]!.candleSignal,
    ),
  );
  late final Widget optionChain = paintedTables
      ? _OptionChainPanel(store: store)
      : OptionChainWidgets(store: store);
  late final Widget depth = paintedTables
      ? _DepthPanel(state: store.byId[store.chartInstrumentId]!)
      : DepthWidgets(state: store.byId[store.chartInstrumentId]!);
  late final Widget watchlist = paintedTables
      ? _WatchlistPanel(store: store)
      : WatchlistWidgets(store: store);

  late final List<Widget> _narrow = [
    indices,
    header,
    chart,
    optionChain,
    depth,
    watchlist,
  ];

  late final List<Widget> _wide = [
    indices,
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 300, child: watchlist),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              header,
              const SizedBox(height: 12),
              chart,
              const SizedBox(height: 12),
              optionChain,
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 300, child: depth),
      ],
    ),
  ];

  @override
  List<Widget> panels({required bool wide}) => wide ? _wide : _narrow;

  @override
  void dispose() {}
}

class _IndicesStrip extends StatelessWidget {
  const _IndicesStrip({required this.store});

  final SahiStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final info in store.universe.indices) ...[
          if (info != store.universe.indices.first) const SizedBox(width: 8),
          Expanded(child: _IndexTile(state: store.byId[info.id]!)),
        ],
      ],
    );
  }
}

class _IndexTile extends StatelessWidget {
  const _IndexTile({required this.state});

  final SahiInstrumentState state;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: ListenableBuilder(
        listenable: state.priceSignal,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.info.symbol, style: _muted),
            const SizedBox(height: 4),
            Text(
              formatPaise(state.ltp),
              style: _cell.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              formatChange(state),
              style: TextStyle(
                color: changeColor(state),
                fontSize: 11,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureHeader extends StatelessWidget {
  const _FutureHeader({required this.state});

  final SahiInstrumentState state;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: ListenableBuilder(
        listenable: state.priceSignal,
        builder: (context, _) {
          final oi = state.openInterest;
          final prevOi = state.prevOpenInterest;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    state.info.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPaise(state.ltp),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFeatures: _tabular,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatChange(state),
                    style: TextStyle(
                      color: changeColor(state),
                      fontSize: 13,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat('VOLUME', formatCompact(state.volume)),
                  _Stat('OI', formatCompact(oi)),
                  _Stat(
                    'OI CHG',
                    oi == null || prevOi == null
                        ? '—'
                        : formatCompact((oi - prevOi).abs()),
                  ),
                  _Stat(
                    'CIRCUIT',
                    '${formatPaise(state.dprLower)} – '
                        '${formatPaise(state.dprUpper)}',
                    flex: 2,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.flex = 1});

  final String label;
  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _muted.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: _cell, maxLines: 1, overflow: TextOverflow.fade),
        ],
      ),
    );
  }
}

/// NIFTY option chain: 21 strikes around the money are on screen.
///
/// Painted, not built: the rows repaint directly when any shown option
/// ticks, and all numbers are drawn from a [GlyphAtlas] in one call, so a
/// busy chain costs no widget rebuilds or text layout per frame.
class _OptionChainPanel extends StatefulWidget {
  const _OptionChainPanel({required this.store});

  final SahiStore store;

  static const int visibleEachSide = 10;
  static const double rowHeight = 21;

  @override
  State<_OptionChainPanel> createState() => _OptionChainPanelState();
}

class _OptionChainPanelState extends State<_OptionChainPanel> {
  late final List<(int, SahiInstrumentState, SahiInstrumentState)> _rows;
  late final Listenable _anyTick;

  @override
  void initState() {
    super.initState();
    final universe = widget.store.universe;
    final atm = universe.atmRow;
    _rows = [
      for (final row in universe.chain.sublist(
        atm - _OptionChainPanel.visibleEachSide,
        atm + _OptionChainPanel.visibleEachSide + 1,
      ))
        (
          row.strike,
          widget.store.byId[row.call.id]!,
          widget.store.byId[row.put.id]!,
        ),
    ];
    _anyTick = Listenable.merge([
      for (final (_, call, put) in _rows) ...[
        call.priceSignal,
        put.priceSignal,
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return DashboardPanel(
      title: 'NIFTY OPTION CHAIN',
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: Text('OI', style: _muted)),
              Expanded(child: Text('CALL LTP', style: _muted)),
              Expanded(
                child: Text(
                  'STRIKE',
                  style: _muted,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text('PUT LTP', style: _muted, textAlign: TextAlign.end),
              ),
              Expanded(
                child: Text('OI', style: _muted, textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _rows.length * _OptionChainPanel.rowHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _OptionChainPainter(_rows, _anyTick, dpr),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChainPainter extends CustomPainter {
  _OptionChainPainter(this.rows, Listenable repaint, this.dpr)
    : super(repaint: repaint);

  final List<(int, SahiInstrumentState, SahiInstrumentState)> rows;
  final double dpr;

  static final GlyphBatch _batch = GlyphBatch();

  @override
  void paint(Canvas canvas, Size size) {
    final atlas = GlyphAtlas.of(12, devicePixelRatio: dpr);
    final column = size.width / 5;
    final textTop = (_OptionChainPanel.rowHeight - atlas.height) / 2;
    for (var i = 0; i < rows.length; i++) {
      final (strike, call, put) = rows[i];
      final y = i * _OptionChainPanel.rowHeight + textTop;
      final atm = strike == SahiUniverse.niftySpot;
      atlas
        ..add(_batch, formatCompact(call.openInterest), 0, y, Colors.white)
        ..add(_batch, formatPaise(call.ltp), column, y, changeColor(call))
        ..addCentred(
          _batch,
          '${strike ~/ 100}',
          column * 2.5,
          y,
          atm ? Colors.amber : Colors.white70,
        )
        ..addRight(
          _batch,
          formatPaise(put.ltp),
          column * 4,
          y,
          changeColor(put),
        )
        ..addRight(
          _batch,
          formatCompact(put.openInterest),
          size.width,
          y,
          Colors.white,
        );
    }
    _batch.draw(canvas, atlas);
  }

  @override
  bool shouldRepaint(_OptionChainPainter old) =>
      old.dpr != dpr || !identical(old.rows, rows);
}

/// Full market depth (20 levels for NIFTY FUT) with order counts, painted
/// from the atlas and repainted directly from the depth signal.
class _DepthPanel extends StatelessWidget {
  const _DepthPanel({required this.state});

  final SahiInstrumentState state;

  static const double rowHeight = 18;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final levels = state.info.depthLevels;
    return DashboardPanel(
      title: 'MARKET DEPTH · ${state.info.symbol}',
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: Text('ORD', style: _muted)),
              Expanded(flex: 2, child: Text('QTY', style: _muted)),
              Expanded(
                flex: 2,
                child: Text('BID', style: _muted, textAlign: TextAlign.end),
              ),
              SizedBox(width: 12),
              Expanded(flex: 2, child: Text('ASK', style: _muted)),
              Expanded(
                flex: 2,
                child: Text('QTY', style: _muted, textAlign: TextAlign.end),
              ),
              Expanded(
                child: Text('ORD', style: _muted, textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            // Levels plus the buy/sell totals bar.
            height: levels * rowHeight + 28,
            width: double.infinity,
            child: CustomPaint(painter: _DepthPainter(state, dpr)),
          ),
        ],
      ),
    );
  }
}

class _DepthPainter extends CustomPainter {
  _DepthPainter(this.state, this.dpr) : super(repaint: state.depthSignal);

  final SahiInstrumentState state;
  final double dpr;

  static final GlyphBatch _batch = GlyphBatch();
  static final Paint _buyBar = Paint()..color = _green;
  static final Paint _sellBar = Paint()..color = _red;

  @override
  void paint(Canvas canvas, Size size) {
    final atlas = GlyphAtlas.of(12, devicePixelRatio: dpr);
    // Columns as flex 1, 2, 2 | 12 px | 2, 2, 1.
    final unit = (size.width - 12) / 10;
    final bidEnd = unit * 5;
    final askStart = bidEnd + 12;
    final textTop = (_DepthPanel.rowHeight - atlas.height) / 2;

    final bids = state.bids;
    final asks = state.asks;
    final rows = bids.count > asks.count ? bids.count : asks.count;
    for (var i = 0; i < rows; i++) {
      final y = i * _DepthPanel.rowHeight + textTop;
      if (i < bids.count) {
        atlas
          ..add(_batch, '${bids.orders[i]}', 0, y, Colors.white)
          ..add(_batch, '${bids.quantities[i]}', unit, y, Colors.white)
          ..addRight(_batch, formatPaise(bids.prices[i]), bidEnd, y, _green);
      }
      if (i < asks.count) {
        atlas
          ..add(_batch, formatPaise(asks.prices[i]), askStart, y, _red)
          ..addRight(
            _batch,
            '${asks.quantities[i]}',
            askStart + unit * 4,
            y,
            Colors.white,
          )
          ..addRight(_batch, '${asks.orders[i]}', size.width, y, Colors.white);
      }
    }

    // Buy/sell pressure across the whole book.
    final totalBuy = state.totalBuyQty;
    final totalSell = state.totalSellQty;
    final barTop = size.height - 18;
    final buyLabel = formatCompact(totalBuy);
    final sellLabel = formatCompact(totalSell);
    final barLeft = atlas.measure(buyLabel) + 8;
    final barRight = size.width - atlas.measure(sellLabel) - 8;
    final total = totalBuy + totalSell;
    final split =
        barLeft + (barRight - barLeft) * (total == 0 ? 0.5 : totalBuy / total);
    final barY = barTop + atlas.height / 2 - 3;
    canvas
      ..drawRRect(
        RRect.fromLTRBR(
          barLeft,
          barY,
          split,
          barY + 6,
          const Radius.circular(3),
        ),
        _buyBar,
      )
      ..drawRRect(
        RRect.fromLTRBR(
          split,
          barY,
          barRight,
          barY + 6,
          const Radius.circular(3),
        ),
        _sellBar,
      );
    atlas
      ..add(_batch, buyLabel, 0, barTop, Colors.white)
      ..addRight(_batch, sellLabel, size.width, barTop, Colors.white);

    _batch.draw(canvas, atlas);
  }

  @override
  bool shouldRepaint(_DepthPainter old) =>
      old.dpr != dpr || !identical(old.state, state);
}

/// The user's watchlist: the 20 most traded stocks, painted. Symbols are
/// laid out once; numbers come from the atlas.
class _WatchlistPanel extends StatefulWidget {
  const _WatchlistPanel({required this.store});

  final SahiStore store;

  static const double rowHeight = 27;

  @override
  State<_WatchlistPanel> createState() => _WatchlistPanelState();
}

class _WatchlistPanelState extends State<_WatchlistPanel> {
  late final List<SahiInstrumentState> _rows = [
    for (final info in widget.store.universe.stocks.take(20))
      widget.store.byId[info.id]!,
  ];
  late final Listenable _anyTick = Listenable.merge([
    for (final state in _rows) state.priceSignal,
  ]);
  late final List<TextPainter> _symbols = [
    for (final state in _rows)
      TextPainter(
        text: TextSpan(
          text: state.info.symbol,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  @override
  void dispose() {
    for (final symbol in _symbols) {
      symbol.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return DashboardPanel(
      title: 'WATCHLIST',
      child: SizedBox(
        height: _rows.length * _WatchlistPanel.rowHeight,
        width: double.infinity,
        child: CustomPaint(
          painter: _WatchlistPainter(_rows, _symbols, _anyTick, dpr),
        ),
      ),
    );
  }
}

class _WatchlistPainter extends CustomPainter {
  _WatchlistPainter(this.rows, this.symbols, Listenable repaint, this.dpr)
    : super(repaint: repaint);

  final List<SahiInstrumentState> rows;
  final List<TextPainter> symbols;
  final double dpr;

  static final GlyphBatch _small = GlyphBatch();
  static final GlyphBatch _medium = GlyphBatch();
  static final GlyphBatch _large = GlyphBatch();

  @override
  void paint(Canvas canvas, Size size) {
    final small = GlyphAtlas.of(11, devicePixelRatio: dpr);
    final medium = GlyphAtlas.of(12, devicePixelRatio: dpr);
    final large = GlyphAtlas.of(13, devicePixelRatio: dpr);
    // Columns as flex 3, 2, 3, 2.
    final unit = size.width / 10;
    const rowHeight = _WatchlistPanel.rowHeight;
    for (var i = 0; i < rows.length; i++) {
      final state = rows[i];
      final top = i * rowHeight;
      final symbol = symbols[i];
      symbol.paint(canvas, Offset(0, top + (rowHeight - symbol.height) / 2));
      small.addRight(
        _small,
        formatCompact(state.volume),
        unit * 5,
        top + (rowHeight - small.height) / 2,
        Colors.white54,
      );
      large.addRight(
        _large,
        formatPaise(state.ltp),
        unit * 8,
        top + (rowHeight - large.height) / 2,
        Colors.white,
      );
      medium.addRight(
        _medium,
        formatChange(state),
        size.width,
        top + (rowHeight - medium.height) / 2,
        changeColor(state),
      );
    }
    _small.draw(canvas, small);
    _medium.draw(canvas, medium);
    _large.draw(canvas, large);
  }

  @override
  bool shouldRepaint(_WatchlistPainter old) =>
      old.dpr != dpr || !identical(old.rows, rows);
}
