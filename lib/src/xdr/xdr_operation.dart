// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_muxed_account.dart';
import 'xdr_operation_body.dart';

class XdrOperation {
  XdrOperation(this._body);

  XdrMuxedAccount? _sourceAccount;

  XdrMuxedAccount? get sourceAccount => this._sourceAccount;

  set sourceAccount(XdrMuxedAccount? value) => this._sourceAccount = value;

  XdrOperationBody _body;

  XdrOperationBody get body => this._body;

  set body(XdrOperationBody value) => this._body = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperation encodedOperation) {
    if (encodedOperation.sourceAccount != null) {
      stream.writeInt(1);
      XdrMuxedAccount.encode(stream, encodedOperation.sourceAccount!);
    } else {
      stream.writeInt(0);
    }
    XdrOperationBody.encode(stream, encodedOperation.body);
  }

  static XdrOperation decode(XdrDataInputStream stream) {
    XdrMuxedAccount? sourceAccount;
    int sourceAccountPresent = stream.readInt();
    if (sourceAccountPresent != 0) {
      sourceAccount = XdrMuxedAccount.decode(stream);
    }
    XdrOperation decodedOperation =
        XdrOperation(XdrOperationBody.decode(stream));

    decodedOperation.sourceAccount = sourceAccount;
    return decodedOperation;
  }
}
