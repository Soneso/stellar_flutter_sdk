// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_set_options_result_code.dart';

class XdrSetOptionsResult {
  XdrSetOptionsResultCode _code;

  XdrSetOptionsResultCode get discriminant => this._code;

  set discriminant(XdrSetOptionsResultCode value) => this._code = value;

  XdrSetOptionsResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrSetOptionsResult encodedSetOptionsResult,
  ) {
    stream.writeInt(encodedSetOptionsResult.discriminant.value);
    switch (encodedSetOptionsResult.discriminant) {
      case XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrSetOptionsResult decode(XdrDataInputStream stream) {
    XdrSetOptionsResult decodedSetOptionsResult = XdrSetOptionsResult(
      XdrSetOptionsResultCode.decode(stream),
    );
    switch (decodedSetOptionsResult.discriminant) {
      case XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS:
        break;
      default:
        break;
    }
    return decodedSetOptionsResult;
  }
}
