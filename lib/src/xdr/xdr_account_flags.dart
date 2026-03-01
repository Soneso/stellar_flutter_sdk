// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrAccountFlags {
  final _value;

  const XdrAccountFlags._internal(this._value);

  toString() => 'AccountFlags.$_value';

  XdrAccountFlags(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrAccountFlags && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Flags set on issuer accounts
  /// TrustLines are created with authorized set to "false" requiring
  /// the issuer to set it for each TrustLine.
  static const AUTH_REQUIRED_FLAG = const XdrAccountFlags._internal(1);

  /// If set, the authorized flag in TrustLines can be cleared
  /// otherwise, authorization cannot be revoked.
  static const AUTH_REVOCABLE_FLAG = const XdrAccountFlags._internal(2);

  /// Once set, causes all AUTH_* flags to be read-only.
  static const AUTH_IMMUTABLE_FLAG = const XdrAccountFlags._internal(4);

  /// Clawback enabled (0x8): trust lines are created with clawback enabled set to "true", and claimable balances created from those trustlines are created with clawback enabled set to "true"
  static const AUTH_CLAWBACK_ENABLED_FLAG = const XdrAccountFlags._internal(8);

  static XdrAccountFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return AUTH_REQUIRED_FLAG;
      case 2:
        return AUTH_REVOCABLE_FLAG;
      case 4:
        return AUTH_IMMUTABLE_FLAG;
      case 8:
        return AUTH_CLAWBACK_ENABLED_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAccountFlags value) {
    stream.writeInt(value.value);
  }
}
