// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrTxDemandVector {
  XdrTxDemandVector(this._txDemandVector);

  List<XdrHash> _txDemandVector;
  List<XdrHash> get txDemandVector => this._txDemandVector;
  set txDemandVector(List<XdrHash> value) => this._txDemandVector = value;

  static void encode(XdrDataOutputStream stream, XdrTxDemandVector encodedTxDemandVector) {
    int size = encodedTxDemandVector.txDemandVector.length;
    stream.writeInt(size);
    for (int i = 0; i < size; i++) {
      XdrHash.encode(stream, encodedTxDemandVector.txDemandVector[i]);
    }
  }

  static XdrTxDemandVector decode(XdrDataInputStream stream) {
    int size = stream.readInt();
    List<XdrHash> items = List<XdrHash>.empty(growable: true);
    for (int i = 0; i < size; i++) {
      items.add(XdrHash.decode(stream));
    }
    return XdrTxDemandVector(items);
  }
}
