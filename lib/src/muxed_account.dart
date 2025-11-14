// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_data_io.dart';
import 'dart:typed_data';

/// Represents a muxed account for transaction multiplexing.
///
/// Muxed accounts (introduced in CAP-27) allow a single Stellar account to be
/// subdivided into multiple virtual accounts identified by a 64-bit ID. This
/// enables exchanges and payment processors to use a single pooled account for
/// multiple users without requiring separate on-chain accounts.
///
/// Address formats:
/// - Standard account: G... (56 characters, Ed25519 public key)
/// - Muxed account: M... (69 characters, includes account + ID)
///
/// Use cases:
/// - Exchange deposit addresses for multiple customers
/// - Payment processing with memo-less transfers
/// - Simplified account management for custodial services
///
/// Protocol specification:
/// - [CAP-27](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md)
///
/// Example:
/// ```dart
/// // Create from standard account (no multiplexing)
/// MuxedAccount account1 = MuxedAccount("GDJK...", null);
///
/// // Create with ID for multiplexing
/// MuxedAccount account2 = MuxedAccount("GDJK...", 12345);
///
/// // Parse from M... address
/// MuxedAccount? account3 = MuxedAccount.fromAccountId("MAAAAA...");
///
/// // Use in transactions
/// Transaction tx = TransactionBuilder(sourceAccount)
///   .addOperation(
///     PaymentOperationBuilder(
///       account2.accountId, // Uses M... address
///       Asset.native(),
///       "100"
///     ).build()
///   )
///   .build();
/// ```
///
/// Important notes:
/// - The underlying Ed25519 account must exist on the ledger
/// - The ID is only used for routing within applications
/// - Not all operations support muxed accounts
///
/// See also:
/// - [KeyPair] for standard account management
/// - [Transaction] for using muxed accounts in operations
class MuxedAccount {
  late String _accountId;
  String _ed25519AccountId;
  int? _id;

  /// Creates a MuxedAccount with an Ed25519 account ID and optional muxing ID.
  ///
  /// Parameters:
  /// - [_ed25519AccountId]: The underlying Ed25519 account ID (G... address)
  /// - [_id]: Optional 64-bit multiplexing ID, or null for standard accounts
  MuxedAccount(this._ed25519AccountId, this._id) {
    _accountId = "0";
  }

  /// Creates a MuxedAccount from any account ID format.
  ///
  /// Automatically detects and parses:
  /// - M... addresses (muxed with ID)
  /// - G... addresses (standard Ed25519)
  ///
  /// Parameters:
  /// - [accountId]: The account ID string (M... or G...)
  ///
  /// Returns: A [MuxedAccount] or null if format is invalid
  ///
  /// Example:
  /// ```dart
  /// MuxedAccount? muxed = MuxedAccount.fromAccountId("MAAAAA...");
  /// MuxedAccount? standard = MuxedAccount.fromAccountId("GDJK...");
  /// ```
  static MuxedAccount? fromAccountId(String accountId) {
    if (accountId.startsWith('M')) {
      return fromMed25519AccountId(accountId);
    } else if (accountId.startsWith('G')) {
      return MuxedAccount(accountId, null);
    }
    return null;
  }

  /// Creates a MuxedAccount from a muxed Ed25519 address (M...).
  ///
  /// Decodes the muxed address to extract both the underlying Ed25519
  /// account and the 64-bit multiplexing ID.
  ///
  /// Parameters:
  /// - [med25519AccountId]: The M... address string
  ///
  /// Returns: A [MuxedAccount] with the decoded ID
  ///
  /// Example:
  /// ```dart
  /// MuxedAccount muxed = MuxedAccount.fromMed25519AccountId(
  ///   "MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6"
  /// );
  /// print(muxed.id); // 123
  /// print(muxed.ed25519AccountId); // "GDJK..."
  /// ```
  static MuxedAccount fromMed25519AccountId(String med25519AccountId) {
    XdrMuxedAccount xdrMuxAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519);
    Uint8List bytes = StrKey.decodeStellarMuxedAccountId(med25519AccountId);
    XdrMuxedAccountMed25519 muxMed25519 =
        XdrMuxedAccountMed25519.decodeInverted(XdrDataInputStream(bytes));
    xdrMuxAccount.med25519 = muxMed25519;
    return fromXdr(xdrMuxAccount);
  }

  /// Gets the underlying Ed25519 account ID (G... address).
  ///
  /// Returns: The base account ID without muxing information
  String get ed25519AccountId => _ed25519AccountId;

  /// Gets the 64-bit multiplexing ID.
  ///
  /// Returns: The ID if this is a muxed account, null for standard accounts
  int? get id => _id;

  /// Gets the full account ID in the appropriate format.
  ///
  /// Returns:
  /// - M... address if this is a muxed account with an ID
  /// - G... address if this is a standard account
  ///
  /// Example:
  /// ```dart
  /// MuxedAccount muxed = MuxedAccount("GDJK...", 123);
  /// print(muxed.accountId); // "MAAAAA..." (M address)
  ///
  /// MuxedAccount standard = MuxedAccount("GDJK...", null);
  /// print(standard.accountId); // "GDJK..." (G address)
  /// ```
  String get accountId {
    if (_accountId == "0") {
      XdrMuxedAccount xdrMuxedAccount = toXdr();
      if (xdrMuxedAccount.discriminant ==
          XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519) {
        XdrDataOutputStream xdrOutputStream = new XdrDataOutputStream();
        XdrMuxedAccountMed25519.encodeInverted(
            xdrOutputStream, xdrMuxedAccount.med25519!);
        Uint8List bytes = Uint8List.fromList(xdrOutputStream.bytes);
        _accountId = StrKey.encodeStellarMuxedAccountId(bytes);
      } else if (xdrMuxedAccount.discriminant ==
          XdrCryptoKeyType.KEY_TYPE_ED25519) {
        _accountId = _ed25519AccountId;
      }
    }
    return _accountId;
  }

  /// Converts this muxed account to XDR format.
  ///
  /// Returns: [XdrMuxedAccount] for protocol serialization
  XdrMuxedAccount toXdr() {
    if (_id == null) {
      return KeyPair.fromAccountId(_ed25519AccountId).xdrMuxedAccount;
    } else {
      XdrMuxedAccount xdrMuxAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519);
      XdrUint256 uint256 = new XdrUint256(StrKey.decodeStellarAccountId(_ed25519AccountId));
      XdrUint64 id64 = XdrUint64(_id!);
      XdrMuxedAccountMed25519 muxMed25519 = XdrMuxedAccountMed25519(id64, uint256);
      xdrMuxAccount.med25519 = muxMed25519;
      return xdrMuxAccount;
    }
  }

  /// Creates a MuxedAccount from XDR format.
  ///
  /// Parameters:
  /// - [xdrMuxedAccount]: The XDR muxed account structure
  ///
  /// Returns: A [MuxedAccount] instance
  static MuxedAccount fromXdr(XdrMuxedAccount xdrMuxedAccount) {
    String? ed25519AccountId;
    int? id;
    if (xdrMuxedAccount.discriminant ==
        XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519) {
      ed25519AccountId = StrKey.encodeStellarAccountId(
          xdrMuxedAccount.med25519!.ed25519.uint256);
      id = xdrMuxedAccount.med25519!.id.uint64;
    } else if (xdrMuxedAccount.discriminant ==
        XdrCryptoKeyType.KEY_TYPE_ED25519) {
      ed25519AccountId =
          StrKey.encodeStellarAccountId(xdrMuxedAccount.ed25519!.uint256);
    }
    return MuxedAccount(ed25519AccountId!, id);
  }
}
