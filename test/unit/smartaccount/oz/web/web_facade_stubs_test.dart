// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/browser_webauthn_provider.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/indexed_db_storage_adapter.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/local_storage_adapter.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_storage_adapter.dart';

void main() {
  group('BrowserWebAuthnProvider stub', () {
    test('test_browser_webauthn_provider_stub_construction_does_not_throw', () {
      // why: KMP `JsWebAuthnGuardTest` rule — construction never throws,
      // input validation occurs at invocation time.
      expect(
        () => BrowserWebAuthnProvider(
          rpId: 'example.com',
          rpName: 'Example RP',
        ),
        returnsNormally,
      );
    });

    test('test_browser_webauthn_provider_stub_register_throws_unsupported_error',
        () async {
      final provider = BrowserWebAuthnProvider(
        rpId: 'example.com',
        rpName: 'Example RP',
      );
      await expectLater(
        provider.register(
          challenge: Uint8List.fromList(const <int>[1, 2, 3]),
          userId: Uint8List.fromList(const <int>[4, 5, 6]),
          userName: 'alice@example.com',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
        'test_browser_webauthn_provider_stub_authenticate_throws_unsupported_error',
        () async {
      final provider = BrowserWebAuthnProvider(
        rpId: 'example.com',
        rpName: 'Example RP',
      );
      await expectLater(
        provider.authenticate(
          challenge: Uint8List.fromList(const <int>[7, 8, 9]),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('LocalStorageAdapter stub', () {
    test('test_local_storage_adapter_stub_construction_does_not_throw', () {
      expect(() => LocalStorageAdapter(), returnsNormally);
      expect(
        () => LocalStorageAdapter(keyPrefix: 'custom_'),
        returnsNormally,
      );
    });

    test('test_local_storage_adapter_stub_save_throws_unsupported_error',
        () async {
      final adapter = LocalStorageAdapter();
      final credential = StoredCredential(
        credentialId: 'abc',
        publicKey: Uint8List.fromList(const <int>[0x04, 0x01, 0x02]),
      );
      await expectLater(
        adapter.save(credential),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('IndexedDBStorageAdapter stub', () {
    test('test_indexed_db_storage_adapter_stub_construction_does_not_throw',
        () {
      expect(() => IndexedDBStorageAdapter(), returnsNormally);
      expect(
        () => IndexedDBStorageAdapter(dbName: 'custom_db'),
        returnsNormally,
      );
    });

    test('test_indexed_db_storage_adapter_stub_save_throws_unsupported_error',
        () async {
      final adapter = IndexedDBStorageAdapter();
      final credential = StoredCredential(
        credentialId: 'abc',
        publicKey: Uint8List.fromList(const <int>[0x04, 0x01, 0x02]),
      );
      await expectLater(
        adapter.save(credential),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('test_indexed_db_storage_adapter_stub_close_no_op', () async {
      final adapter = IndexedDBStorageAdapter();
      // why: close() on the stub is a no-op so cross-target shutdown
      // code can call it unconditionally.
      await expectLater(adapter.close(), completes);
      // Calling close repeatedly stays safe.
      await expectLater(adapter.close(), completes);
    });
  });
}
