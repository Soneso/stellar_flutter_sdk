// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrMessageType {
  final _value;
  const XdrMessageType._internal(this._value);
  toString() => 'MessageType.$_value';
  XdrMessageType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrMessageType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const ERROR_MSG = const XdrMessageType._internal(0);
  static const AUTH = const XdrMessageType._internal(2);
  static const DONT_HAVE = const XdrMessageType._internal(3);
  static const PEERS = const XdrMessageType._internal(5);
  static const GET_TX_SET = const XdrMessageType._internal(6);
  static const TX_SET = const XdrMessageType._internal(7);
  static const GENERALIZED_TX_SET = const XdrMessageType._internal(17);
  static const TRANSACTION = const XdrMessageType._internal(8);
  static const GET_SCP_QUORUMSET = const XdrMessageType._internal(9);
  static const SCP_QUORUMSET = const XdrMessageType._internal(10);
  static const SCP_MESSAGE = const XdrMessageType._internal(11);
  static const GET_SCP_STATE = const XdrMessageType._internal(12);
  static const HELLO = const XdrMessageType._internal(13);
  static const SEND_MORE = const XdrMessageType._internal(16);
  static const SEND_MORE_EXTENDED = const XdrMessageType._internal(20);
  static const FLOOD_ADVERT = const XdrMessageType._internal(18);
  static const FLOOD_DEMAND = const XdrMessageType._internal(19);
  static const TIME_SLICED_SURVEY_REQUEST = const XdrMessageType._internal(21);
  static const TIME_SLICED_SURVEY_RESPONSE = const XdrMessageType._internal(22);
  static const TIME_SLICED_SURVEY_START_COLLECTING = const XdrMessageType._internal(23);
  static const TIME_SLICED_SURVEY_STOP_COLLECTING = const XdrMessageType._internal(24);

  static XdrMessageType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ERROR_MSG;
      case 2:
        return AUTH;
      case 3:
        return DONT_HAVE;
      case 5:
        return PEERS;
      case 6:
        return GET_TX_SET;
      case 7:
        return TX_SET;
      case 17:
        return GENERALIZED_TX_SET;
      case 8:
        return TRANSACTION;
      case 9:
        return GET_SCP_QUORUMSET;
      case 10:
        return SCP_QUORUMSET;
      case 11:
        return SCP_MESSAGE;
      case 12:
        return GET_SCP_STATE;
      case 13:
        return HELLO;
      case 16:
        return SEND_MORE;
      case 20:
        return SEND_MORE_EXTENDED;
      case 18:
        return FLOOD_ADVERT;
      case 19:
        return FLOOD_DEMAND;
      case 21:
        return TIME_SLICED_SURVEY_REQUEST;
      case 22:
        return TIME_SLICED_SURVEY_RESPONSE;
      case 23:
        return TIME_SLICED_SURVEY_START_COLLECTING;
      case 24:
        return TIME_SLICED_SURVEY_STOP_COLLECTING;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrMessageType value) {
    stream.writeInt(value.value);
  }
}
