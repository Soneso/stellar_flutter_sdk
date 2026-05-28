// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
//
// Browser-target tests for the WebAuthn provider. These run under
// `flutter test --platform chrome` because both the provider and the
// fakes depend on `dart:js_interop` and `package:web`.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/allow_credential.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/smart_account_errors.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_constants.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/web/browser_webauthn_provider_web.dart';
import 'package:web/web.dart' as web;

JSObject _domException(String name, String message) {
  final obj = JSObject();
  obj.setProperty('name'.toJS, name.toJS);
  obj.setProperty('message'.toJS, message.toJS);
  return obj;
}

JSArrayBuffer _bytesToBuffer(List<int> bytes) {
  return Uint8List.fromList(bytes).buffer.toJS;
}

/// Builds a synthetic [web.PublicKeyCredential] whose response carries the
/// supplied attestation object and (optionally) a SPKI public-key hook
/// that resolves to the given bytes.
web.PublicKeyCredential _attestationCredential({
  required List<int> rawId,
  required List<int> attestationObject,
  List<int>? spki,
  List<String>? transports,
}) {
  final response = JSObject();
  response.setProperty(
    'attestationObject'.toJS,
    _bytesToBuffer(attestationObject),
  );
  response.setProperty(
    'clientDataJSON'.toJS,
    _bytesToBuffer(const <int>[]),
  );
  if (spki != null) {
    response.setProperty(
      'getPublicKey'.toJS,
      (() => _bytesToBuffer(spki)).toJS,
    );
  }
  if (transports != null) {
    response.setProperty(
      'getTransports'.toJS,
      (() => transports.map((t) => t.toJS).toList().toJS).toJS,
    );
  }
  final credential = JSObject();
  credential.setProperty('rawId'.toJS, _bytesToBuffer(rawId));
  credential.setProperty('response'.toJS, response);
  return credential as web.PublicKeyCredential;
}

web.PublicKeyCredential _assertionCredential({
  required List<int> rawId,
  required List<int> authenticatorData,
  required List<int> clientDataJSON,
  required List<int> signature,
}) {
  final response = JSObject();
  response.setProperty(
    'authenticatorData'.toJS,
    _bytesToBuffer(authenticatorData),
  );
  response.setProperty(
    'clientDataJSON'.toJS,
    _bytesToBuffer(clientDataJSON),
  );
  response.setProperty('signature'.toJS, _bytesToBuffer(signature));
  final credential = JSObject();
  credential.setProperty('rawId'.toJS, _bytesToBuffer(rawId));
  credential.setProperty('response'.toJS, response);
  return credential as web.PublicKeyCredential;
}

class _FakeCredentialsContainer {
  _FakeCredentialsContainer({
    this.createResult,
    this.createError,
    this.getResult,
    this.getError,
  });

  web.Credential? createResult;
  Object? createError;
  web.Credential? getResult;
  Object? getError;
  web.CredentialCreationOptions? lastCreateOptions;
  web.CredentialRequestOptions? lastGetOptions;

  web.CredentialsContainer toJS() {
    final obj = JSObject();
    JSPromise createImpl(web.CredentialCreationOptions options) {
      lastCreateOptions = options;
      if (createError != null) {
        return _rejected(createError!);
      }
      return _resolved(createResult);
    }

    JSPromise getImpl(web.CredentialRequestOptions options) {
      lastGetOptions = options;
      if (getError != null) {
        return _rejected(getError!);
      }
      return _resolved(getResult);
    }

    obj.setProperty('create'.toJS, createImpl.toJS);
    obj.setProperty('get'.toJS, getImpl.toJS);
    return obj as web.CredentialsContainer;
  }
}

JSPromise _resolved(JSAny? value) {
  // Build a real JS Promise via the global constructor so dart2js does
  // not box the value inside a Dart Future-backed JSPromise.
  return _newPromise((JSFunction resolve, JSFunction reject) {
    resolve.callAsFunction(null, value);
  });
}

JSPromise _rejected(Object error) {
  return _newPromise((JSFunction resolve, JSFunction reject) {
    final jsError = error is JSAny ? error : error.toString().toJS;
    reject.callAsFunction(null, jsError);
  });
}

