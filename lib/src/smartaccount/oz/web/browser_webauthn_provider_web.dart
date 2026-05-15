// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../core/allow_credential.dart';
import '../../core/smart_account_errors.dart';
import '../../core/smart_account_utils.dart';
import '../../core/web_authn_cbor_parser.dart';
import '../../core/web_authn_provider.dart';
import '../oz_constants.dart';

/// Browser implementation of [WebAuthnProvider] using the Web
/// Authentication API.
///
/// This provider drives `navigator.credentials.create()` and
/// `navigator.credentials.get()` directly. It requests ES256 (secp256r1,
/// COSE algorithm `-7`) keys and returns the public key as an
/// uncompressed 65-byte secp256r1 point (`0x04 || X || Y`).
///
/// Public-key extraction during registration runs three strategies in
/// order:
///
/// 1. `response.getPublicKey()` returns SubjectPublicKeyInfo (SPKI); the
///    final 65 bytes are the uncompressed secp256r1 point. Preferred
///    because it is the most direct path.
/// 2. Parse the CBOR-encoded authenticator data inside the attestation
///    object and extract `(X, Y)` from the COSE key structure.
/// 3. Pattern-match the raw attestation object bytes for the COSE ES256
///    key prefix (`a5 01 02 03 26 20 01 21 58 20`) and extract `(X, Y)`.
///
/// This provider is browser-only. On non-web targets the conditional
/// export selects a stub that throws [UnsupportedError]. Construction
/// itself never throws — the `navigator.credentials` availability guard
/// runs at the first call to [register] or [authenticate].
class BrowserWebAuthnProvider extends WebAuthnProvider {
  /// Relying party identifier (typically the origin domain, e.g.
  /// `app.example.com`).
  final String rpId;

  /// Human-readable relying party name presented to the user during the
  /// platform prompt.
  final String rpName;

  /// Timeout in milliseconds passed to the WebAuthn ceremony.
  final int timeoutMs;

  /// Optional injected credentials handle used by tests to drive the
  /// provider against a fake [web.CredentialsContainer] without invoking
  /// the real authenticator.
  final web.CredentialsContainer? _injectedCredentials;

  /// Constructs a [BrowserWebAuthnProvider] backed by
  /// `navigator.credentials`.
  BrowserWebAuthnProvider({
    required this.rpId,
    required this.rpName,
    this.timeoutMs = OZConstants.webauthnTimeoutMs,
  }) : _injectedCredentials = null;

