// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecTypeOption {
  XdrSCSpecTypeDef _valueType;
  XdrSCSpecTypeDef get valueType => this._valueType;
  set valueType(XdrSCSpecTypeDef value) => this._valueType = value;

  XdrSCSpecTypeOption(this._valueType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeOption encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.valueType);
  }

  static XdrSCSpecTypeOption decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeOption(XdrSCSpecTypeDef.decode(stream));
  }
}
