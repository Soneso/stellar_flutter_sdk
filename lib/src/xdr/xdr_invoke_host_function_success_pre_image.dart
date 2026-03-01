// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';
import 'xdr_sc_val.dart';

class XdrInvokeHostFunctionSuccessPreImage {
  XdrSCVal _returnValue;
  XdrSCVal get returnValue => this._returnValue;
  set returnValue(XdrSCVal value) => this._returnValue = value;

  List<XdrContractEvent> _events;
  List<XdrContractEvent> get events => this._events;
  set events(List<XdrContractEvent> value) => this._events = value;

  XdrInvokeHostFunctionSuccessPreImage(this._returnValue, this._events);

  static void encode(
    XdrDataOutputStream stream,
    XdrInvokeHostFunctionSuccessPreImage encoded,
  ) {
    XdrSCVal.encode(stream, encoded.returnValue);

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrContractEvent.encode(stream, encoded._events[i]);
    }
  }

  static XdrInvokeHostFunctionSuccessPreImage decode(
    XdrDataInputStream stream,
  ) {
    XdrSCVal returnValue = XdrSCVal.decode(stream);

    int eventsSize = stream.readInt();
    List<XdrContractEvent> events = List<XdrContractEvent>.empty(
      growable: true,
    );
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrContractEvent.decode(stream));
    }

    return XdrInvokeHostFunctionSuccessPreImage(returnValue, events);
  }
}
