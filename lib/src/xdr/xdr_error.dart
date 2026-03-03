// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_error_code.dart';

class XdrError {

  XdrErrorCode _code;
  XdrErrorCode get code => this._code;
  set code(XdrErrorCode value) => this._code = value;

  String _msg;
  String get msg => this._msg;
  set msg(String value) => this._msg = value;

  XdrError(this._code, this._msg);

  static void encode(XdrDataOutputStream stream, XdrError encodedError) {
    XdrErrorCode.encode(stream, encodedError.code);
    stream.writeString(encodedError.msg);
  }

  static XdrError decode(XdrDataInputStream stream) {
    XdrErrorCode code = XdrErrorCode.decode(stream);
    String msg = stream.readString();
    return XdrError(code, msg);
  }
}
