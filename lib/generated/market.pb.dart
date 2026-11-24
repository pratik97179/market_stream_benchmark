// This is a generated file - do not edit.
//
// Generated from market.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'market.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'market.pbenum.dart';

enum MarketEvent_Event {
  quote,
  trade,
  orderBook,
  candle,
  index_,
  instrumentStatus,
  notSet
}

/// Trading system events.
class MarketEvent extends $pb.GeneratedMessage {
  factory MarketEvent({
    $fixnum.Int64? sequence,
    $fixnum.Int64? timestampMicros,
    QuoteUpdate? quote,
    TradeUpdate? trade,
    OrderBookUpdate? orderBook,
    CandleUpdate? candle,
    IndexUpdate? index,
    InstrumentStatusUpdate? instrumentStatus,
  }) {
    final result = MarketEvent._();
    if (sequence != null) result.sequence = sequence;
    if (timestampMicros != null) result.timestampMicros = timestampMicros;
    if (quote != null) result.quote = quote;
    if (trade != null) result.trade = trade;
    if (orderBook != null) result.orderBook = orderBook;
    if (candle != null) result.candle = candle;
    if (index != null) result.index = index;
    if (instrumentStatus != null) result.instrumentStatus = instrumentStatus;
    return result;
  }

  MarketEvent._();

