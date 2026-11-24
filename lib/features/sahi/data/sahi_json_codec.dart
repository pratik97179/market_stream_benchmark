import 'package:fixnum/fixnum.dart';

import '../../../generated/sahi_marketdata.pb.dart';

/// JSON twin of the Sahi-style tick stream.
///
/// Sahi itself streams Protobuf only. This is how the same ticks would look
/// as JSON if a broker sent them the way its REST API answers: snake_case
/// keys, prices as integer paise, epoch-millisecond times, enums as short
/// names, optional fields left out. The oneof is a single top-level key, so
/// one text frame is e.g. `{"depth_tick":{...}}`.
///
/// Decoding builds the same generated message objects as
/// `ServerMessage.fromBuffer`, so the rest of the app is identical for both
/// formats and the benchmark compares decoding alone.
abstract final class SahiJsonCodec {
  // ---- Server -> client -------------------------------------------------

  static Map<String, Object?> encodeServerMessage(ServerMessage message) {
    switch (message.whichPayload()) {
      case ServerMessage_Payload.ltpTick:
        return {'ltp_tick': _encodeLtp(message.ltpTick)};
      case ServerMessage_Payload.quoteTick:
        return {'quote_tick': _encodeQuote(message.quoteTick)};
      case ServerMessage_Payload.depthTick:
        return {'depth_tick': _encodeDepth(message.depthTick)};
      case ServerMessage_Payload.ack:
        final ack = message.ack;
        return {
          'ack': {
            'action': _actionNames[ack.action.value],
            'instrument_ids': [for (final id in ack.instrumentIds) id.toInt()],
          },
        };
      case ServerMessage_Payload.error:
        return {
          'error': {
            'code': message.error.code,
            'message': message.error.message,
          },
        };
      case ServerMessage_Payload.notSet:
        return const {};
    }
  }

  static Map<String, Object?> _encodeLtp(LtpTick t) => {
    'instrument_id': t.instrumentId.toInt(),
    'exchange_segment': _segmentNames[t.exchangeSegment.value],
    'instrument_type': _typeNames[t.instrumentType.value],
    'last_trade_price': t.lastTradePrice.toInt(),
    if (t.hasLastTradeTime()) 'last_trade_time': t.lastTradeTime.toInt(),
  };

  static Map<String, Object?> _encodeQuote(QuoteTick t) => {
    'instrument_id': t.instrumentId.toInt(),
    'exchange_segment': _segmentNames[t.exchangeSegment.value],
    'instrument_type': _typeNames[t.instrumentType.value],
    'last_trade_price': t.lastTradePrice.toInt(),
    if (t.hasLastTradeTime()) 'last_trade_time': t.lastTradeTime.toInt(),
    'volume_today': t.volumeToday.toInt(),
    'dpr_upper': t.dprUpper.toInt(),
    'dpr_lower': t.dprLower.toInt(),
    if (t.hasPrevOpenInterest())
      'prev_open_interest': t.prevOpenInterest.toInt(),
    if (t.hasOpenInterest()) 'open_interest': t.openInterest.toInt(),
  };

  static Map<String, Object?> _encodeDepth(DepthTick t) => {
    'instrument_id': t.instrumentId.toInt(),
    'exchange_segment': _segmentNames[t.exchangeSegment.value],
    'instrument_type': _typeNames[t.instrumentType.value],
    'last_trade_price': t.lastTradePrice.toInt(),
    if (t.hasLastTradeTime()) 'last_trade_time': t.lastTradeTime.toInt(),
    'volume_today': t.volumeToday.toInt(),
    'dpr_upper': t.dprUpper.toInt(),
    'dpr_lower': t.dprLower.toInt(),
    if (t.hasPrevOpenInterest())
      'prev_open_interest': t.prevOpenInterest.toInt(),
    if (t.hasOpenInterest()) 'open_interest': t.openInterest.toInt(),
    'best_buys': [for (final l in t.bestBuys) _encodeLevel(l)],
    'best_sells': [for (final l in t.bestSells) _encodeLevel(l)],
    'total_buy_qty': t.totalBuyQty.toInt(),
    'total_sell_qty': t.totalSellQty.toInt(),
  };

  static Map<String, Object?> _encodeLevel(DepthLevel l) => {
    'price': l.price.toInt(),
    'qty': l.qty.toInt(),
    'num_orders': l.numOrders.toInt(),
  };

  /// Decodes one parsed JSON frame (the output of `jsonDecode`).
  static ServerMessage decodeServerMessage(Map<String, dynamic> json) {
    final ltp = json['ltp_tick'];
    if (ltp != null) return ServerMessage(ltpTick: _decodeLtp(ltp));
    final quote = json['quote_tick'];
    if (quote != null) return ServerMessage(quoteTick: _decodeQuote(quote));
    final depth = json['depth_tick'];
    if (depth != null) return ServerMessage(depthTick: _decodeDepth(depth));

    final ack = json['ack'];
    if (ack != null) {
      return ServerMessage(
        ack: Ack(
          action: Action.values[_actionNames.indexOf(ack['action'] as String)],
          instrumentIds: [
            for (final id in ack['instrument_ids'] as List) Int64(id as int),
          ],
        ),
      );
    }
    final error = json['error'];
    if (error != null) {
      return ServerMessage(
        error: StreamError(
          code: error['code'] as String,
          message: error['message'] as String,
        ),
      );
    }
    throw FormatException('Unknown message: ${json.keys}');
  }

