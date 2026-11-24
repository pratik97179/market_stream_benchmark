import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:market_stream_benchmark/features/sahi/data/sahi_delta.dart';
import 'package:market_stream_benchmark/features/sahi/data/sahi_json_codec.dart';
import 'package:market_stream_benchmark/features/sahi/domain/sahi_store.dart';
import 'package:market_stream_benchmark/features/sahi/domain/sahi_universe.dart';
import 'package:market_stream_benchmark/features/sahi/presentation/sahi_dashboard.dart';
import 'package:market_stream_benchmark/generated/sahi_marketdata.pb.dart';

import '../tool/src/sahi_feed.dart';

void main() {
  group('Sahi universe and scenarios', () {
    test('has 1,000 unique instruments', () {
      final universe = SahiUniverse();
      expect(universe.instruments, hasLength(1000));
      expect(universe.byId, hasLength(1000));
    });

    test('scenarios subscribe 100 and 1,000 instruments, each once', () {
      for (final (scenario, count) in [
        (SahiScenario.normal(), 100),
        (SahiScenario.heavy(), 1000),
      ]) {
        expect(scenario.instrumentCount, count);
        expect(scenario.modes, hasLength(count));
      }
    });
  });

  test('JSON and Protobuf decode to identical messages', () {
    final generator = SahiTickGenerator(
      SahiScenario.heavy().modes,
      ticksPerSecond: 4000,
    );
    final seen = <ServerMessage_Payload>{};
    for (var i = 0; i < 5000; i++) {
      final message = generator.next();
      seen.add(message.whichPayload());

      final fromProto = ServerMessage.fromBuffer(message.writeToBuffer());
      final fromJson = SahiJsonCodec.decodeServerMessage(
        jsonDecode(jsonEncode(SahiJsonCodec.encodeServerMessage(message)))
            as Map<String, dynamic>,
      );
      expect(fromJson, fromProto);
      expect(fromProto, message);
    }
    expect(seen, {
      ServerMessage_Payload.ltpTick,
      ServerMessage_Payload.quoteTick,
      ServerMessage_Payload.depthTick,
    });
  });

  test('generator is deterministic for a subscription', () {
    final modes = SahiScenario.normal().modes;
    final a = SahiTickGenerator(modes, ticksPerSecond: 200);
    final b = SahiTickGenerator(modes, ticksPerSecond: 200);
    for (var i = 0; i < 500; i++) {
      expect(a.next(), b.next());
    }
  });

  test('depth ticks are never zero-padded and respect the feed depth', () {
    final generator = SahiTickGenerator(
      SahiScenario.heavy().modes,
      ticksPerSecond: 4000,
    );
    final future = SahiUniverse().niftyFuture.id;
    var futureTicks = 0;
    for (var i = 0; i < 20000; i++) {
      final message = generator.next();
      if (!message.hasDepthTick()) continue;
      final tick = message.depthTick;
      for (final level in [...tick.bestBuys, ...tick.bestSells]) {
        expect(level.qty, greaterThan(Int64.ZERO));
      }
      if (tick.instrumentId.toInt() == future) {
        futureTicks++;
        expect(tick.bestBuys, hasLength(20));
        expect(tick.bestSells, hasLength(20));
      } else {
        expect(tick.bestBuys.length, lessThanOrEqualTo(5));
      }
    }
    expect(futureTicks, greaterThan(0));
  });

  group('SahiStore', () {
    test('applies quote and depth snapshots', () {
      final store = SahiStore();
      final future = SahiUniverse().niftyFuture;
      store.apply(
        ServerMessage(
          depthTick: DepthTick(
            instrumentId: Int64(future.id),
            lastTradePrice: Int64(2441500),
            lastTradeTime: Int64(1795496700000),
            volumeToday: Int64(750),
            openInterest: Int64(1000),
            prevOpenInterest: Int64(900),
            bestBuys: [
              DepthLevel(
                price: Int64(2441495),
                qty: Int64(75),
                numOrders: Int64(2),
              ),
            ],
            bestSells: [
              DepthLevel(
                price: Int64(2441500),
                qty: Int64(150),
                numOrders: Int64(3),
              ),
              DepthLevel(
                price: Int64(2441505),
                qty: Int64(225),
                numOrders: Int64(4),
              ),
            ],
            totalBuyQty: Int64(5000),
            totalSellQty: Int64(6000),
          ),
        ),
      );
      final state = store.byId[future.id]!;
      expect(state.ltp, 2441500);
      expect(state.openInterest, 1000);
      expect(state.bids.count, 1);
      expect(state.asks.count, 2);
      expect(state.asks.quantities[1], 225);
      expect(state.totalSellQty, 6000);
      expect(state.candles, hasLength(1));

      // Ack messages are not ticks.
      expect(store.apply(ServerMessage(ack: Ack())), isFalse);
    });

    test('builds candles only for the chart instrument', () {
      final store = SahiStore();
      final stock = SahiUniverse().stocks.first;
      store.apply(
        ServerMessage(
          ltpTick: LtpTick(
            instrumentId: Int64(stock.id),
            lastTradePrice: Int64(100000),
            lastTradeTime: Int64(1795496700000),
          ),
        ),
      );
      expect(store.byId[stock.id]!.candles, isEmpty);
      expect(store.byId[stock.id]!.ltp, 100000);
    });
  });

  for (final painted in [true, false]) {
    testWidgets(
      'dashboard (${painted ? 'painted' : 'widget'} tables) redraws only for '
      'instruments on screen',
      (tester) async {
        final store = SahiStore();
        final dashboard = SahiDashboard(store: store, paintedTables: painted);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(children: dashboard.panels(wide: false)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        ServerMessage quote(int id, int price) => ServerMessage(
          quoteTick: QuoteTick(
            instrumentId: Int64(id),
            lastTradePrice: Int64(price),
            lastTradeTime: Int64(1795496700000),
          ),
        );

        // Stock rank 250 is subscribed in the heavy scenario but on no panel.
        final hidden = SahiUniverse().stocks[250].id;
        store
          ..apply(quote(hidden, 12345))
          ..flush();
        expect(tester.binding.hasScheduledFrame, isFalse);

        // A watchlist stock changes: its painted row repaints, nothing rebuilds.
        final reliance = SahiUniverse().stocks.first.id;
        store
          ..apply(quote(reliance, 9999999))
          ..flush();
        expect(tester.binding.hasScheduledFrame, isTrue);
        await tester.pump();

        // The futures header is a widget: its text updates.
        store
          ..apply(quote(SahiUniverse().niftyFuture.id, 9999999))
          ..flush();
        await tester.pump();
        // Painted watchlist rows are not Text widgets; widget rows are.
        expect(
          find.text('99,999.99'),
          painted ? findsOneWidget : findsNWidgets(2),
        );
      },
    );
  }

  test('coalesced worker deltas give the same state as every tick', () {
    final generator = SahiTickGenerator(
      SahiScenario.heavy().modes,
      ticksPerSecond: 4000,
    );
    final direct = SahiStore();
    final viaDelta = SahiStore();
    final coalescer = SahiCoalescer(
      chartInstrumentId: viaDelta.chartInstrumentId,
    );

    var deltas = 0;
    var ticksInDeltas = 0;
    for (var i = 0; i < 20000; i++) {
      final message = generator.next();
      direct.apply(message);
      coalescer.add(
        message,
        payloadBytes: 40,
        decodeMicros: 3,
        receiveMicros: i,
      );
      // The UI pulls at irregular points, as frames would.
      if (i % 97 == 0 || i % 61 == 0) {
        final delta = coalescer.takeDelta();
        ticksInDeltas += delta[SahiDelta.hTicks];
        expect(delta[SahiDelta.hDecodeSamples], delta[SahiDelta.hTicks]);
        viaDelta.applyDelta(delta);
        deltas++;
      }
    }
    final last = coalescer.takeDelta();
    ticksInDeltas += last[SahiDelta.hTicks];
    viaDelta.applyDelta(last);

    expect(ticksInDeltas, 20000);
    expect(deltas, greaterThan(100));
    for (final id in direct.byId.keys) {
      final a = direct.byId[id]!;
      final b = viaDelta.byId[id]!;
      expect(b.ltp, a.ltp, reason: 'ltp $id');
      expect(b.lastTradeTime, a.lastTradeTime, reason: 'time $id');
      expect(b.volume, a.volume, reason: 'volume $id');
      expect(b.dprUpper, a.dprUpper);
      expect(b.openInterest, a.openInterest, reason: 'oi $id');
      expect(b.prevOpenInterest, a.prevOpenInterest);
      expect(b.totalBuyQty, a.totalBuyQty);
      expect(b.bids.count, a.bids.count, reason: 'bids $id');
      expect(b.asks.count, a.asks.count);
      for (var l = 0; l < a.bids.count; l++) {
        expect(b.bids.prices[l], a.bids.prices[l]);
        expect(b.bids.orders[l], a.bids.orders[l]);
      }
      for (var l = 0; l < a.asks.count; l++) {
        expect(b.asks.quantities[l], a.asks.quantities[l]);
      }
    }

    // Candles keep every intermediate high and low.
    final chartA = direct.byId[direct.chartInstrumentId]!.candles;
    final chartB = viaDelta.byId[viaDelta.chartInstrumentId]!.candles;
    expect(chartB.length, chartA.length);
    for (var c = 0; c < chartA.length; c++) {
      expect(chartB[c].open, chartA[c].open);
      expect(chartB[c].high, chartA[c].high);
      expect(chartB[c].low, chartA[c].low);
      expect(chartB[c].close, chartA[c].close);
    }
  });
}
