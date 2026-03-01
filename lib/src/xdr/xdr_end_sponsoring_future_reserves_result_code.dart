// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrEndSponsoringFutureReservesResultCode {
  final _value;

  const XdrEndSponsoringFutureReservesResultCode._internal(this._value);

  toString() => 'EndSponsoringFutureReservesResultCode.$_value';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrEndSponsoringFutureReservesResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  XdrEndSponsoringFutureReservesResultCode(this._value);

  get value => this._value;

  /// Success.
  static const END_SPONSORING_FUTURE_RESERVES_SUCCESS =
      const XdrEndSponsoringFutureReservesResultCode._internal(0);

  static const END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED =
      const XdrEndSponsoringFutureReservesResultCode._internal(-1);

  static XdrEndSponsoringFutureReservesResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return END_SPONSORING_FUTURE_RESERVES_SUCCESS;
      case -1:
        return END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream,
      XdrEndSponsoringFutureReservesResultCode value) {
    stream.writeInt(value.value);
  }
}
