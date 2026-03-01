// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_bucket_entry_type.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_entry.dart';
import 'xdr_ledger_key.dart';

class XdrBucketEntry {
  XdrBucketEntryType _type;
  XdrBucketEntryType get discriminant => this._type;
  set discriminant(XdrBucketEntryType value) => this._type = value;

  XdrLedgerEntry? _liveEntry;
  XdrLedgerEntry? get liveEntry => this._liveEntry;
  set liveEntry(XdrLedgerEntry? value) => this._liveEntry = value;

  XdrLedgerKey? _deadEntry;
  XdrLedgerKey? get deadEntry => this._deadEntry;
  set deadEntry(XdrLedgerKey? value) => this._deadEntry = value;

  XdrBucketEntry(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrBucketEntry encodedBucketEntry) {
    stream.writeInt(encodedBucketEntry.discriminant.value);
    switch (encodedBucketEntry.discriminant) {
      case XdrBucketEntryType.LIVEENTRY:
        XdrLedgerEntry.encode(stream, encodedBucketEntry.liveEntry!);
        break;
      case XdrBucketEntryType.DEADENTRY:
        XdrLedgerKey.encode(stream, encodedBucketEntry.deadEntry!);
        break;
    }
  }

  static XdrBucketEntry decode(XdrDataInputStream stream) {
    XdrBucketEntry decodedBucketEntry =
        XdrBucketEntry(XdrBucketEntryType.decode(stream));
    switch (decodedBucketEntry.discriminant) {
      case XdrBucketEntryType.LIVEENTRY:
        decodedBucketEntry.liveEntry = XdrLedgerEntry.decode(stream);
        break;
      case XdrBucketEntryType.DEADENTRY:
        decodedBucketEntry.deadEntry = XdrLedgerKey.decode(stream);
        break;
    }
    return decodedBucketEntry;
  }
}
