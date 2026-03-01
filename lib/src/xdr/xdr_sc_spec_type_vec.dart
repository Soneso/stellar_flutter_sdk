// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecTypeVec {
  XdrSCSpecTypeDef _elementType;
  XdrSCSpecTypeDef get elementType => this._elementType;
  set elementType(XdrSCSpecTypeDef value) => this._elementType = value;

  XdrSCSpecTypeVec(this._elementType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeVec encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.elementType);
  }

  static XdrSCSpecTypeVec decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeVec(XdrSCSpecTypeDef.decode(stream));
  }
}
