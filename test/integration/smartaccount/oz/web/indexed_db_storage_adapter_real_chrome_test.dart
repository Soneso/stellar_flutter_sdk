// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
//
// Real-browser integration test for the IndexedDB-backed adapter.
// Skipped during default CI runs; included in the headless-Chrome web
// integration suite via the `web-integration` tag.

@Tags(['web-integration'])
@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/indexed_db_storage_adapter.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_storage_adapter.dart';

void main() {
  group('IndexedDBStorageAdapter (real Chrome)', () {
    late IndexedDBStorageAdapter adapter;

    setUp(() async {
      adapter = IndexedDBStorageAdapter(dbName: 'integration_test_db');
      await adapter.clear();
    });

    tearDown(() async {
      await adapter.deleteDatabase();
    });

    test('test_real_indexeddb_round_trip', () async {
      final cred = StoredCredential(
        credentialId: 'integration-real-idb-1',
        publicKey: Uint8List.fromList(<int>[
          0x04, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
        ]),
      );
      await adapter.save(cred);
      final loaded = await adapter.get(cred.credentialId);
      expect(loaded?.credentialId, cred.credentialId);
      expect(loaded?.publicKey, cred.publicKey);
    });
  });
}
