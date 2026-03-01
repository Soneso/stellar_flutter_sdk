// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrAllowTrustResultCode {
  final _value;

  const XdrAllowTrustResultCode._internal(this._value);

  toString() => 'AllowTrustResultCode.$_value';

  XdrAllowTrustResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrAllowTrustResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success code.
  static const ALLOW_TRUST_SUCCESS = const XdrAllowTrustResultCode._internal(0);

  // Codes considered as "failure" for the operation.

  /// Asset is not ASSET_TYPE_ALPHANUM.
  static const ALLOW_TRUST_MALFORMED =
      const XdrAllowTrustResultCode._internal(-1);

  /// Trustor does not have a trustline.
  static const ALLOW_TRUST_NO_TRUST_LINE =
      const XdrAllowTrustResultCode._internal(-2);

  /// Source account does not require trust.
  static const ALLOW_TRUST_TRUST_NOT_REQUIRED =
      const XdrAllowTrustResultCode._internal(-3);

  /// Source account can't revoke trust.
  static const ALLOW_TRUST_CANT_REVOKE =
      const XdrAllowTrustResultCode._internal(-4);

  /// Trusting self is not allowed.
  static const ALLOW_TRUST_SELF_NOT_ALLOWED =
      const XdrAllowTrustResultCode._internal(-5);

  /// Claimable balances can't be created on revoke due to low reserves.
  static const ALLOW_TRUST_LOW_RESERVE =
      const XdrAllowTrustResultCode._internal(-6);

  static XdrAllowTrustResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ALLOW_TRUST_SUCCESS;
      case -1:
        return ALLOW_TRUST_MALFORMED;
      case -2:
        return ALLOW_TRUST_NO_TRUST_LINE;
      case -3:
        return ALLOW_TRUST_TRUST_NOT_REQUIRED;
      case -4:
        return ALLOW_TRUST_CANT_REVOKE;
      case -5:
        return ALLOW_TRUST_SELF_NOT_ALLOWED;
      case -6:
        return ALLOW_TRUST_LOW_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrAllowTrustResultCode value) {
    stream.writeInt(value.value);
  }
}
