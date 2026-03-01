// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_contract_event_body.dart';
import 'xdr_contract_event_type.dart';
import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_hash.dart';

class XdrContractEvent {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrHash? _hash;
  XdrHash? get hash => this._hash;
  set hash(XdrHash? value) => this._hash = value;

  XdrContractEventType _type;
  XdrContractEventType get type => this._type;
  set type(XdrContractEventType value) => this._type = value;

  XdrContractEventBody _body;
  XdrContractEventBody get body => this._body;
  set body(XdrContractEventBody value) => this._body = value;

  XdrContractEvent(this._ext, this._hash, this._type, this._body);

  static void encode(XdrDataOutputStream stream, XdrContractEvent encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    if (encoded.hash != null) {
      stream.writeInt(1);
      XdrHash.encode(stream, encoded.hash!);
    } else {
      stream.writeInt(0);
    }
    XdrContractEventType.encode(stream, encoded.type);
    XdrContractEventBody.encode(stream, encoded.body);
  }

  static XdrContractEvent decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrHash? hash;
    int hashPresent = stream.readInt();
    if (hashPresent != 0) {
      hash = XdrHash.decode(stream);
    }

    XdrContractEventType type = XdrContractEventType.decode(stream);
    XdrContractEventBody body = XdrContractEventBody.decode(stream);
    return XdrContractEvent(ext, hash, type, body);
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
