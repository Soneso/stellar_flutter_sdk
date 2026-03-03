// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrBeginSponsoringFutureReservesResultCode {
  final _value;
  const XdrBeginSponsoringFutureReservesResultCode._internal(this._value);
  toString() => 'BeginSponsoringFutureReservesResultCode.$_value';
  XdrBeginSponsoringFutureReservesResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrBeginSponsoringFutureReservesResultCode &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS =
      const XdrBeginSponsoringFutureReservesResultCode._internal(0);
  static const BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED =
      const XdrBeginSponsoringFutureReservesResultCode._internal(-1);
  static const BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED =
      const XdrBeginSponsoringFutureReservesResultCode._internal(-2);
  static const BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE =
      const XdrBeginSponsoringFutureReservesResultCode._internal(-3);

  static XdrBeginSponsoringFutureReservesResultCode decode(
    XdrDataInputStream stream,
  ) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS;
      case -1:
        return BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED;
      case -2:
        return BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED;
      case -3:
        return BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrBeginSponsoringFutureReservesResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
