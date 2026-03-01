// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrChangeTrustResultCode {
  final _value;

  const XdrChangeTrustResultCode._internal(this._value);

  toString() => 'ChangeTrustResultCode.$_value';

  XdrChangeTrustResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrChangeTrustResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const CHANGE_TRUST_SUCCESS = const XdrChangeTrustResultCode._internal(
    0,
  );

  /// Bad input.
  static const CHANGE_TRUST_MALFORMED =
      const XdrChangeTrustResultCode._internal(-1);

  /// Could not find issuer.
  static const CHANGE_TRUST_NO_ISSUER =
      const XdrChangeTrustResultCode._internal(-2);

  /// Cannot drop limit below balance. Cannot create with a limit of 0.
  static const CHANGE_TRUST_INVALID_LIMIT =
      const XdrChangeTrustResultCode._internal(-3);

  /// Not enough funds to create a new trust line
  static const CHANGE_TRUST_LOW_RESERVE =
      const XdrChangeTrustResultCode._internal(-4);

  /// Trusting self is not allowed.
  static const CHANGE_TRUST_SELF_NOT_ALLOWED =
      const XdrChangeTrustResultCode._internal(-5);

  /// Asset trustline is missing for pool.
  static const CHANGE_TRUST_TRUST_LINE_MISSING =
      const XdrChangeTrustResultCode._internal(-6);

  /// Asset trustline is still referenced in a pool.
  static const CHANGE_TRUST_CANNOT_DELETE =
      const XdrChangeTrustResultCode._internal(-7);

  /// Asset trustline is deauthorized.
  static const CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES =
      const XdrChangeTrustResultCode._internal(-8);

  static XdrChangeTrustResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CHANGE_TRUST_SUCCESS;
      case -1:
        return CHANGE_TRUST_MALFORMED;
      case -2:
        return CHANGE_TRUST_NO_ISSUER;
      case -3:
        return CHANGE_TRUST_INVALID_LIMIT;
      case -4:
        return CHANGE_TRUST_LOW_RESERVE;
      case -5:
        return CHANGE_TRUST_SELF_NOT_ALLOWED;
      case -6:
        return CHANGE_TRUST_TRUST_LINE_MISSING;
      case -7:
        return CHANGE_TRUST_CANNOT_DELETE;
      case -8:
        return CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrChangeTrustResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
