import 'dart:math' as math;

import '../../../generated/sahi_marketdata.pb.dart';

/// Static description of one tradable instrument, as a broker app would get
/// it from its instrument master download. Prices are in paise.
class SahiInstrumentInfo {
  const SahiInstrumentInfo({
    required this.id,
    required this.symbol,
    required this.segment,
    required this.type,
    required this.prevClose,
    required this.depthLevels,
    required this.tickWeight,
    this.strike,
  });

  final int id;
  final String symbol;
  final ExchangeSegment segment;
  final InstrumentType type;

  /// Previous close in paise. The tick stream does not carry it; apps load
  /// it with the instrument master to show day change.
  final int prevClose;

  /// Order-book levels the exchange feed provides: 5 (L2) or 20 (L3).
  final int depthLevels;

  /// Relative tick frequency: liquid instruments tick far more often.
  final double tickWeight;

  /// Strike in paise, for options.
  final int? strike;

  bool get isIndex => type == InstrumentType.INSTRUMENT_TYPE_INDEX;

  bool get isDerivative =>
      segment == ExchangeSegment.EXCHANGE_SEGMENT_NFO ||
      segment == ExchangeSegment.EXCHANGE_SEGMENT_BFO;
}

/// One NIFTY option-chain row: the call and put at a strike.
class SahiStrikeRow {
  const SahiStrikeRow(this.strike, this.call, this.put);

  final int strike;
  final SahiInstrumentInfo call;
  final SahiInstrumentInfo put;
}

/// Deterministic 1,000-instrument universe shaped like an Indian broker's:
/// 3 indices, a NIFTY future, 300 stocks, 96 stock futures and a 300-strike
/// NIFTY option chain. Identical on server and client.
class SahiUniverse {
  SahiUniverse._(this.instruments, this.chain)
    : byId = {for (final info in instruments) info.id: info};

  factory SahiUniverse() => _instance;

  static final SahiUniverse _instance = _build();

  final List<SahiInstrumentInfo> instruments;
  final Map<int, SahiInstrumentInfo> byId;

  /// Option chain, lowest strike first.
  final List<SahiStrikeRow> chain;

  static const int tickSize = 5; // paise
  static const int niftySpot = 2435000; // 24,350.00
  static const int strikeStep = 5000; // 50.00
  static const int strikesEachSide = 150;

  List<SahiInstrumentInfo> get indices =>
      instruments.where((i) => i.isIndex).toList(growable: false);

  SahiInstrumentInfo get niftyFuture => byId[35001]!;

  List<SahiInstrumentInfo> get stocks => instruments
      .where((i) => i.type == InstrumentType.INSTRUMENT_TYPE_STOCK)
      .toList(growable: false);

  List<SahiInstrumentInfo> get stockFutures => instruments
      .where((i) => i.type == InstrumentType.INSTRUMENT_TYPE_STOCK_FUT)
      .toList(growable: false);

  /// Index in [chain] of the at-the-money strike.
  int get atmRow => strikesEachSide;

  static int roundToTick(num paise) =>
      math.max(tickSize, (paise / tickSize).round() * tickSize);

  static SahiUniverse _build() {
    final random = math.Random(7);
    final list = <SahiInstrumentInfo>[
      const SahiInstrumentInfo(
        id: 26000,
        symbol: 'NIFTY 50',
        segment: ExchangeSegment.EXCHANGE_SEGMENT_NSE,
        type: InstrumentType.INSTRUMENT_TYPE_INDEX,
        prevClose: niftySpot,
        depthLevels: 0,
        tickWeight: 8,
      ),
      const SahiInstrumentInfo(
        id: 26009,
        symbol: 'NIFTY BANK',
        segment: ExchangeSegment.EXCHANGE_SEGMENT_NSE,
        type: InstrumentType.INSTRUMENT_TYPE_INDEX,
        prevClose: 5210000,
        depthLevels: 0,
        tickWeight: 8,
      ),
      const SahiInstrumentInfo(
        id: 1,
        symbol: 'SENSEX',
        segment: ExchangeSegment.EXCHANGE_SEGMENT_BSE,
        type: InstrumentType.INSTRUMENT_TYPE_INDEX,
        prevClose: 8025000,
        depthLevels: 0,
        tickWeight: 8,
      ),
      const SahiInstrumentInfo(
        id: 35001,
        symbol: 'NIFTY FUT',
        segment: ExchangeSegment.EXCHANGE_SEGMENT_NFO,
        type: InstrumentType.INSTRUMENT_TYPE_INDEX_FUT,
        prevClose: 2441000,
        depthLevels: 20,
        tickWeight: 20,
      ),
    ];

    final stocks = <SahiInstrumentInfo>[];
    for (var rank = 0; rank < 300; rank++) {
      final symbol = rank < _symbols.length
          ? _symbols[rank]
          : 'EQ${(rank + 1).toString().padLeft(3, '0')}';
      final rupees = 50 + random.nextInt(4950);
      stocks.add(
        SahiInstrumentInfo(
          id: 1000 + rank * 7,
          symbol: symbol,
          segment: ExchangeSegment.EXCHANGE_SEGMENT_NSE,
          type: InstrumentType.INSTRUMENT_TYPE_STOCK,
          prevClose: roundToTick(rupees * 100),
          depthLevels: 5,
          // Zipf-like: the most traded names tick far more often.
          tickWeight: 10 / (1 + rank / 8) + 0.3,
        ),
      );
    }
    list.addAll(stocks);

    for (var i = 0; i < 96; i++) {
      final stock = stocks[i];
      list.add(
        SahiInstrumentInfo(
          id: 50000 + i,
          symbol: '${stock.symbol} FUT',
          segment: ExchangeSegment.EXCHANGE_SEGMENT_NFO,
          type: InstrumentType.INSTRUMENT_TYPE_STOCK_FUT,
          prevClose: roundToTick(stock.prevClose * 1.004),
          depthLevels: 5,
          tickWeight: 1,
        ),
      );
    }

    final chain = <SahiStrikeRow>[];
    for (var k = -strikesEachSide; k < strikesEachSide; k++) {
      final strike = niftySpot + k * strikeStep;
      final distance = k.abs();
      // Time value decays away from the money; options never go below 0.05.
      final timeValue = 12000 * math.exp(-distance / 12);
      final weight = 30 * math.exp(-distance / 10) + 0.3;
      SahiInstrumentInfo option(bool call) {
        final intrinsic = call
            ? math.max(0, niftySpot - strike)
            : math.max(0, strike - niftySpot);
        final row = k + strikesEachSide;
        return SahiInstrumentInfo(
          id: 40000 + row * 2 + (call ? 0 : 1),
          symbol: 'NIFTY ${strike ~/ 100} ${call ? 'CE' : 'PE'}',
          segment: ExchangeSegment.EXCHANGE_SEGMENT_NFO,
          type: call
              ? InstrumentType.INSTRUMENT_TYPE_INDEX_OPT_CE
              : InstrumentType.INSTRUMENT_TYPE_INDEX_OPT_PE,
          prevClose: roundToTick(intrinsic + timeValue),
          depthLevels: 5,
          tickWeight: weight,
          strike: strike,
        );
      }

      final row = SahiStrikeRow(strike, option(true), option(false));
      chain.add(row);
      list
        ..add(row.call)
        ..add(row.put);
    }

    return SahiUniverse._(List.unmodifiable(list), List.unmodifiable(chain));
  }

