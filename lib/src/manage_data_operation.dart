// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'dart:typed_data';
import 'util.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_data_entry.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#manage-data" target="_blank">ManageData</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>.
class ManageDataOperation extends Operation {
  String _name;
  Uint8List? _value;

  ManageDataOperation(this._name, Uint8List? value) {
    this._value = value;
  }

  /// The name of the data value
  String get name => _name;

  /// Data value
  Uint8List? get value => _value;

  @override
  XdrOperationBody toOperationBody() {
    XdrString64 name = new XdrString64(this.name);
    XdrDataValue? xDataValue;
    if (this.value != null) {
      xDataValue = new XdrDataValue(this.value!);
    }

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.MANAGE_DATA);
    body.manageDataOp = new XdrManageDataOp(name, xDataValue);

    return body;
  }

  /// Construct a new ManageOffer builder from a ManageDataOp XDR.
  static ManageDataOperationBuilder builder(XdrManageDataOp op) {
    Uint8List? value;
    if (op.dataValue != null) {
      value = op.dataValue!.dataValue;
    }

    return ManageDataOperationBuilder(op.dataName.string64, value);
  }
}

class ManageDataOperationBuilder {
  String _name;
  Uint8List? _value;
  MuxedAccount? _mSourceAccount;

  /// Creates a new ManageData builder. If you want to delete data entry pass null as a <code>value</code> param.
  ManageDataOperationBuilder(this._name, Uint8List? value) {
    this._value = value;
  }

  /// Sets the source account for this operation.
  ManageDataOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ManageDataOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds a ManageDataOperation.
  ManageDataOperation build() {
    ManageDataOperation operation = new ManageDataOperation(_name, _value);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
