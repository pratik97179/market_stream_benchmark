import 'package:flutter/material.dart';

import '../../trading/presentation/widgets/market_dashboard.dart'
    show DashboardPanel;
import '../domain/sahi_store.dart';
import '../domain/sahi_universe.dart';
import 'sahi_dashboard.dart'
    show changeColor, formatChange, formatCompact, formatPaise;

// The option chain, depth and watchlist built from ordinary Text widgets.
//
// This is how the tables were written for rounds 1 and 2 of the findings:
// each row rebuilds when its instruments change, and every number is laid
// out as text on each rebuild. Kept so those rounds stay reproducible; the
// painted versions in sahi_dashboard.dart replace them for round 3.

const _tabular = [FontFeature.tabularFigures()];
const _green = Color(0xFF26A69A);
const _red = Color(0xFFEF5350);
const _muted = TextStyle(color: Colors.white54, fontSize: 11);
const _cell = TextStyle(
  color: Colors.white,
  fontSize: 12,
  fontFeatures: _tabular,
);

/// NIFTY option chain: 21 strikes around the money. Each row listens to its
/// call and put only.
class OptionChainWidgets extends StatelessWidget {
  const OptionChainWidgets({super.key, required this.store});

  final SahiStore store;

  static const int visibleEachSide = 10;

  @override
  Widget build(BuildContext context) {
    final atm = store.universe.atmRow;
    final rows = store.universe.chain.sublist(
      atm - visibleEachSide,
      atm + visibleEachSide + 1,
    );
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
          for (final row in rows)
            _StrikeRow(
              strike: row.strike,
              call: store.byId[row.call.id]!,
              put: store.byId[row.put.id]!,
              atm: row.strike == SahiUniverse.niftySpot,
            ),
        ],
      ),
    );
  }
}

class _StrikeRow extends StatefulWidget {
  const _StrikeRow({
    required this.strike,
    required this.call,
    required this.put,
    required this.atm,
  });

  final int strike;
  final SahiInstrumentState call;
  final SahiInstrumentState put;
  final bool atm;

  @override
  State<_StrikeRow> createState() => _StrikeRowState();
}

class _StrikeRowState extends State<_StrikeRow> {
  late final Listenable _either = Listenable.merge([
    widget.call.priceSignal,
    widget.put.priceSignal,
  ]);

  @override
  Widget build(BuildContext context) {
    final strikeLabel = Text(
      '${widget.strike ~/ 100}',
      textAlign: TextAlign.center,
      style: _cell.copyWith(
        fontWeight: widget.atm ? FontWeight.bold : FontWeight.normal,
        color: widget.atm ? Colors.amber : Colors.white70,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListenableBuilder(
        listenable: _either,
        builder: (context, _) {
          final call = widget.call;
          final put = widget.put;
          return Row(
            children: [
              Expanded(
                child: Text(formatCompact(call.openInterest), style: _cell),
              ),
              Expanded(
                child: Text(
                  formatPaise(call.ltp),
                  style: _cell.copyWith(color: changeColor(call)),
                ),
              ),
              Expanded(child: strikeLabel),
              Expanded(
                child: Text(
                  formatPaise(put.ltp),
                  textAlign: TextAlign.end,
                  style: _cell.copyWith(color: changeColor(put)),
                ),
              ),
              Expanded(
                child: Text(
                  formatCompact(put.openInterest),
                  textAlign: TextAlign.end,
                  style: _cell,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full market depth (20 levels for NIFTY FUT) with order counts.
class DepthWidgets extends StatelessWidget {
  const DepthWidgets({super.key, required this.state});

  final SahiInstrumentState state;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'MARKET DEPTH · ${state.info.symbol}',
      child: ListenableBuilder(
        listenable: state.depthSignal,
        builder: (context, _) {
          final bids = state.bids;
          final asks = state.asks;
          final rows = bids.count > asks.count ? bids.count : asks.count;
          final totalBuy = state.totalBuyQty;
          final totalSell = state.totalSellQty;
          final total = totalBuy + totalSell;
          return Column(
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
              for (var i = 0; i < rows; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          i < bids.count ? '${bids.orders[i]}' : '',
                          style: _cell,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          i < bids.count ? '${bids.quantities[i]}' : '',
                          style: _cell,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          i < bids.count ? formatPaise(bids.prices[i]) : '',
                          textAlign: TextAlign.end,
                          style: _cell.copyWith(color: _green),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Text(
                          i < asks.count ? formatPaise(asks.prices[i]) : '',
                          style: _cell.copyWith(color: _red),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          i < asks.count ? '${asks.quantities[i]}' : '',
                          textAlign: TextAlign.end,
                          style: _cell,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          i < asks.count ? '${asks.orders[i]}' : '',
                          textAlign: TextAlign.end,
                          style: _cell,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(formatCompact(totalBuy), style: _cell),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0.5 : totalBuy / total,
                        minHeight: 6,
                        color: _green,
                        backgroundColor: _red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatCompact(totalSell), style: _cell),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The 20-stock watchlist. Each row listens to its own instrument.
class WatchlistWidgets extends StatelessWidget {
  const WatchlistWidgets({super.key, required this.store});

  final SahiStore store;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: 'WATCHLIST',
      child: Column(
        children: [
          for (final info in store.universe.stocks.take(20))
            _WatchRow(state: store.byId[info.id]!),
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.state});

  final SahiInstrumentState state;

  @override
  Widget build(BuildContext context) {
    final symbol = Text(
      state.info.symbol,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListenableBuilder(
        listenable: state.priceSignal,
        builder: (context, _) => Row(
          children: [
            Expanded(flex: 3, child: symbol),
            Expanded(
              flex: 2,
              child: Text(
                formatCompact(state.volume),
                textAlign: TextAlign.end,
                style: _muted,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                formatPaise(state.ltp),
                textAlign: TextAlign.end,
                style: _cell.copyWith(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatChange(state),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: changeColor(state),
                  fontSize: 12,
                  fontFeatures: _tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
