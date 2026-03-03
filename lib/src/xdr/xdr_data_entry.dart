// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_entry_ext.dart';
import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_string64.dart';

class XdrDataEntry {
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

  XdrDataEntry(this._accountID, this._dataName, this._dataValue, this._ext);

  static void encode(
    XdrDataOutputStream stream,
    XdrDataEntry encodedDataEntry,
  ) {
    XdrAccountID.encode(stream, encodedDataEntry.accountID);
    XdrString64.encode(stream, encodedDataEntry.dataName);
    XdrDataValue.encode(stream, encodedDataEntry.dataValue);
    XdrDataEntryExt.encode(stream, encodedDataEntry.ext);
  }

  static XdrDataEntry decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrString64 dataName = XdrString64.decode(stream);
    XdrDataValue dataValue = XdrDataValue.decode(stream);
    XdrDataEntryExt ext = XdrDataEntryExt.decode(stream);
    return XdrDataEntry(accountID, dataName, dataValue, ext);
  }
}
