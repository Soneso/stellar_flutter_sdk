// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_key.dart';
import 'xdr_revoke_sponsorship_signer.dart';
import 'xdr_revoke_sponsorship_type.dart';

class XdrRevokeSponsorshipOp {
  XdrRevokeSponsorshipType _type;

  XdrRevokeSponsorshipType get discriminant => this._type;

  set discriminant(XdrRevokeSponsorshipType value) => this._type = value;

  XdrLedgerKey? _ledgerKey;

  XdrLedgerKey? get ledgerKey => this._ledgerKey;

  set ledgerKey(XdrLedgerKey? value) => this._ledgerKey = value;

  XdrRevokeSponsorshipSigner? _signer;

  XdrRevokeSponsorshipSigner? get signer => this._signer;

  set signer(XdrRevokeSponsorshipSigner? value) => this._signer = value;

  XdrRevokeSponsorshipOp(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipOp encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY:
        XdrLedgerKey.encode(stream, encoded.ledgerKey!);
        break;
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER:
        XdrRevokeSponsorshipSigner.encode(stream, encoded.signer!);
        break;
    }
  }

  static XdrRevokeSponsorshipOp decode(XdrDataInputStream stream) {
    XdrRevokeSponsorshipOp decoded =
        XdrRevokeSponsorshipOp(XdrRevokeSponsorshipType.decode(stream));
    switch (decoded.discriminant) {
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY:
        decoded.ledgerKey = XdrLedgerKey.decode(stream);
        break;
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER:
        decoded.signer = XdrRevokeSponsorshipSigner.decode(stream);
        break;
    }
    return decoded;
  }
}
