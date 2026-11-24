import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_stream_benchmark/app/benchmark_app.dart';
import 'package:market_stream_benchmark/app/server_settings.dart';
import 'package:market_stream_benchmark/features/trading/data/benchmark_feed.dart';
import 'package:market_stream_benchmark/features/trading/domain/market_store.dart';
import 'package:market_stream_benchmark/features/trading/presentation/widgets/market_dashboard.dart';
import 'package:market_stream_benchmark/generated/market.pb.dart';

void main() {
  testWidgets('Home screen lists every benchmark variant', (tester) async {
    await tester.pumpWidget(const BenchmarkApp());

    expect(find.text('Market Feed Benchmark'), findsOneWidget);
    for (final variant in BenchmarkVariant.values) {
      await tester.scrollUntilVisible(find.text(variant.title), 100);
      expect(find.text(variant.title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Server: 127.0.0.1:8080'), -100);
    expect(find.text('Server: 127.0.0.1:8080'), findsOneWidget);
  });

  group('isValidIPv4', () {
    test('accepts dotted-quad addresses', () {
      expect(isValidIPv4('192.168.1.20'), isTrue);
      expect(isValidIPv4('0.0.0.0'), isTrue);
      expect(isValidIPv4('255.255.255.255'), isTrue);
    });

    test('rejects malformed addresses', () {
      for (final value in [
        '',
        '1.2.3',
        '1.2.3.4.5',
        '256.1.1.1',
        '01.2.3.4',
        '1.2.3.-4',
        '1.2.3.+4',
        'a.b.c.d',
        '::1',
      ]) {
        expect(isValidIPv4(value), isFalse, reason: value);
      }
    });
  });

  group('MarketStore', () {
    MarketEvent candle(int start, int close) =>
        MarketEvent()
          ..candle = (CandleUpdate()
            ..instrumentId = 0
            ..openCents = Int64(100)
            ..highCents = Int64(close)
            ..lowCents = Int64(100)
            ..closeCents = Int64(close)
            ..intervalStartMicros = Int64(start));

    MarketEvent trade(int id, int price) =>
        MarketEvent()
          ..trade = (TradeUpdate()
            ..instrumentId = id
            ..priceCents = Int64(price)
            ..side = TradeSide.BUY);

    test(
      'replaces the last candle within an interval, appends on a new one',
      () {
        final store = MarketStore()
          ..apply(TradingBatch(events: [candle(0, 101), candle(0, 102)]))
          ..apply(TradingBatch(events: [candle(1000, 103)]));

        expect(store.instruments[0].candles.map((c) => c.close), [102, 103]);
      },
    );

    test('tracks last trade price and newest-first trades per instrument', () {
      final store = MarketStore()
        ..apply(TradingBatch(events: [trade(3, 500), trade(3, 510)]));

      final state = store.instruments[3];
      expect(state.lastTradeCents, 510);
      expect(state.displayPriceCents, 510);
      expect(state.trades.map((t) => t.priceCents), [510, 500]);
      expect(store.instruments[4].trades, isEmpty);
    });

    test('keeps a bounded trade history', () {
      final store = MarketStore()
        ..apply(
          TradingBatch(events: [for (var i = 0; i < 50; i++) trade(1, i)]),
        );
      expect(store.instruments[1].trades.length, InstrumentState.maxTrades);
      expect(store.instruments[1].trades.first.priceCents, 49);
    });

    test('order book updates fixed levels and ignores out-of-range levels', () {
      MarketEvent level(BookSide side, int level, int price) =>
          MarketEvent()
            ..orderBook = (OrderBookUpdate()
              ..instrumentId = 2
              ..side = side
              ..level = level
              ..priceCents = Int64(price)
              ..quantity = 10);

      final store = MarketStore()
        ..apply(
          TradingBatch(
            events: [
              level(BookSide.BID, 0, 990),
              level(BookSide.ASK, 4, 1050),
              level(BookSide.BID, 9, 1),
            ],
          ),
        );

      final state = store.instruments[2];
      expect(state.bids.present, [true, false, false, false, false]);
      expect(state.bids.prices[0], 990);
      expect(state.asks.present[4], isTrue);
      expect(state.asks.prices[4], 1050);
    });

    test('flush notifies each touched slice once and nothing else', () {
      final store = MarketStore();
      var price3 = 0, trades3 = 0, price4 = 0, book3 = 0;
      store.instruments[3].priceSignal.addListener(() => price3++);
      store.instruments[3].tradesSignal.addListener(() => trades3++);
      store.instruments[3].bookSignal.addListener(() => book3++);
      store.instruments[4].priceSignal.addListener(() => price4++);

      store
        ..apply(TradingBatch(events: [trade(3, 1), trade(3, 2), trade(3, 3)]))
        ..apply(TradingBatch(events: [trade(3, 4)]));
      expect(price3, 0, reason: 'apply alone must not notify');

      store.flush();
      expect(price3, 1);
      expect(trades3, 1);
      expect(book3, 0);
      expect(price4, 0);

      store.flush();
      expect(price3, 1, reason: 'nothing pending');
    });
  });

  test('TradingBatch round-trips through proto3 JSON', () {
    final batch = TradingBatch(
      events: [
        MarketEvent()
          ..sequence = Int64(7)
          ..quote = (QuoteUpdate()
            ..instrumentId = 2
            ..bidPriceCents = Int64(9999)
            ..askPriceCents = Int64(10001)),
      ],
    );

    final wire = jsonEncode(batch.toProto3Json());
    expect(wire, contains('"bidPriceCents"'));

    final decoded = TradingBatch()..mergeFromProto3Json(jsonDecode(wire));
    expect(decoded, batch);
  });

  testWidgets('dashboard redraws only when displayed data changes', (
    tester,
  ) async {
    final store = MarketStore();
    final dashboard = MarketDashboard(store: store);
    addTearDown(dashboard.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [dashboard.indices, ...dashboard.narrowPanels],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    MarketEvent trade(int id, int price) =>
        MarketEvent()
          ..trade = (TradeUpdate()
            ..instrumentId = id
            ..priceCents = Int64(price)
            ..side = TradeSide.SELL);

    // Instrument 15 is not in the watchlist or selected: no frame needed.
    store
      ..apply(TradingBatch(events: [trade(15, 12345)]))
      ..flush();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // The selected instrument (0) changes: its widgets update.
    store
      ..apply(TradingBatch(events: [trade(0, 99999)]))
      ..flush();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(find.text('999.99'), findsWidgets);
    expect(find.text('123.45'), findsNothing);
  });
}
