// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';

/// Creates and funds a new account with a specified starting balance.
///
/// The CreateAccount operation creates a new account on the Stellar network and
/// funds it with a specified starting balance of native lumens (XLM). The starting
/// balance must be at least the minimum account reserve (currently 1 XLM) to meet
/// the base reserve requirement.
///
/// Use this operation when:
/// - Creating new user accounts in your application
/// - Initializing escrow or multisig accounts
/// - Setting up new service accounts
///
/// Important notes:
/// - The destination account must not already exist on the network
/// - The source account must have sufficient XLM to fund the starting balance
/// - The starting balance must meet the minimum reserve requirement
/// - The operation will fail if the destination account already exists
///
/// Example:
/// ```dart
/// // Create a new account with 10 XLM starting balance
/// var newAccount = KeyPair.random();
/// var createAccount = CreateAccountOperationBuilder(
///   newAccount.accountId,
///   "10.0"
/// ).build();
///
/// // Create account with custom source
/// var createAccountWithSource = CreateAccountOperationBuilder(
///   newAccount.accountId,
///   "10.0"
/// ).setSourceAccount(fundingAccount.accountId).build();
///
/// // Add to transaction
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(createAccount)
///   .build();
/// ```
///
/// See also:
/// - [PaymentOperation] for sending funds to existing accounts
/// - [Operation] for general operation documentation
/// - [Stellar Account Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts)
class CreateAccountOperation extends Operation {
  String _destination;
  String _startingBalance;

  /// Creates a CreateAccount operation.
  ///
  /// Parameters:
  /// - [_destination] - Account ID of the account to be created
  /// - [_startingBalance] - Starting balance in XLM (must meet minimum reserve)
  CreateAccountOperation(this._destination, this._startingBalance);

  /// Amount of XLM to send to the newly created account.
  String get startingBalance => _startingBalance;

  /// Account that is created and funded.
  String get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrAccountID xDestination =
        XdrAccountID(KeyPair.fromAccountId(this.destination).xdrPublicKey);
    XdrBigInt64 startingBalance =
    XdrBigInt64(Util.toXdrBigInt64Amount(this.startingBalance));

    XdrOperationBody body = XdrOperationBody(XdrOperationType.CREATE_ACCOUNT);
    body.createAccountOp = XdrCreateAccountOp(xDestination, startingBalance);
    return body;
  }

  /// Constructs a CreateAccountOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] - XDR CreateAccountOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static CreateAccountOperationBuilder builder(XdrCreateAccountOp op) {
    return CreateAccountOperationBuilder(
        KeyPair.fromXdrPublicKey(op.destination.accountID).accountId,
        Util.fromXdrBigInt64Amount(op.startingBalance.bigInt));
  }
}

/// Builder for constructing CreateAccount operations.
///
/// Provides a fluent interface for building CreateAccount operations with optional
/// parameters. Use this builder to create new accounts with a starting balance.
///
/// Example:
/// ```dart
/// var operation = CreateAccountOperationBuilder(
///   destinationAccountId,
///   "10.0"
/// ).setSourceAccount(sourceAccountId).build();
/// ```
class CreateAccountOperationBuilder {
  String _destination;
  String _startingBalance;
  MuxedAccount? _mSourceAccount;

  /// Creates a CreateAccount operation builder.
  ///
  /// Parameters:
  /// - [_destination] - Account ID of the account to be created
  /// - [_startingBalance] - Starting balance in XLM (must meet minimum reserve)
  CreateAccountOperationBuilder(this._destination, this._startingBalance);

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] - Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  CreateAccountOperationBuilder setSourceAccount(String sourceAccountId) {
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
  CreateAccountOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the CreateAccount operation.
  ///
  /// Returns: Configured CreateAccountOperation instance
  CreateAccountOperation build() {
    CreateAccountOperation operation =
        CreateAccountOperation(_destination, _startingBalance);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
