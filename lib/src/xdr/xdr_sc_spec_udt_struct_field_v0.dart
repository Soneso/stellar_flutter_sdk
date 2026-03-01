// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecUDTStructFieldV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeDef _type;
  XdrSCSpecTypeDef get type => this._type;
  set type(XdrSCSpecTypeDef value) => this._type = value;

  XdrSCSpecUDTStructFieldV0(this._doc, this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTStructFieldV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    XdrSCSpecTypeDef.encode(stream, encoded.type);
  }

  static XdrSCSpecUDTStructFieldV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecUDTStructFieldV0(
        doc, name, XdrSCSpecTypeDef.decode(stream));
  }
}
