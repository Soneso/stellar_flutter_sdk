// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrManageOfferResultCode {
  final _value;
  const XdrManageOfferResultCode._internal(this._value);
  toString() => 'ManageOfferResultCode.$_value';
  XdrManageOfferResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrManageOfferResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const MANAGE_SELL_OFFER_SUCCESS =
      const XdrManageOfferResultCode._internal(0);
  static const MANAGE_SELL_OFFER_MALFORMED =
      const XdrManageOfferResultCode._internal(-1);
  static const MANAGE_SELL_OFFER_SELL_NO_TRUST =
      const XdrManageOfferResultCode._internal(-2);
  static const MANAGE_SELL_OFFER_BUY_NO_TRUST =
      const XdrManageOfferResultCode._internal(-3);
  static const MANAGE_SELL_OFFER_SELL_NOT_AUTHORIZED =
      const XdrManageOfferResultCode._internal(-4);
  static const MANAGE_SELL_OFFER_BUY_NOT_AUTHORIZED =
      const XdrManageOfferResultCode._internal(-5);
  static const MANAGE_SELL_OFFER_LINE_FULL =
      const XdrManageOfferResultCode._internal(-6);
  static const MANAGE_SELL_OFFER_UNDERFUNDED =
      const XdrManageOfferResultCode._internal(-7);
  static const MANAGE_SELL_OFFER_CROSS_SELF =
      const XdrManageOfferResultCode._internal(-8);
  static const MANAGE_SELL_OFFER_SELL_NO_ISSUER =
      const XdrManageOfferResultCode._internal(-9);
  static const MANAGE_SELL_OFFER_BUY_NO_ISSUER =
      const XdrManageOfferResultCode._internal(-10);
  static const MANAGE_SELL_OFFER_NOT_FOUND =
      const XdrManageOfferResultCode._internal(-11);
  static const MANAGE_SELL_OFFER_LOW_RESERVE =
      const XdrManageOfferResultCode._internal(-12);

  static XdrManageOfferResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MANAGE_SELL_OFFER_SUCCESS;
      case -1:
        return MANAGE_SELL_OFFER_MALFORMED;
      case -2:
        return MANAGE_SELL_OFFER_SELL_NO_TRUST;
      case -3:
        return MANAGE_SELL_OFFER_BUY_NO_TRUST;
      case -4:
        return MANAGE_SELL_OFFER_SELL_NOT_AUTHORIZED;
      case -5:
        return MANAGE_SELL_OFFER_BUY_NOT_AUTHORIZED;
      case -6:
        return MANAGE_SELL_OFFER_LINE_FULL;
      case -7:
        return MANAGE_SELL_OFFER_UNDERFUNDED;
      case -8:
        return MANAGE_SELL_OFFER_CROSS_SELF;
      case -9:
        return MANAGE_SELL_OFFER_SELL_NO_ISSUER;
      case -10:
        return MANAGE_SELL_OFFER_BUY_NO_ISSUER;
      case -11:
        return MANAGE_SELL_OFFER_NOT_FOUND;
      case -12:
        return MANAGE_SELL_OFFER_LOW_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrManageOfferResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
