// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrManageOfferEffect {
  final _value;
  const XdrManageOfferEffect._internal(this._value);
  toString() => 'ManageOfferEffect.$_value';
  XdrManageOfferEffect(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrManageOfferEffect && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const MANAGE_OFFER_CREATED = const XdrManageOfferEffect._internal(0);
  static const MANAGE_OFFER_UPDATED = const XdrManageOfferEffect._internal(1);
  static const MANAGE_OFFER_DELETED = const XdrManageOfferEffect._internal(2);

  static XdrManageOfferEffect decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MANAGE_OFFER_CREATED;
      case 1:
        return MANAGE_OFFER_UPDATED;
      case 2:
        return MANAGE_OFFER_DELETED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrManageOfferEffect value) {
    stream.writeInt(value.value);
  }
}
