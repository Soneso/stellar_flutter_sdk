// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSignerKeyType {
  final _value;
  const XdrSignerKeyType._internal(this._value);
  toString() => 'SignerKeyType.$_value';
  XdrSignerKeyType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrSignerKeyType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SIGNER_KEY_TYPE_ED25519 = const XdrSignerKeyType._internal(0);
  static const SIGNER_KEY_TYPE_PRE_AUTH_TX =
      const XdrSignerKeyType._internal(1);
  static const SIGNER_KEY_TYPE_HASH_X = const XdrSignerKeyType._internal(2);
  static const KEY_TYPE_ED25519_SIGNED_PAYLOAD =
      const XdrSignerKeyType._internal(3);
  static const KEY_TYPE_MUXED_ED25519 = const XdrSignerKeyType._internal(0x100);

  static XdrSignerKeyType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SIGNER_KEY_TYPE_ED25519;
      case 1:
        return SIGNER_KEY_TYPE_PRE_AUTH_TX;
      case 2:
        return SIGNER_KEY_TYPE_HASH_X;
      case 3:
        return KEY_TYPE_ED25519_SIGNED_PAYLOAD;
      case 0x100:
        return KEY_TYPE_MUXED_ED25519;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSignerKeyType value) {
    stream.writeInt(value.value);
  }
}
