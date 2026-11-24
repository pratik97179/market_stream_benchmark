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

import 'package:protobuf/protobuf.dart' as $pb;

class TradeSide extends $pb.ProtobufEnum {
  static const TradeSide TRADE_SIDE_UNSPECIFIED =
      TradeSide._(0, _omitEnumNames ? '' : 'TRADE_SIDE_UNSPECIFIED');
  static const TradeSide BUY = TradeSide._(1, _omitEnumNames ? '' : 'BUY');
  static const TradeSide SELL = TradeSide._(2, _omitEnumNames ? '' : 'SELL');

  static const $core.List<TradeSide> values = <TradeSide>[
    TRADE_SIDE_UNSPECIFIED,
    BUY,
    SELL,
  ];

  static final $core.List<TradeSide?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static TradeSide? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TradeSide._(super.value, super.name);
}

class BookSide extends $pb.ProtobufEnum {
  static const BookSide BOOK_SIDE_UNSPECIFIED =
      BookSide._(0, _omitEnumNames ? '' : 'BOOK_SIDE_UNSPECIFIED');
  static const BookSide BID = BookSide._(1, _omitEnumNames ? '' : 'BID');
  static const BookSide ASK = BookSide._(2, _omitEnumNames ? '' : 'ASK');

  static const $core.List<BookSide> values = <BookSide>[
    BOOK_SIDE_UNSPECIFIED,
    BID,
    ASK,
  ];

  static final $core.List<BookSide?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static BookSide? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BookSide._(super.value, super.name);
}

class InstrumentStatus extends $pb.ProtobufEnum {
  static const InstrumentStatus INSTRUMENT_STATUS_UNSPECIFIED =
      InstrumentStatus._(
          0, _omitEnumNames ? '' : 'INSTRUMENT_STATUS_UNSPECIFIED');
  static const InstrumentStatus ACTIVE =
      InstrumentStatus._(1, _omitEnumNames ? '' : 'ACTIVE');
  static const InstrumentStatus HALTED =
      InstrumentStatus._(2, _omitEnumNames ? '' : 'HALTED');
  static const InstrumentStatus CLOSED =
      InstrumentStatus._(3, _omitEnumNames ? '' : 'CLOSED');

  static const $core.List<InstrumentStatus> values = <InstrumentStatus>[
    INSTRUMENT_STATUS_UNSPECIFIED,
    ACTIVE,
    HALTED,
    CLOSED,
  ];

  static final $core.List<InstrumentStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static InstrumentStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InstrumentStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
