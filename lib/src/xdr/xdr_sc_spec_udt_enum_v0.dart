// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_udt_enum_case_v0.dart';

class XdrSCSpecUDTEnumV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTEnumCaseV0> _cases;
  List<XdrSCSpecUDTEnumCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTEnumCaseV0> value) => this._cases = value;

  XdrSCSpecUDTEnumV0(this._doc, this._lib, this._name, this._cases);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTEnumV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTEnumCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTEnumV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTEnumCaseV0> cases =
        List<XdrSCSpecUDTEnumCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTEnumCaseV0.decode(stream));
    }

    return XdrSCSpecUDTEnumV0(doc, lib, name, cases);
  }
}