  factory MarketEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarketEvent()..mergeFromBuffer(data, registry);
  factory MarketEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarketEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MarketEvent_Event> _MarketEvent_EventByTag =
      {
    10: MarketEvent_Event.quote,
    11: MarketEvent_Event.trade,
    12: MarketEvent_Event.orderBook,
    13: MarketEvent_Event.candle,
    14: MarketEvent_Event.index_,
    15: MarketEvent_Event.instrumentStatus,
    0: MarketEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarketEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: MarketEvent.$_createMessage)
    ..oo(0, [10, 11, 12, 13, 14, 15])
    ..aInt64(1, _omitFieldNames ? '' : 'sequence')
    ..aInt64(2, _omitFieldNames ? '' : 'timestampMicros')
    ..aOM<QuoteUpdate>(10, _omitFieldNames ? '' : 'quote',
        subBuilder: QuoteUpdate.$_createMessage)
    ..aOM<TradeUpdate>(11, _omitFieldNames ? '' : 'trade',
        subBuilder: TradeUpdate.$_createMessage)
    ..aOM<OrderBookUpdate>(12, _omitFieldNames ? '' : 'orderBook',
        subBuilder: OrderBookUpdate.$_createMessage)
    ..aOM<CandleUpdate>(13, _omitFieldNames ? '' : 'candle',
        subBuilder: CandleUpdate.$_createMessage)
    ..aOM<IndexUpdate>(14, _omitFieldNames ? '' : 'index',
        subBuilder: IndexUpdate.$_createMessage)
    ..aOM<InstrumentStatusUpdate>(15, _omitFieldNames ? '' : 'instrumentStatus',
        subBuilder: InstrumentStatusUpdate.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarketEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarketEvent copyWith(void Function(MarketEvent) updates) =>
      super.copyWith((message) => updates(message as MarketEvent))
          as MarketEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarketEvent() / MarketEvent.new instead')
  static MarketEvent create() => MarketEvent._();
  static $pb.GeneratedMessage $_createMessage() => MarketEvent._();
  @$core.override
  MarketEvent createEmptyInstance() => MarketEvent._();
  @$core.pragma('dart2js:noInline')
  static MarketEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MarketEvent>(
          MarketEvent.$_createMessage);
  static MarketEvent? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  MarketEvent_Event whichEvent() => _MarketEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestampMicros => $_getI64(1);
  @$pb.TagNumber(2)
  set timestampMicros($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestampMicros() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestampMicros() => $_clearField(2);

  @$pb.TagNumber(10)
  QuoteUpdate get quote => $_getN(2);
  @$pb.TagNumber(10)
  set quote(QuoteUpdate value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasQuote() => $_has(2);
  @$pb.TagNumber(10)
  void clearQuote() => $_clearField(10);
  @$pb.TagNumber(10)
  QuoteUpdate ensureQuote() => $_ensure(2);

  @$pb.TagNumber(11)
  TradeUpdate get trade => $_getN(3);
  @$pb.TagNumber(11)
  set trade(TradeUpdate value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTrade() => $_has(3);
  @$pb.TagNumber(11)
  void clearTrade() => $_clearField(11);
  @$pb.TagNumber(11)
  TradeUpdate ensureTrade() => $_ensure(3);

  @$pb.TagNumber(12)
  OrderBookUpdate get orderBook => $_getN(4);
  @$pb.TagNumber(12)
  set orderBook(OrderBookUpdate value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasOrderBook() => $_has(4);
  @$pb.TagNumber(12)
  void clearOrderBook() => $_clearField(12);
  @$pb.TagNumber(12)
  OrderBookUpdate ensureOrderBook() => $_ensure(4);

  @$pb.TagNumber(13)
  CandleUpdate get candle => $_getN(5);
  @$pb.TagNumber(13)
  set candle(CandleUpdate value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCandle() => $_has(5);
  @$pb.TagNumber(13)
  void clearCandle() => $_clearField(13);
  @$pb.TagNumber(13)
  CandleUpdate ensureCandle() => $_ensure(5);

  @$pb.TagNumber(14)
  IndexUpdate get index => $_getN(6);
  @$pb.TagNumber(14)
  set index(IndexUpdate value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasIndex() => $_has(6);
  @$pb.TagNumber(14)
  void clearIndex() => $_clearField(14);
  @$pb.TagNumber(14)
  IndexUpdate ensureIndex() => $_ensure(6);

  @$pb.TagNumber(15)
  InstrumentStatusUpdate get instrumentStatus => $_getN(7);
  @$pb.TagNumber(15)
  set instrumentStatus(InstrumentStatusUpdate value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasInstrumentStatus() => $_has(7);
  @$pb.TagNumber(15)
  void clearInstrumentStatus() => $_clearField(15);
  @$pb.TagNumber(15)
  InstrumentStatusUpdate ensureInstrumentStatus() => $_ensure(7);
}

class QuoteUpdate extends $pb.GeneratedMessage {
  factory QuoteUpdate({
    $core.int? instrumentId,
    $fixnum.Int64? bidPriceCents,
    $fixnum.Int64? askPriceCents,
    $core.int? bidQuantity,
    $core.int? askQuantity,
  }) {
    final result = QuoteUpdate._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (bidPriceCents != null) result.bidPriceCents = bidPriceCents;
    if (askPriceCents != null) result.askPriceCents = askPriceCents;
    if (bidQuantity != null) result.bidQuantity = bidQuantity;
    if (askQuantity != null) result.askQuantity = askQuantity;
    return result;
  }

  QuoteUpdate._();

  factory QuoteUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuoteUpdate()..mergeFromBuffer(data, registry);
  factory QuoteUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuoteUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuoteUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: QuoteUpdate.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'instrumentId')
    ..aInt64(2, _omitFieldNames ? '' : 'bidPriceCents')
    ..aInt64(3, _omitFieldNames ? '' : 'askPriceCents')
    ..aI(4, _omitFieldNames ? '' : 'bidQuantity')
    ..aI(5, _omitFieldNames ? '' : 'askQuantity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuoteUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuoteUpdate copyWith(void Function(QuoteUpdate) updates) =>
      super.copyWith((message) => updates(message as QuoteUpdate))
          as QuoteUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QuoteUpdate() / QuoteUpdate.new instead')
  static QuoteUpdate create() => QuoteUpdate._();
  static $pb.GeneratedMessage $_createMessage() => QuoteUpdate._();
  @$core.override
  QuoteUpdate createEmptyInstance() => QuoteUpdate._();
  @$core.pragma('dart2js:noInline')
  static QuoteUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QuoteUpdate>(
          QuoteUpdate.$_createMessage);
  static QuoteUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get instrumentId => $_getIZ(0);
  @$pb.TagNumber(1)
  set instrumentId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bidPriceCents => $_getI64(1);
  @$pb.TagNumber(2)
  set bidPriceCents($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBidPriceCents() => $_has(1);
  @$pb.TagNumber(2)
  void clearBidPriceCents() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get askPriceCents => $_getI64(2);
  @$pb.TagNumber(3)
  set askPriceCents($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAskPriceCents() => $_has(2);
  @$pb.TagNumber(3)
  void clearAskPriceCents() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get bidQuantity => $_getIZ(3);
  @$pb.TagNumber(4)
  set bidQuantity($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBidQuantity() => $_has(3);
  @$pb.TagNumber(4)
  void clearBidQuantity() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get askQuantity => $_getIZ(4);
  @$pb.TagNumber(5)
  set askQuantity($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAskQuantity() => $_has(4);
  @$pb.TagNumber(5)
  void clearAskQuantity() => $_clearField(5);
}

class TradeUpdate extends $pb.GeneratedMessage {
  factory TradeUpdate({
    $core.int? instrumentId,
    $fixnum.Int64? priceCents,
    $core.int? quantity,
    TradeSide? side,
  }) {
    final result = TradeUpdate._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (priceCents != null) result.priceCents = priceCents;
    if (quantity != null) result.quantity = quantity;
    if (side != null) result.side = side;
    return result;
  }

  TradeUpdate._();

  factory TradeUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TradeUpdate()..mergeFromBuffer(data, registry);
  factory TradeUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TradeUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TradeUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: TradeUpdate.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'instrumentId')
    ..aInt64(2, _omitFieldNames ? '' : 'priceCents')
    ..aI(3, _omitFieldNames ? '' : 'quantity')
    ..aE<TradeSide>(4, _omitFieldNames ? '' : 'side',
        enumValues: TradeSide.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TradeUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TradeUpdate copyWith(void Function(TradeUpdate) updates) =>
      super.copyWith((message) => updates(message as TradeUpdate))
          as TradeUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TradeUpdate() / TradeUpdate.new instead')
  static TradeUpdate create() => TradeUpdate._();
  static $pb.GeneratedMessage $_createMessage() => TradeUpdate._();
  @$core.override
  TradeUpdate createEmptyInstance() => TradeUpdate._();
  @$core.pragma('dart2js:noInline')
  static TradeUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TradeUpdate>(
          TradeUpdate.$_createMessage);
  static TradeUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get instrumentId => $_getIZ(0);
  @$pb.TagNumber(1)
  set instrumentId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get priceCents => $_getI64(1);
  @$pb.TagNumber(2)
  set priceCents($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPriceCents() => $_has(1);
  @$pb.TagNumber(2)
  void clearPriceCents() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get quantity => $_getIZ(2);
  @$pb.TagNumber(3)
  set quantity($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQuantity() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuantity() => $_clearField(3);

  @$pb.TagNumber(4)
  TradeSide get side => $_getN(3);
  @$pb.TagNumber(4)
  set side(TradeSide value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSide() => $_has(3);
  @$pb.TagNumber(4)
  void clearSide() => $_clearField(4);
}

class OrderBookUpdate extends $pb.GeneratedMessage {
  factory OrderBookUpdate({
    $core.int? instrumentId,
    BookSide? side,
    $core.int? level,
    $fixnum.Int64? priceCents,
    $core.int? quantity,
  }) {
    final result = OrderBookUpdate._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (side != null) result.side = side;
    if (level != null) result.level = level;
    if (priceCents != null) result.priceCents = priceCents;
    if (quantity != null) result.quantity = quantity;
    return result;
  }

  OrderBookUpdate._();

  factory OrderBookUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OrderBookUpdate()..mergeFromBuffer(data, registry);
  factory OrderBookUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OrderBookUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrderBookUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: OrderBookUpdate.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'instrumentId')
    ..aE<BookSide>(2, _omitFieldNames ? '' : 'side',
        enumValues: BookSide.values)
    ..aI(3, _omitFieldNames ? '' : 'level')
    ..aInt64(4, _omitFieldNames ? '' : 'priceCents')
    ..aI(5, _omitFieldNames ? '' : 'quantity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderBookUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderBookUpdate copyWith(void Function(OrderBookUpdate) updates) =>
      super.copyWith((message) => updates(message as OrderBookUpdate))
          as OrderBookUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OrderBookUpdate() / OrderBookUpdate.new instead')
  static OrderBookUpdate create() => OrderBookUpdate._();
  static $pb.GeneratedMessage $_createMessage() => OrderBookUpdate._();
  @$core.override
  OrderBookUpdate createEmptyInstance() => OrderBookUpdate._();
  @$core.pragma('dart2js:noInline')
  static OrderBookUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OrderBookUpdate>(
          OrderBookUpdate.$_createMessage);
  static OrderBookUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get instrumentId => $_getIZ(0);
  @$pb.TagNumber(1)
  set instrumentId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  BookSide get side => $_getN(1);
  @$pb.TagNumber(2)
  set side(BookSide value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSide() => $_has(1);
  @$pb.TagNumber(2)
  void clearSide() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get level => $_getIZ(2);
  @$pb.TagNumber(3)
  set level($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get priceCents => $_getI64(3);
  @$pb.TagNumber(4)
  set priceCents($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPriceCents() => $_has(3);
  @$pb.TagNumber(4)
  void clearPriceCents() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get quantity => $_getIZ(4);
  @$pb.TagNumber(5)
  set quantity($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasQuantity() => $_has(4);
  @$pb.TagNumber(5)
  void clearQuantity() => $_clearField(5);
}

class CandleUpdate extends $pb.GeneratedMessage {
  factory CandleUpdate({
    $core.int? instrumentId,
    $fixnum.Int64? openCents,
    $fixnum.Int64? highCents,
    $fixnum.Int64? lowCents,
    $fixnum.Int64? closeCents,
    $fixnum.Int64? volume,
    $fixnum.Int64? intervalStartMicros,
  }) {
    final result = CandleUpdate._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (openCents != null) result.openCents = openCents;
    if (highCents != null) result.highCents = highCents;
    if (lowCents != null) result.lowCents = lowCents;
    if (closeCents != null) result.closeCents = closeCents;
    if (volume != null) result.volume = volume;
    if (intervalStartMicros != null)
      result.intervalStartMicros = intervalStartMicros;
    return result;
  }

  CandleUpdate._();

  factory CandleUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CandleUpdate()..mergeFromBuffer(data, registry);
  factory CandleUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CandleUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CandleUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: CandleUpdate.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'instrumentId')
    ..aInt64(2, _omitFieldNames ? '' : 'openCents')
    ..aInt64(3, _omitFieldNames ? '' : 'highCents')
    ..aInt64(4, _omitFieldNames ? '' : 'lowCents')
    ..aInt64(5, _omitFieldNames ? '' : 'closeCents')
    ..aInt64(6, _omitFieldNames ? '' : 'volume')
    ..aInt64(7, _omitFieldNames ? '' : 'intervalStartMicros')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CandleUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CandleUpdate copyWith(void Function(CandleUpdate) updates) =>
      super.copyWith((message) => updates(message as CandleUpdate))
          as CandleUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CandleUpdate() / CandleUpdate.new instead')
  static CandleUpdate create() => CandleUpdate._();
  static $pb.GeneratedMessage $_createMessage() => CandleUpdate._();
  @$core.override
  CandleUpdate createEmptyInstance() => CandleUpdate._();
  @$core.pragma('dart2js:noInline')
  static CandleUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CandleUpdate>(
          CandleUpdate.$_createMessage);
  static CandleUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get instrumentId => $_getIZ(0);
  @$pb.TagNumber(1)
  set instrumentId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get openCents => $_getI64(1);
  @$pb.TagNumber(2)
  set openCents($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOpenCents() => $_has(1);
  @$pb.TagNumber(2)
  void clearOpenCents() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get highCents => $_getI64(2);
  @$pb.TagNumber(3)
  set highCents($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHighCents() => $_has(2);
  @$pb.TagNumber(3)
  void clearHighCents() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lowCents => $_getI64(3);
  @$pb.TagNumber(4)
  set lowCents($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLowCents() => $_has(3);
  @$pb.TagNumber(4)
  void clearLowCents() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get closeCents => $_getI64(4);
  @$pb.TagNumber(5)
  set closeCents($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCloseCents() => $_has(4);
  @$pb.TagNumber(5)
  void clearCloseCents() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get volume => $_getI64(5);
  @$pb.TagNumber(6)
  set volume($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVolume() => $_has(5);
  @$pb.TagNumber(6)
  void clearVolume() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get intervalStartMicros => $_getI64(6);
  @$pb.TagNumber(7)
  set intervalStartMicros($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIntervalStartMicros() => $_has(6);
  @$pb.TagNumber(7)
  void clearIntervalStartMicros() => $_clearField(7);
}

class IndexUpdate extends $pb.GeneratedMessage {
  factory IndexUpdate({
    $core.int? indexId,
    $fixnum.Int64? valueCents,
    $fixnum.Int64? changeCents,
  }) {
    final result = IndexUpdate._();
    if (indexId != null) result.indexId = indexId;
    if (valueCents != null) result.valueCents = valueCents;
    if (changeCents != null) result.changeCents = changeCents;
    return result;
  }

  IndexUpdate._();

  factory IndexUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IndexUpdate()..mergeFromBuffer(data, registry);
  factory IndexUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IndexUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IndexUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: IndexUpdate.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'indexId')
    ..aInt64(2, _omitFieldNames ? '' : 'valueCents')
    ..aInt64(3, _omitFieldNames ? '' : 'changeCents')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IndexUpdate copyWith(void Function(IndexUpdate) updates) =>
      super.copyWith((message) => updates(message as IndexUpdate))
          as IndexUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IndexUpdate() / IndexUpdate.new instead')
  static IndexUpdate create() => IndexUpdate._();
  static $pb.GeneratedMessage $_createMessage() => IndexUpdate._();
  @$core.override
  IndexUpdate createEmptyInstance() => IndexUpdate._();
  @$core.pragma('dart2js:noInline')
  static IndexUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IndexUpdate>(
          IndexUpdate.$_createMessage);
  static IndexUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get indexId => $_getIZ(0);
  @$pb.TagNumber(1)
  set indexId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndexId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndexId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get valueCents => $_getI64(1);
  @$pb.TagNumber(2)
  set valueCents($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValueCents() => $_has(1);
  @$pb.TagNumber(2)
  void clearValueCents() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get changeCents => $_getI64(2);
  @$pb.TagNumber(3)
  set changeCents($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChangeCents() => $_has(2);
  @$pb.TagNumber(3)
  void clearChangeCents() => $_clearField(3);
}

class InstrumentStatusUpdate extends $pb.GeneratedMessage {
  factory InstrumentStatusUpdate({
    $core.int? instrumentId,
    InstrumentStatus? status,
  }) {
    final result = InstrumentStatusUpdate._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (status != null) result.status = status;
    return result;
  }

  InstrumentStatusUpdate._();

  factory InstrumentStatusUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstrumentStatusUpdate()..mergeFromBuffer(data, registry);
  factory InstrumentStatusUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstrumentStatusUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstrumentStatusUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: InstrumentStatusUpdate.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'instrumentId')
    ..aE<InstrumentStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: InstrumentStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstrumentStatusUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstrumentStatusUpdate copyWith(
          void Function(InstrumentStatusUpdate) updates) =>
      super.copyWith((message) => updates(message as InstrumentStatusUpdate))
          as InstrumentStatusUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use InstrumentStatusUpdate() / InstrumentStatusUpdate.new instead')
  static InstrumentStatusUpdate create() => InstrumentStatusUpdate._();
  static $pb.GeneratedMessage $_createMessage() => InstrumentStatusUpdate._();
  @$core.override
  InstrumentStatusUpdate createEmptyInstance() => InstrumentStatusUpdate._();
  @$core.pragma('dart2js:noInline')
  static InstrumentStatusUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstrumentStatusUpdate>(
          InstrumentStatusUpdate.$_createMessage);
  static InstrumentStatusUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get instrumentId => $_getIZ(0);
  @$pb.TagNumber(1)
  set instrumentId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  InstrumentStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(InstrumentStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class TradingBatch extends $pb.GeneratedMessage {
  factory TradingBatch({
    $core.Iterable<MarketEvent>? events,
  }) {
    final result = TradingBatch._();
    if (events != null) result.events.addAll(events);
    return result;
  }

  TradingBatch._();

  factory TradingBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TradingBatch()..mergeFromBuffer(data, registry);
  factory TradingBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TradingBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TradingBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'market'),
      createEmptyInstance: TradingBatch.$_createMessage)
    ..pPM<MarketEvent>(1, _omitFieldNames ? '' : 'events',
        subBuilder: MarketEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TradingBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TradingBatch copyWith(void Function(TradingBatch) updates) =>
      super.copyWith((message) => updates(message as TradingBatch))
          as TradingBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TradingBatch() / TradingBatch.new instead')
  static TradingBatch create() => TradingBatch._();
  static $pb.GeneratedMessage $_createMessage() => TradingBatch._();
  @$core.override
  TradingBatch createEmptyInstance() => TradingBatch._();
  @$core.pragma('dart2js:noInline')
  static TradingBatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TradingBatch>(
          TradingBatch.$_createMessage);
  static TradingBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MarketEvent> get events => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