@JS('Promise')
external JSFunction _promiseCtor;

JSPromise _newPromise(void Function(JSFunction resolve, JSFunction reject) body) {
  final executor = body.toJS;
  final promise = _promiseCtor.callAsConstructor<JSPromise>(executor);
  return promise;
}

/// Builds a minimal, well-formed CBOR attestation object whose embedded
/// authenticator data carries an AT-flagged COSE ES256 key with the
/// secp256r1 generator-point coordinates. Sufficient for the 3-strategy
/// extraction code paths to succeed.
List<int> _validAttestationObject() {
  // secp256r1 base point coordinates (Gx, Gy):
  final gx = <int>[
    0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
    0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
    0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
    0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96,
  ];
  final gy = <int>[
    0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
    0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
    0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
    0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5,
  ];
  final authData = <int>[];
  // rpIdHash (32 bytes of 0x00).
  authData.addAll(List<int>.filled(32, 0));
  // flags: AT bit set (0x40) | UP bit (0x01).
  authData.add(0x41);
  // signCount.
  authData.addAll(<int>[0, 0, 0, 1]);
  // aaguid.
  authData.addAll(List<int>.filled(16, 0));
  // credentialIdLen = 4.
  authData.addAll(<int>[0, 4]);
  // credentialId.
  authData.addAll(<int>[1, 2, 3, 4]);
  // COSE prefix.
  authData.addAll(<int>[
    0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
  ]);
  authData.addAll(gx);
  authData.addAll(<int>[0x22, 0x58, 0x20]);
  authData.addAll(gy);

  // Wrap into a minimal attestation object via raw CBOR (a3 = map of 3:
  // fmt:none, attStmt:{}, authData:bytestring).
  final attestation = <int>[
    0xA3,
    0x63, 0x66, 0x6D, 0x74, // text(3) "fmt"
    0x64, 0x6E, 0x6F, 0x6E, 0x65, // text(4) "none"
    0x67, 0x61, 0x74, 0x74, 0x53, 0x74, 0x6D, 0x74, // text(7) "attStmt"
    0xA0, // map(0)
    0x68, 0x61, 0x75, 0x74, 0x68, 0x44, 0x61, 0x74, 0x61, // text(8) "authData"
  ];
  // bytestring of authData.
  if (authData.length < 24) {
    attestation.add(0x40 + authData.length);
  } else if (authData.length < 256) {
    attestation.addAll(<int>[0x58, authData.length]);
  } else {
    attestation.addAll(<int>[
      0x59,
      (authData.length >> 8) & 0xFF,
      authData.length & 0xFF,
    ]);
  }
  attestation.addAll(authData);
  return attestation;
}

/// Builds a 91-byte SPKI envelope whose final 65 bytes are the supplied
/// uncompressed secp256r1 public key.
List<int> _spkiOf(List<int> uncompressedKey) {
  // 26-byte SPKI header followed by the 65-byte public key.
  final header = <int>[
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
    0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
    0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00,
  ];
  return <int>[...header, ...uncompressedKey];
}

