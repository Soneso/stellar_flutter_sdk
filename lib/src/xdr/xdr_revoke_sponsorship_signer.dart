// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_signer_key.dart';

class XdrRevokeSponsorshipSigner {
  XdrAccountID _accountId;

  XdrAccountID get accountId => this._accountId;

  set accountId(XdrAccountID value) => this._accountId = value;

  XdrSignerKey _signerKey;

  XdrSignerKey get signerKey => this._signerKey;

  set signerKey(XdrSignerKey value) => this._signerKey = value;

  XdrRevokeSponsorshipSigner(this._accountId, this._signerKey);

  static void encode(
    XdrDataOutputStream stream,
    XdrRevokeSponsorshipSigner encoded,
  ) {
    XdrAccountID.encode(stream, encoded.accountId);
    XdrSignerKey.encode(stream, encoded.signerKey);
  }

  static XdrRevokeSponsorshipSigner decode(XdrDataInputStream stream) {
    return XdrRevokeSponsorshipSigner(
      XdrAccountID.decode(stream),
      XdrSignerKey.decode(stream),
    );
  }
}
