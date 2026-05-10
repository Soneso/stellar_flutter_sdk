// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Configurable mock implementation of [WebAuthnProvider] for unit testing.
///
/// This mock allows tests to:
/// - Supply predetermined registration and authentication results
/// - Configure exceptions to simulate error conditions
/// - Track call counts and captured arguments for verification
///
/// By default, the mock produces valid registration and authentication
/// results using synthetic test data. Override [registrationResult],
/// [authenticationResult], [registrationException], or
/// [authenticationException] to change the behaviour.
class MockWebAuthnProvider extends WebAuthnProvider {
  /// Constructs a [MockWebAuthnProvider] with all configuration fields
  /// initialised to their defaults.
  MockWebAuthnProvider();

  // ----- Configuration -----

  /// The result returned from [register] when no exception is configured.
  /// `null` causes a synthetic default result to be generated.
  WebAuthnRegistrationResult? registrationResult;

  /// The exception thrown from [register]. Takes precedence over
  /// [registrationResult].
  WebAuthnException? registrationException;

  /// The result returned from [authenticate] when no exception is
  /// configured. `null` causes a synthetic default result to be generated.
  WebAuthnAuthenticationResult? authenticationResult;

  /// The exception thrown from [authenticate]. Takes precedence over
  /// [authenticationResult].
  WebAuthnException? authenticationException;

  // ----- Call tracking -----

  int _registerCallCount = 0;
  int _authenticateCallCount = 0;
  Uint8List? _lastRegisterChallenge;
  Uint8List? _lastRegisterUserId;
  String? _lastRegisterUserName;
  Uint8List? _lastAuthenticateChallenge;
  List<AllowCredential>? _lastAuthenticateAllowCredentials;

  /// Number of times [register] has been called.
  int get registerCallCount => _registerCallCount;

  /// Number of times [authenticate] has been called.
  int get authenticateCallCount => _authenticateCallCount;

  /// The most recent challenge passed to [register], or `null` if never
  /// called.
  Uint8List? get lastRegisterChallenge => _lastRegisterChallenge;

  /// The most recent userId passed to [register], or `null` if never called.
  Uint8List? get lastRegisterUserId => _lastRegisterUserId;

  /// The most recent userName passed to [register], or `null` if never
  /// called.
  String? get lastRegisterUserName => _lastRegisterUserName;

  /// The most recent challenge passed to [authenticate], or `null` if never
  /// called.
  Uint8List? get lastAuthenticateChallenge => _lastAuthenticateChallenge;

  /// The most recent `allowCredentials` passed to [authenticate], or `null`
  /// if never called or if the caller passed `null`.
  List<AllowCredential>? get lastAuthenticateAllowCredentials =>
      _lastAuthenticateAllowCredentials;

  // ----- WebAuthnProvider implementation -----

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async {
    _registerCallCount++;
    _lastRegisterChallenge = Uint8List.fromList(challenge);
    _lastRegisterUserId = Uint8List.fromList(userId);
    _lastRegisterUserName = userName;

    final ex = registrationException;
    if (ex != null) throw ex;

    return registrationResult ?? _defaultRegistrationResult();
  }

  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  }) async {
    _authenticateCallCount++;
    _lastAuthenticateChallenge = Uint8List.fromList(challenge);
    _lastAuthenticateAllowCredentials = allowCredentials;

    final ex = authenticationException;
    if (ex != null) throw ex;

    return authenticationResult ?? _defaultAuthenticationResult();
  }

  // ----- Reset -----

  /// Resets all call-tracking state and configured responses to their
  /// defaults.
  void reset() {
    registrationResult = null;
    registrationException = null;
    authenticationResult = null;
    authenticationException = null;
    _registerCallCount = 0;
    _authenticateCallCount = 0;
    _lastRegisterChallenge = null;
    _lastRegisterUserId = null;
    _lastRegisterUserName = null;
    _lastAuthenticateChallenge = null;
    _lastAuthenticateAllowCredentials = null;
  }

  // ----- Synthetic fixture builders -----

  /// Creates a deterministic 65-byte uncompressed secp256r1-shaped public
  /// key fixture (`0x04` prefix + 32-byte X + 32-byte Y) parameterised by
  /// [seed].
  static Uint8List testPublicKey({int seed = 0}) {
    final out = Uint8List(65);
    out[0] = 0x04;
    for (var i = 1; i < 65; i++) {
      out[i] = (i + seed) & 0xFF;
    }
    return out;
  }

  /// Creates a deterministic 16-byte test credential ID parameterised by
  /// [seed].
  static Uint8List testCredentialId({int seed = 0}) {
    final out = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      out[i] = (i + seed) & 0xFF;
    }
    return out;
  }

  /// Creates a deterministic 128-byte synthetic attestation object fixture
  /// parameterised by [seed]. The bytes are NOT a valid CBOR structure;
  /// the fixture is for byte-identity assertions only.
  static Uint8List testAttestationObject({int seed = 0}) {
    final out = Uint8List(128);
    for (var i = 0; i < 128; i++) {
      out[i] = (i + seed + 0x10) & 0xFF;
    }
    return out;
  }

  WebAuthnRegistrationResult _defaultRegistrationResult() {
    return WebAuthnRegistrationResult(
      credentialId: testCredentialId(),
      publicKey: testPublicKey(),
      attestationObject: testAttestationObject(),
      transports: const ['internal'],
      deviceType: 'multiDevice',
      backedUp: true,
    );
  }

  WebAuthnAuthenticationResult _defaultAuthenticationResult() {
    final authData = Uint8List(37);
    for (var i = 0; i < 37; i++) {
      authData[i] = i & 0xFF;
    }
    final clientData = Uint8List.fromList(
      utf8.encode('{"type":"webauthn.get","challenge":"test"}'),
    );
    final sig = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      sig[i] = i & 0xFF;
    }
    return WebAuthnAuthenticationResult(
      credentialId: testCredentialId(),
      authenticatorData: authData,
      clientDataJSON: clientData,
      signature: sig,
    );
  }
}
