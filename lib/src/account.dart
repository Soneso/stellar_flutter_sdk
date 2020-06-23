// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'util.dart';


/// Specifies interface for Account object used in TransactionBuilder.
abstract class TransactionBuilderAccount {

  /// Returns ID associated with this Account.
  String get accountId;

  /// Returns keypair associated with this Account.
  KeyPair get keypair;

  /// Returns current sequence number ot this Account.
  int get sequenceNumber;

  /// Returns sequence number incremented by one, but does not increment internal counter.
  int get incrementedSequenceNumber;

  /// Increments sequence number in this object by one.
  void incrementSequenceNumber();
}

/// Represents an account in Stellar network with it's sequence number.
/// Account object is required to build a [Transaction].
class Account implements TransactionBuilderAccount {

  KeyPair _mKeyPair;
  int _mSequenceNumber;

  Account(KeyPair keypair, int sequenceNumber) {
    _mKeyPair = checkNotNull(keypair, "keypair cannot be null");
    _mSequenceNumber =
        checkNotNull(sequenceNumber, "sequenceNumber cannot be null");
  }

  @override
  String get accountId => _mKeyPair.accountId;

  @override
  KeyPair get keypair => _mKeyPair;

  @override
  int get sequenceNumber => _mSequenceNumber;

  @override
  int get incrementedSequenceNumber => _mSequenceNumber + 1;

  /// Increments sequence number in this account object by one.
  void incrementSequenceNumber() {
    _mSequenceNumber++;
  }
}
