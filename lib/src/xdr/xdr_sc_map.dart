// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_map_entry.dart';

class XdrSCMap {
  XdrSCMap(this._sCMap);

  List<XdrSCMapEntry> _sCMap;
  List<XdrSCMapEntry> get sCMap => this._sCMap;
  set sCMap(List<XdrSCMapEntry> value) => this._sCMap = value;

  static void encode(XdrDataOutputStream stream, XdrSCMap encodedSCMap) {
    int size = encodedSCMap.sCMap.length;
    stream.writeInt(size);
    for (int i = 0; i < size; i++) {
      XdrSCMapEntry.encode(stream, encodedSCMap.sCMap[i]);
    }
  }

  static XdrSCMap decode(XdrDataInputStream stream) {
    int size = stream.readInt();
    List<XdrSCMapEntry> items = List<XdrSCMapEntry>.empty(growable: true);
    for (int i = 0; i < size; i++) {
      items.add(XdrSCMapEntry.decode(stream));
    }
    return XdrSCMap(items);
  }
}
