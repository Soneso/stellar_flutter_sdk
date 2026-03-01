// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_data.dart';
import 'xdr_ledger_entry_ext.dart';
import 'xdr_uint32.dart';

class XdrLedgerEntryBase {
  XdrLedgerEntryBase(this._lastModifiedLedgerSeq, this._data, this._ext);

  XdrUint32 _lastModifiedLedgerSeq;

  XdrUint32 get lastModifiedLedgerSeq => this._lastModifiedLedgerSeq;

  set lastModifiedLedgerSeq(XdrUint32 value) =>
      this._lastModifiedLedgerSeq = value;

  XdrLedgerEntryData _data;

  XdrLedgerEntryData get data => this._data;

  set data(XdrLedgerEntryData value) => this._data = value;

  XdrLedgerEntryExt _ext;

  XdrLedgerEntryExt get ext => this._ext;

  set ext(XdrLedgerEntryExt value) => this._ext = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerEntryBase encodedLedgerEntry,
  ) {
    XdrUint32.encode(stream, encodedLedgerEntry.lastModifiedLedgerSeq);
    XdrLedgerEntryData.encode(stream, encodedLedgerEntry.data);
    XdrLedgerEntryExt.encode(stream, encodedLedgerEntry.ext);
  }

  static XdrLedgerEntryBase decode(XdrDataInputStream stream) {
    XdrUint32 lastModifiedLedgerSeq = XdrUint32.decode(stream);
    XdrLedgerEntryData data = XdrLedgerEntryData.decode(stream);
    XdrLedgerEntryExt ext = XdrLedgerEntryExt.decode(stream);
    return XdrLedgerEntryBase(lastModifiedLedgerSeq, data, ext);
  }
}
