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

import 'package:protobuf/protobuf.dart' as $pb;

class ExchangeSegment extends $pb.ProtobufEnum {
  static const ExchangeSegment EXCHANGE_SEGMENT_INVALID =
      ExchangeSegment._(0, _omitEnumNames ? '' : 'EXCHANGE_SEGMENT_INVALID');
  static const ExchangeSegment EXCHANGE_SEGMENT_NSE =
      ExchangeSegment._(1, _omitEnumNames ? '' : 'EXCHANGE_SEGMENT_NSE');
  static const ExchangeSegment EXCHANGE_SEGMENT_BSE =
      ExchangeSegment._(2, _omitEnumNames ? '' : 'EXCHANGE_SEGMENT_BSE');
  static const ExchangeSegment EXCHANGE_SEGMENT_NFO =
      ExchangeSegment._(3, _omitEnumNames ? '' : 'EXCHANGE_SEGMENT_NFO');
  static const ExchangeSegment EXCHANGE_SEGMENT_BFO =
      ExchangeSegment._(4, _omitEnumNames ? '' : 'EXCHANGE_SEGMENT_BFO');

  static const $core.List<ExchangeSegment> values = <ExchangeSegment>[
    EXCHANGE_SEGMENT_INVALID,
    EXCHANGE_SEGMENT_NSE,
    EXCHANGE_SEGMENT_BSE,
    EXCHANGE_SEGMENT_NFO,
    EXCHANGE_SEGMENT_BFO,
  ];

  static final $core.List<ExchangeSegment?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ExchangeSegment? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExchangeSegment._(super.value, super.name);
}

class InstrumentType extends $pb.ProtobufEnum {
  static const InstrumentType INSTRUMENT_TYPE_INVALID =
      InstrumentType._(0, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_INVALID');
  static const InstrumentType INSTRUMENT_TYPE_INDEX =
      InstrumentType._(1, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_INDEX');
  static const InstrumentType INSTRUMENT_TYPE_STOCK =
      InstrumentType._(2, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_STOCK');
  static const InstrumentType INSTRUMENT_TYPE_ETF =
      InstrumentType._(3, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_ETF');
  static const InstrumentType INSTRUMENT_TYPE_INDEX_FUT =
      InstrumentType._(4, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_INDEX_FUT');
  static const InstrumentType INSTRUMENT_TYPE_INDEX_OPT_CE =
      InstrumentType._(5, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_INDEX_OPT_CE');
  static const InstrumentType INSTRUMENT_TYPE_INDEX_OPT_PE =
      InstrumentType._(6, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_INDEX_OPT_PE');
  static const InstrumentType INSTRUMENT_TYPE_STOCK_FUT =
      InstrumentType._(7, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_STOCK_FUT');
  static const InstrumentType INSTRUMENT_TYPE_STOCK_OPT_CE =
      InstrumentType._(8, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_STOCK_OPT_CE');
  static const InstrumentType INSTRUMENT_TYPE_STOCK_OPT_PE =
      InstrumentType._(9, _omitEnumNames ? '' : 'INSTRUMENT_TYPE_STOCK_OPT_PE');

  static const $core.List<InstrumentType> values = <InstrumentType>[
    INSTRUMENT_TYPE_INVALID,
    INSTRUMENT_TYPE_INDEX,
    INSTRUMENT_TYPE_STOCK,
    INSTRUMENT_TYPE_ETF,
    INSTRUMENT_TYPE_INDEX_FUT,
    INSTRUMENT_TYPE_INDEX_OPT_CE,
    INSTRUMENT_TYPE_INDEX_OPT_PE,
    INSTRUMENT_TYPE_STOCK_FUT,
    INSTRUMENT_TYPE_STOCK_OPT_CE,
    INSTRUMENT_TYPE_STOCK_OPT_PE,
  ];

  static final $core.List<InstrumentType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static InstrumentType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InstrumentType._(super.value, super.name);
}

class Mode extends $pb.ProtobufEnum {
  static const Mode MODE_INVALID =
      Mode._(0, _omitEnumNames ? '' : 'MODE_INVALID');
  static const Mode MODE_LTP = Mode._(1, _omitEnumNames ? '' : 'MODE_LTP');
  static const Mode MODE_QUOTE = Mode._(2, _omitEnumNames ? '' : 'MODE_QUOTE');
  static const Mode MODE_DEPTH = Mode._(3, _omitEnumNames ? '' : 'MODE_DEPTH');

  static const $core.List<Mode> values = <Mode>[
    MODE_INVALID,
    MODE_LTP,
    MODE_QUOTE,
    MODE_DEPTH,
  ];

  static final $core.List<Mode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Mode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Mode._(super.value, super.name);
}

class Action extends $pb.ProtobufEnum {
  static const Action ACTION_INVALID =
      Action._(0, _omitEnumNames ? '' : 'ACTION_INVALID');
  static const Action ACTION_SUBSCRIBE =
      Action._(1, _omitEnumNames ? '' : 'ACTION_SUBSCRIBE');
  static const Action ACTION_UNSUBSCRIBE =
      Action._(2, _omitEnumNames ? '' : 'ACTION_UNSUBSCRIBE');
  static const Action ACTION_MODE_CHANGE =
      Action._(3, _omitEnumNames ? '' : 'ACTION_MODE_CHANGE');

  static const $core.List<Action> values = <Action>[
    ACTION_INVALID,
    ACTION_SUBSCRIBE,
    ACTION_UNSUBSCRIBE,
    ACTION_MODE_CHANGE,
  ];

  static final $core.List<Action?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Action? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Action._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
