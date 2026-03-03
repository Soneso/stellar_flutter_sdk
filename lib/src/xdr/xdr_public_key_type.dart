// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrPublicKeyType {
  final _value;
  const XdrPublicKeyType._internal(this._value);
  toString() => 'PublicKeyType.$_value';
  XdrPublicKeyType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrPublicKeyType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const PUBLIC_KEY_TYPE_ED25519 = const XdrPublicKeyType._internal(0);

  static XdrPublicKeyType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PUBLIC_KEY_TYPE_ED25519;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrPublicKeyType value) {
    stream.writeInt(value.value);
  }
}
