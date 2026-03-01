// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecTypeResult {
  XdrSCSpecTypeDef _okType;
  XdrSCSpecTypeDef get okType => this._okType;
  set okType(XdrSCSpecTypeDef value) => this._okType = value;

  XdrSCSpecTypeDef _errorType;
  XdrSCSpecTypeDef get errorType => this._errorType;
  set errorType(XdrSCSpecTypeDef value) => this._errorType = value;

  XdrSCSpecTypeResult(this._okType, this._errorType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeResult encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.okType);
    XdrSCSpecTypeDef.encode(stream, encoded.errorType);
  }

  static XdrSCSpecTypeResult decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeResult(
        XdrSCSpecTypeDef.decode(stream), XdrSCSpecTypeDef.decode(stream));
  }
}
