// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecTypeMap {
  XdrSCSpecTypeDef _keyType;
  XdrSCSpecTypeDef get keyType => this._keyType;
  set keyType(XdrSCSpecTypeDef value) => this._keyType = value;

  XdrSCSpecTypeDef _valueType;
  XdrSCSpecTypeDef get valueType => this._valueType;
  set valueType(XdrSCSpecTypeDef value) => this._valueType = value;

  XdrSCSpecTypeMap(this._keyType, this._valueType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeMap encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.keyType);
    XdrSCSpecTypeDef.encode(stream, encoded.valueType);
  }

  static XdrSCSpecTypeMap decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeMap(
        XdrSCSpecTypeDef.decode(stream), XdrSCSpecTypeDef.decode(stream));
  }
}
