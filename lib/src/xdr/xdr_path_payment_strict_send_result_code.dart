// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrPathPaymentStrictSendResultCode {
  final _value;
  const XdrPathPaymentStrictSendResultCode._internal(this._value);
  toString() => 'PathPaymentStrictSendResultCode.$_value';
  XdrPathPaymentStrictSendResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrPathPaymentStrictSendResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const PATH_PAYMENT_STRICT_SEND_SUCCESS =
      const XdrPathPaymentStrictSendResultCode._internal(0);

  ///  Bad input.
  static const PATH_PAYMENT_STRICT_SEND_MALFORMED =
      const XdrPathPaymentStrictSendResultCode._internal(-1);

  /// Not enough funds in source account.
  static const PATH_PAYMENT_STRICT_SEND_UNDERFUNDED =
      const XdrPathPaymentStrictSendResultCode._internal(-2);

  /// No trust line on source account.
  static const PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST =
      const XdrPathPaymentStrictSendResultCode._internal(-3);

  /// Source not authorized to transfer.
  static const PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED =
      const XdrPathPaymentStrictSendResultCode._internal(-4);

  /// Destination account does not exist.
  static const PATH_PAYMENT_STRICT_SEND_NO_DESTINATION =
      const XdrPathPaymentStrictSendResultCode._internal(-5);

  /// Dest missing a trust line for asset.
  static const PATH_PAYMENT_STRICT_SEND_NO_TRUST =
      const XdrPathPaymentStrictSendResultCode._internal(-6);

  /// Dest not authorized to hold asset.
  static const PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED =
      const XdrPathPaymentStrictSendResultCode._internal(-7);

  /// Dest would go above their limit.
  static const PATH_PAYMENT_STRICT_SEND_LINE_FULL =
      const XdrPathPaymentStrictSendResultCode._internal(-8);

  /// Missing issuer on one asset.
  static const PATH_PAYMENT_STRICT_SEND_NO_ISSUER =
      const XdrPathPaymentStrictSendResultCode._internal(-9);

  /// Not enough offers to satisfy path.
  static const PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS =
      const XdrPathPaymentStrictSendResultCode._internal(-10);

  /// Would cross one of its own offers.
  static const PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF =
      const XdrPathPaymentStrictSendResultCode._internal(-11);

  /// Could not satisfy destMin.
  static const PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN =
      const XdrPathPaymentStrictSendResultCode._internal(-12);

  static XdrPathPaymentStrictSendResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PATH_PAYMENT_STRICT_SEND_SUCCESS;
      case -1:
        return PATH_PAYMENT_STRICT_SEND_MALFORMED;
      case -2:
        return PATH_PAYMENT_STRICT_SEND_UNDERFUNDED;
      case -3:
        return PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST;
      case -4:
        return PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED;
      case -5:
        return PATH_PAYMENT_STRICT_SEND_NO_DESTINATION;
      case -6:
        return PATH_PAYMENT_STRICT_SEND_NO_TRUST;
      case -7:
        return PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED;
      case -8:
        return PATH_PAYMENT_STRICT_SEND_LINE_FULL;
      case -9:
        return PATH_PAYMENT_STRICT_SEND_NO_ISSUER;
      case -10:
        return PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS;
      case -11:
        return PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF;
      case -12:
        return PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrPathPaymentStrictSendResultCode value) {
    stream.writeInt(value.value);
  }
}
