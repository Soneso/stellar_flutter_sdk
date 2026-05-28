// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import '../core/allow_credential.dart';
import '../core/smart_account_errors.dart';
import '../core/web_authn_provider.dart';
import 'oz_constants.dart';

/// Method-channel name used by the platform WebAuthn bridge.
///
/// The native iOS plugin (`SmartAccountWebAuthnPlugin` in Swift) and Android
/// plugin (`SmartAccountWebAuthnPlugin` in Kotlin) both register a handler on
/// this channel. The channel name is part of the public contract between the
/// SDK and consumers who supply their own native overlay; renaming it would
/// break those overlays.
const String _webAuthnChannelName =
    'com.soneso.stellar_flutter_sdk/smartaccount/webauthn';

/// `PlatformException.code` strings emitted by the native plugins. These are
/// part of the cross-platform IPC contract and must match the strings used by
/// the iOS Swift handler and the Android Kotlin handler verbatim.
const String _codeCancelled = 'WEBAUTHN_CANCELLED';
const String _codeRegistrationFailed = 'WEBAUTHN_REGISTRATION_FAILED';
const String _codeAuthenticationFailed = 'WEBAUTHN_AUTHENTICATION_FAILED';
const String _codeNotSupported = 'WEBAUTHN_NOT_SUPPORTED';

/// `WebAuthnProvider` implementation that dispatches to the native platform's
/// WebAuthn plugin via a Flutter method channel.
///
/// On Android the underlying implementation uses the AndroidX Credential
/// Manager API; on iOS and macOS it uses Apple's `AuthenticationServices`
/// framework. The Dart bridge serialises call arguments, invokes the platform
/// method, and translates results and `PlatformException`s back into the SDK's
/// typed result and exception surface.
///
/// Instances MUST be invoked from the root isolate; background isolates do not
/// have a foreground activity/window and calls from them fail with
/// [WebAuthnRegistrationFailed] or [WebAuthnAuthenticationFailed].
///
/// For entitlement and associated-domain setup see
/// `documentation/smart-accounts/webauthn-ios.md` and
/// `documentation/smart-accounts/webauthn-android.md`.
class PlatformWebAuthnProvider implements WebAuthnProvider {
  /// Constructs a platform WebAuthn provider for the given relying party.
  ///
  /// The [methodChannel] parameter is `protected`: it exists so unit tests
  /// can substitute a mock channel via `flutter_test`'s
  /// `TestDefaultBinaryMessengerBinding.defaultBinaryMessenger.setMockMethodCallHandler`,
  /// or to inject a custom channel name in a consumer app that re-namespaces
  /// the plugin handlers. Production code MUST omit this argument so the
  /// shared channel name is used.
  PlatformWebAuthnProvider({
    required this.rpId,
    required this.rpName,
    this.timeout = OZConstants.webauthnTimeoutMs,
    this.authenticatorAttachment,
    MethodChannel? methodChannel,
  })  : assert(rpId.isNotEmpty, 'rpId must not be empty'),
        assert(rpName.isNotEmpty, 'rpName must not be empty'),
        assert(timeout > 0, 'timeout must be positive'),
        _channel = methodChannel ?? const MethodChannel(_webAuthnChannelName);

  /// Relying-party identifier (a domain name such as `example.com`). Must
  /// match the domain declared in the platform's associated-domains
  /// configuration (Apple App Site Association on iOS / macOS, Digital Asset
  /// Links on Android).
  final String rpId;

  /// Human-readable relying-party name displayed in the system passkey
  /// prompt during registration.
  final String rpName;

  /// Timeout for the WebAuthn ceremony in milliseconds. Defaults to
  /// [OZConstants.webauthnTimeoutMs] (60 s).
  final int timeout;

  /// Optional authenticator-attachment hint. `null` (the default) allows
  /// both platform and cross-platform authenticators. `"platform"` restricts
  /// to built-in biometric authenticators (Face ID / Touch ID / Android
  /// platform authenticator). `"cross-platform"` restricts to security keys.
  ///
  /// On iOS and macOS the value is currently ignored by the platform
  /// implementation because Apple's AuthenticationServices framework does
  /// not expose an equivalent control; the field is preserved across the
  /// channel for parity with Android and forward compatibility.
  final String? authenticatorAttachment;

  final MethodChannel _channel;

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async {
    final args = <String, Object?>{
      'rpId': rpId,
      'rpName': rpName,
      'timeout': timeout,
      'challenge': challenge,
      'userId': userId,
      'userName': userName,
      if (authenticatorAttachment != null)
        'authenticatorAttachment': authenticatorAttachment,
    };

    final Map<Object?, Object?>? raw;
    try {
      raw = await _channel.invokeMapMethod<Object?, Object?>('register', args);
    } on PlatformException catch (e) {
      throw _mapRegistrationException(e);
    }
    if (raw == null) {
      throw WebAuthnException.registrationFailed(
        'Native plugin returned null registration result',
      );
    }

    return _decodeRegistrationResult(raw);
  }

