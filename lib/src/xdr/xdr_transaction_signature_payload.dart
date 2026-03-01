// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_transaction_signature_payload_tagged_transaction.dart';

class XdrTransactionSignaturePayload {
  XdrTransactionSignaturePayload(this._networkId, this._taggedTransaction);
  XdrHash _networkId;
  XdrHash get networkId => this._networkId;
  set networkId(XdrHash value) => this._networkId = value;

  XdrTransactionSignaturePayloadTaggedTransaction _taggedTransaction;
  XdrTransactionSignaturePayloadTaggedTransaction get taggedTransaction =>
      this._taggedTransaction;
  set taggedTransaction(
          XdrTransactionSignaturePayloadTaggedTransaction value) =>
      this._taggedTransaction = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionSignaturePayload encodedTransactionSignaturePayload) {
    XdrHash.encode(stream, encodedTransactionSignaturePayload._networkId);
    XdrTransactionSignaturePayloadTaggedTransaction.encode(
        stream, encodedTransactionSignaturePayload._taggedTransaction);
  }

  static XdrTransactionSignaturePayload decode(XdrDataInputStream stream) {
    XdrHash networkId = XdrHash.decode(stream);
    XdrTransactionSignaturePayloadTaggedTransaction taggedTransaction =
        XdrTransactionSignaturePayloadTaggedTransaction.decode(stream);
    return XdrTransactionSignaturePayload(networkId, taggedTransaction);
  }
}
