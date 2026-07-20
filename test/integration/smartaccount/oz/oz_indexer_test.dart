// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Live tests against the default testnet indexer (Mercury). They verify the
// endpoint is up and speaks the wire format the SDK expects: the health
// probe, the stats route, and the lookup routes with their response DTO
// shapes.
//
// Lookups use freshly generated identifiers (a random credential ID, a
// random keypair's G-address, a random C-address), which are valid by
// construction and cannot collide with indexed data, so the expected results
// are deterministic: well-formed empty responses for the lookup routes and
// the typed failure for an unknown contract.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final random = Random.secure();

  Uint8List randomBytes(int length) => Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)));

  OZIndexerClient client() {
    final client =
        OZIndexerClient.forNetwork(Network.TESTNET.networkPassphrase);
    expect(client, isNotNull, reason: 'testnet must have a default indexer');
    return client!;
  }

  test('default indexer is healthy',
      timeout: const Timeout(Duration(minutes: 1)), () async {
    final indexer = client();
    try {
      expect(await indexer.isHealthy(), isTrue,
          reason: 'the default testnet indexer must report healthy');
    } finally {
      await indexer.close();
    }
  });

  test('stats returns live data', timeout: const Timeout(Duration(minutes: 1)),
      () async {
    final indexer = client();
    try {
      final stats = (await indexer.getStats()).stats;
      expect(stats.totalEvents, greaterThan(0),
          reason: 'the indexer must have processed events, '
              'got: ${stats.totalEvents}');
      expect(stats.uniqueContracts, greaterThan(0),
          reason: 'the indexer must have indexed contracts, '
              'got: ${stats.uniqueContracts}');
    } finally {
      await indexer.close();
    }
  });

  test('lookup by unknown credential ID returns a well-formed empty result',
      timeout: const Timeout(Duration(minutes: 1)), () async {
    final indexer = client();
    try {
      // The client takes a base64url credential ID and queries the API by
      // its hex form, which the response echoes.
      final credentialBytes = randomBytes(16);
      final credentialIdBase64url =
          base64UrlEncode(credentialBytes).replaceAll('=', '');
      final response = await indexer.lookupByCredentialId(credentialIdBase64url);
      expect(response.credentialId, Util.bytesToHex(credentialBytes),
          reason: 'response must echo the queried credential ID as hex');
      expect(response.count, 0);
      expect(response.contracts, isEmpty);
    } finally {
      await indexer.close();
    }
  });

  test('lookup by unknown address returns a well-formed empty result',
      timeout: const Timeout(Duration(minutes: 1)), () async {
    final indexer = client();
    try {
      final address = KeyPair.random().accountId;
      final response = await indexer.lookupByAddress(address);
      expect(response.signerAddress, address,
          reason: 'response must echo the queried address');
      expect(response.count, 0);
      expect(response.contracts, isEmpty);
    } finally {
      await indexer.close();
    }
  });

  test('get unknown contract throws the typed indexer error',
      timeout: const Timeout(Duration(minutes: 1)), () async {
    final indexer = client();
    try {
      final contractId = StrKey.encodeContractId(randomBytes(32));
      Object? thrown;
      try {
        await indexer.getContract(contractId);
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isA<SmartAccountIndexerRequestFailed>(),
          reason: 'an unindexed contract must surface the typed indexer '
              'failure, got: $thrown');
      expect((thrown as SmartAccountIndexerRequestFailed).message,
          contains('404'),
          reason: 'the failure must be the service not-found, not a '
              'transport error');
    } finally {
      await indexer.close();
    }
  });
}
