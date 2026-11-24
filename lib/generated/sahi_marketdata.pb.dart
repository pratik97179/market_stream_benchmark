// This is a generated file - do not edit.
//
// Generated from sahi_marketdata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sahi_marketdata.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'sahi_marketdata.pbenum.dart';

enum ClientMessage_Payload { subscribe, unsubscribe, modeChange, notSet }

/// Client -> server. One message per binary frame.
class ClientMessage extends $pb.GeneratedMessage {
  factory ClientMessage({
    Subscribe? subscribe,
    Unsubscribe? unsubscribe,
    ModeChange? modeChange,
  }) {
    final result = ClientMessage._();
    if (subscribe != null) result.subscribe = subscribe;
    if (unsubscribe != null) result.unsubscribe = unsubscribe;
    if (modeChange != null) result.modeChange = modeChange;
    return result;
  }

  ClientMessage._();

  factory ClientMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientMessage()..mergeFromBuffer(data, registry);
  factory ClientMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientMessage()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ClientMessage_Payload>
      _ClientMessage_PayloadByTag = {
    1: ClientMessage_Payload.subscribe,
    2: ClientMessage_Payload.unsubscribe,
    3: ClientMessage_Payload.modeChange,
    0: ClientMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientMessage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: ClientMessage.$_createMessage)
    ..oo(0, [1, 2, 3])
    ..aOM<Subscribe>(1, _omitFieldNames ? '' : 'subscribe',
        subBuilder: Subscribe.$_createMessage)
    ..aOM<Unsubscribe>(2, _omitFieldNames ? '' : 'unsubscribe',
        subBuilder: Unsubscribe.$_createMessage)
    ..aOM<ModeChange>(3, _omitFieldNames ? '' : 'modeChange',
        subBuilder: ModeChange.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessage copyWith(void Function(ClientMessage) updates) =>
      super.copyWith((message) => updates(message as ClientMessage))
          as ClientMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClientMessage() / ClientMessage.new instead')
  static ClientMessage create() => ClientMessage._();
  static $pb.GeneratedMessage $_createMessage() => ClientMessage._();
  @$core.override
  ClientMessage createEmptyInstance() => ClientMessage._();
  @$core.pragma('dart2js:noInline')
  static ClientMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientMessage>(
          ClientMessage.$_createMessage);
  static ClientMessage? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ClientMessage_Payload whichPayload() =>
      _ClientMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Subscribe get subscribe => $_getN(0);
  @$pb.TagNumber(1)
  set subscribe(Subscribe value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscribe() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscribe() => $_clearField(1);
  @$pb.TagNumber(1)
  Subscribe ensureSubscribe() => $_ensure(0);

  @$pb.TagNumber(2)
  Unsubscribe get unsubscribe => $_getN(1);
  @$pb.TagNumber(2)
  set unsubscribe(Unsubscribe value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUnsubscribe() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnsubscribe() => $_clearField(2);
  @$pb.TagNumber(2)
  Unsubscribe ensureUnsubscribe() => $_ensure(1);

  @$pb.TagNumber(3)
  ModeChange get modeChange => $_getN(2);
  @$pb.TagNumber(3)
  set modeChange(ModeChange value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasModeChange() => $_has(2);
  @$pb.TagNumber(3)
  void clearModeChange() => $_clearField(3);
  @$pb.TagNumber(3)
  ModeChange ensureModeChange() => $_ensure(2);
}

class Subscribe extends $pb.GeneratedMessage {
  factory Subscribe({
    Mode? mode,
    $core.Iterable<$fixnum.Int64>? instrumentIds,
  }) {
    final result = Subscribe._();
    if (mode != null) result.mode = mode;
    if (instrumentIds != null) result.instrumentIds.addAll(instrumentIds);
    return result;
  }

  Subscribe._();

  factory Subscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Subscribe()..mergeFromBuffer(data, registry);
  factory Subscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Subscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Subscribe',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: Subscribe.$_createMessage)
    ..aE<Mode>(1, _omitFieldNames ? '' : 'mode', enumValues: Mode.values)
    ..p<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'instrumentIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscribe copyWith(void Function(Subscribe) updates) =>
      super.copyWith((message) => updates(message as Subscribe)) as Subscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Subscribe() / Subscribe.new instead')
  static Subscribe create() => Subscribe._();
  static $pb.GeneratedMessage $_createMessage() => Subscribe._();
  @$core.override
  Subscribe createEmptyInstance() => Subscribe._();
  @$core.pragma('dart2js:noInline')
  static Subscribe getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Subscribe>(Subscribe.$_createMessage);
  static Subscribe? _defaultInstance;

  @$pb.TagNumber(1)
  Mode get mode => $_getN(0);
  @$pb.TagNumber(1)
  set mode(Mode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get instrumentIds => $_getList(1);
}

class Unsubscribe extends $pb.GeneratedMessage {
  factory Unsubscribe({
    $core.Iterable<$fixnum.Int64>? instrumentIds,
  }) {
    final result = Unsubscribe._();
    if (instrumentIds != null) result.instrumentIds.addAll(instrumentIds);
    return result;
  }

  Unsubscribe._();

  factory Unsubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Unsubscribe()..mergeFromBuffer(data, registry);
  factory Unsubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Unsubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Unsubscribe',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: Unsubscribe.$_createMessage)
    ..p<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'instrumentIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Unsubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Unsubscribe copyWith(void Function(Unsubscribe) updates) =>
      super.copyWith((message) => updates(message as Unsubscribe))
          as Unsubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Unsubscribe() / Unsubscribe.new instead')
  static Unsubscribe create() => Unsubscribe._();
  static $pb.GeneratedMessage $_createMessage() => Unsubscribe._();
  @$core.override
  Unsubscribe createEmptyInstance() => Unsubscribe._();
  @$core.pragma('dart2js:noInline')
  static Unsubscribe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Unsubscribe>(
          Unsubscribe.$_createMessage);
  static Unsubscribe? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$fixnum.Int64> get instrumentIds => $_getList(0);
}

class ModeChange extends $pb.GeneratedMessage {
  factory ModeChange({
    Mode? mode,
    $core.Iterable<$fixnum.Int64>? instrumentIds,
  }) {
    final result = ModeChange._();
    if (mode != null) result.mode = mode;
    if (instrumentIds != null) result.instrumentIds.addAll(instrumentIds);
    return result;
  }

  ModeChange._();

  factory ModeChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModeChange()..mergeFromBuffer(data, registry);
  factory ModeChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModeChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModeChange',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: ModeChange.$_createMessage)
    ..aE<Mode>(1, _omitFieldNames ? '' : 'mode', enumValues: Mode.values)
    ..p<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'instrumentIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModeChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModeChange copyWith(void Function(ModeChange) updates) =>
      super.copyWith((message) => updates(message as ModeChange)) as ModeChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModeChange() / ModeChange.new instead')
  static ModeChange create() => ModeChange._();
  static $pb.GeneratedMessage $_createMessage() => ModeChange._();
  @$core.override
  ModeChange createEmptyInstance() => ModeChange._();
  @$core.pragma('dart2js:noInline')
  static ModeChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModeChange>(ModeChange.$_createMessage);
  static ModeChange? _defaultInstance;

  @$pb.TagNumber(1)
  Mode get mode => $_getN(0);
  @$pb.TagNumber(1)
  set mode(Mode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get instrumentIds => $_getList(1);
}

enum ServerMessage_Payload { ack, ltpTick, quoteTick, depthTick, error, notSet }

/// Server -> client. One message per binary frame; every tick is a complete
/// snapshot of its instrument at the subscribed mode.
class ServerMessage extends $pb.GeneratedMessage {
  factory ServerMessage({
    Ack? ack,
    LtpTick? ltpTick,
    QuoteTick? quoteTick,
    DepthTick? depthTick,
    StreamError? error,
  }) {
    final result = ServerMessage._();
    if (ack != null) result.ack = ack;
    if (ltpTick != null) result.ltpTick = ltpTick;
    if (quoteTick != null) result.quoteTick = quoteTick;
    if (depthTick != null) result.depthTick = depthTick;
    if (error != null) result.error = error;
    return result;
  }

  ServerMessage._();

  factory ServerMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerMessage()..mergeFromBuffer(data, registry);
  factory ServerMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerMessage()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ServerMessage_Payload>
      _ServerMessage_PayloadByTag = {
    1: ServerMessage_Payload.ack,
    2: ServerMessage_Payload.ltpTick,
    3: ServerMessage_Payload.quoteTick,
    4: ServerMessage_Payload.depthTick,
    5: ServerMessage_Payload.error,
    0: ServerMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerMessage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: ServerMessage.$_createMessage)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<Ack>(1, _omitFieldNames ? '' : 'ack', subBuilder: Ack.$_createMessage)
    ..aOM<LtpTick>(2, _omitFieldNames ? '' : 'ltpTick',
        subBuilder: LtpTick.$_createMessage)
    ..aOM<QuoteTick>(3, _omitFieldNames ? '' : 'quoteTick',
        subBuilder: QuoteTick.$_createMessage)
    ..aOM<DepthTick>(4, _omitFieldNames ? '' : 'depthTick',
        subBuilder: DepthTick.$_createMessage)
    ..aOM<StreamError>(5, _omitFieldNames ? '' : 'error',
        subBuilder: StreamError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerMessage copyWith(void Function(ServerMessage) updates) =>
      super.copyWith((message) => updates(message as ServerMessage))
          as ServerMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ServerMessage() / ServerMessage.new instead')
  static ServerMessage create() => ServerMessage._();
  static $pb.GeneratedMessage $_createMessage() => ServerMessage._();
  @$core.override
  ServerMessage createEmptyInstance() => ServerMessage._();
  @$core.pragma('dart2js:noInline')
  static ServerMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerMessage>(
          ServerMessage.$_createMessage);
  static ServerMessage? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  ServerMessage_Payload whichPayload() =>
      _ServerMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Ack get ack => $_getN(0);
  @$pb.TagNumber(1)
  set ack(Ack value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAck() => $_has(0);
  @$pb.TagNumber(1)
  void clearAck() => $_clearField(1);
  @$pb.TagNumber(1)
  Ack ensureAck() => $_ensure(0);

  @$pb.TagNumber(2)
  LtpTick get ltpTick => $_getN(1);
  @$pb.TagNumber(2)
  set ltpTick(LtpTick value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLtpTick() => $_has(1);
  @$pb.TagNumber(2)
  void clearLtpTick() => $_clearField(2);
  @$pb.TagNumber(2)
  LtpTick ensureLtpTick() => $_ensure(1);

  @$pb.TagNumber(3)
  QuoteTick get quoteTick => $_getN(2);
  @$pb.TagNumber(3)
  set quoteTick(QuoteTick value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasQuoteTick() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuoteTick() => $_clearField(3);
  @$pb.TagNumber(3)
  QuoteTick ensureQuoteTick() => $_ensure(2);

  @$pb.TagNumber(4)
  DepthTick get depthTick => $_getN(3);
  @$pb.TagNumber(4)
  set depthTick(DepthTick value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDepthTick() => $_has(3);
  @$pb.TagNumber(4)
  void clearDepthTick() => $_clearField(4);
  @$pb.TagNumber(4)
  DepthTick ensureDepthTick() => $_ensure(3);

  @$pb.TagNumber(5)
  StreamError get error => $_getN(4);
  @$pb.TagNumber(5)
  set error(StreamError value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
  @$pb.TagNumber(5)
  StreamError ensureError() => $_ensure(4);
}

class Ack extends $pb.GeneratedMessage {
  factory Ack({
    Action? action,
    $core.Iterable<$fixnum.Int64>? instrumentIds,
  }) {
    final result = Ack._();
    if (action != null) result.action = action;
    if (instrumentIds != null) result.instrumentIds.addAll(instrumentIds);
    return result;
  }

  Ack._();

  factory Ack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ack()..mergeFromBuffer(data, registry);
  factory Ack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ack()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ack',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: Ack.$_createMessage)
    ..aE<Action>(1, _omitFieldNames ? '' : 'action', enumValues: Action.values)
    ..p<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'instrumentIds', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ack copyWith(void Function(Ack) updates) =>
      super.copyWith((message) => updates(message as Ack)) as Ack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ack() / Ack.new instead')
  static Ack create() => Ack._();
  static $pb.GeneratedMessage $_createMessage() => Ack._();
  @$core.override
  Ack createEmptyInstance() => Ack._();
  @$core.pragma('dart2js:noInline')
  static Ack getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ack>(Ack.$_createMessage);
  static Ack? _defaultInstance;

  @$pb.TagNumber(1)
  Action get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(Action value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get instrumentIds => $_getList(1);
}

class StreamError extends $pb.GeneratedMessage {
  factory StreamError({
    $core.String? code,
    $core.String? message,
  }) {
    final result = StreamError._();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  StreamError._();

  factory StreamError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamError()..mergeFromBuffer(data, registry);
  factory StreamError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamError()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamError',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: StreamError.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamError copyWith(void Function(StreamError) updates) =>
      super.copyWith((message) => updates(message as StreamError))
          as StreamError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamError() / StreamError.new instead')
  static StreamError create() => StreamError._();
  static $pb.GeneratedMessage $_createMessage() => StreamError._();
  @$core.override
  StreamError createEmptyInstance() => StreamError._();
  @$core.pragma('dart2js:noInline')
  static StreamError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamError>(
          StreamError.$_createMessage);
  static StreamError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// Prices in paise; times in epoch milliseconds.
class LtpTick extends $pb.GeneratedMessage {
  factory LtpTick({
    $fixnum.Int64? instrumentId,
    ExchangeSegment? exchangeSegment,
    InstrumentType? instrumentType,
    $fixnum.Int64? lastTradePrice,
    $fixnum.Int64? lastTradeTime,
  }) {
    final result = LtpTick._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (exchangeSegment != null) result.exchangeSegment = exchangeSegment;
    if (instrumentType != null) result.instrumentType = instrumentType;
    if (lastTradePrice != null) result.lastTradePrice = lastTradePrice;
    if (lastTradeTime != null) result.lastTradeTime = lastTradeTime;
    return result;
  }

  LtpTick._();

  factory LtpTick.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LtpTick()..mergeFromBuffer(data, registry);
  factory LtpTick.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LtpTick()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LtpTick',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: LtpTick.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'instrumentId')
    ..aE<ExchangeSegment>(2, _omitFieldNames ? '' : 'exchangeSegment',
        enumValues: ExchangeSegment.values)
    ..aE<InstrumentType>(3, _omitFieldNames ? '' : 'instrumentType',
        enumValues: InstrumentType.values)
    ..aInt64(4, _omitFieldNames ? '' : 'lastTradePrice')
    ..aInt64(5, _omitFieldNames ? '' : 'lastTradeTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LtpTick clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LtpTick copyWith(void Function(LtpTick) updates) =>
      super.copyWith((message) => updates(message as LtpTick)) as LtpTick;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LtpTick() / LtpTick.new instead')
  static LtpTick create() => LtpTick._();
  static $pb.GeneratedMessage $_createMessage() => LtpTick._();
  @$core.override
  LtpTick createEmptyInstance() => LtpTick._();
  @$core.pragma('dart2js:noInline')
  static LtpTick getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LtpTick>(LtpTick.$_createMessage);
  static LtpTick? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get instrumentId => $_getI64(0);
  @$pb.TagNumber(1)
  set instrumentId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  ExchangeSegment get exchangeSegment => $_getN(1);
  @$pb.TagNumber(2)
  set exchangeSegment(ExchangeSegment value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExchangeSegment() => $_has(1);
  @$pb.TagNumber(2)
  void clearExchangeSegment() => $_clearField(2);

  @$pb.TagNumber(3)
  InstrumentType get instrumentType => $_getN(2);
  @$pb.TagNumber(3)
  set instrumentType(InstrumentType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInstrumentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstrumentType() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastTradePrice => $_getI64(3);
  @$pb.TagNumber(4)
  set lastTradePrice($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastTradePrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastTradePrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastTradeTime => $_getI64(4);
  @$pb.TagNumber(5)
  set lastTradeTime($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastTradeTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastTradeTime() => $_clearField(5);
}

class QuoteTick extends $pb.GeneratedMessage {
  factory QuoteTick({
    $fixnum.Int64? instrumentId,
    ExchangeSegment? exchangeSegment,
    InstrumentType? instrumentType,
    $fixnum.Int64? lastTradePrice,
    $fixnum.Int64? lastTradeTime,
    $fixnum.Int64? volumeToday,
    $fixnum.Int64? dprUpper,
    $fixnum.Int64? dprLower,
    $fixnum.Int64? prevOpenInterest,
    $fixnum.Int64? openInterest,
  }) {
    final result = QuoteTick._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (exchangeSegment != null) result.exchangeSegment = exchangeSegment;
    if (instrumentType != null) result.instrumentType = instrumentType;
    if (lastTradePrice != null) result.lastTradePrice = lastTradePrice;
    if (lastTradeTime != null) result.lastTradeTime = lastTradeTime;
    if (volumeToday != null) result.volumeToday = volumeToday;
    if (dprUpper != null) result.dprUpper = dprUpper;
    if (dprLower != null) result.dprLower = dprLower;
    if (prevOpenInterest != null) result.prevOpenInterest = prevOpenInterest;
    if (openInterest != null) result.openInterest = openInterest;
    return result;
  }

  QuoteTick._();

  factory QuoteTick.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuoteTick()..mergeFromBuffer(data, registry);
  factory QuoteTick.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuoteTick()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuoteTick',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: QuoteTick.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'instrumentId')
    ..aE<ExchangeSegment>(2, _omitFieldNames ? '' : 'exchangeSegment',
        enumValues: ExchangeSegment.values)
    ..aE<InstrumentType>(3, _omitFieldNames ? '' : 'instrumentType',
        enumValues: InstrumentType.values)
    ..aInt64(4, _omitFieldNames ? '' : 'lastTradePrice')
    ..aInt64(5, _omitFieldNames ? '' : 'lastTradeTime')
    ..aInt64(6, _omitFieldNames ? '' : 'volumeToday')
    ..aInt64(7, _omitFieldNames ? '' : 'dprUpper')
    ..aInt64(8, _omitFieldNames ? '' : 'dprLower')
    ..aInt64(9, _omitFieldNames ? '' : 'prevOpenInterest')
    ..aInt64(10, _omitFieldNames ? '' : 'openInterest')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuoteTick clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuoteTick copyWith(void Function(QuoteTick) updates) =>
      super.copyWith((message) => updates(message as QuoteTick)) as QuoteTick;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QuoteTick() / QuoteTick.new instead')
  static QuoteTick create() => QuoteTick._();
  static $pb.GeneratedMessage $_createMessage() => QuoteTick._();
  @$core.override
  QuoteTick createEmptyInstance() => QuoteTick._();
  @$core.pragma('dart2js:noInline')
  static QuoteTick getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuoteTick>(QuoteTick.$_createMessage);
  static QuoteTick? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get instrumentId => $_getI64(0);
  @$pb.TagNumber(1)
  set instrumentId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  ExchangeSegment get exchangeSegment => $_getN(1);
  @$pb.TagNumber(2)
  set exchangeSegment(ExchangeSegment value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExchangeSegment() => $_has(1);
  @$pb.TagNumber(2)
  void clearExchangeSegment() => $_clearField(2);

  @$pb.TagNumber(3)
  InstrumentType get instrumentType => $_getN(2);
  @$pb.TagNumber(3)
  set instrumentType(InstrumentType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInstrumentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstrumentType() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastTradePrice => $_getI64(3);
  @$pb.TagNumber(4)
  set lastTradePrice($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastTradePrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastTradePrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastTradeTime => $_getI64(4);
  @$pb.TagNumber(5)
  set lastTradeTime($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastTradeTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastTradeTime() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get volumeToday => $_getI64(5);
  @$pb.TagNumber(6)
  set volumeToday($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVolumeToday() => $_has(5);
  @$pb.TagNumber(6)
  void clearVolumeToday() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get dprUpper => $_getI64(6);
  @$pb.TagNumber(7)
  set dprUpper($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDprUpper() => $_has(6);
  @$pb.TagNumber(7)
  void clearDprUpper() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get dprLower => $_getI64(7);
  @$pb.TagNumber(8)
  set dprLower($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDprLower() => $_has(7);
  @$pb.TagNumber(8)
  void clearDprLower() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get prevOpenInterest => $_getI64(8);
  @$pb.TagNumber(9)
  set prevOpenInterest($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPrevOpenInterest() => $_has(8);
  @$pb.TagNumber(9)
  void clearPrevOpenInterest() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get openInterest => $_getI64(9);
  @$pb.TagNumber(10)
  set openInterest($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOpenInterest() => $_has(9);
  @$pb.TagNumber(10)
  void clearOpenInterest() => $_clearField(10);
}

class DepthLevel extends $pb.GeneratedMessage {
  factory DepthLevel({
    $fixnum.Int64? price,
    $fixnum.Int64? qty,
    $fixnum.Int64? numOrders,
  }) {
    final result = DepthLevel._();
    if (price != null) result.price = price;
    if (qty != null) result.qty = qty;
    if (numOrders != null) result.numOrders = numOrders;
    return result;
  }

  DepthLevel._();

  factory DepthLevel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DepthLevel()..mergeFromBuffer(data, registry);
  factory DepthLevel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DepthLevel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DepthLevel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: DepthLevel.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'price')
    ..aInt64(2, _omitFieldNames ? '' : 'qty')
    ..aInt64(3, _omitFieldNames ? '' : 'numOrders')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DepthLevel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DepthLevel copyWith(void Function(DepthLevel) updates) =>
      super.copyWith((message) => updates(message as DepthLevel)) as DepthLevel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DepthLevel() / DepthLevel.new instead')
  static DepthLevel create() => DepthLevel._();
  static $pb.GeneratedMessage $_createMessage() => DepthLevel._();
  @$core.override
  DepthLevel createEmptyInstance() => DepthLevel._();
  @$core.pragma('dart2js:noInline')
  static DepthLevel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DepthLevel>(DepthLevel.$_createMessage);
  static DepthLevel? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get price => $_getI64(0);
  @$pb.TagNumber(1)
  set price($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrice() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrice() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get qty => $_getI64(1);
  @$pb.TagNumber(2)
  set qty($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQty() => $_has(1);
  @$pb.TagNumber(2)
  void clearQty() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get numOrders => $_getI64(2);
  @$pb.TagNumber(3)
  set numOrders($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNumOrders() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumOrders() => $_clearField(3);
}

class DepthTick extends $pb.GeneratedMessage {
  factory DepthTick({
    $fixnum.Int64? instrumentId,
    ExchangeSegment? exchangeSegment,
    InstrumentType? instrumentType,
    $fixnum.Int64? lastTradePrice,
    $fixnum.Int64? lastTradeTime,
    $fixnum.Int64? volumeToday,
    $fixnum.Int64? dprUpper,
    $fixnum.Int64? dprLower,
    $fixnum.Int64? prevOpenInterest,
    $fixnum.Int64? openInterest,
    $core.Iterable<DepthLevel>? bestBuys,
    $core.Iterable<DepthLevel>? bestSells,
    $fixnum.Int64? totalBuyQty,
    $fixnum.Int64? totalSellQty,
  }) {
    final result = DepthTick._();
    if (instrumentId != null) result.instrumentId = instrumentId;
    if (exchangeSegment != null) result.exchangeSegment = exchangeSegment;
    if (instrumentType != null) result.instrumentType = instrumentType;
    if (lastTradePrice != null) result.lastTradePrice = lastTradePrice;
    if (lastTradeTime != null) result.lastTradeTime = lastTradeTime;
    if (volumeToday != null) result.volumeToday = volumeToday;
    if (dprUpper != null) result.dprUpper = dprUpper;
    if (dprLower != null) result.dprLower = dprLower;
    if (prevOpenInterest != null) result.prevOpenInterest = prevOpenInterest;
    if (openInterest != null) result.openInterest = openInterest;
    if (bestBuys != null) result.bestBuys.addAll(bestBuys);
    if (bestSells != null) result.bestSells.addAll(bestSells);
    if (totalBuyQty != null) result.totalBuyQty = totalBuyQty;
    if (totalSellQty != null) result.totalSellQty = totalSellQty;
    return result;
  }

  DepthTick._();

  factory DepthTick.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DepthTick()..mergeFromBuffer(data, registry);
  factory DepthTick.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DepthTick()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DepthTick',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'sahi_like.marketdata.v1'),
      createEmptyInstance: DepthTick.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'instrumentId')
    ..aE<ExchangeSegment>(2, _omitFieldNames ? '' : 'exchangeSegment',
        enumValues: ExchangeSegment.values)
    ..aE<InstrumentType>(3, _omitFieldNames ? '' : 'instrumentType',
        enumValues: InstrumentType.values)
    ..aInt64(4, _omitFieldNames ? '' : 'lastTradePrice')
    ..aInt64(5, _omitFieldNames ? '' : 'lastTradeTime')
    ..aInt64(6, _omitFieldNames ? '' : 'volumeToday')
    ..aInt64(7, _omitFieldNames ? '' : 'dprUpper')
    ..aInt64(8, _omitFieldNames ? '' : 'dprLower')
    ..aInt64(9, _omitFieldNames ? '' : 'prevOpenInterest')
    ..aInt64(10, _omitFieldNames ? '' : 'openInterest')
    ..pPM<DepthLevel>(11, _omitFieldNames ? '' : 'bestBuys',
        subBuilder: DepthLevel.$_createMessage)
    ..pPM<DepthLevel>(12, _omitFieldNames ? '' : 'bestSells',
        subBuilder: DepthLevel.$_createMessage)
    ..aInt64(13, _omitFieldNames ? '' : 'totalBuyQty')
    ..aInt64(14, _omitFieldNames ? '' : 'totalSellQty')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DepthTick clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DepthTick copyWith(void Function(DepthTick) updates) =>
      super.copyWith((message) => updates(message as DepthTick)) as DepthTick;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DepthTick() / DepthTick.new instead')
  static DepthTick create() => DepthTick._();
  static $pb.GeneratedMessage $_createMessage() => DepthTick._();
  @$core.override
  DepthTick createEmptyInstance() => DepthTick._();
  @$core.pragma('dart2js:noInline')
  static DepthTick getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DepthTick>(DepthTick.$_createMessage);
  static DepthTick? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get instrumentId => $_getI64(0);
  @$pb.TagNumber(1)
  set instrumentId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstrumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstrumentId() => $_clearField(1);

  @$pb.TagNumber(2)
  ExchangeSegment get exchangeSegment => $_getN(1);
  @$pb.TagNumber(2)
  set exchangeSegment(ExchangeSegment value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExchangeSegment() => $_has(1);
  @$pb.TagNumber(2)
  void clearExchangeSegment() => $_clearField(2);

  @$pb.TagNumber(3)
  InstrumentType get instrumentType => $_getN(2);
  @$pb.TagNumber(3)
  set instrumentType(InstrumentType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInstrumentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstrumentType() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastTradePrice => $_getI64(3);
  @$pb.TagNumber(4)
  set lastTradePrice($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastTradePrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastTradePrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastTradeTime => $_getI64(4);
  @$pb.TagNumber(5)
  set lastTradeTime($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastTradeTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastTradeTime() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get volumeToday => $_getI64(5);
  @$pb.TagNumber(6)
  set volumeToday($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVolumeToday() => $_has(5);
  @$pb.TagNumber(6)
  void clearVolumeToday() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get dprUpper => $_getI64(6);
  @$pb.TagNumber(7)
  set dprUpper($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDprUpper() => $_has(6);
  @$pb.TagNumber(7)
  void clearDprUpper() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get dprLower => $_getI64(7);
  @$pb.TagNumber(8)
  set dprLower($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDprLower() => $_has(7);
  @$pb.TagNumber(8)
  void clearDprLower() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get prevOpenInterest => $_getI64(8);
  @$pb.TagNumber(9)
  set prevOpenInterest($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPrevOpenInterest() => $_has(8);
  @$pb.TagNumber(9)
  void clearPrevOpenInterest() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get openInterest => $_getI64(9);
  @$pb.TagNumber(10)
  set openInterest($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOpenInterest() => $_has(9);
  @$pb.TagNumber(10)
  void clearOpenInterest() => $_clearField(10);

  /// Only levels holding orders: up to 5 (L2) or 20 (L3), never zero-padded.
  @$pb.TagNumber(11)
  $pb.PbList<DepthLevel> get bestBuys => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<DepthLevel> get bestSells => $_getList(11);

  @$pb.TagNumber(13)
  $fixnum.Int64 get totalBuyQty => $_getI64(12);
  @$pb.TagNumber(13)
  set totalBuyQty($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTotalBuyQty() => $_has(12);
  @$pb.TagNumber(13)
  void clearTotalBuyQty() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get totalSellQty => $_getI64(13);
  @$pb.TagNumber(14)
  set totalSellQty($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasTotalSellQty() => $_has(13);
  @$pb.TagNumber(14)
  void clearTotalSellQty() => $_clearField(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
