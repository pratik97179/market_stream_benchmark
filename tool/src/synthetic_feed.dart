import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';

import 'server.dart' show serverLog;

import 'package:market_stream_benchmark/generated/market.pb.dart';

// Synthetic feed (`/trading/*`): small per-change events (quotes, trades,
// single order-book levels, candles, indices) batched into each frame.

/// Trading feed intensity, chosen per connection with `?load=heavy`.
enum TradingLoad {
  /// ~7–25 events per batch every 40–140 ms (~200 events/sec).
  normal,

  /// ~60–140 events per batch every 8–20 ms (~6,000 events/sec), closer to a
  /// busy market-data stream.
  heavy,
}

class TradingFeed {
  TradingFeed({this.load = TradingLoad.normal})
    : random = Random(42),
      prices = List<int>.generate(20, (i) => 100000 + i * 12500);

  final TradingLoad load;
  final Random random;
  final List<int> prices;

  int sequence = 0;
  int batchNumber = 0;

  static const int instrumentTotal = 20;
  static const int indexTotal = 3;

  /// Events per candle interval. Timestamps advance 1 ms per event, so this
  /// is also the candle length in milliseconds.
  static const int candleIntervalEvents = 1000;
  static const int baseTimestampMicros = 1700000000000000;

  final Map<int, CandleState> candles = {};

  int nextInt(int max) => random.nextInt(max);

  int get timestamp => baseTimestampMicros + sequence * 1000;

  int get _intervalIndex => sequence ~/ candleIntervalEvents;

  /// Returns the candle for [id] in the current interval, starting a new one
  /// (opened at the current price) when the interval has rolled over.
  CandleState _currentCandle(int id) {
    final interval = _intervalIndex;
    final existing = candles[id];
    if (existing != null && existing.interval == interval) return existing;

    final price = prices[id];
    return candles[id] = CandleState(interval, price);
  }

  MarketEvent _baseEvent() {
    return MarketEvent()
      ..sequence = Int64(sequence++)
      ..timestampMicros = Int64(timestamp);
  }

  int _instrument() => nextInt(instrumentTotal);

  MarketEvent _quote() {
    final id = _instrument();
    final price = prices[id];

    return _baseEvent()
      ..quote = (QuoteUpdate()
        ..instrumentId = id
        ..bidPriceCents = Int64(price - nextInt(20) - 1)
        ..askPriceCents = Int64(price + nextInt(20) + 1)
        ..bidQuantity = 100 + nextInt(5000)
        ..askQuantity = 100 + nextInt(5000));
  }

  MarketEvent _trade() {
    final id = _instrument();
    final movement = nextInt(30) + 1;
    final buy = random.nextBool();

    final candle = _currentCandle(id);
    prices[id] += buy ? movement : -movement;
    final quantity = nextInt(900) + 1;
    candle.record(prices[id], quantity);

    return _baseEvent()
      ..trade = (TradeUpdate()
        ..instrumentId = id
        ..priceCents = Int64(prices[id])
        ..quantity = quantity
        ..side = buy ? TradeSide.BUY : TradeSide.SELL);
  }

  MarketEvent _orderBook() {
    final id = _instrument();
    final price = prices[id];
    final isBid = random.nextBool();
    final level = nextInt(5);

    return _baseEvent()
      ..orderBook = (OrderBookUpdate()
        ..instrumentId = id
        ..side = isBid ? BookSide.BID : BookSide.ASK
        ..level = level
        ..priceCents = Int64(
          isBid ? price - (level + 1) * 25 : price + (level + 1) * 25,
        )
        ..quantity = nextInt(5000) + 100);
  }

  MarketEvent _candle() {
    final id = _instrument();
    final candle = _currentCandle(id);

    return _baseEvent()
      ..candle = (CandleUpdate()
        ..instrumentId = id
        ..openCents = Int64(candle.open)
        ..highCents = Int64(candle.high)
        ..lowCents = Int64(candle.low)
        ..closeCents = Int64(candle.close)
        ..volume = Int64(candle.volume)
        ..intervalStartMicros = Int64(
          baseTimestampMicros + candle.interval * candleIntervalEvents * 1000,
        ));
  }

  MarketEvent _index() {
    final id = nextInt(indexTotal);
    final base = [2481225, 8143210, 5621845][id];
    final change = nextInt(5000) - 2500;

    return _baseEvent()
      ..index = (IndexUpdate()
        ..indexId = id
        ..valueCents = Int64(base + change)
        ..changeCents = Int64(change));
  }

  MarketEvent _instrumentStatus() {
    return _baseEvent()
      ..instrumentStatus = (InstrumentStatusUpdate()
        ..instrumentId = _instrument()
        ..status = InstrumentStatus.ACTIVE);
  }

  MarketEvent _generateEvent() {
    // Quotes: 40%, trades: 25%, order book: 20%,
    // candles: 10%, indices: 4%, status: 1%.

    final roll = nextInt(100);

    if (roll < 40) return _quote();
    if (roll < 65) return _trade();
    if (roll < 85) return _orderBook();
    if (roll < 95) return _candle();
    if (roll < 99) return _index();

    return _instrumentStatus();
  }

  TradingBatch generateBatch() {
    batchNumber++;

    // Variable batch sizes, with occasional bursts.
    final burst = batchNumber % 12 == 0;
    final count = switch (load) {
      TradingLoad.normal => burst ? 30 + nextInt(21) : 8 + nextInt(17),
      TradingLoad.heavy => burst ? 200 + nextInt(101) : 60 + nextInt(81),
    };

    final batch = TradingBatch();

    for (var i = 0; i < count; i++) {
      batch.events.add(_generateEvent());
    }

    return batch;
  }

  int nextDelayMs() => switch (load) {
    TradingLoad.normal => 40 + nextInt(101),
    TradingLoad.heavy => 8 + nextInt(13),
  };
}

class CandleState {
  CandleState(this.interval, int price)
    : open = price,
      high = price,
      low = price,
      close = price;

  final int interval;
  final int open;
  int high;
  int low;
  int close;
  int volume = 0;

  void record(int price, int quantity) {
    high = max(high, price);
    low = min(low, price);
    close = price;
    volume += quantity;
  }
}

void serveSyntheticFeed(WebSocket socket, String path, TradingLoad load) {
  final feed = TradingFeed(load: load);
  final isJson = path == '/trading/json';

  Timer? timer;

  serverLog('Trading client connected: $path | load=${load.name} | seed=42');

  void sendBatch() {
    if (socket.readyState != WebSocket.open) return;

    final batch = feed.generateBatch();

    if (isJson) {
      // Standard proto3 JSON (camelCase field names), as a real JSON API
      // would send, rather than the field-number keyed writeToJson() format.
      socket.add(jsonEncode(batch.toProto3Json()));
    } else {
      socket.add(batch.writeToBuffer());
    }

    timer = Timer(Duration(milliseconds: feed.nextDelayMs()), sendBatch);
  }

  sendBatch();

  socket.listen(
    (_) {},
    onDone: () {
      timer?.cancel();
      serverLog('Trading client disconnected: $path');
    },
    onError: (error) {
      timer?.cancel();
      serverLog('Trading socket error: $error');
    },
  );
}
