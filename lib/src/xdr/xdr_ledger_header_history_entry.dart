// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_ledger_header.dart';
import 'xdr_ledger_header_history_entry_ext.dart';

class XdrLedgerHeaderHistoryEntry {
  XdrLedgerHeaderHistoryEntry(this._hash, this._header, this._ext);

  XdrHash _hash;

  XdrHash get hash => this._hash;

  set hash(XdrHash value) => this._hash = value;

  XdrLedgerHeader _header;

  XdrLedgerHeader get header => this._header;

  set header(XdrLedgerHeader value) => this._header = value;

  XdrLedgerHeaderHistoryEntryExt _ext;

  XdrLedgerHeaderHistoryEntryExt get ext => this._ext;

  set ext(XdrLedgerHeaderHistoryEntryExt value) => this._ext = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerHeaderHistoryEntry encodedLedgerHeaderHistoryEntry) {
    XdrHash.encode(stream, encodedLedgerHeaderHistoryEntry.hash);
    XdrLedgerHeader.encode(stream, encodedLedgerHeaderHistoryEntry.header);
    XdrLedgerHeaderHistoryEntryExt.encode(
        stream, encodedLedgerHeaderHistoryEntry.ext);
  }

  static XdrLedgerHeaderHistoryEntry decode(XdrDataInputStream stream) {
    XdrHash hash = XdrHash.decode(stream);
    XdrLedgerHeader header = XdrLedgerHeader.decode(stream);
    XdrLedgerHeaderHistoryEntryExt ext =
        XdrLedgerHeaderHistoryEntryExt.decode(stream);
    return XdrLedgerHeaderHistoryEntry(hash, header, ext);
  }
}
