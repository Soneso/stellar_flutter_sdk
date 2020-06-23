// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'dart:typed_data';
import 'util.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_data_entry.dart';

/// Represents <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html#manage-data" target="_blank">ManageData</a> operation.
/// See: <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html" target="_blank">List of Operations</a>.
class ManageDataOperation extends Operation {
  String _name;
  Uint8List _value;

  ManageDataOperation(String name, Uint8List value) {
    this._name = checkNotNull(name, "name cannot be null");
    this._value = value;
  }

  /// The name of the data value
  String get name => _name;

  /// Data value
  Uint8List get value => _value;

  @override
  XdrOperationBody toOperationBody() {
    XdrManageDataOp op = new XdrManageDataOp();
    XdrString64 name = new XdrString64();
    name.string64 = this.name;
    op.dataName = name;

    if (value != null) {
      XdrDataValue dataValue = new XdrDataValue();
      dataValue.dataValue = this.value;
      op.dataValue = dataValue;
    }

    XdrOperationBody body = new XdrOperationBody();
    body.discriminant = XdrOperationType.MANAGE_DATA;
    body.manageDataOp = op;

    return body;
  }

  /// Construct a new ManageOffer builder from a ManageDataOp XDR.
  static ManageDataOperationBuilder builder(XdrManageDataOp op) {
    Uint8List value;
    if (op.dataValue != null) {
      value = op.dataValue.dataValue;
    }

    return ManageDataOperationBuilder(op.dataName.string64, value);
  }
}

class ManageDataOperationBuilder {
  String _name;
  Uint8List _value;
  String _mSourceAccount;

  /// Creates a new ManageData builder. If you want to delete data entry pass null as a <code>value</code> param.
  ManageDataOperationBuilder(String name, Uint8List value) {
    this._name = checkNotNull(name, "name cannot be null");
    this._value = value;
  }

  /// Sets the source account for this operation.
  ManageDataOperationBuilder setSourceAccount(String sourceAccount) {
    _mSourceAccount =
        checkNotNull(sourceAccount, "sourceAccount cannot be null");
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