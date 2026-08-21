// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Renders an asset amount for a SEP request field.
///
/// Scoped to the classic seven decimal places, and to request fields the SDK
/// types as a [double]. Not for Soroban token amounts, whose scale the token
/// defines and which routinely carry far more than seven decimals, and not
/// for transaction amounts, which reach operation XDR through
/// Util.decimalStringToStroops.
class SepRequestAmount {
  /// Renders an amount as a plain decimal string suitable for a request
  /// parameter.
  ///
  /// Never uses scientific notation, which double.toString switches to for
  /// small and large magnitudes and which anchors do not accept. Stellar
  /// assets carry at most seven decimal places, so the fraction is rounded to
  /// seven digits, trailing zeroes in the fractional part are trimmed and the
  /// decimal point is suppressed for whole amounts.
  ///
  /// Three limits are worth knowing. An amount below half a stroop rounds to
  /// "0" and the sign is dropped, and a non-finite amount renders as the
  /// empty string; neither names an amount the caller can transact, and both
  /// leave the anchor to answer. From 2^29 (536870912) upward a double no
  /// longer carries seven meaningful fractional digits, because that is
  /// where one unit in the last place first exceeds a stroop, so the last
  /// digits describe the stored value rather than the amount that was
  /// written.
  static String format(double amount) {
    if (!amount.isFinite) {
      return "";
    }

    // toStringAsFixed keeps fixed notation only below 1e21. At and above
    // that magnitude one unit in the last place exceeds one, so every such
    // double is a whole number and BigInt carries its digits exactly.
    if (amount.abs() >= 1e21) {
      return BigInt.from(amount).toString();
    }

    String formatted = amount.toStringAsFixed(7);
    while (formatted.endsWith("0")) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith(".")) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return formatted == "-0" ? "0" : formatted;
  }
}
