// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrPaymentResultCode {
  final _value;
  const XdrPaymentResultCode._internal(this._value);
  toString() => 'PaymentResultCode.$_value';
  XdrPaymentResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrPaymentResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Payment successfully completed.
  static const PAYMENT_SUCCESS = const XdrPaymentResultCode._internal(0);

  /// Bad input.
  static const PAYMENT_MALFORMED = const XdrPaymentResultCode._internal(-1);

  /// Not enough funds in source account.
  static const PAYMENT_UNDERFUNDED = const XdrPaymentResultCode._internal(-2);

  /// No trust line on source account.
  static const PAYMENT_SRC_NO_TRUST = const XdrPaymentResultCode._internal(-3);

  /// Source not authorized to transfer.
  static const PAYMENT_SRC_NOT_AUTHORIZED =
      const XdrPaymentResultCode._internal(-4);

  /// Destination account does not exist.
  static const PAYMENT_NO_DESTINATION = const XdrPaymentResultCode._internal(
    -5,
  );

  /// Destination missing a trust line for asset.
  static const PAYMENT_NO_TRUST = const XdrPaymentResultCode._internal(-6);

  /// Destination not authorized to hold asset.
  static const PAYMENT_NOT_AUTHORIZED = const XdrPaymentResultCode._internal(
    -7,
  );

  /// Destination would go above their limit.
  static const PAYMENT_LINE_FULL = const XdrPaymentResultCode._internal(-8);

  /// Missing issuer on asset.
  static const PAYMENT_NO_ISSUER = const XdrPaymentResultCode._internal(-9);

  static XdrPaymentResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PAYMENT_SUCCESS;
      case -1:
        return PAYMENT_MALFORMED;
      case -2:
        return PAYMENT_UNDERFUNDED;
      case -3:
        return PAYMENT_SRC_NO_TRUST;
      case -4:
        return PAYMENT_SRC_NOT_AUTHORIZED;
      case -5:
        return PAYMENT_NO_DESTINATION;
      case -6:
        return PAYMENT_NO_TRUST;
      case -7:
        return PAYMENT_NOT_AUTHORIZED;
      case -8:
        return PAYMENT_LINE_FULL;
      case -9:
        return PAYMENT_NO_ISSUER;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrPaymentResultCode value) {
    stream.writeInt(value.value);
  }
}
