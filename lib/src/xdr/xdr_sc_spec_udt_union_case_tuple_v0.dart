// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecUDTUnionCaseTupleV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecTypeDef> _type;
  List<XdrSCSpecTypeDef> get type => this._type;
  set type(List<XdrSCSpecTypeDef> value) => this._type = value;

  XdrSCSpecUDTUnionCaseTupleV0(this._doc, this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseTupleV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    int typeSize = encoded.type.length;
    stream.writeInt(typeSize);
    for (int i = 0; i < typeSize; i++) {
      XdrSCSpecTypeDef.encode(stream, encoded.type[i]);
    }
  }

  static XdrSCSpecUDTUnionCaseTupleV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    int typeSize = stream.readInt();
    List<XdrSCSpecTypeDef> type = List<XdrSCSpecTypeDef>.empty(growable: true);
    for (int i = 0; i < typeSize; i++) {
      type.add(XdrSCSpecTypeDef.decode(stream));
    }
    return XdrSCSpecUDTUnionCaseTupleV0(doc, name, type);
  }
}
