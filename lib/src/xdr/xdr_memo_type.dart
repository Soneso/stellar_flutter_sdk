// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrMemoType {
  final _value;
  const XdrMemoType._internal(this._value);
  toString() => 'MemoType.$_value';
  XdrMemoType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrMemoType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const MEMO_NONE = const XdrMemoType._internal(0);
  static const MEMO_TEXT = const XdrMemoType._internal(1);
  static const MEMO_ID = const XdrMemoType._internal(2);
  static const MEMO_HASH = const XdrMemoType._internal(3);
  static const MEMO_RETURN = const XdrMemoType._internal(4);

  static XdrMemoType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MEMO_NONE;
      case 1:
        return MEMO_TEXT;
      case 2:
        return MEMO_ID;
      case 3:
        return MEMO_HASH;
      case 4:
        return MEMO_RETURN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrMemoType value) {
    stream.writeInt(value.value);
  }
}
