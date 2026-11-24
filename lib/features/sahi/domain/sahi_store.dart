import 'package:flutter/foundation.dart';

import '../../../generated/sahi_marketdata.pb.dart';
import '../../trading/domain/market_store.dart' show Candle;
import '../data/sahi_delta.dart';
import 'sahi_universe.dart';

/// Change notification for one slice of one instrument. [SahiStore.apply]
/// marks signals dirty; [SahiStore.flush] notifies each dirty one once.
class SahiSignal extends ChangeNotifier {
  bool _dirty = false;

  void _notify() {
    _dirty = false;
    notifyListeners();
  }
}

/// One side of the book, in fixed arrays: only [count] levels are valid.
class SahiBookSide {
  static const int maxLevels = 20;

  final List<int> prices = List<int>.filled(maxLevels, 0);
  final List<int> quantities = List<int>.filled(maxLevels, 0);
  final List<int> orders = List<int>.filled(maxLevels, 0);
  int count = 0;

  void _setFlat(Int64List data, int offset, int levels) {
    final n = levels < maxLevels ? levels : maxLevels;
    for (var i = 0; i < n; i++) {
      final o = offset + i * 3;
      prices[i] = data[o];
      quantities[i] = data[o + 1];
      orders[i] = data[o + 2];
    }
    count = n;
  }

  void _set(List<DepthLevel> levels) {
    final n = levels.length < maxLevels ? levels.length : maxLevels;
    for (var i = 0; i < n; i++) {
      final level = levels[i];
      prices[i] = level.price.toInt();
      quantities[i] = level.qty.toInt();
      orders[i] = level.numOrders.toInt();
    }
    count = n;
  }
}

class SahiInstrumentState {
  SahiInstrumentState(this.info);

  static const int maxCandles = 120;

  final SahiInstrumentInfo info;

  int? ltp;
  int? lastTradeTime;
  int volume = 0;
  int? dprUpper;
  int? dprLower;
  int? openInterest;
  int? prevOpenInterest;

  final SahiBookSide bids = SahiBookSide();
  final SahiBookSide asks = SahiBookSide();
  int totalBuyQty = 0;
  int totalSellQty = 0;

  /// LTP, volume, OI or circuit band changed.
  final SahiSignal priceSignal = SahiSignal();

  /// Order book changed.
  final SahiSignal depthSignal = SahiSignal();

  /// One-second candles built from ticks; kept only for the chart
  /// instrument, as a trading app does for the chart on screen.
  final List<Candle> candles = [];
  final SahiSignal candleSignal = SahiSignal();

  int? get changePaise => ltp == null ? null : ltp! - info.prevClose;

  double? get changePercent =>
      ltp == null ? null : (ltp! - info.prevClose) * 100 / info.prevClose;

  void _clear() {
    ltp = null;
    lastTradeTime = null;
    volume = 0;
    dprUpper = null;
    dprLower = null;
    openInterest = null;
    prevOpenInterest = null;
    bids.count = 0;
    asks.count = 0;
    totalBuyQty = 0;
    totalSellQty = 0;
    candles.clear();
  }
}

/// Live state for every instrument in the universe, updated tick by tick.
class SahiStore {
  SahiStore()
    : universe = SahiUniverse(),
      byId = {
        for (final info in SahiUniverse().instruments)
          info.id: SahiInstrumentState(info),
      };

  final SahiUniverse universe;
  final Map<int, SahiInstrumentState> byId;

  /// The instrument whose chart is on screen.
  late final int chartInstrumentId = universe.niftyFuture.id;

  final List<SahiSignal> _dirty = [];

  void _mark(SahiSignal signal) {
    if (signal._dirty) return;
    signal._dirty = true;
    _dirty.add(signal);
  }