  /// Constructs a [BrowserWebAuthnProvider] backed by an injected
  /// credentials container. Test seam — production code uses the unnamed
  /// constructor.
  @visibleForTesting
  BrowserWebAuthnProvider.withCredentialsContainer({
    required this.rpId,
    required this.rpName,
    required web.CredentialsContainer credentialsContainer,
    this.timeoutMs = OZConstants.webauthnTimeoutMs,
  }) : _injectedCredentials = credentialsContainer;

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async {
    final credentials = _resolveCredentials();
    if (credentials == null) {
      throw WebAuthnException.notSupported(
        details:
            'WebAuthn is not supported in this environment. '
            'navigator.credentials is not available (Node.js or non-browser context).',
      );
    }

    final options = web.CredentialCreationOptions(
      publicKey: web.PublicKeyCredentialCreationOptions(
        rp: web.PublicKeyCredentialRpEntity(name: rpName, id: rpId),
        user: web.PublicKeyCredentialUserEntity(
          name: userName,
          id: _bytesToBuffer(userId),
          displayName: userName,
        ),
        challenge: _bytesToBuffer(challenge),
        pubKeyCredParams: <web.PublicKeyCredentialParameters>[
          web.PublicKeyCredentialParameters(type: 'public-key', alg: -7),
        ].toJS,
        authenticatorSelection: web.AuthenticatorSelectionCriteria(
          residentKey: 'preferred',
          // why: the OZ WebAuthn verifier contract requires the User
          // Verified (UV) flag in the authenticator data. `required`
          // forces the browser to prompt for biometric/PIN verification on
          // every ceremony, which is needed on `localhost` where
          // `preferred` may skip verification.
          userVerification: 'required',
        ),
        timeout: timeoutMs,
        attestation: 'direct',
      ),
    );

    web.Credential? credentialAny;
    try {
      credentialAny = await credentials.create(options).toDart;
    } on Object catch (e) {
      throw _mapWebAuthnError(e, isRegistration: true);
    }

    if (credentialAny == null) {
      throw WebAuthnException.registrationFailed(
        'navigator.credentials.create() returned null',
      );
    }

    final credential = credentialAny as web.PublicKeyCredential;
    final credentialIdBytes = _bufferToBytes(credential.rawId);
    final response =
        credential.response as web.AuthenticatorAttestationResponse;
    final attestationObjectBytes = _bufferToBytes(response.attestationObject);

    final extractedPublicKey =
        _extractPublicKey(response, attestationObjectBytes);
    final transports = _extractTransports(response);
    final flagsInfo = _parseAuthenticatorFlags(attestationObjectBytes);

    return WebAuthnRegistrationResult(
      credentialId: credentialIdBytes,
      publicKey: extractedPublicKey,
      attestationObject: attestationObjectBytes,
      transports: transports,
      deviceType: flagsInfo.deviceType,
      backedUp: flagsInfo.backedUp,
    );
  }

  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  }) async {
    final credentials = _resolveCredentials();
    if (credentials == null) {
      throw WebAuthnException.notSupported(
        details:
            'WebAuthn is not supported in this environment. '
            'navigator.credentials is not available (Node.js or non-browser context).',
      );
    }

    final publicKey = web.PublicKeyCredentialRequestOptions(
      challenge: _bytesToBuffer(challenge),
      rpId: rpId,
      // why: same UV requirement as registration. `required` ensures the
      // assertion carries a verified user gesture on every call.
      userVerification: 'required',
      timeout: timeoutMs,
    );

    if (allowCredentials != null && allowCredentials.isNotEmpty) {
      // why: build descriptors only when allowCredentials is non-empty.
      // The WebAuthn spec treats omission and an empty `transports`
      // array differently — we omit the field entirely when no transport
      // hints are present, mirroring the upstream implementation.
      final descriptors = <web.PublicKeyCredentialDescriptor>[];
      for (final cred in allowCredentials) {
        final hasTransports =
            cred.transports != null && cred.transports!.isNotEmpty;
        final web.PublicKeyCredentialDescriptor descriptor;
        if (hasTransports) {
          descriptor = web.PublicKeyCredentialDescriptor(
            type: 'public-key',
            id: _bytesToBuffer(cred.id),
            transports: cred.transports!.map((t) => t.toJS).toList().toJS,
          );
        } else {
          descriptor = web.PublicKeyCredentialDescriptor(
            type: 'public-key',
            id: _bytesToBuffer(cred.id),
          );
        }
        descriptors.add(descriptor);
      }
      publicKey.allowCredentials = descriptors.toJS;
    }

    final options = web.CredentialRequestOptions(publicKey: publicKey);

    web.Credential? credentialAny;
    try {
      credentialAny = await credentials.get(options).toDart;
    } on Object catch (e) {
      throw _mapWebAuthnError(e, isRegistration: false);
    }

    if (credentialAny == null) {
      throw WebAuthnException.authenticationFailed(
        'navigator.credentials.get() returned null',
      );
    }

    final credential = credentialAny as web.PublicKeyCredential;
    final credentialIdBytes = _bufferToBytes(credential.rawId);
    final response =
        credential.response as web.AuthenticatorAssertionResponse;
    final authenticatorDataBytes = _bufferToBytes(response.authenticatorData);
    final clientDataJSONBytes = _bufferToBytes(response.clientDataJSON);
    final signatureBytes = _bufferToBytes(response.signature);

    return WebAuthnAuthenticationResult(
      credentialId: credentialIdBytes,
      authenticatorData: authenticatorDataBytes,
      clientDataJSON: clientDataJSONBytes,
      signature: signatureBytes,
    );
  }

  // ---------------------------------------------------------------------------
  // Public-key extraction (3 strategies)
  // ---------------------------------------------------------------------------

  Uint8List _extractPublicKey(
    web.AuthenticatorAttestationResponse response,
    Uint8List attestationObjectBytes,
  ) {
    final spkiKey = _tryGetPublicKeyFromResponse(response);
    if (spkiKey != null) return spkiKey;

    final authDataKey = _tryExtractFromAuthenticatorData(attestationObjectBytes);
    if (authDataKey != null) return authDataKey;

    final patternKey = _tryExtractFromAttestationPattern(attestationObjectBytes);
    if (patternKey != null) return patternKey;

    throw WebAuthnException.registrationFailed(
      'Could not extract secp256r1 public key from attestation response. '
      'None of the three extraction strategies succeeded.',
    );
  }

  Uint8List? _tryGetPublicKeyFromResponse(
    web.AuthenticatorAttestationResponse response,
  ) {
    try {
      // why: older browsers expose `getPublicKey` only on a subset of
      // authenticator responses, and a small number of polyfills install a
      // non-callable shim. Verify the property is present, non-null AND
      // callable (`typeof === "function"`) before invoking; otherwise fall
      // through to attestation-object parsing.
      if (!response.has('getPublicKey')) return null;
      final getPublicKeyProp =
          response.getProperty<JSAny?>('getPublicKey'.toJS);
      if (getPublicKeyProp == null) return null;
      if (!getPublicKeyProp.typeofEquals('function')) return null;

      final spkiAny = response.getPublicKey();
      if (spkiAny == null) return null;

      final spkiBytes = _bufferToBytes(spkiAny);
      if (spkiBytes.isEmpty) return null;

      return WebAuthnCborParser.extractPublicKeyFromSpki(spkiBytes);
    } on Object {
      return null;
    }
  }

  Uint8List? _tryExtractFromAuthenticatorData(Uint8List attestationObjectBytes) {
    try {
      final authData = WebAuthnCborParser
          .extractAuthenticatorDataFromAttestation(attestationObjectBytes);
      if (authData == null) return null;
      return SmartAccountUtils.extractPublicKeyFromAuthenticatorData(authData);
    } on Object {
      return null;
    }
  }

  Uint8List? _tryExtractFromAttestationPattern(Uint8List attestationObjectBytes) {
    try {
      return SmartAccountUtils
          .extractPublicKeyFromAttestationObject(attestationObjectBytes);
    } on Object {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Authenticator flags + transports
  // ---------------------------------------------------------------------------

  AuthenticatorFlags _parseAuthenticatorFlags(Uint8List attestationObjectBytes) {
    final authData =
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(
      attestationObjectBytes,
    );
    return WebAuthnCborParser.parseAuthenticatorFlags(authData);
  }

  List<String>? _extractTransports(
    web.AuthenticatorAttestationResponse response,
  ) {
    try {
      final hasGetTransports = response.has('getTransports') &&
          response.getProperty<JSAny?>('getTransports'.toJS) != null;
      if (!hasGetTransports) return null;

      final jsArray = response.getTransports();
      // ignore: unnecessary_null_comparison
      if (jsArray == null) return null;
      final dartList = jsArray.toDart;
      if (dartList.isEmpty) return null;
      return dartList
          .map((s) => s.toDart)
          .toList(growable: false);
    } on Object {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping (DOMException.name → SmartAccountException subtype)
  // ---------------------------------------------------------------------------

  WebAuthnException _mapWebAuthnError(
    Object error, {
    required bool isRegistration,
  }) {
    final errorName = _readErrorName(error);
    final errorMessage = _readErrorMessage(error) ?? error.toString();

    switch (errorName) {
      case 'NotAllowedError':
        return WebAuthnException.cancelled(cause: error);
      case 'SecurityError':
        final detail =
            'Security error: The operation is insecure or the RP ID does not '
            'match the current origin. $errorMessage';
        return isRegistration
            ? WebAuthnException.registrationFailed(detail, cause: error)
            : WebAuthnException.authenticationFailed(detail, cause: error);
      case 'AbortError':
        final detail = 'Operation was aborted or timed out. $errorMessage';
        return isRegistration
            ? WebAuthnException.registrationFailed(detail, cause: error)
            : WebAuthnException.authenticationFailed(detail, cause: error);
      case 'InvalidStateError':
        final detail = 'Invalid state: $errorMessage';
        return isRegistration
            ? WebAuthnException.registrationFailed(detail, cause: error)
            : WebAuthnException.authenticationFailed(detail, cause: error);
      case 'NotSupportedError':
        return WebAuthnException.notSupported(
          details: 'WebAuthn operation not supported: $errorMessage',
          cause: error,
        );
      case 'ConstraintError':
        final detail = 'Authenticator constraint error: $errorMessage';
        return isRegistration
            ? WebAuthnException.registrationFailed(detail, cause: error)
            : WebAuthnException.authenticationFailed(detail, cause: error);
      default:
        return isRegistration
            ? WebAuthnException.registrationFailed(errorMessage, cause: error)
            : WebAuthnException.authenticationFailed(errorMessage, cause: error);
    }
  }

  String? _readErrorName(Object error) {
    if (error is! JSObject) return null;
    try {
      final value = error.getProperty<JSAny?>('name'.toJS);
      if (value is JSString) return value.toDart;
    } on Object {
      // Fall through.
    }
    return null;
  }

  String? _readErrorMessage(Object error) {
    if (error is SmartAccountException) return error.message;
    if (error is! JSObject) return null;
    try {
      final value = error.getProperty<JSAny?>('message'.toJS);
      if (value is JSString) return value.toDart;
    } on Object {
      // Fall through.
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Environment guard (Guard 1 from the security checklist)
  // ---------------------------------------------------------------------------

  web.CredentialsContainer? _resolveCredentials() {
    final injected = _injectedCredentials;
    if (injected != null) return injected;
    try {
      // Accessing `window.navigator` outside a browser raises a JS
      // `ReferenceError`-equivalent; the try/catch below maps that to
      // `null` so the caller emits `WebAuthnNotSupported` rather than
      // surfacing the raw JS error.
      return web.window.navigator.credentials;
    } on Object {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ArrayBuffer / Uint8List conversion helpers
  // ---------------------------------------------------------------------------

  /// Converts a Dart [Uint8List] into a JS [JSArrayBuffer] view.
  JSArrayBuffer _bytesToBuffer(Uint8List bytes) {
    final typed = Uint8List.fromList(bytes);
    return typed.buffer.toJS;
  }

  /// Converts a JS [JSArrayBuffer] into a Dart [Uint8List] copy.
  Uint8List _bufferToBytes(JSArrayBuffer buffer) {
    final bytes = buffer.toDart.asUint8List();
    return Uint8List.fromList(bytes);
  }
}
