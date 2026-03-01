// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_udt_error_enum_case_v0.dart';

class XdrSCSpecUDTErrorEnumV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTErrorEnumCaseV0> _cases;
  List<XdrSCSpecUDTErrorEnumCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTErrorEnumCaseV0> value) => this._cases = value;

  XdrSCSpecUDTErrorEnumV0(this._doc, this._lib, this._name, this._cases);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTErrorEnumV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTErrorEnumCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTErrorEnumV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTErrorEnumCaseV0> cases =
        List<XdrSCSpecUDTErrorEnumCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTErrorEnumCaseV0.decode(stream));
    }

    return XdrSCSpecUDTErrorEnumV0(doc, lib, name, cases);
  }
}