  /// Folds one tick into the state. Returns false for non-tick messages.
  /// Does not notify listeners; call [flush].
  bool apply(ServerMessage message) {
    switch (message.whichPayload()) {
      case ServerMessage_Payload.ltpTick:
        final tick = message.ltpTick;
        final state = byId[tick.instrumentId.toInt()];
        if (state == null) return true;
        state.ltp = tick.lastTradePrice.toInt();
        if (tick.hasLastTradeTime()) {
          state.lastTradeTime = tick.lastTradeTime.toInt();
        }
        _mark(state.priceSignal);
        _recordCandle(state);
        return true;

      case ServerMessage_Payload.quoteTick:
        final tick = message.quoteTick;
        final state = byId[tick.instrumentId.toInt()];
        if (state == null) return true;
        state
          ..ltp = tick.lastTradePrice.toInt()
          ..volume = tick.volumeToday.toInt()
          ..dprUpper = tick.dprUpper.toInt()
          ..dprLower = tick.dprLower.toInt()
          ..openInterest = tick.hasOpenInterest()
              ? tick.openInterest.toInt()
              : null
          ..prevOpenInterest = tick.hasPrevOpenInterest()
              ? tick.prevOpenInterest.toInt()
              : null;
        if (tick.hasLastTradeTime()) {
          state.lastTradeTime = tick.lastTradeTime.toInt();
        }
        _mark(state.priceSignal);
        _recordCandle(state);
        return true;

      case ServerMessage_Payload.depthTick:
        final tick = message.depthTick;
        final state = byId[tick.instrumentId.toInt()];
        if (state == null) return true;
        state
          ..ltp = tick.lastTradePrice.toInt()
          ..volume = tick.volumeToday.toInt()
          ..dprUpper = tick.dprUpper.toInt()
          ..dprLower = tick.dprLower.toInt()
          ..openInterest = tick.hasOpenInterest()
              ? tick.openInterest.toInt()
              : null
          ..prevOpenInterest = tick.hasPrevOpenInterest()
              ? tick.prevOpenInterest.toInt()
              : null
          ..totalBuyQty = tick.totalBuyQty.toInt()
          ..totalSellQty = tick.totalSellQty.toInt();
        if (tick.hasLastTradeTime()) {
          state.lastTradeTime = tick.lastTradeTime.toInt();
        }
        state.bids._set(tick.bestBuys);
        state.asks._set(tick.bestSells);
        _mark(state.priceSignal);
        _mark(state.depthSignal);
        _recordCandle(state);
        return true;

      case ServerMessage_Payload.ack:
      case ServerMessage_Payload.error:
      case ServerMessage_Payload.notSet:
        return false;
    }
  }

  /// Applies a delta from the feed worker (see [SahiDelta]): only the
  /// instruments that changed, newest values each. Does not notify; call
  /// [flush].
  void applyDelta(Int64List d) {
    var o = SahiDelta.headerLength + d[SahiDelta.hDecodeSamples];

    // Every chart tick, so candles keep intermediate highs and lows.
    final chart = byId[chartInstrumentId]!;
    for (var i = 0, n = d[SahiDelta.hChartTicks]; i < n; i++) {
      _recordCandleAt(chart, d[o], d[o + 1]);
      o += 2;
    }

    for (var r = 0, n = d[SahiDelta.hRecords]; r < n; r++) {
      final state = byId[d[o]];
      final flags = d[o + 1];
      final buyLevels = d[o + 11];
      final sellLevels = d[o + 12];
      if (state != null) {
        state.ltp = d[o + 2];
        if (flags & SahiDelta.flagLastTradeTime != 0) {
          state.lastTradeTime = d[o + 3];
        }
        if (flags & SahiDelta.flagQuote != 0) {
          state
            ..volume = d[o + 4]
            ..dprUpper = d[o + 5]
            ..dprLower = d[o + 6];
        }
        state.openInterest = flags & SahiDelta.flagOpenInterest != 0
            ? d[o + 7]
            : null;
        state.prevOpenInterest = flags & SahiDelta.flagPrevOpenInterest != 0
            ? d[o + 8]
            : null;
        _mark(state.priceSignal);
        if (flags & SahiDelta.flagDepth != 0) {
          state
            ..totalBuyQty = d[o + 9]
            ..totalSellQty = d[o + 10];
          var p = o + SahiDelta.recordFixed;
          state.bids._setFlat(d, p, buyLevels);
          p += buyLevels * 3;
          state.asks._setFlat(d, p, sellLevels);
          _mark(state.depthSignal);
        }
      }
      o += SahiDelta.recordFixed + (buyLevels + sellLevels) * 3;
    }
  }

  void _recordCandle(SahiInstrumentState state) {
    if (state.info.id != chartInstrumentId) return;
    final price = state.ltp;
    final time = state.lastTradeTime;
    if (price == null || time == null) return;
    _recordCandleAt(state, price, time);
  }

  void _recordCandleAt(SahiInstrumentState state, int price, int time) {
    final startMicros = time ~/ 1000 * 1000000;
    final candles = state.candles;
    if (candles.isNotEmpty && candles.last.intervalStartMicros == startMicros) {
      final candle = candles.last;
      if (price > candle.high) candle.high = price;
      if (price < candle.low) candle.low = price;
      candle.close = price;
      candle.volume = state.volume;
    } else {
      candles.add(
        Candle(
          intervalStartMicros: startMicros,
          open: price,
          high: price,
          low: price,
          close: price,
          volume: state.volume,
        ),
      );
      if (candles.length > SahiInstrumentState.maxCandles) {
        candles.removeAt(0);
      }
    }
    _mark(state.candleSignal);
  }

  /// Notifies every signal changed since the last flush, once each.
  void flush() {
    if (_dirty.isEmpty) return;
    final pending = List<SahiSignal>.of(_dirty);
    _dirty.clear();
    for (final signal in pending) {
      signal._notify();
    }
  }

  /// Clears all state and notifies every listener.
  void reset() {
    for (final state in byId.values) {
      state._clear();
      _mark(state.priceSignal);
      _mark(state.depthSignal);
      _mark(state.candleSignal);
    }
    flush();
  }
}
