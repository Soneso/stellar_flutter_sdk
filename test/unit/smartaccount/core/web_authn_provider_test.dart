// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Library-private parser is reached via direct relative-path import; the file
// is intentionally not exported from the SDK barrel.
import 'package:stellar_flutter_sdk/src/smartaccount/core/web_authn_cbor_parser.dart';

import 'mock_webauthn_provider.dart';

// Test constants — secp256r1 generator-point G coordinates (SEC 2).
final Uint8List _testXCoordinate = Uint8List.fromList(const [
  0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
  0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
  0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
  0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96,
]);

final Uint8List _testYCoordinate = Uint8List.fromList(const [
  0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
  0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
  0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
  0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5,
]);

Uint8List _expectedPublicKey() {
  final key = Uint8List(65);
  key[0] = 0x04;
  key.setRange(1, 33, _testXCoordinate);
  key.setRange(33, 65, _testYCoordinate);
  return key;
}

Uint8List _buildCoseKey() {
  final prefix = Uint8List.fromList(const [
    0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
  ]);
  final separator = Uint8List.fromList(const [0x22, 0x58, 0x20]);
  final builder = BytesBuilder()
    ..add(prefix)
    ..add(_testXCoordinate)
    ..add(separator)
    ..add(_testYCoordinate);
  return builder.toBytes();
}

Uint8List _buildAttestationObject() {
  return _buildCoseKey();
}

/// Builds the smallest legal authenticator-data buffer:
/// 32-byte rpIdHash + 1-byte flags + 4-byte signCount (37 bytes total).
Uint8List _buildMinimalAuthenticatorData(int flagsByte) {
  final buf = Uint8List(37);
  for (var i = 0; i < 32; i++) {
    buf[i] = 0xAA;
  }
  buf[32] = flagsByte & 0xFF;
  // signCount bytes 33..36 left zero — the parser does not consume them.
  return buf;
}

/// Builds authenticator data with attested credential data:
/// rpIdHash(32) + flags(1) + signCount(4) + aaguid(16) + credLen(2) + cred(N) + COSE key.
Uint8List _buildAuthenticatorData({
  int flags = 0x41, // UP + AT flags set
  int credentialIdLength = 16,
}) {
  final rpIdHash = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    rpIdHash[i] = 0xAA;
  }
  final signCount = Uint8List(4);
  final aaguid = Uint8List(16);
  final credIdLen = Uint8List.fromList(<int>[
    (credentialIdLength >> 8) & 0xFF,
    credentialIdLength & 0xFF,
  ]);
  final credentialId = Uint8List(credentialIdLength);
  for (var i = 0; i < credentialIdLength; i++) {
    credentialId[i] = 0xBB;
  }
  final coseKey = _buildCoseKey();

  final builder = BytesBuilder()
    ..add(rpIdHash)
    ..add(<int>[flags & 0xFF])
    ..add(signCount)
    ..add(aaguid)
    ..add(credIdLen)
    ..add(credentialId)
    ..add(coseKey);
  return builder.toBytes();
}

