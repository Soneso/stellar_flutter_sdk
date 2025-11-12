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

/// Sets, modifies, or deletes a data entry on an account.
///
/// ManageData allows accounts to store arbitrary key-value pairs on the ledger.
/// Each account can have multiple data entries, each identified by a unique name.
/// Data entries can be used to store application-specific information, metadata,
/// or any other data that needs to be publicly verifiable on the blockchain.
///
/// Use this operation when:
/// - Storing metadata or configuration on an account
/// - Recording application-specific data
/// - Creating verifiable timestamps or records
/// - Implementing decentralized identity features
///
/// Important notes:
/// - Data entry names must be unique per account (max 64 bytes)
/// - Data values can be up to 64 bytes
/// - Setting value to null deletes the data entry
/// - Each data entry increases account reserve requirement
/// - Data is public and permanently recorded on the ledger
///
/// Example:
/// ```dart
/// // Add or update a data entry
/// var data = Uint8List.fromList(utf8.encode("myValue"));
/// var setData = ManageDataOperationBuilder(
///   "myKey",
///   data
/// ).build();
///
/// // Delete a data entry (set value to null)
/// var deleteData = ManageDataOperationBuilder(
///   "myKey",
///   null
/// ).build();
///
/// // Store JSON metadata
/// var jsonData = Uint8List.fromList(
///   utf8.encode('{"version":"1.0","type":"user"}')
/// );
/// var metadata = ManageDataOperationBuilder(
///   "app:metadata",
///   jsonData
/// ).setSourceAccount(accountId).build();
/// ```
///
/// See also:
/// - [Operation] for general operation documentation
/// - [Stellar Data Entry Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#data-entry)
class ManageDataOperation extends Operation {
  String _name;
  Uint8List? _value;

  /// Creates a ManageData operation.
  ///
  /// Parameters:
  /// - [_name] - Name of the data entry (max 64 bytes)
  /// - [value] - Data value (max 64 bytes, null to delete)
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

  /// Constructs a ManageDataOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] - XDR ManageDataOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static ManageDataOperationBuilder builder(XdrManageDataOp op) {
    Uint8List? value;
    if (op.dataValue != null) {
      value = op.dataValue!.dataValue;
    }

    return ManageDataOperationBuilder(op.dataName.string64, value);
  }
}

/// Builder for constructing ManageData operations.
///
/// Provides a fluent interface for building ManageData operations with optional
/// parameters. Use this builder to set, modify, or delete data entries.
///
/// Example:
/// ```dart
/// // Set or update data
/// var setData = ManageDataOperationBuilder(
///   "myKey",
///   Uint8List.fromList(utf8.encode("value"))
/// ).build();
///
/// // Delete data
/// var deleteData = ManageDataOperationBuilder("myKey", null).build();
/// ```
class ManageDataOperationBuilder {
  String _name;
  Uint8List? _value;
  MuxedAccount? _mSourceAccount;

  /// Creates a ManageData operation builder.
  ///
  /// Parameters:
  /// - [_name] - Name of the data entry (max 64 bytes)
  /// - [value] - Data value (max 64 bytes, null to delete entry)
  ManageDataOperationBuilder(this._name, Uint8List? value) {
    this._value = value;
  }

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] - Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  ManageDataOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount] - Muxed account to use as operation source
  ///
  /// Returns: This builder instance for method chaining
  ManageDataOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the ManageData operation.
  ///
  /// Returns: Configured ManageDataOperation instance
  ManageDataOperation build() {
    ManageDataOperation operation = new ManageDataOperation(_name, _value);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
