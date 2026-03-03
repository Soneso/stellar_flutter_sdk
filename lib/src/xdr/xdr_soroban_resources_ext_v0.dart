// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrSorobanResourcesExtV0 {

  List<XdrUint32> _archivedSorobanEntries;
  List<XdrUint32> get archivedSorobanEntries => this._archivedSorobanEntries;
  set archivedSorobanEntries(List<XdrUint32> value) => this._archivedSorobanEntries = value;

  XdrSorobanResourcesExtV0(this._archivedSorobanEntries);

  static void encode(XdrDataOutputStream stream, XdrSorobanResourcesExtV0 encodedSorobanResourcesExtV0) {
    int archivedSorobanEntriessize = encodedSorobanResourcesExtV0.archivedSorobanEntries.length;
    stream.writeInt(archivedSorobanEntriessize);
    for (int i = 0; i < archivedSorobanEntriessize; i++) {
      XdrUint32.encode(stream, encodedSorobanResourcesExtV0.archivedSorobanEntries[i]);
    }
  }

  static XdrSorobanResourcesExtV0 decode(XdrDataInputStream stream) {
    int archivedSorobanEntriessize = stream.readInt();
    List<XdrUint32> archivedSorobanEntries = List<XdrUint32>.empty(growable: true);
    for (int i = 0; i < archivedSorobanEntriessize; i++) {
      archivedSorobanEntries.add(XdrUint32.decode(stream));
    }
    return XdrSorobanResourcesExtV0(archivedSorobanEntries);
  }
}
