// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrErrorCode {
  final _value;
  const XdrErrorCode._internal(this._value);
  toString() => 'ErrorCode.$_value';
  XdrErrorCode(this._value);
  get value => this._value;

  static const ERR_MISC = const XdrErrorCode._internal(0);
  static const ERR_DATA = const XdrErrorCode._internal(1);
  static const ERR_CONF = const XdrErrorCode._internal(2);
  static const ERR_AUTH = const XdrErrorCode._internal(3);
  static const ERR_LOAD = const XdrErrorCode._internal(4);

  static XdrErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ERR_MISC;
      case 1:
        return ERR_DATA;
      case 2:
        return ERR_CONF;
      case 3:
        return ERR_AUTH;
      case 4:
        return ERR_LOAD;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrError {
  XdrError();
  XdrErrorCode? _code;
  XdrErrorCode? get code => this._code;
  set code(XdrErrorCode? value) => this._code = value;

  String? _msg;
  String? get msg => this._msg;
  set msg(String? value) => this._msg = value;

  static void encode(XdrDataOutputStream stream, XdrError encodedError) {
    XdrErrorCode.encode(stream, encodedError.code!);
    stream.writeString(encodedError.msg);
  }

  static XdrError decode(XdrDataInputStream stream) {
    XdrError decodedError = XdrError();
    decodedError.code = XdrErrorCode.decode(stream);
    decodedError.msg = stream.readString();
    return decodedError;
  }
}
