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
  /// The rendering starts from the shortest decimal representation that reads
  /// back to the same double - the digits double.toString shows - and rounds
  /// it to at most seven decimal places, trimming trailing fractional zeroes
  /// and suppressing the decimal point for whole amounts. It never uses
  /// scientific notation, which double.toString switches to below 1e-6 and at
  /// 1e21 and which anchors do not accept, and it never renders the binary
  /// expansion behind the shortest representation. A fraction that ends
  /// exactly halfway rounds away from zero.
  ///
  /// Two limits are worth knowing. An amount below half a stroop rounds to
  /// "0" and the sign is dropped, and a non-finite amount renders as the
  /// empty string; neither names an amount the caller can transact, and both
  /// leave the anchor to answer.
  static String format(double amount) {
    if (!amount.isFinite) {
      return "";
    }

    // toString is the shortest decimal representation that reads back to the
    // same double. Everything below is decimal string arithmetic on it, so
    // no binary digit beyond it can appear.
    String shortest = amount.toString();
    String sign = "";
    if (shortest.startsWith("-")) {
      sign = "-";
      shortest = shortest.substring(1);
    }

    // Split the representation into its digit string and the position of the
    // decimal point within it, folding a scientific exponent into that
    // position.
    int exponent = 0;
    final int eIndex = shortest.indexOf(RegExp(r'[eE]'));
    if (eIndex >= 0) {
      exponent = int.parse(shortest.substring(eIndex + 1));
      shortest = shortest.substring(0, eIndex);
    }
    int pointPosition;
    final int dotIndex = shortest.indexOf('.');
    if (dotIndex >= 0) {
      pointPosition = dotIndex;
      shortest = shortest.replaceFirst('.', '');
    } else {
      pointPosition = shortest.length;
    }
    final String digits = shortest;
    pointPosition += exponent;

    String integerDigits;
    String fractionDigits;
    if (pointPosition <= 0) {
      integerDigits = "0";
      fractionDigits = digits.padLeft(digits.length - pointPosition, '0');
    } else if (pointPosition >= digits.length) {
      integerDigits = digits.padRight(pointPosition, '0');
      fractionDigits = "";
    } else {
      integerDigits = digits.substring(0, pointPosition);
      fractionDigits = digits.substring(pointPosition);
    }

    // Round the fraction to seven places on the decimal digits, carrying
    // into the integer part when the fraction overflows.
    if (fractionDigits.length > 7) {
      final bool roundsUp = fractionDigits.codeUnitAt(7) >= 0x35; // '5'
      fractionDigits = fractionDigits.substring(0, 7);
      if (roundsUp) {
        final List<int> combined =
            (integerDigits + fractionDigits).codeUnits.toList();
        int index = combined.length - 1;
        bool carry = true;
        while (carry && index >= 0) {
          if (combined[index] == 0x39) {
            // '9'
            combined[index] = 0x30; // '0'
          } else {
            combined[index] += 1;
            carry = false;
          }
          index--;
        }
        String rounded = String.fromCharCodes(combined);
        if (carry) {
          rounded = "1$rounded";
        }
        fractionDigits = rounded.substring(rounded.length - 7);
        integerDigits = rounded.substring(0, rounded.length - 7);
      }
    }

    while (fractionDigits.endsWith("0")) {
      fractionDigits = fractionDigits.substring(0, fractionDigits.length - 1);
    }
    final String body = fractionDigits.isEmpty
        ? integerDigits
        : "$integerDigits.$fractionDigits";

    // A zero result carries no sign.
    if (!body.contains(RegExp(r'[1-9]'))) {
      return "0";
    }
    return sign + body;
  }
}
