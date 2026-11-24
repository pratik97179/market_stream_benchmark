import 'dart:typed_data';

import '../../../generated/sahi_marketdata.pb.dart';

/// Compact per-frame update sent from the feed worker isolate to the UI.
///
/// The worker folds every decoded tick into a table of latest values per
/// instrument ([SahiCoalescer]). When the UI is ready for a new frame it
/// asks for a delta: one [Int64List] with only the instruments that changed
/// since the last delta, newest values each. Typed data crosses isolates as
/// a memory copy, with no per-object work on the UI thread.
///
/// Layout (all int64):
///
///     header        [headerLength] values, at the h* indices
///     decode        one decode time (µs) per tick
///     chart ticks   (price, time) pairs for the chart instrument, so its
///                   candles keep every intermediate high and low
///     records       per changed instrument:
///                   id, flags, ltp, lastTradeTime, volume, dprUpper,
///                   dprLower, openInterest, prevOpenInterest, totalBuyQty,
///                   totalSellQty, buyLevels, sellLevels,
///                   then (price, qty, orders) per buy level, per sell level
abstract final class SahiDelta {
  static const int hTicks = 0;
  static const int hPayloadBytes = 1;
  static const int hWorkerBusyMicros = 2;
  static const int hOldestReceiveMicros = 3;
  static const int hRecords = 4;
  static const int hDecodeSamples = 5;
  static const int hChartTicks = 6;
  static const int hDecodeErrors = 7;
  static const int headerLength = 8;

  static const int recordFixed = 13;

  static const int flagLastTradeTime = 1;
  static const int flagQuote = 2;
  static const int flagDepth = 4;
  static const int flagOpenInterest = 8;
  static const int flagPrevOpenInterest = 16;
}

/// Latest values per instrument, kept by the worker between deltas.
class _Slot {
  _Slot(this.id);

  final int id;
  int flags = 0;
  int ltp = 0;
  int lastTradeTime = 0;
  int volume = 0;
  int dprUpper = 0;
  int dprLower = 0;
  int openInterest = 0;
  int prevOpenInterest = 0;
  int totalBuyQty = 0;
  int totalSellQty = 0;
  int buyLevels = 0;
  int sellLevels = 0;
  Int64List? book; // 20 buy + 20 sell levels × (price, qty, orders)
  bool changed = false;
}

/// Folds decoded ticks into latest-per-instrument state and packs deltas.
/// Runs on the worker isolate; pure Dart so it is unit-testable.
class SahiCoalescer {
  SahiCoalescer({required this.chartInstrumentId});

  static const int _maxLevels = 20;

  final int chartInstrumentId;
  final Map<int, _Slot> _slots = {};
  final List<_Slot> _changed = [];

  // Stats since the last delta.
  int _ticks = 0;
  int _payloadBytes = 0;
  int _workerBusyMicros = 0;
  int _oldestReceiveMicros = 0;
  int _decodeErrors = 0;
  final List<int> _decodeSamples = [];
  final List<int> _chartTicks = [];

  bool get hasPending => _ticks > 0 || _decodeErrors > 0 || _changed.isNotEmpty;

  void recordError() => _decodeErrors++;

  /// Adds one decoded message. [receiveMicros] is when its frame arrived, on
  /// the process-wide monotonic clock (`Timeline.now`); [decodeMicros] is how
  /// long decoding it took.
  void add(
    ServerMessage message, {
    required int payloadBytes,
    required int decodeMicros,
    required int receiveMicros,
  }) {
    final int id;
    final int flags;
    switch (message.whichPayload()) {
      case ServerMessage_Payload.ltpTick:
        final t = message.ltpTick;
        id = t.instrumentId.toInt();
        final slot = _slot(id);
        slot.ltp = t.lastTradePrice.toInt();
        if (t.hasLastTradeTime()) {
          slot.lastTradeTime = t.lastTradeTime.toInt();
          flags = SahiDelta.flagLastTradeTime;
        } else {
          flags = 0;
        }
        // Keep fields from richer modes; LTP ticks only refresh the price.
        slot.flags = (slot.flags & ~SahiDelta.flagLastTradeTime) | flags;
        _touch(slot, t.lastTradePrice.toInt(), slot.lastTradeTime);

      case ServerMessage_Payload.quoteTick:
        final t = message.quoteTick;
        id = t.instrumentId.toInt();
        final slot = _slot(id);
        slot
          ..ltp = t.lastTradePrice.toInt()
          ..volume = t.volumeToday.toInt()
          ..dprUpper = t.dprUpper.toInt()
          ..dprLower = t.dprLower.toInt();
        var f = SahiDelta.flagQuote | (slot.flags & SahiDelta.flagDepth);
        if (t.hasLastTradeTime()) {
          slot.lastTradeTime = t.lastTradeTime.toInt();
          f |= SahiDelta.flagLastTradeTime;
        }
        if (t.hasOpenInterest()) {
          slot.openInterest = t.openInterest.toInt();
          f |= SahiDelta.flagOpenInterest;
        }
        if (t.hasPrevOpenInterest()) {
          slot.prevOpenInterest = t.prevOpenInterest.toInt();
          f |= SahiDelta.flagPrevOpenInterest;
        }
        slot.flags = f;
        _touch(slot, slot.ltp, slot.lastTradeTime);

      case ServerMessage_Payload.depthTick:
        final t = message.depthTick;
        id = t.instrumentId.toInt();
        final slot = _slot(id);
        slot
          ..ltp = t.lastTradePrice.toInt()
          ..volume = t.volumeToday.toInt()
          ..dprUpper = t.dprUpper.toInt()
          ..dprLower = t.dprLower.toInt()
          ..totalBuyQty = t.totalBuyQty.toInt()
          ..totalSellQty = t.totalSellQty.toInt();
        var f = SahiDelta.flagQuote | SahiDelta.flagDepth;
        if (t.hasLastTradeTime()) {
          slot.lastTradeTime = t.lastTradeTime.toInt();
          f |= SahiDelta.flagLastTradeTime;
        }
        if (t.hasOpenInterest()) {
          slot.openInterest = t.openInterest.toInt();
          f |= SahiDelta.flagOpenInterest;
        }
        if (t.hasPrevOpenInterest()) {
          slot.prevOpenInterest = t.prevOpenInterest.toInt();
          f |= SahiDelta.flagPrevOpenInterest;
        }
        slot.flags = f;
        final book = slot.book ??= Int64List(_maxLevels * 6);
        slot.buyLevels = _copyLevels(t.bestBuys, book, 0);
        slot.sellLevels = _copyLevels(t.bestSells, book, _maxLevels * 3);
        _touch(slot, slot.ltp, slot.lastTradeTime);

      case ServerMessage_Payload.ack:
      case ServerMessage_Payload.error:
      case ServerMessage_Payload.notSet:
        if (message.hasError()) _decodeErrors++;
        return;
    }

    if (_ticks == 0) _oldestReceiveMicros = receiveMicros;
    _ticks++;
    _payloadBytes += payloadBytes;
    _decodeSamples.add(decodeMicros);
  }

