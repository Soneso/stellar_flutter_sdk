// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_udt_struct_field_v0.dart';

class XdrSCSpecUDTStructV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTStructFieldV0> _fields;
  List<XdrSCSpecUDTStructFieldV0> get fields => this._fields;
  set fields(List<XdrSCSpecUDTStructFieldV0> value) => this._fields = value;

  XdrSCSpecUDTStructV0(this._doc, this._lib, this._name, this._fields);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTStructV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);
    int casesSize = encoded.fields.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTStructFieldV0.encode(stream, encoded.fields[i]);
    }
  }

  static XdrSCSpecUDTStructV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();
    int fieldsSize = stream.readInt();
    List<XdrSCSpecUDTStructFieldV0> fields =
        List<XdrSCSpecUDTStructFieldV0>.empty(growable: true);
    for (int i = 0; i < fieldsSize; i++) {
      fields.add(XdrSCSpecUDTStructFieldV0.decode(stream));
    }

    return XdrSCSpecUDTStructV0(doc, lib, name, fields);
  }
}
