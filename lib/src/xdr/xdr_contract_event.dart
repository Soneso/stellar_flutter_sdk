// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_contract_event_base.dart';
import 'xdr_data_io.dart';

class XdrContractEvent extends XdrContractEventBase {
  XdrContractEvent(super.ext, super.hash, super.type, super.body);

  static void encode(XdrDataOutputStream stream, XdrContractEvent val) {
    XdrContractEventBase.encode(stream, val);
  }

  static XdrContractEvent decode(XdrDataInputStream stream) {
    var b = XdrContractEventBase.decode(stream);
    return XdrContractEvent(b.ext, b.hash, b.type, b.body);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrContractEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrContractEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrContractEvent.decode(XdrDataInputStream(bytes));
  }
}
