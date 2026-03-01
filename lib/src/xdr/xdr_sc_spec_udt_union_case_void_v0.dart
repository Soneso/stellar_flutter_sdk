// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCSpecUDTUnionCaseVoidV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecUDTUnionCaseVoidV0(this._doc, this._name);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseVoidV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
  }

  static XdrSCSpecUDTUnionCaseVoidV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecUDTUnionCaseVoidV0(doc, name);
  }
}