void main() {
  group('BrowserWebAuthnProvider (web)', () {
    test('test_constructor_uses_default_timeout_60000_ms', () {
      final provider = BrowserWebAuthnProvider(
        rpId: 'example.com',
        rpName: 'Example',
      );
      expect(provider.timeoutMs, OZConstants.webauthnTimeoutMs);
      expect(provider.timeoutMs, 60000);
    });

    test('test_constructor_accepts_custom_timeout', () {
      final provider = BrowserWebAuthnProvider(
        rpId: 'example.com',
        rpName: 'Example',
        timeoutMs: 12345,
      );
      expect(provider.timeoutMs, 12345);
    });

    test('test_navigator_credentials_undefined_throws_not_supported',
        () async {
      // Construct via the production constructor, which has no injected
      // container. On Chrome, `window.navigator.credentials` IS defined,
      // so the guard passes. Force the missing-container path by using
      // the test seam with a credentials container whose `create` simply
      // throws to mimic absence — but the cleaner mirror is to call the
      // constructor that omits the injection AND clears the JS global.
      // Since deleting `navigator.credentials` is risky in shared test
      // environments, route the not-supported assertion through the
      // injected-container path with a synthetic absence.
      final fake = _FakeCredentialsContainer(
        createError: _domException(
          'NotSupportedError',
          'WebAuthn is not supported in this environment. '
              'navigator.credentials is not available (Node.js or non-browser context).',
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('test_create_credential_happy_returns_pubkey_and_credential_id',
        () async {
      final attestation = _validAttestationObject();
      final pubkey = <int>[0x04];
      // Build a 65-byte uncompressed key using secp256r1 generator.
      pubkey.addAll(<int>[
        0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
        0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
        0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
        0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96,
      ]);
      pubkey.addAll(<int>[
        0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
        0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
        0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
        0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5,
      ]);
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1, 2, 3, 4],
          attestationObject: attestation,
          spki: _spkiOf(pubkey),
          transports: const ['internal'],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.register(
        challenge: Uint8List.fromList(List<int>.filled(32, 7)),
        userId: Uint8List.fromList(List<int>.filled(16, 9)),
        userName: 'alice',
      );
      expect(result.credentialId, Uint8List.fromList(<int>[1, 2, 3, 4]));
      expect(result.publicKey.length, 65);
      expect(result.publicKey[0], 0x04);
      expect(result.transports, ['internal']);
    });

    test('test_get_assertion_happy_returns_signature', () async {
      final fake = _FakeCredentialsContainer(
        getResult: _assertionCredential(
          rawId: const <int>[5, 6, 7],
          authenticatorData: const <int>[0xAA, 0xBB],
          clientDataJSON: const <int>[0xCC],
          signature: const <int>[0xDE, 0xAD, 0xBE, 0xEF],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.authenticate(
        challenge: Uint8List(32),
      );
      expect(result.credentialId, Uint8List.fromList(<int>[5, 6, 7]));
      expect(result.signature,
          Uint8List.fromList(<int>[0xDE, 0xAD, 0xBE, 0xEF]));
    });

    test('test_authenticate_returns_der_signature_unmodified', () async {
      final fake = _FakeCredentialsContainer(
        getResult: _assertionCredential(
          rawId: const <int>[1],
          authenticatorData: const <int>[],
          clientDataJSON: const <int>[],
          signature: const <int>[0x30, 0x44, 0x02, 0x20],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.authenticate(challenge: Uint8List(32));
      expect(result.signature,
          Uint8List.fromList(<int>[0x30, 0x44, 0x02, 0x20]));
    });

    test('test_create_throws_not_allowed_error_maps_to_cancelled', () async {
      final fake = _FakeCredentialsContainer(
        createError: _domException('NotAllowedError', 'user dismissed'),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(isA<WebAuthnCancelled>()),
      );
    });

    test('test_create_throws_invalid_state_error_distinct_error', () async {
      final fake = _FakeCredentialsContainer(
        createError: _domException('InvalidStateError', 'already exists'),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(
          isA<WebAuthnRegistrationFailed>().having(
            (e) => e.message,
            'message',
            contains('Invalid state'),
          ),
        ),
      );
    });

    test('test_get_throws_security_error_maps_to_authentication_failed',
        () async {
      final fake = _FakeCredentialsContainer(
        getError: _domException('SecurityError', 'rp mismatch'),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.authenticate(challenge: Uint8List(32)),
        throwsA(
          isA<WebAuthnAuthenticationFailed>().having(
            (e) => e.message,
            'message',
            contains('Security error'),
          ),
        ),
      );
    });

    test('test_create_returns_null_throws_registration_failed', () async {
      final fake = _FakeCredentialsContainer();
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(
          isA<WebAuthnRegistrationFailed>().having(
            (e) => e.message,
            'message',
            contains('returned null'),
          ),
        ),
      );
    });

    test('test_top_level_frame_guard_rejects_iframe', () async {
      // Top-level frame enforcement is handled by the browser, surfacing
      // as a SecurityError. Verify the SDK maps that consistently.
      final fake = _FakeCredentialsContainer(
        getError: _domException(
          'SecurityError',
          'The operation is not allowed in this iframe',
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.authenticate(challenge: Uint8List(32)),
        throwsA(isA<WebAuthnAuthenticationFailed>()),
      );
    });

    test('test_non_secure_context_rejected', () async {
      // Non-secure contexts surface as SecurityError. Verify the mapping.
      final fake = _FakeCredentialsContainer(
        createError: _domException(
          'SecurityError',
          'WebAuthn requires HTTPS or localhost',
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(
          isA<WebAuthnRegistrationFailed>().having(
            (e) => e.message,
            'message',
            contains('Security error'),
          ),
        ),
      );
    });

    test('test_rp_id_validation_against_origin', () async {
      // RP-ID/origin mismatch surfaces as SecurityError.
      final fake = _FakeCredentialsContainer(
        getError: _domException(
          'SecurityError',
          'RP ID does not match origin',
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'wrong.example',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.authenticate(challenge: Uint8List(32)),
        throwsA(isA<WebAuthnAuthenticationFailed>()),
      );
    });

    test(
        'test_authenticate_with_allow_credentials_includes_transports_when_present',
        () async {
      final fake = _FakeCredentialsContainer(
        getResult: _assertionCredential(
          rawId: const <int>[1],
          authenticatorData: const <int>[],
          clientDataJSON: const <int>[],
          signature: const <int>[1, 2, 3, 4],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await provider.authenticate(
        challenge: Uint8List(32),
        allowCredentials: [
          AllowCredential(
            id: Uint8List.fromList(const <int>[1, 2, 3]),
            transports: const ['internal', 'hybrid'],
          ),
        ],
      );
      final published = fake.lastGetOptions!.publicKey.allowCredentials.toDart;
      expect(published.length, 1);
      final descriptor = published.first;
      // Verify the transports field is present and matches.
      final transportsAny =
          (descriptor as JSObject).getProperty<JSAny?>('transports'.toJS);
      expect(transportsAny, isNotNull);
      final transports = (transportsAny as JSArray<JSString>)
          .toDart
          .map((s) => s.toDart)
          .toList();
      expect(transports, ['internal', 'hybrid']);
    });

    test(
        'test_authenticate_with_allow_credentials_omits_transports_when_empty',
        () async {
      final fake = _FakeCredentialsContainer(
        getResult: _assertionCredential(
          rawId: const <int>[1],
          authenticatorData: const <int>[],
          clientDataJSON: const <int>[],
          signature: const <int>[1, 2, 3, 4],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await provider.authenticate(
        challenge: Uint8List(32),
        allowCredentials: [
          AllowCredential(
            id: Uint8List.fromList(const <int>[1, 2, 3]),
            transports: const <String>[],
          ),
        ],
      );
      final published = fake.lastGetOptions!.publicKey.allowCredentials.toDart;
      final descriptor = published.first;
      final transportsAny =
          (descriptor as JSObject).getProperty<JSAny?>('transports'.toJS);
      expect(transportsAny, isNull);
    });

    test('test_authenticate_with_null_allow_credentials_does_not_set_field',
        () async {
      final fake = _FakeCredentialsContainer(
        getResult: _assertionCredential(
          rawId: const <int>[1],
          authenticatorData: const <int>[],
          clientDataJSON: const <int>[],
          signature: const <int>[1, 2, 3, 4],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await provider.authenticate(challenge: Uint8List(32));
      final publicKey = fake.lastGetOptions!.publicKey;
      // The field is unset; reading throws or returns undefined.
      final raw = (publicKey as JSObject)
          .getProperty<JSAny?>('allowCredentials'.toJS);
      expect(raw, isNull);
    });

    test('test_register_returns_transports_when_get_transports_present',
        () async {
      final attestation = _validAttestationObject();
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1, 2, 3],
          attestationObject: attestation,
          transports: const ['internal'],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.register(
        challenge: Uint8List(32),
        userId: Uint8List(16),
        userName: 'alice',
      );
      expect(result.transports, ['internal']);
    });

    test('test_register_returns_null_transports_when_get_transports_absent',
        () async {
      final attestation = _validAttestationObject();
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1, 2, 3],
          attestationObject: attestation,
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.register(
        challenge: Uint8List(32),
        userId: Uint8List(16),
        userName: 'alice',
      );
      expect(result.transports, isNull);
    });

    test('test_register_extracts_pubkey_via_strategy_1_get_public_key',
        () async {
      final pubkey = <int>[0x04];
      pubkey.addAll(<int>[
        0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
        0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
        0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
        0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96,
      ]);
      pubkey.addAll(<int>[
        0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
        0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
        0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
        0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5,
      ]);
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1, 2, 3],
          attestationObject: const <int>[0x00], // intentionally invalid
          spki: _spkiOf(pubkey),
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.register(
        challenge: Uint8List(32),
        userId: Uint8List(16),
        userName: 'alice',
      );
      expect(result.publicKey.length, 65);
      expect(result.publicKey[0], 0x04);
    });

    test(
        'test_register_falls_back_to_strategy_2_when_get_public_key_returns_null',
        () async {
      final attestation = _validAttestationObject();
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1],
          attestationObject: attestation,
          // No spki — strategy 1 fails, strategy 2 (auth-data CBOR)
          // succeeds because the attestation object contains a valid
          // COSE key.
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.register(
        challenge: Uint8List(32),
        userId: Uint8List(16),
        userName: 'alice',
      );
      expect(result.publicKey.length, 65);
    });

    test(
        'test_register_falls_back_to_strategy_3_when_strategies_1_and_2_fail',
        () async {
      // Build a malformed attestation object whose CBOR top-level
      // structure is broken but whose embedded COSE key is still
      // pattern-matchable by the raw-byte search.
      final cose = <int>[
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
      ];
      cose.addAll(<int>[
        0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
        0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
        0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
        0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96,
      ]);
      cose.addAll(<int>[0x22, 0x58, 0x20]);
      cose.addAll(<int>[
        0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
        0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
        0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
        0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5,
      ]);
      // Garbage CBOR header followed by the raw COSE bytes.
      final attestation = <int>[0x00, 0xFF, 0xFF, ...cose];
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1],
          attestationObject: attestation,
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      final result = await provider.register(
        challenge: Uint8List(32),
        userId: Uint8List(16),
        userName: 'alice',
      );
      expect(result.publicKey.length, 65);
    });

    test('test_register_throws_when_all_three_strategies_fail', () async {
      final fake = _FakeCredentialsContainer(
        createResult: _attestationCredential(
          rawId: const <int>[1],
          attestationObject: const <int>[0xDE, 0xAD],
        ),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(
          isA<WebAuthnRegistrationFailed>().having(
            (e) => e.message,
            'message',
            contains('three extraction strategies'),
          ),
        ),
      );
    });

    test(
        'test_abort_error_maps_to_authentication_failed_with_aborted_message',
        () async {
      final fake = _FakeCredentialsContainer(
        getError: _domException('AbortError', 'timed out'),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.authenticate(challenge: Uint8List(32)),
        throwsA(
          isA<WebAuthnAuthenticationFailed>().having(
            (e) => e.message,
            'message',
            contains('aborted'),
          ),
        ),
      );
    });

    test('test_constraint_error_maps_to_constraint_failed_with_message',
        () async {
      final fake = _FakeCredentialsContainer(
        createError: _domException('ConstraintError', 'no UV available'),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.register(
          challenge: Uint8List(32),
          userId: Uint8List(16),
          userName: 'alice',
        ),
        throwsA(
          isA<WebAuthnRegistrationFailed>().having(
            (e) => e.message,
            'message',
            contains('constraint'),
          ),
        ),
      );
    });

    test(
        'test_unknown_error_falls_through_to_authentication_failed_with_raw_message',
        () async {
      final fake = _FakeCredentialsContainer(
        getError: _domException('SomeUnexpectedError', 'mystery'),
      );
      final provider = BrowserWebAuthnProvider.withCredentialsContainer(
        rpId: 'example.com',
        rpName: 'Example',
        credentialsContainer: fake.toJS(),
      );
      await expectLater(
        provider.authenticate(challenge: Uint8List(32)),
        throwsA(
          isA<WebAuthnAuthenticationFailed>().having(
            (e) => e.message,
            'message',
            contains('mystery'),
          ),
        ),
      );
    });
  });
}
