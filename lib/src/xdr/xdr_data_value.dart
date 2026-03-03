// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrDataValue {
  XdrDataValue(this._dataValue);

  Uint8List _dataValue;
  Uint8List get dataValue => this._dataValue;
  set dataValue(Uint8List value) => this._dataValue = value;

  static void encode(XdrDataOutputStream stream, XdrDataValue encodedDataValue) {
    int dataValueSize = encodedDataValue.dataValue.length;
    stream.writeInt(dataValueSize);
    stream.write(encodedDataValue.dataValue);
  }

  static XdrDataValue decode(XdrDataInputStream stream) {
    int dataValueSize = stream.readInt();
    return XdrDataValue(stream.readBytes(dataValueSize));
  }
}
