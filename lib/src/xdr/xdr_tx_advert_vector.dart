// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrTxAdvertVector {
  XdrTxAdvertVector(this._txAdvertVector);

  List<XdrHash> _txAdvertVector;
  List<XdrHash> get txAdvertVector => this._txAdvertVector;
  set txAdvertVector(List<XdrHash> value) => this._txAdvertVector = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTxAdvertVector encodedTxAdvertVector,
  ) {
    int size = encodedTxAdvertVector.txAdvertVector.length;
    stream.writeInt(size);
    for (int i = 0; i < size; i++) {
      XdrHash.encode(stream, encodedTxAdvertVector.txAdvertVector[i]);
    }
  }

  static XdrTxAdvertVector decode(XdrDataInputStream stream) {
    int size = stream.readInt();
    List<XdrHash> items = List<XdrHash>.empty(growable: true);
    for (int i = 0; i < size; i++) {
      items.add(XdrHash.decode(stream));
    }
    return XdrTxAdvertVector(items);
  }
}
