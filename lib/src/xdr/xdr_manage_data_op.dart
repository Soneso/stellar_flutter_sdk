// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_string64.dart';

class XdrManageDataOp {

  XdrString64 _dataName;
  XdrString64 get dataName => this._dataName;
  set dataName(XdrString64 value) => this._dataName = value;

  XdrDataValue? _dataValue;
  XdrDataValue? get dataValue => this._dataValue;
  set dataValue(XdrDataValue? value) => this._dataValue = value;

  XdrManageDataOp(this._dataName, this._dataValue);

  static void encode(XdrDataOutputStream stream, XdrManageDataOp encodedManageDataOp) {
    XdrString64.encode(stream, encodedManageDataOp.dataName);
    if (encodedManageDataOp.dataValue != null) {
      stream.writeInt(1);
      XdrDataValue.encode(stream, encodedManageDataOp.dataValue!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrManageDataOp decode(XdrDataInputStream stream) {
    XdrString64 dataName = XdrString64.decode(stream);
    XdrDataValue? dataValue;
    int dataValuePresent = stream.readInt();
    if (dataValuePresent != 0) {
      dataValue = XdrDataValue.decode(stream);
    }
    return XdrManageDataOp(dataName, dataValue);
  }
}
