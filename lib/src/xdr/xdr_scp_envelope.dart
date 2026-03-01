// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_scp_statement.dart';
import 'xdr_signature.dart';

class XdrSCPEnvelope {
  XdrSCPEnvelope(this._statement, this._signature);
  XdrSCPStatement _statement;
  XdrSCPStatement get statement => this._statement;
  set statement(XdrSCPStatement value) => this._statement = value;

  XdrSignature _signature;
  XdrSignature get signature => this._signature;
  set signature(XdrSignature value) => this._signature = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPEnvelope encodedSCPEnvelope) {
    XdrSCPStatement.encode(stream, encodedSCPEnvelope.statement);
    XdrSignature.encode(stream, encodedSCPEnvelope.signature);
  }

  static XdrSCPEnvelope decode(XdrDataInputStream stream) {
    XdrSCPStatement statement = XdrSCPStatement.decode(stream);
    XdrSignature signature = XdrSignature.decode(stream);
    return XdrSCPEnvelope(statement, signature);
  }
}
