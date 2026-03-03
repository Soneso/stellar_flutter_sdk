// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_val.dart';

class XdrContractEventV0 {
  List<XdrSCVal> _topics;
  List<XdrSCVal> get topics => this._topics;
  set topics(List<XdrSCVal> value) => this._topics = value;

  XdrSCVal _data;
  XdrSCVal get data => this._data;
  set data(XdrSCVal value) => this._data = value;

  XdrContractEventV0(this._topics, this._data);

  static void encode(
    XdrDataOutputStream stream,
    XdrContractEventV0 encodedContractEventV0,
  ) {
    int topicssize = encodedContractEventV0.topics.length;
    stream.writeInt(topicssize);
    for (int i = 0; i < topicssize; i++) {
      XdrSCVal.encode(stream, encodedContractEventV0.topics[i]);
    }
    XdrSCVal.encode(stream, encodedContractEventV0.data);
  }

  static XdrContractEventV0 decode(XdrDataInputStream stream) {
    int topicssize = stream.readInt();
    List<XdrSCVal> topics = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < topicssize; i++) {
      topics.add(XdrSCVal.decode(stream));
    }
    XdrSCVal data = XdrSCVal.decode(stream);
    return XdrContractEventV0(topics, data);
  }
}
