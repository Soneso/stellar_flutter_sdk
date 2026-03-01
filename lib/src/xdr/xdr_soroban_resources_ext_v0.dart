// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrSorobanResourcesExtV0 {
  // Vector of indices representing what Soroban
  // entries in the footprint are archived, based on the
  // order of keys provided in the readWrite footprint.
  List<XdrUint32> _archivedSorobanEntries;
  List<XdrUint32> get archivedSorobanEntries => this._archivedSorobanEntries;
  set archivedSorobanEntries(List<XdrUint32> value) =>
      this._archivedSorobanEntries = value;

  XdrSorobanResourcesExtV0(this._archivedSorobanEntries);

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanResourcesExtV0 encoded,
  ) {
    int entriesSize = encoded.archivedSorobanEntries.length;
    stream.writeInt(entriesSize);
    for (int i = 0; i < entriesSize; i++) {
      XdrUint32.encode(stream, encoded.archivedSorobanEntries[i]);
    }
  }

  static XdrSorobanResourcesExtV0 decode(XdrDataInputStream stream) {
    int entriesSize = stream.readInt();
    List<XdrUint32> entries = List<XdrUint32>.empty(growable: true);
    for (int i = 0; i < entriesSize; i++) {
      entries.add(XdrUint32.decode(stream));
    }

    return XdrSorobanResourcesExtV0(entries);
  }
}
