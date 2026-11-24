import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../generated/market.pb.dart';

/// Change notification for one slice of market state.
///
/// [MarketStore.apply] marks signals dirty as events arrive; listeners are
/// notified once per [MarketStore.flush], however many events touched the
/// slice. Widgets listen only to the slices they display.
class MarketSignal extends ChangeNotifier {
  bool _dirty = false;

  void _notify() {
    _dirty = false;
    notifyListeners();
  }
}

/// One side of a fixed-depth order book. Index 0 is the best level.
class OrderBookSide {
  OrderBookSide(int depth)
    : prices = List<int>.filled(depth, 0),
      quantities = List<int>.filled(depth, 0),
      present = List<bool>.filled(depth, false);

  final List<int> prices;
  final List<int> quantities;
  final List<bool> present;

  int get depth => prices.length;

  void _clear() {
    for (var i = 0; i < depth; i++) {
      prices[i] = 0;
      quantities[i] = 0;
      present[i] = false;
    }
  }
}

class TradePrint {
  const TradePrint({
    required this.priceCents,
    required this.quantity,
    required this.isBuy,
  });

  final int priceCents;
  final int quantity;
  final bool isBuy;
}

class Candle {
  Candle({
    required this.intervalStartMicros,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final int intervalStartMicros;
  int open;
  int high;
  int low;
  int close;
  int volume;
}

class InstrumentState {
  InstrumentState(this.id, {required int bookDepth})
    : bids = OrderBookSide(bookDepth),
      asks = OrderBookSide(bookDepth);

  static const int maxTrades = 20;
  static const int maxCandles = 120;

  final int id;

  int? bidCents;
  int? askCents;
  int bidQuantity = 0;
  int askQuantity = 0;
  int? lastTradeCents;

  /// Quote or last-trade price changed.
  final MarketSignal priceSignal = MarketSignal();

  final OrderBookSide bids;
  final OrderBookSide asks;
  final MarketSignal bookSignal = MarketSignal();

  /// Newest first.
  final ListQueue<TradePrint> trades = ListQueue<TradePrint>();
  final MarketSignal tradesSignal = MarketSignal();

  /// Oldest first, at most [maxCandles].
  final List<Candle> candles = [];
  final MarketSignal candlesSignal = MarketSignal();

  InstrumentStatus status = InstrumentStatus.INSTRUMENT_STATUS_UNSPECIFIED;

  /// Last traded price, falling back to the quote mid before the first trade.
  int? get displayPriceCents {
    if (lastTradeCents != null) return lastTradeCents;
    final bid = bidCents;
    final ask = askCents;
    if (bid == null || ask == null) return null;
    return (bid + ask) ~/ 2;
  }

  Iterable<MarketSignal> get _signals => [
    priceSignal,
    bookSignal,
    tradesSignal,
    candlesSignal,
  ];

  void _clear() {
    bidCents = null;
    askCents = null;
    bidQuantity = 0;
    askQuantity = 0;
    lastTradeCents = null;
    bids._clear();
    asks._clear();
    trades.clear();
    candles.clear();
    status = InstrumentStatus.INSTRUMENT_STATUS_UNSPECIFIED;
  }
}

class IndexState {
  IndexState(this.id);

  final int id;
  int? valueCents;
  int changeCents = 0;
  final MarketSignal signal = MarketSignal();
}

/// Mutable market state with fine-grained change signals.
///
/// Applying a batch only updates plain fields and marks the affected
/// signals dirty; [flush] then notifies each dirty signal once. This keeps
/// UI work proportional to what actually changed on screen.
class MarketStore {
  MarketStore({
    this.instrumentCount = 20,
    this.indexCount = 3,
    this.bookDepth = 5,
  }) : instruments = List.generate(
         instrumentCount,
         (id) => InstrumentState(id, bookDepth: bookDepth),
         growable: false,
       ),
       indices = List.generate(indexCount, IndexState.new, growable: false);

  final int instrumentCount;
  final int indexCount;
  final int bookDepth;

  final List<InstrumentState> instruments;
  final List<IndexState> indices;

  final List<MarketSignal> _dirty = [];

  void _mark(MarketSignal signal) {
    if (signal._dirty) return;
    signal._dirty = true;
    _dirty.add(signal);
  }

  InstrumentState? _instrument(int id) =>
      id >= 0 && id < instrumentCount ? instruments[id] : null;

  /// Folds [batch] into the state. Does not notify listeners; call [flush].
  void apply(TradingBatch batch) {
    for (final event in batch.events) {
      switch (event.whichEvent()) {
        case MarketEvent_Event.quote:
          final quote = event.quote;
          final state = _instrument(quote.instrumentId);
          if (state == null) break;
          state
            ..bidCents = quote.bidPriceCents.toInt()
            ..askCents = quote.askPriceCents.toInt()
            ..bidQuantity = quote.bidQuantity
            ..askQuantity = quote.askQuantity;
          _mark(state.priceSignal);

        case MarketEvent_Event.trade:
          final trade = event.trade;
          final state = _instrument(trade.instrumentId);
          if (state == null) break;
          final price = trade.priceCents.toInt();
          state.lastTradeCents = price;
          state.trades.addFirst(
            TradePrint(
              priceCents: price,
              quantity: trade.quantity,
              isBuy: trade.side == TradeSide.BUY,
            ),
          );
          if (state.trades.length > InstrumentState.maxTrades) {
            state.trades.removeLast();
          }
          _mark(state.priceSignal);
          _mark(state.tradesSignal);

        case MarketEvent_Event.orderBook:
          final update = event.orderBook;
          final state = _instrument(update.instrumentId);
          if (state == null || update.level < 0 || update.level >= bookDepth) {
            break;
          }
          final side = update.side == BookSide.BID ? state.bids : state.asks;
          side.prices[update.level] = update.priceCents.toInt();
          side.quantities[update.level] = update.quantity;
          side.present[update.level] = true;
          _mark(state.bookSignal);

        case MarketEvent_Event.candle:
          final update = event.candle;
          final state = _instrument(update.instrumentId);
          if (state == null) break;
          final start = update.intervalStartMicros.toInt();
          final candles = state.candles;
          if (candles.isNotEmpty && candles.last.intervalStartMicros == start) {
            candles.last
              ..open = update.openCents.toInt()
              ..high = update.highCents.toInt()
              ..low = update.lowCents.toInt()
              ..close = update.closeCents.toInt()
              ..volume = update.volume.toInt();
          } else {
            candles.add(
              Candle(
                intervalStartMicros: start,
                open: update.openCents.toInt(),
                high: update.highCents.toInt(),
                low: update.lowCents.toInt(),
                close: update.closeCents.toInt(),
                volume: update.volume.toInt(),
              ),
            );
            if (candles.length > InstrumentState.maxCandles) {
              candles.removeAt(0);
            }
          }
          _mark(state.candlesSignal);

        case MarketEvent_Event.index_:
          final update = event.index;
          final id = update.indexId;
          if (id < 0 || id >= indexCount) break;
          final state = indices[id]
            ..valueCents = update.valueCents.toInt()
            ..changeCents = update.changeCents.toInt();
          _mark(state.signal);

        case MarketEvent_Event.instrumentStatus:
          final update = event.instrumentStatus;
          _instrument(update.instrumentId)?.status = update.status;

        case MarketEvent_Event.notSet:
          break;
      }
    }
  }

  /// Notifies every signal changed since the last flush, once each.
  void flush() {
    if (_dirty.isEmpty) return;
    final pending = List<MarketSignal>.of(_dirty);
    _dirty.clear();
    for (final signal in pending) {
      signal._notify();
    }
  }

  /// Clears all state and notifies every listener.
  void reset() {
    for (final state in instruments) {
      state._clear();
      state._signals.forEach(_mark);
    }
    for (final index in indices) {
      index
        ..valueCents = null
        ..changeCents = 0;
      _mark(index.signal);
    }
    flush();
  }
}
