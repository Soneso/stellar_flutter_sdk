// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_type.dart';

class XdrMemoType {
  final _value;
  const XdrMemoType._internal(this._value);
  toString() => 'MemoType.$_value';
  XdrMemoType(this._value);
  get value => this._value;

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

class XdrMemo {
  XdrMemo();
  XdrMemoType _type;
  XdrMemoType get discriminant => this._type;
  set discriminant(XdrMemoType value) => this._type = value;

  String _text;
  String get text => this._text;
  set text(String value) => this._text = value;

  XdrUint64 _id;
  XdrUint64 get id => this._id;
  set id(XdrUint64 value) => this._id = value;

  XdrHash _hash;
  XdrHash get hash => this._hash;
  set hash(XdrHash value) => this._hash = value;

  XdrHash _retHash;
  XdrHash get retHash => this._retHash;
  set retHash(XdrHash value) => this._retHash = value;

  static void encode(XdrDataOutputStream stream, XdrMemo encodedMemo) {
    stream.writeInt(encodedMemo.discriminant.value);
    switch (encodedMemo.discriminant) {
      case XdrMemoType.MEMO_NONE:
        break;
      case XdrMemoType.MEMO_TEXT:
        stream.writeString(encodedMemo.text);
        break;
      case XdrMemoType.MEMO_ID:
        XdrUint64.encode(stream, encodedMemo.id);
        break;
      case XdrMemoType.MEMO_HASH:
        XdrHash.encode(stream, encodedMemo.hash);
        break;
      case XdrMemoType.MEMO_RETURN:
        XdrHash.encode(stream, encodedMemo.retHash);
        break;
    }
  }

  static XdrMemo decode(XdrDataInputStream stream) {
    XdrMemo decodedMemo = XdrMemo();
    XdrMemoType discriminant = XdrMemoType.decode(stream);
    decodedMemo.discriminant = discriminant;
    switch (decodedMemo.discriminant) {
      case XdrMemoType.MEMO_NONE:
        break;
      case XdrMemoType.MEMO_TEXT:
        decodedMemo.text = stream.readString();
        break;
      case XdrMemoType.MEMO_ID:
        decodedMemo.id = XdrUint64.decode(stream);
        break;
      case XdrMemoType.MEMO_HASH:
        decodedMemo.hash = XdrHash.decode(stream);
        break;
      case XdrMemoType.MEMO_RETURN:
        decodedMemo.retHash = XdrHash.decode(stream);
        break;
    }
    return decodedMemo;
  }
}
