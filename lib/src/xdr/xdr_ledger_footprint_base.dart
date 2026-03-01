// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_key.dart';

class XdrLedgerFootprintBase {
  List<XdrLedgerKey> _readOnly;
  List<XdrLedgerKey> get readOnly => this._readOnly;
  set readOnly(List<XdrLedgerKey> value) => this._readOnly = value;

  List<XdrLedgerKey> _readWrite;
  List<XdrLedgerKey> get readWrite => this._readWrite;
  set readWrite(List<XdrLedgerKey> value) => this._readWrite = value;

  XdrLedgerFootprintBase(this._readOnly, this._readWrite);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerFootprintBase encoded,
  ) {
    int readOnlySize = encoded.readOnly.length;
    stream.writeInt(readOnlySize);
    for (int i = 0; i < readOnlySize; i++) {
      XdrLedgerKey.encode(stream, encoded.readOnly[i]);
    }

    int readWriteSize = encoded.readWrite.length;
    stream.writeInt(readWriteSize);
    for (int i = 0; i < readWriteSize; i++) {
      XdrLedgerKey.encode(stream, encoded.readWrite[i]);
    }
  }

  static XdrLedgerFootprintBase decode(XdrDataInputStream stream) {
    int readOnlySize = stream.readInt();
    List<XdrLedgerKey> readOnly = List<XdrLedgerKey>.empty(growable: true);
    for (int i = 0; i < readOnlySize; i++) {
      readOnly.add(XdrLedgerKey.decode(stream));
    }

    int readWriteSize = stream.readInt();
    List<XdrLedgerKey> readWrite = List<XdrLedgerKey>.empty(growable: true);
    for (int i = 0; i < readWriteSize; i++) {
      readWrite.add(XdrLedgerKey.decode(stream));
    }

    return XdrLedgerFootprintBase(readOnly, readWrite);
  }
}
