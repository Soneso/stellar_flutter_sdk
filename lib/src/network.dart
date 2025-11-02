// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'util.dart';

/// Represents a Stellar network (public, testnet, or custom).
///
/// The Network class specifies which Stellar network to use for transactions.
/// Each network has a unique network passphrase that is hashed into every
/// transaction hash, preventing transactions from one network being replayed
/// on another network (replay attack protection).
///
/// Available networks:
/// - [PUBLIC]: The production Stellar network (mainnet)
/// - [TESTNET]: The test network for development and testing
/// - [FUTURENET]: The network for testing upcoming protocol features
///
/// Network passphrases are critical for security:
/// - Transactions signed for one network cannot be submitted to another
/// - The passphrase is hashed into the transaction signature
/// - Always verify you're using the correct network before signing
///
/// Example usage:
/// ```dart
/// // Sign for testnet (development)
/// transaction.sign(keyPair, Network.TESTNET);
///
/// // Sign for mainnet (production)
/// transaction.sign(keyPair, Network.PUBLIC);
///
/// // Create custom network (for standalone/private networks)
/// Network customNetwork = Network("Custom Network ; January 2024");
/// transaction.sign(keyPair, customNetwork);
/// ```
///
/// Security warnings:
/// - NEVER use TESTNET credentials on PUBLIC network
/// - NEVER use PUBLIC network for testing
/// - Always double-check network before signing with real funds
/// - Test thoroughly on TESTNET before deploying to PUBLIC
///
/// See also:
/// - [Transaction.sign] for signing with a specific network
/// - [Transaction.hash] to compute network-specific transaction hash
/// - [Stellar Networks Documentation](https://developers.stellar.org/docs/learn/fundamentals/networks)
class Network {
  /// The production Stellar network (mainnet).
  ///
  /// Use this for real transactions with actual funds. Transactions on this
  /// network have real economic value and cannot be reversed.
  static final Network PUBLIC =
      new Network("Public Global Stellar Network ; September 2015");

  /// The test network for development and testing.
  ///
  /// Use this for development and testing. Test XLM can be obtained from
  /// friendbot and has no real value. Always test your application thoroughly
  /// on TESTNET before deploying to PUBLIC.
  static final Network TESTNET =
      new Network("Test SDF Network ; September 2015");

  /// The future network for testing upcoming protocol features.
  ///
  /// This network is used to test protocol changes before they are released
  /// to TESTNET and PUBLIC. It may be reset periodically.
  static final Network FUTURENET =
      new Network("Test SDF Future Network ; October 2022");

  String _networkPassphrase;

  /// Creates a new Network object to represent a network with a given [networkPassphrase].
  Network(this._networkPassphrase);

  /// Returns the network passphrase of this network.
  String get networkPassphrase => _networkPassphrase;

  /// Returns the network id (SHA-256 hashed networkPassphrase).
  Uint8List? get networkId =>
      Util.hash(Uint8List.fromList(utf8.encode(this.networkPassphrase)));
}
