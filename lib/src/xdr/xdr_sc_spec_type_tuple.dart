// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecTypeTuple {
  List<XdrSCSpecTypeDef> _valueTypes;
  List<XdrSCSpecTypeDef> get valueTypes => this._valueTypes;
  set valueTypes(List<XdrSCSpecTypeDef> value) => this._valueTypes = value;

  XdrSCSpecTypeTuple(this._valueTypes);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeTuple encoded) {
    int valueTypesSize = encoded.valueTypes.length;
    stream.writeInt(valueTypesSize);
    for (int i = 0; i < valueTypesSize; i++) {
      XdrSCSpecTypeDef.encode(stream, encoded.valueTypes[i]);
    }
  }

  static XdrSCSpecTypeTuple decode(XdrDataInputStream stream) {
    int valueTypesSize = stream.readInt();
    List<XdrSCSpecTypeDef> valTypes = List<XdrSCSpecTypeDef>.empty(
      growable: true,
    );
    for (int i = 0; i < valueTypesSize; i++) {
      valTypes.add(XdrSCSpecTypeDef.decode(stream));
    }
    return XdrSCSpecTypeTuple(valTypes);
  }
}
