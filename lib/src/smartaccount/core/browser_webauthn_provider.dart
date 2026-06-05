// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Public facade for the browser WebAuthn provider.
///
/// On Flutter web (`dart:js_interop` available) this re-exports the real
/// implementation that drives `navigator.credentials`. On every other
/// target it re-exports a stub that throws [UnsupportedError] from each
/// method while keeping construction safe.
///
/// Consumers should always import this facade rather than the platform
/// files directly. The conditional-export wiring guarantees the correct
/// implementation is selected at compile time without any call-site
/// branching.
library;

export 'web/browser_webauthn_provider_stub.dart'
    if (dart.library.js_interop) 'web/browser_webauthn_provider_web.dart';