  static LtpTick _decodeLtp(Map<String, dynamic> j) {
    final tick = LtpTick()
      ..instrumentId = Int64(j['instrument_id'] as int)
      ..exchangeSegment = _segments[j['exchange_segment']]!
      ..instrumentType = _types[j['instrument_type']]!
      ..lastTradePrice = Int64(j['last_trade_price'] as int);
    final time = j['last_trade_time'];
    if (time != null) tick.lastTradeTime = Int64(time as int);
    return tick;
  }

  static QuoteTick _decodeQuote(Map<String, dynamic> j) {
    final tick = QuoteTick()
      ..instrumentId = Int64(j['instrument_id'] as int)
      ..exchangeSegment = _segments[j['exchange_segment']]!
      ..instrumentType = _types[j['instrument_type']]!
      ..lastTradePrice = Int64(j['last_trade_price'] as int)
      ..volumeToday = Int64(j['volume_today'] as int)
      ..dprUpper = Int64(j['dpr_upper'] as int)
      ..dprLower = Int64(j['dpr_lower'] as int);
    final time = j['last_trade_time'];
    if (time != null) tick.lastTradeTime = Int64(time as int);
    final prevOi = j['prev_open_interest'];
    if (prevOi != null) tick.prevOpenInterest = Int64(prevOi as int);
    final oi = j['open_interest'];
    if (oi != null) tick.openInterest = Int64(oi as int);
    return tick;
  }

  static DepthTick _decodeDepth(Map<String, dynamic> j) {
    final tick = DepthTick()
      ..instrumentId = Int64(j['instrument_id'] as int)
      ..exchangeSegment = _segments[j['exchange_segment']]!
      ..instrumentType = _types[j['instrument_type']]!
      ..lastTradePrice = Int64(j['last_trade_price'] as int)
      ..volumeToday = Int64(j['volume_today'] as int)
      ..dprUpper = Int64(j['dpr_upper'] as int)
      ..dprLower = Int64(j['dpr_lower'] as int)
      ..totalBuyQty = Int64(j['total_buy_qty'] as int)
      ..totalSellQty = Int64(j['total_sell_qty'] as int);
    final time = j['last_trade_time'];
    if (time != null) tick.lastTradeTime = Int64(time as int);
    final prevOi = j['prev_open_interest'];
    if (prevOi != null) tick.prevOpenInterest = Int64(prevOi as int);
    final oi = j['open_interest'];
    if (oi != null) tick.openInterest = Int64(oi as int);
    final buys = tick.bestBuys;
    for (final level in j['best_buys'] as List) {
      buys.add(_decodeLevel(level as Map<String, dynamic>));
    }
    final sells = tick.bestSells;
    for (final level in j['best_sells'] as List) {
      sells.add(_decodeLevel(level as Map<String, dynamic>));
    }
    return tick;
  }

  static DepthLevel _decodeLevel(Map<String, dynamic> j) => DepthLevel()
    ..price = Int64(j['price'] as int)
    ..qty = Int64(j['qty'] as int)
    ..numOrders = Int64(j['num_orders'] as int);

  // ---- Client -> server -------------------------------------------------

  static Map<String, Object?> encodeSubscribe(Mode mode, List<int> ids) => {
    'subscribe': {'mode': _modeNames[mode.value], 'instrument_ids': ids},
  };

  /// Returns the subscribe request in [json], or null for other requests.
  static ({Mode mode, List<int> ids})? decodeSubscribe(
    Map<String, dynamic> json,
  ) {
    final subscribe = json['subscribe'];
    if (subscribe == null) return null;
    return (
      mode: Mode.values[_modeNames.indexOf(subscribe['mode'] as String)],
      ids: (subscribe['instrument_ids'] as List).cast<int>(),
    );
  }

  // ---- Enum names -------------------------------------------------------

  static const _segmentNames = ['INVALID', 'NSE', 'BSE', 'NFO', 'BFO'];
  static const _typeNames = [
    'INVALID',
    'INDEX',
    'STOCK',
    'ETF',
    'INDEX_FUT',
    'INDEX_OPT_CE',
    'INDEX_OPT_PE',
    'STOCK_FUT',
    'STOCK_OPT_CE',
    'STOCK_OPT_PE',
  ];
  static const _modeNames = ['INVALID', 'LTP', 'QUOTE', 'DEPTH'];
  static const _actionNames = [
    'INVALID',
    'SUBSCRIBE',
    'UNSUBSCRIBE',
    'MODE_CHANGE',
  ];

  static final Map<Object?, ExchangeSegment> _segments = {
    for (final s in ExchangeSegment.values) _segmentNames[s.value]: s,
  };
  static final Map<Object?, InstrumentType> _types = {
    for (final t in InstrumentType.values) _typeNames[t.value]: t,
  };
}
