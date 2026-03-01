// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_flags.dart';
import 'xdr_data_io.dart';

class XdrTrustLineFlags {
  final _value;

  const XdrTrustLineFlags._internal(this._value);

  toString() => 'TrustLineFlags.$_value';

  XdrTrustLineFlags(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrTrustLineFlags && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// The issuer has authorized account to perform transactions with its credit.
  static const AUTHORIZED_FLAG = const XdrTrustLineFlags._internal(1);

  /// The issuer has authorized account to maintain and reduce liabilities for its credit.
  static const AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG =
      const XdrTrustLineFlags._internal(2);

  static const TRUSTLINE_CLAWBACK_ENABLED_FLAG =
      const XdrTrustLineFlags._internal(4);

  static XdrTrustLineFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return AUTHORIZED_FLAG;
      case 2:
        return AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG;
      case 4:
        return TRUSTLINE_CLAWBACK_ENABLED_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAccountFlags value) {
    stream.writeInt(value.value);
  }
}
