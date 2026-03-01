// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_v1.dart';

class XdrLedgerEntryExt {
  XdrLedgerEntryExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrLedgerEntryV1? _ledgerEntryExtensionV1;
  XdrLedgerEntryV1? get ledgerEntryExtensionV1 => this._ledgerEntryExtensionV1;
  set ledgerEntryExtensionV1(XdrLedgerEntryV1? value) =>
      this._ledgerEntryExtensionV1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerEntryExt encodedLedgerEntryExt,
  ) {
    stream.writeInt(encodedLedgerEntryExt.discriminant);
    switch (encodedLedgerEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrLedgerEntryV1.encode(
          stream,
          encodedLedgerEntryExt.ledgerEntryExtensionV1!,
        );
        break;
    }
  }

  static XdrLedgerEntryExt decode(XdrDataInputStream stream) {
    XdrLedgerEntryExt decodedLedgerEntryExt = XdrLedgerEntryExt(
      stream.readInt(),
    );
    switch (decodedLedgerEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedLedgerEntryExt.ledgerEntryExtensionV1 = XdrLedgerEntryV1.decode(
          stream,
        );
        break;
    }
    return decodedLedgerEntryExt;
  }
}