  /// Authenticates with an existing WebAuthn credential via the platform
  /// passkey API.
  ///
  /// See [WebAuthnProvider.authenticate] for the contract.
  ///
  /// Note: On Apple platforms (iOS, macOS) and Web, a missing credential
  /// surfaces as [WebAuthnCancelled] rather than a distinct error code,
  /// because the underlying platform APIs do not expose a separate "no
  /// credential available" result — the system silently dismisses the
  /// prompt indistinguishably from a user cancellation. On Android the
  /// equivalent native exception (`NoCredentialException`) is mapped to
  /// [WebAuthnAuthenticationFailed]. Consumers handling missing-credential
  /// separately from user-cancel should branch on `Platform.isAndroid`.
  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  }) async {
    final args = <String, Object?>{
      'rpId': rpId,
      'timeout': timeout,
      'challenge': challenge,
      if (allowCredentials != null)
        'allowCredentials': allowCredentials
            .map((credential) => <String, Object?>{
                  'id': credential.id,
                  if (credential.transports != null)
                    'transports': List<String>.from(credential.transports!),
                })
            .toList(growable: false),
    };

    final Map<Object?, Object?>? raw;
    try {
      raw =
          await _channel.invokeMapMethod<Object?, Object?>('authenticate', args);
    } on PlatformException catch (e) {
      throw _mapAuthenticationException(e);
    }
    if (raw == null) {
      throw WebAuthnException.authenticationFailed(
        'Native plugin returned null authentication result',
      );
    }

    return _decodeAuthenticationResult(raw);
  }

  WebAuthnRegistrationResult _decodeRegistrationResult(
    Map<Object?, Object?> raw,
  ) {
    final credentialId =
        _requireBytes(raw, 'credentialId', _codeRegistrationFailed);
    final publicKey = _requireBytes(raw, 'publicKey', _codeRegistrationFailed);
    final attestationObject =
        _requireBytes(raw, 'attestationObject', _codeRegistrationFailed);
    final transports = _optionalStringList(raw['transports']);
    final deviceType = _optionalString(raw['deviceType']);
    final backedUp = _optionalBool(raw['backedUp']);

    return WebAuthnRegistrationResult(
      credentialId: credentialId,
      publicKey: publicKey,
      attestationObject: attestationObject,
      transports: transports,
      deviceType: deviceType,
      backedUp: backedUp,
    );
  }

  WebAuthnAuthenticationResult _decodeAuthenticationResult(
    Map<Object?, Object?> raw,
  ) {
    final credentialId =
        _requireBytes(raw, 'credentialId', _codeAuthenticationFailed);
    final authenticatorData =
        _requireBytes(raw, 'authenticatorData', _codeAuthenticationFailed);
    final clientDataJSON =
        _requireBytes(raw, 'clientDataJSON', _codeAuthenticationFailed);
    final signature = _requireBytes(raw, 'signature', _codeAuthenticationFailed);

    return WebAuthnAuthenticationResult(
      credentialId: credentialId,
      authenticatorData: authenticatorData,
      clientDataJSON: clientDataJSON,
      signature: signature,
    );
  }

  WebAuthnException _mapRegistrationException(PlatformException e) {
    switch (e.code) {
      case _codeCancelled:
        return WebAuthnCancelled(
          message: e.message ?? 'User cancelled WebAuthn operation',
          cause: e,
        );
      case _codeNotSupported:
        return WebAuthnNotSupported(
          message: e.message ?? 'WebAuthn is not supported on this platform',
          cause: e,
        );
      case _codeRegistrationFailed:
        return WebAuthnRegistrationFailed(
          'WebAuthn registration failed: ${e.message ?? e.code}',
          e,
        );
      default:
        return WebAuthnRegistrationFailed(
          'WebAuthn registration failed: unexpected platform error '
          '${e.code} ${e.message ?? ""}'.trimRight(),
          e,
        );
    }
  }

  WebAuthnException _mapAuthenticationException(PlatformException e) {
    switch (e.code) {
      case _codeCancelled:
        return WebAuthnCancelled(
          message: e.message ?? 'User cancelled WebAuthn operation',
          cause: e,
        );
      case _codeNotSupported:
        return WebAuthnNotSupported(
          message: e.message ?? 'WebAuthn is not supported on this platform',
          cause: e,
        );
      case _codeAuthenticationFailed:
        return WebAuthnAuthenticationFailed(
          'WebAuthn authentication failed: ${e.message ?? e.code}',
          e,
        );
      default:
        return WebAuthnAuthenticationFailed(
          'WebAuthn authentication failed: unexpected platform error '
          '${e.code} ${e.message ?? ""}'.trimRight(),
          e,
        );
    }
  }
}

/// Reads a required byte-array field from a method-channel result map.
///
/// Method channels return byte arrays as `Uint8List`. Native plugins MUST
/// emit `Uint8List`-compatible payloads; defensive handling for `List<int>`
/// is included to tolerate non-conforming custom message codecs.
Uint8List _requireBytes(
  Map<Object?, Object?> map,
  String key,
  String contextCode,
) {
  final value = map[key];
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  if (value is List) {
    return Uint8List.fromList(value.cast<int>());
  }
  throw _missingBytesException(key, contextCode, value);
}

WebAuthnException _missingBytesException(
  String field,
  String contextCode,
  Object? actual,
) {
  final reason = actual == null
      ? 'Missing required byte field "$field" in native response'
      : 'Field "$field" in native response has unexpected type '
          '${actual.runtimeType}; expected Uint8List';
  if (contextCode == _codeRegistrationFailed) {
    return WebAuthnException.registrationFailed(reason);
  }
  return WebAuthnException.authenticationFailed(reason);
}

List<String>? _optionalStringList(Object? value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((dynamic e) => e as String).toList(growable: false);
  }
  return null;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return null;
}

bool? _optionalBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  return null;
}