  /// Adds worker time spent on one message (decode plus [add]).
  void addBusy(int micros) => _workerBusyMicros += micros;

  _Slot _slot(int id) => _slots[id] ??= _Slot(id);

  void _touch(_Slot slot, int price, int time) {
    if (!slot.changed) {
      slot.changed = true;
      _changed.add(slot);
    }
    if (slot.id == chartInstrumentId &&
        slot.flags & SahiDelta.flagLastTradeTime != 0) {
      _chartTicks
        ..add(price)
        ..add(time);
    }
  }

  static int _copyLevels(List<DepthLevel> levels, Int64List book, int base) {
    final n = levels.length < _maxLevels ? levels.length : _maxLevels;
    for (var i = 0; i < n; i++) {
      final level = levels[i];
      final o = base + i * 3;
      book[o] = level.price.toInt();
      book[o + 1] = level.qty.toInt();
      book[o + 2] = level.numOrders.toInt();
    }
    return n;
  }

  /// Packs everything since the last call and resets the stats.
  Int64List takeDelta() {
    var length =
        SahiDelta.headerLength + _decodeSamples.length + _chartTicks.length;
    for (final slot in _changed) {
      length += SahiDelta.recordFixed;
      if (slot.flags & SahiDelta.flagDepth != 0) {
        length += (slot.buyLevels + slot.sellLevels) * 3;
      }
    }

    final out = Int64List(length);
    out[SahiDelta.hTicks] = _ticks;
    out[SahiDelta.hPayloadBytes] = _payloadBytes;
    out[SahiDelta.hWorkerBusyMicros] = _workerBusyMicros;
    out[SahiDelta.hOldestReceiveMicros] = _oldestReceiveMicros;
    out[SahiDelta.hRecords] = _changed.length;
    out[SahiDelta.hDecodeSamples] = _decodeSamples.length;
    out[SahiDelta.hChartTicks] = _chartTicks.length ~/ 2;
    out[SahiDelta.hDecodeErrors] = _decodeErrors;

    var o = SahiDelta.headerLength;
    for (final sample in _decodeSamples) {
      out[o++] = sample;
    }
    for (final value in _chartTicks) {
      out[o++] = value;
    }
    for (final slot in _changed) {
      out[o++] = slot.id;
      out[o++] = slot.flags;
      out[o++] = slot.ltp;
      out[o++] = slot.lastTradeTime;
      out[o++] = slot.volume;
      out[o++] = slot.dprUpper;
      out[o++] = slot.dprLower;
      out[o++] = slot.openInterest;
      out[o++] = slot.prevOpenInterest;
      out[o++] = slot.totalBuyQty;
      out[o++] = slot.totalSellQty;
      final depth = slot.flags & SahiDelta.flagDepth != 0;
      out[o++] = depth ? slot.buyLevels : 0;
      out[o++] = depth ? slot.sellLevels : 0;
      if (depth) {
        final book = slot.book!;
        out.setRange(o, o + slot.buyLevels * 3, book);
        o += slot.buyLevels * 3;
        out.setRange(o, o + slot.sellLevels * 3, book, _maxLevels * 3);
        o += slot.sellLevels * 3;
      }
      slot.changed = false;
    }

    _changed.clear();
    _decodeSamples.clear();
    _chartTicks.clear();
    _ticks = 0;
    _payloadBytes = 0;
    _workerBusyMicros = 0;
    _decodeErrors = 0;
    return out;
  }
}
