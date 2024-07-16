// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';

/// Specifies interface for Account object used in TransactionBuilder.
abstract class TransactionBuilderAccount {
  /// Returns ID associated with this Account.
  String get accountId;

  /// Returns current sequence number ot this Account.
  BigInt get sequenceNumber;

  /// Returns sequence number incremented by one, but does not increment internal counter.
  BigInt get incrementedSequenceNumber;

  // Muxed account object created from this account object.
  MuxedAccount get muxedAccount;

  /// Increments sequence number in this object by one.
  void incrementSequenceNumber();
}

/// Represents an account in Stellar network with it's sequence number.
/// Account object is required to build a [Transaction].
class Account implements TransactionBuilderAccount {
  String _accountId;
  BigInt _mSequenceNumber;
  late MuxedAccount _muxedAccount;

  Account(this._accountId, this._mSequenceNumber,
      {int? muxedAccountMed25519Id}) {
    this._muxedAccount = MuxedAccount(this._accountId, muxedAccountMed25519Id);
  }

  static Account fromAccountId(String accountId, BigInt sequenceNumber) {
    MuxedAccount mux = MuxedAccount.fromAccountId(accountId)!;
    return new Account(mux.ed25519AccountId, sequenceNumber,
        muxedAccountMed25519Id: mux.id);
  }

  @override
  String get accountId => _accountId;

  @override
  BigInt get sequenceNumber => _mSequenceNumber;

  @override
  MuxedAccount get muxedAccount => _muxedAccount;

  @override
  BigInt get incrementedSequenceNumber => _mSequenceNumber + BigInt.one;

  /// Increments sequence number in this account object by one.
  void incrementSequenceNumber() {
    _mSequenceNumber = _mSequenceNumber +  BigInt.one;
  }
}
