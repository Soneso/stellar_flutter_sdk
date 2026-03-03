// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrSCSpecUDTErrorEnumCaseV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrUint32 _value;
  XdrUint32 get value => this._value;
  set value(XdrUint32 value) => this._value = value;

  XdrSCSpecUDTErrorEnumCaseV0(this._doc, this._name, this._value);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCSpecUDTErrorEnumCaseV0 encodedSCSpecUDTErrorEnumCaseV0,
  ) {
    stream.writeString(encodedSCSpecUDTErrorEnumCaseV0.doc);
    stream.writeString(encodedSCSpecUDTErrorEnumCaseV0.name);
    XdrUint32.encode(stream, encodedSCSpecUDTErrorEnumCaseV0.value);
  }

  static XdrSCSpecUDTErrorEnumCaseV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    XdrUint32 value = XdrUint32.decode(stream);
    return XdrSCSpecUDTErrorEnumCaseV0(doc, name, value);
  }
}
