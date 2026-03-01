// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrPathPaymentStrictReceiveResultCode {
  final _value;
  const XdrPathPaymentStrictReceiveResultCode._internal(this._value);
  toString() => 'PathPaymentStrictReceiveResultCode.$_value';
  XdrPathPaymentStrictReceiveResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrPathPaymentStrictReceiveResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const PATH_PAYMENT_STRICT_RECEIVE_SUCCESS =
      const XdrPathPaymentStrictReceiveResultCode._internal(0);

  ///  Bad input.
  static const PATH_PAYMENT_STRICT_RECEIVE_MALFORMED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-1);

  /// Not enough funds in source account.
  static const PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-2);

  /// No trust line on source account.
  static const PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST =
      const XdrPathPaymentStrictReceiveResultCode._internal(-3);

  /// Source not authorized to transfer.
  static const PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-4);

  /// Destination account does not exist.
  static const PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION =
      const XdrPathPaymentStrictReceiveResultCode._internal(-5);

  /// Dest missing a trust line for asset.
  static const PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST =
      const XdrPathPaymentStrictReceiveResultCode._internal(-6);

  /// Dest not authorized to hold asset.
  static const PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED =
      const XdrPathPaymentStrictReceiveResultCode._internal(-7);

  /// Dest would go above their limit.
  static const PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL =
      const XdrPathPaymentStrictReceiveResultCode._internal(-8);

  /// Missing issuer on one asset.
  static const PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER =
      const XdrPathPaymentStrictReceiveResultCode._internal(-9);

  /// Not enough offers to satisfy path.
  static const PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS =
      const XdrPathPaymentStrictReceiveResultCode._internal(-10);

  /// Would cross one of its own offers.
  static const PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF =
      const XdrPathPaymentStrictReceiveResultCode._internal(-11);

  /// Could not satisfy sendmax.
  static const PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX =
      const XdrPathPaymentStrictReceiveResultCode._internal(-12);

  static XdrPathPaymentStrictReceiveResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PATH_PAYMENT_STRICT_RECEIVE_SUCCESS;
      case -1:
        return PATH_PAYMENT_STRICT_RECEIVE_MALFORMED;
      case -2:
        return PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED;
      case -3:
        return PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST;
      case -4:
        return PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED;
      case -5:
        return PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION;
      case -6:
        return PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST;
      case -7:
        return PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED;
      case -8:
        return PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL;
      case -9:
        return PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER;
      case -10:
        return PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS;
      case -11:
        return PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF;
      case -12:
        return PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrPathPaymentStrictReceiveResultCode value) {
    stream.writeInt(value.value);
  }
}
