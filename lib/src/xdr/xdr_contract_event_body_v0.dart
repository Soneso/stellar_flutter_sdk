// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_val.dart';

class XdrContractEventBodyV0 {
  List<XdrSCVal> _topics;
  List<XdrSCVal> get topics => this._topics;
  set topics(List<XdrSCVal> value) => this._topics = value;

  XdrSCVal _data;
  XdrSCVal get data => this._data;
  set data(XdrSCVal value) => this._data = value;

  XdrContractEventBodyV0(this._topics, this._data);

  static void encode(
      XdrDataOutputStream stream, XdrContractEventBodyV0 encoded) {
    int topicsSize = encoded.topics.length;
    stream.writeInt(topicsSize);
    for (int i = 0; i < topicsSize; i++) {
      XdrSCVal.encode(stream, encoded.topics[i]);
    }
    XdrSCVal.encode(stream, encoded.data);
  }

  static XdrContractEventBodyV0 decode(XdrDataInputStream stream) {
    int topicsSize = stream.readInt();
    List<XdrSCVal> topics = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < topicsSize; i++) {
      topics.add(XdrSCVal.decode(stream));
    }
    XdrSCVal data = XdrSCVal.decode(stream);

    return XdrContractEventBodyV0(topics, data);
  }
}
