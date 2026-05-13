// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:meta/meta.dart';

import '../../xdr/xdr.dart';

/// Internal helpers shared by the OZ transaction pipeline and the OZ
/// multi-signer manager for generating cryptographically random
/// Soroban address-credentials nonces.
///
/// The Soroban address-credentials `nonce` field is an `Int64`. To prevent
/// replay the contract requires the value to be unpredictable across
/// invocations, so the SDK draws 8 bytes from a [Random.secure]
/// source and reinterprets the result as a signed 64-bit integer (the
/// full signed range, both positive and negative, is valid on the wire).
///
/// Implementation note: the work is done through [BigInt] rather than
/// native `int` arithmetic so the full 64 bits of entropy flow through
/// unchanged on every platform Dart targets. A naive bit-shift
/// accumulator using a native `int` would truncate to 53 bits of
/// entropy on the JS target (where `int` is a double), and would clamp
/// the high bit so the resulting nonce was always non-negative.
@internal
abstract final class OZSecureNonce {
  /// Generates an 8-byte cryptographically-random nonce reinterpreted as
  /// a signed `Int64` wrapped in an [XdrInt64].
  ///
  /// Each call instantiates a fresh [Random.secure] source. The cost is
  /// negligible compared to the surrounding RPC round-trips and keeps
  /// the helper free of process-wide state.
  static XdrInt64 generate() {
    final random = Random.secure();
    var n = BigInt.zero;
    for (var i = 0; i < 8; i++) {
      n = (n << 8) | BigInt.from(random.nextInt(256));
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
}
