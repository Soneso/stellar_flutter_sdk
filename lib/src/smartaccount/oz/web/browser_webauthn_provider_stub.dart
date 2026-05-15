// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../core/allow_credential.dart';
import '../../core/web_authn_provider.dart';
import '../oz_constants.dart';

/// Non-web stub of [BrowserWebAuthnProvider].
///
/// This file is selected by the conditional-export wiring on every target
/// where `dart:js_interop` is unavailable (Dart VM, Flutter mobile/desktop
/// AOT, Flutter mobile JIT). It exposes the same constructor and method
/// signatures as the browser implementation so consumer code that calls
/// `BrowserWebAuthnProvider(...)` compiles unchanged on every target.
///
/// Construction never throws; this matches the symmetry rule documented on
/// the browser implementation. Each method invocation throws
/// [UnsupportedError] with guidance toward the platform-specific provider
/// that should be used instead.
class BrowserWebAuthnProvider extends WebAuthnProvider {
  /// Relying party identifier (e.g. `app.example.com`).
  final String rpId;

  /// Human-readable relying party name displayed during ceremonies.
  final String rpName;

  /// Timeout in milliseconds for WebAuthn ceremonies.
  final int timeoutMs;

  /// Constructs a [BrowserWebAuthnProvider] stub. The constructor accepts
  /// the same parameters as the browser implementation so cross-target
  /// code compiles unchanged.
  BrowserWebAuthnProvider({
    required this.rpId,
    required this.rpName,
    this.timeoutMs = OZConstants.webauthnTimeoutMs,
  });

  Never _unsupported() => throw UnsupportedError(
        'BrowserWebAuthnProvider is only available on Flutter web. '
        'On non-web targets use AppleWebAuthnProvider (iOS / macOS) or '
        'PlatformWebAuthnProvider (Android).',
      );

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async =>
      _unsupported();

  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  }) async =>
      _unsupported();
}
