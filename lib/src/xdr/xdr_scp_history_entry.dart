// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_scp_history_entry_v0.dart';

class XdrSCPHistoryEntry {
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSCPHistoryEntryV0? _v0;
  XdrSCPHistoryEntryV0? get v0 => this._v0;
  set v0(XdrSCPHistoryEntryV0? value) => this._v0 = value;

  XdrSCPHistoryEntry(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPHistoryEntry encodedSCPHistoryEntry,
  ) {
    stream.writeInt(encodedSCPHistoryEntry.discriminant);
    switch (encodedSCPHistoryEntry.discriminant) {
      case 0:
        XdrSCPHistoryEntryV0.encode(stream, encodedSCPHistoryEntry.v0!);
        break;
    }
  }

  static XdrSCPHistoryEntry decode(XdrDataInputStream stream) {
    XdrSCPHistoryEntry decodedSCPHistoryEntry = XdrSCPHistoryEntry(
      stream.readInt(),
    );
    switch (decodedSCPHistoryEntry.discriminant) {
      case 0:
        decodedSCPHistoryEntry.v0 = XdrSCPHistoryEntryV0.decode(stream);
        break;
    }
    return decodedSCPHistoryEntry;
  }
}
