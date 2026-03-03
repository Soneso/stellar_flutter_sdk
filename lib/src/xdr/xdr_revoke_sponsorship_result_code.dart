// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrRevokeSponsorshipResultCode {
  final _value;
  const XdrRevokeSponsorshipResultCode._internal(this._value);
  toString() => 'RevokeSponsorshipResultCode.$_value';
  XdrRevokeSponsorshipResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrRevokeSponsorshipResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const REVOKE_SPONSORSHIP_SUCCESS =
      const XdrRevokeSponsorshipResultCode._internal(0);
  static const REVOKE_SPONSORSHIP_DOES_NOT_EXIST =
      const XdrRevokeSponsorshipResultCode._internal(-1);
  static const REVOKE_SPONSORSHIP_NOT_SPONSOR =
      const XdrRevokeSponsorshipResultCode._internal(-2);
  static const REVOKE_SPONSORSHIP_LOW_RESERVE =
      const XdrRevokeSponsorshipResultCode._internal(-3);
  static const REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE =
      const XdrRevokeSponsorshipResultCode._internal(-4);
  static const REVOKE_SPONSORSHIP_MALFORMED =
      const XdrRevokeSponsorshipResultCode._internal(-5);

  static XdrRevokeSponsorshipResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return REVOKE_SPONSORSHIP_SUCCESS;
      case -1:
        return REVOKE_SPONSORSHIP_DOES_NOT_EXIST;
      case -2:
        return REVOKE_SPONSORSHIP_NOT_SPONSOR;
      case -3:
        return REVOKE_SPONSORSHIP_LOW_RESERVE;
      case -4:
        return REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE;
      case -5:
        return REVOKE_SPONSORSHIP_MALFORMED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrRevokeSponsorshipResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
