// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'util.dart';

/// Network class is used to specify which Stellar network you want to use.
/// Each network has a <code>networkPassphrase</code> which is hashed to
/// every transaction id.

class Network {
  static final Network PUBLIC =
      new Network("Public Global Stellar Network ; September 2015");
  static final Network TESTNET =
      new Network("Test SDF Network ; September 2015");

  String _networkPassphrase;

  /// Creates a new Network object to represent a network with a given [networkPassphrase].
  Network(String networkPassphrase) {
    this._networkPassphrase =
        checkNotNull(networkPassphrase, "networkPassphrase cannot be null");
  }

  /// Returns the network passphrase of this network.
  String get networkPassphrase => _networkPassphrase;

  /// Returns the network id (SHA-256 hashed networkPassphrase).
  Uint8List get networkId => Util.hash(utf8.encode(this.networkPassphrase));
}
