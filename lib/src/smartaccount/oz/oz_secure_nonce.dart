// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../xdr/xdr.dart';

/// Internal helpers shared by the OZ transaction pipeline, the OZ
/// multi-signer manager, and the OZ signer manager for drawing
/// cryptographically random material — Soroban address-credentials
/// nonces (8 bytes reinterpreted as signed Int64) and arbitrary
/// fixed-length byte buffers (WebAuthn challenges, user ids, salts).
///
/// The Soroban address-credentials `nonce` field is an `Int64`. To prevent
/// replay the contract requires the value to be unpredictable across
/// invocations, so the SDK draws 8 bytes from a [Random.secure]
/// source and reinterprets the result as a signed 64-bit integer (the
/// full signed range, both positive and negative, is valid on the wire).
///
/// Implementation note: the nonce work is done through [BigInt] rather
/// than native `int` arithmetic so the full 64 bits of entropy flow
/// through unchanged on every platform Dart targets. A naive bit-shift
/// accumulator using a native `int` would truncate to 53 bits of
/// entropy on the JS target (where `int` is a double), and would clamp
/// the high bit so the resulting nonce was always non-negative.
///
/// The [Random.secure] source is cached as a private `static final`
/// field so callers do not repeatedly pay the cost of constructing a
/// fresh secure RNG on every invocation. `Random.secure()` is documented
/// to be safe for repeated use across calls; it is not bound to any
/// particular thread or isolate.
@internal
abstract final class OZSecureNonce {
  // why: cached process-wide so high-frequency callers (signer
  // registration, multi-signer signing, transaction submission) avoid
  // the per-call setup cost of constructing a fresh `Random.secure()`
  // source. The field is initialised lazily on first access through
  // standard Dart `static final` semantics.
  static final Random _secureRandom = Random.secure();

  /// Generates an 8-byte cryptographically-random nonce reinterpreted as
  /// a signed `Int64` wrapped in an [XdrInt64].
  static XdrInt64 generate() {
    var n = BigInt.zero;
    for (var i = 0; i < 8; i++) {
      n = (n << 8) | BigInt.from(_secureRandom.nextInt(256));
    }
    final twoTo63 = BigInt.one << 63;
    final twoTo64 = BigInt.one << 64;
    final signed = n >= twoTo63 ? n - twoTo64 : n;
    return XdrInt64(signed);
  }

  /// Variant that returns the raw [BigInt] rather than an [XdrInt64]
  /// wrapper, suited to callers that build their own XDR types from the
  /// underlying value. The value spans the full signed 64-bit range.
  static BigInt generateBigInt() => generate().int64;

  /// Generates [count] cryptographically-random bytes drawn from the
  /// shared [Random.secure] source.
  ///
  /// Used for WebAuthn challenges, WebAuthn user-ids, contract salts,
  /// and any other site that needs `n` bytes of CSPRNG output. Sharing
  /// the same source as [generate] keeps the OZ stack aligned on a
  /// single audited entropy primitive.
  ///
  /// Throws [ArgumentError] when [count] is negative.
  static Uint8List bytes(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must be non-negative');
    }
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      out[i] = _secureRandom.nextInt(256);
    }
    return out;
  }
}
