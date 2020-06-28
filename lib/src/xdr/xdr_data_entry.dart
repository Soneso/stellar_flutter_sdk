// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_account.dart';
import "dart:typed_data";

class XdrDataEntry {
  XdrDataEntry();
  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrString64 _dataName;
  XdrString64 get dataName => this._dataName;
  set dataName(XdrString64 value) => this._dataName = value;

  XdrDataValue _dataValue;
  XdrDataValue get dataValue => this._dataValue;
  set dataValue(XdrDataValue value) => this._dataValue = value;

  XdrDataEntryExt _ext;
  XdrDataEntryExt get ext => this._ext;
  set ext(XdrDataEntryExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrDataEntry encodedDataEntry) {
    XdrAccountID.encode(stream, encodedDataEntry.accountID);
    XdrString64.encode(stream, encodedDataEntry.dataName);
    XdrDataValue.encode(stream, encodedDataEntry.dataValue);
    XdrDataEntryExt.encode(stream, encodedDataEntry.ext);
  }

  static XdrDataEntry decode(XdrDataInputStream stream) {
    XdrDataEntry decodedDataEntry = XdrDataEntry();
    decodedDataEntry.accountID = XdrAccountID.decode(stream);
    decodedDataEntry.dataName = XdrString64.decode(stream);
    decodedDataEntry.dataValue = XdrDataValue.decode(stream);
    decodedDataEntry.ext = XdrDataEntryExt.decode(stream);
    return decodedDataEntry;
  }
}

class XdrDataEntryExt {
  XdrDataEntryExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, XdrDataEntryExt encodedDataEntryExt) {
    stream.writeInt(encodedDataEntryExt.discriminant);
    switch (encodedDataEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrDataEntryExt decode(XdrDataInputStream stream) {
    XdrDataEntryExt decodedDataEntryExt = XdrDataEntryExt();
    int discriminant = stream.readInt();
    decodedDataEntryExt.discriminant = discriminant;
    switch (decodedDataEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedDataEntryExt;
  }
}

class XdrDataValue {
  Uint8List _dataValue;
  XdrDataValue();
  Uint8List get dataValue => this._dataValue;
  set dataValue(Uint8List value) => this._dataValue = value;

  static encode(XdrDataOutputStream stream, XdrDataValue encodedDataValue) {
    int dataValuesize = encodedDataValue.dataValue.length;
    stream.writeInt(dataValuesize);
    stream.write(encodedDataValue.dataValue);
  }

  static XdrDataValue decode(XdrDataInputStream stream) {
    XdrDataValue decodedDataValue = XdrDataValue();
    int dataValuesize = stream.readInt();
    decodedDataValue.dataValue = stream.readBytes(dataValuesize);
    return decodedDataValue;
  }
}
