// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_create_account_result_code.dart';
import 'xdr_data_io.dart';

class XdrCreateAccountResult {
  XdrCreateAccountResultCode _code;

  XdrCreateAccountResultCode get discriminant => this._code;

  set discriminant(XdrCreateAccountResultCode value) => this._code = value;

  XdrCreateAccountResult(this._code);

  static void encode(XdrDataOutputStream stream, XdrCreateAccountResult encodedCreateAccountResult) {
    stream.writeInt(encodedCreateAccountResult.discriminant.value);
    switch (encodedCreateAccountResult.discriminant) {
      case XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrCreateAccountResult decode(XdrDataInputStream stream) {
    XdrCreateAccountResult decodedCreateAccountResult = XdrCreateAccountResult(XdrCreateAccountResultCode.decode(stream));
    switch (decodedCreateAccountResult.discriminant) {
      case XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS:
        break;
      default:
        break;
    }
    return decodedCreateAccountResult;
  }
}