  static const _symbols = [
    'RELIANCE', 'HDFCBANK', 'ICICIBANK', 'INFY', 'TCS', 'BHARTIARTL', //
    'ITC', 'SBIN', 'LT', 'KOTAKBANK', 'AXISBANK', 'HINDUNILVR', //
    'BAJFINANCE', 'MARUTI', 'M&M', 'SUNPHARMA', 'TATAMOTORS', 'HCLTECH', //
    'NTPC', 'TITAN', 'ULTRACEMCO', 'POWERGRID', 'ASIANPAINT', 'ONGC', //
    'TATASTEEL', 'ADANIENT', 'ADANIPORTS', 'COALINDIA', 'WIPRO', 'JSWSTEEL', //
    'BAJAJFINSV', 'NESTLEIND', 'TECHM', 'GRASIM', 'HINDALCO', 'DRREDDY', //
    'CIPLA', 'SBILIFE', 'BPCL', 'EICHERMOT', 'BRITANNIA', 'HEROMOTOCO', //
    'APOLLOHOSP', 'DIVISLAB', 'TATACONSUM', 'INDUSINDBK', 'HDFCLIFE', //
    'SHRIRAMFIN', 'BEL', 'TRENT',
  ];
}

/// What a broker app has subscribed to, and how hard the server pushes.
class SahiScenario {
  const SahiScenario({
    required this.name,
    required this.depth,
    required this.quote,
    required this.ltp,
    required this.ticksPerSecond,
    required this.description,
  });

  final String name;
  final List<int> depth;
  final List<int> quote;
  final List<int> ltp;
  final int ticksPerSecond;
  final String description;

  int get instrumentCount => depth.length + quote.length + ltp.length;

  Map<int, Mode> get modes => {
    for (final id in ltp) id: Mode.MODE_LTP,
    for (final id in quote) id: Mode.MODE_QUOTE,
    for (final id in depth) id: Mode.MODE_DEPTH,
  };

  /// Watchlist of 20 stocks in QUOTE mode, NIFTY FUT in DEPTH (20 levels),
  /// 21 strikes around the money in QUOTE, indices and 34 holdings in LTP:
  /// 100 instruments, ~200 ticks/s.
  static SahiScenario normal() {
    final u = SahiUniverse();
    final stocks = u.stocks;
    final atm = u.atmRow;
    final chain = u.chain.sublist(atm - 10, atm + 11);
    return SahiScenario(
      name: 'normal',
      description: 'watchlist: 100 instruments, ~200 ticks/s',
      depth: [u.niftyFuture.id],
      quote: [
        for (final s in stocks.take(20)) s.id,
        for (final row in chain) ...[row.call.id, row.put.id],
      ],
      ltp: [
        for (final i in u.indices) i.id,
        for (final s in stocks.skip(20).take(34)) s.id,
      ],
      ticksPerSecond: 200,
    );
  }

  /// Expiry-day stress: the full 1,000-instrument limit of one connection.
  /// 5 instruments in DEPTH, the whole option chain and stock futures in
  /// QUOTE, everything else in LTP; ~4,000 ticks/s.
  static SahiScenario heavy() {
    final u = SahiUniverse();
    final stocks = u.stocks;
    return SahiScenario(
      name: 'heavy',
      description: 'expiry stress: 1,000 instruments, ~4,000 ticks/s',
      depth: [u.niftyFuture.id, for (final s in stocks.take(4)) s.id],
      quote: [
        for (final s in stocks.skip(4).take(16)) s.id,
        for (final row in u.chain) ...[row.call.id, row.put.id],
        for (final f in u.stockFutures) f.id,
      ],
      ltp: [
        for (final i in u.indices) i.id,
        for (final s in stocks.skip(20)) s.id,
      ],
      ticksPerSecond: 4000,
    );
  }

  static SahiScenario forLoad(String load) =>
      load == 'heavy' ? heavy() : normal();
}
