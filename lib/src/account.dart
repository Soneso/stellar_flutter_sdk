// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'util.dart';
import 'muxed_account.dart';

/// Specifies interface for Account object used in TransactionBuilder.
abstract class TransactionBuilderAccount {
  /// Returns ID associated with this Account.
  String get accountId;

  /// Returns current sequence number ot this Account.
  int get sequenceNumber;

  /// Returns sequence number incremented by one, but does not increment internal counter.
  int get incrementedSequenceNumber;

  // Muxed account object created from this account object.
  MuxedAccount get muxedAccount;

  /// Increments sequence number in this object by one.
  void incrementSequenceNumber();
}

/// Represents an account in Stellar network with it's sequence number.
/// Account object is required to build a [Transaction].
class Account implements TransactionBuilderAccount {
  String _accountId;
  int _mSequenceNumber;
  MuxedAccount _muxedAccount;

  Account(String ed25519AccountId, int sequenceNumber,
      {int muxedAccountMed25519Id}) {
    _accountId = checkNotNull(ed25519AccountId, "keypair cannot be null");
    _mSequenceNumber =
        checkNotNull(sequenceNumber, "sequenceNumber cannot be null");

    _muxedAccount = MuxedAccount(ed25519AccountId, muxedAccountMed25519Id);
  }

  @override
  String get accountId => _accountId;

  @override
  int get sequenceNumber => _mSequenceNumber;

  @override
  MuxedAccount get muxedAccount => _muxedAccount;

  @override
  int get incrementedSequenceNumber => _mSequenceNumber + 1;

  /// Increments sequence number in this account object by one.
  void incrementSequenceNumber() {
    _mSequenceNumber++;
  }
}