void main() {
  group('AuthenticatorDataFlags (raw bit derivation)', () {
    test('test_authenticator_data_flags_be_clear_yields_singleDevice', () {
      // Flags = 0x01 (UP only). With BE=0 the device is single-device, with
      // BS=0 the credential is not backed up.
      final authData = _buildMinimalAuthenticatorData(0x01);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle),
          reason: 'BE bit clear should yield singleDevice');
      expect(flags.backedUp, isFalse, reason: 'BS bit clear should yield false');
    });

    test('test_authenticator_data_flags_backup_eligible_single_device', () {
      // Flags = 0x01 (UP only). BE=0 -> singleDevice, BS=0 -> not backed up.
      final authData = _buildMinimalAuthenticatorData(0x01);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle),
          reason: 'BE clear must yield singleDevice');
      expect(flags.backedUp, isFalse, reason: 'BS clear must yield false');
    });

    test('test_authenticator_data_flags_backup_eligible_multi_device', () {
      // Flags = 0x09 (UP|BE). BE=1 -> multiDevice, BS=0 -> eligible but not
      // yet backed up.
      final authData = _buildMinimalAuthenticatorData(0x09);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti),
          reason: 'BE set must yield multiDevice');
      expect(flags.backedUp, isFalse,
          reason: 'BS clear must yield false (eligible but not yet backed up)');
    });

    test('test_authenticator_data_flags_backed_up', () {
      // Flags = 0x19 (UP|BE|BS). Both BE and BS set.
      final authData = _buildMinimalAuthenticatorData(0x19);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
      expect(flags.backedUp, isTrue);
    });

    test('test_authenticator_data_flags_attested_credential_data', () {
      // Flags = 0x41 (UP|AT). The AT bit is not surfaced by the parser —
      // verify the parser ignores it gracefully (BE/BS both clear).
      final authData = _buildMinimalAuthenticatorData(0x41);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle),
          reason: 'AT bit must not influence device-type derivation');
      expect(flags.backedUp, isFalse,
          reason: 'AT bit must not influence backup-state derivation');
    });

    test('test_authenticator_data_flags_all_flags_set', () {
      // Flags = 0xDD (every bit except UV/AT2). With BE and BS both set the
      // parser must report multiDevice + backedUp regardless of unrelated
      // bits.
      final authData = _buildMinimalAuthenticatorData(0xDD);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
      expect(flags.backedUp, isTrue);
    });

    test('test_device_type_from_real_authenticator_data_single_device', () {
      // Use the full attested-credential authenticator-data buffer with
      // flags = 0x41 (UP|AT). BE clear => singleDevice.
      final authData = _buildAuthenticatorData(flags: 0x41);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle));
    });

    test('test_device_type_from_real_authenticator_data_multi_device', () {
      // Full attested-credential authenticator data with flags = 0x49
      // (UP|BE|AT). BE set => multiDevice.
      final authData = _buildAuthenticatorData(flags: 0x49);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
    });

    test('test_backed_up_from_real_authenticator_data_not_backed_up', () {
      // Flags = 0x49 (UP|BE|AT). BS clear => not backed up.
      final authData = _buildAuthenticatorData(flags: 0x49);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.backedUp, isFalse);
    });

    test('test_backed_up_from_real_authenticator_data_backed_up', () {
      // Flags = 0x59 (UP|BE|BS|AT). BS set => backed up.
      final authData = _buildAuthenticatorData(flags: 0x59);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(authData);
      expect(flags.backedUp, isTrue);
    });
  });

  group('WebAuthnRegistrationResult', () {
    test('test_webauthn_registration_result_equality', () {
      final credId = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        credId[i] = i & 0xFF;
      }
      final pubKey = _expectedPublicKey();
      final attestObj = _buildAttestationObject();

      final result1 = WebAuthnRegistrationResult(
        credentialId: credId,
        publicKey: pubKey,
        attestationObject: attestObj,
        transports: const ['internal'],
        deviceType: 'multiDevice',
        backedUp: true,
      );

      final result2 = WebAuthnRegistrationResult(
        credentialId: Uint8List.fromList(credId),
        publicKey: Uint8List.fromList(pubKey),
        attestationObject: Uint8List.fromList(attestObj),
        transports: const ['internal'],
        deviceType: 'multiDevice',
        backedUp: true,
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test(
        'test_webauthn_registration_result_inequality_different_credential_id',
        () {
      final attestObj = _buildAttestationObject();
      final cred1 = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        cred1[i] = 0x01;
      }
      final cred2 = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        cred2[i] = 0x02;
      }

      final result1 = WebAuthnRegistrationResult(
        credentialId: cred1,
        publicKey: _expectedPublicKey(),
        attestationObject: attestObj,
      );

      final result2 = WebAuthnRegistrationResult(
        credentialId: cred2,
        publicKey: _expectedPublicKey(),
        attestationObject: attestObj,
      );

      expect(result1 == result2, isFalse);
    });

    test('test_webauthn_registration_result_optional_fields_defaults', () {
      final result = WebAuthnRegistrationResult(
        credentialId: Uint8List(16),
        publicKey: _expectedPublicKey(),
        attestationObject: _buildAttestationObject(),
      );

      expect(result.transports, isNull);
      expect(result.deviceType, isNull);
      expect(result.backedUp, isNull);
    });
  });

  group('WebAuthnAuthenticationResult', () {
    test('test_webauthn_authentication_result_equality', () {
      final credId = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        credId[i] = i & 0xFF;
      }
      final authData = Uint8List(37);
      for (var i = 0; i < 37; i++) {
        authData[i] = i & 0xFF;
      }
      final clientData = Uint8List.fromList(
        utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
      );
      final sig = Uint8List(64);
      for (var i = 0; i < 64; i++) {
        sig[i] = i & 0xFF;
      }

      final result1 = WebAuthnAuthenticationResult(
        credentialId: credId,
        authenticatorData: authData,
        clientDataJSON: clientData,
        signature: sig,
      );

      final result2 = WebAuthnAuthenticationResult(
        credentialId: Uint8List.fromList(credId),
        authenticatorData: Uint8List.fromList(authData),
        clientDataJSON: Uint8List.fromList(clientData),
        signature: Uint8List.fromList(sig),
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test(
        'test_webauthn_authentication_result_inequality_different_signature',
        () {
      final base = WebAuthnAuthenticationResult(
        credentialId: Uint8List(16),
        authenticatorData: Uint8List(37),
        clientDataJSON: Uint8List(100),
        signature: Uint8List(64)
          ..fillRange(0, 64, 0x01),
      );

      final different = WebAuthnAuthenticationResult(
        credentialId: Uint8List(16),
        authenticatorData: Uint8List(37),
        clientDataJSON: Uint8List(100),
        signature: Uint8List(64)
          ..fillRange(0, 64, 0x02),
      );

      expect(base == different, isFalse);
    });
  });

  group('WebAuthnProvider interface (via MockWebAuthnProvider)', () {
    test(
        'test_mock_provider_register_returns_default_result_when_unconfigured',
        () async {
      final mock = MockWebAuthnProvider();
      final challenge = Uint8List.fromList(const [0x10, 0x20, 0x30]);
      final userId = Uint8List.fromList(const [0x40, 0x50]);

      final result = await mock.register(
        challenge: challenge,
        userId: userId,
        userName: 'alice',
      );

      // Default registration result has the synthetic test fixtures.
      expect(result.credentialId, equals(MockWebAuthnProvider.testCredentialId()));
      expect(result.publicKey, equals(MockWebAuthnProvider.testPublicKey()));
      expect(
        result.attestationObject,
        equals(MockWebAuthnProvider.testAttestationObject()),
      );
      expect(result.transports, equals(const ['internal']));
      expect(result.deviceType, equals('multiDevice'));
      expect(result.backedUp, isTrue);
    });

    test('test_mock_provider_register_throws_configured_exception', () async {
      final mock = MockWebAuthnProvider();
      mock.registrationException = WebAuthnException.cancelled();

      await expectLater(
        mock.register(
          challenge: Uint8List(32),
          userId: Uint8List(8),
          userName: 'bob',
        ),
        throwsA(isA<WebAuthnCancelled>()),
      );
    });

    test('test_mock_provider_register_tracks_call_count_and_args', () async {
      final mock = MockWebAuthnProvider();
      await mock.register(
        challenge: Uint8List.fromList(const [0x01]),
        userId: Uint8List.fromList(const [0x10]),
        userName: 'first',
      );
      await mock.register(
        challenge: Uint8List.fromList(const [0xAA, 0xBB]),
        userId: Uint8List.fromList(const [0xCC, 0xDD]),
        userName: 'second',
      );

      expect(mock.registerCallCount, equals(2));
      expect(mock.lastRegisterChallenge,
          equals(Uint8List.fromList(const [0xAA, 0xBB])));
      expect(mock.lastRegisterUserId,
          equals(Uint8List.fromList(const [0xCC, 0xDD])));
      expect(mock.lastRegisterUserName, equals('second'));
    });

    test(
        'test_mock_provider_authenticate_returns_default_result_when_unconfigured',
        () async {
      final mock = MockWebAuthnProvider();
      final result = await mock.authenticate(
        challenge: Uint8List.fromList(const [0x42]),
      );

      expect(result.credentialId, equals(MockWebAuthnProvider.testCredentialId()));
      expect(result.authenticatorData.length, equals(37));
      expect(result.clientDataJSON.length, greaterThan(0));
      expect(result.signature.length, equals(64));
    });

    test('test_mock_provider_authenticate_throws_configured_exception',
        () async {
      final mock = MockWebAuthnProvider();
      mock.authenticationException =
          WebAuthnException.authenticationFailed('mock failure');

      await expectLater(
        mock.authenticate(challenge: Uint8List(32)),
        throwsA(isA<WebAuthnAuthenticationFailed>()),
      );
    });

    test('test_mock_provider_authenticate_tracks_call_count_and_args',
        () async {
      final mock = MockWebAuthnProvider();
      final allow1 = <AllowCredential>[
        AllowCredential.fromId(Uint8List.fromList(const [0x01])),
      ];
      final allow2 = <AllowCredential>[
        AllowCredential.fromId(Uint8List.fromList(const [0x02])),
        AllowCredential.fromId(Uint8List.fromList(const [0x03])),
      ];

      await mock.authenticate(
        challenge: Uint8List.fromList(const [0x01]),
        allowCredentials: allow1,
      );
      await mock.authenticate(
        challenge: Uint8List.fromList(const [0x02, 0x03]),
        allowCredentials: allow2,
      );

      expect(mock.authenticateCallCount, equals(2));
      expect(
        mock.lastAuthenticateChallenge,
        equals(Uint8List.fromList(const [0x02, 0x03])),
      );
      expect(mock.lastAuthenticateAllowCredentials, equals(allow2));
    });

    test('test_mock_provider_reset_clears_all_state', () async {
      final mock = MockWebAuthnProvider();
      await mock.register(
        challenge: Uint8List.fromList(const [0x99]),
        userId: Uint8List.fromList(const [0x88]),
        userName: 'someone',
      );
      await mock.authenticate(
        challenge: Uint8List.fromList(const [0x77]),
        allowCredentials: <AllowCredential>[
          AllowCredential.fromId(Uint8List.fromList(const [0x66])),
        ],
      );
      mock.registrationException = WebAuthnException.cancelled();
      mock.authenticationException = WebAuthnException.cancelled();

      mock.reset();

      expect(mock.registerCallCount, equals(0));
      expect(mock.authenticateCallCount, equals(0));
      expect(mock.lastRegisterChallenge, isNull);
      expect(mock.lastRegisterUserId, isNull);
      expect(mock.lastRegisterUserName, isNull);
      expect(mock.lastAuthenticateChallenge, isNull);
      expect(mock.lastAuthenticateAllowCredentials, isNull);
      expect(mock.registrationException, isNull);
      expect(mock.registrationResult, isNull);
      expect(mock.authenticationException, isNull);
      expect(mock.authenticationResult, isNull);
    });

    test(
        'test_mock_provider_test_public_key_seed_0_starts_with_0x04_and_is_65_bytes',
        () {
      final key = MockWebAuthnProvider.testPublicKey();
      expect(key.length, equals(65));
      expect(key[0], equals(0x04));
    });

    test('test_mock_provider_test_credential_id_seed_0_is_16_bytes', () {
      final id = MockWebAuthnProvider.testCredentialId();
      expect(id.length, equals(16));
    });

    test('test_mock_provider_test_attestation_object_seed_0_is_128_bytes',
        () {
      final ao = MockWebAuthnProvider.testAttestationObject();
      expect(ao.length, equals(128));
    });
  });
}
