// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'constants/bit_constants.dart';

/// `0`, or an optional `-` followed by a digit from 1 to 9 and more digits.
final RegExp _offerIdText = RegExp(r'^(?:0|-?[1-9][0-9]*)$');

/// Returns the offer id that [text] holds.
///
/// The XDR schema declares an offer id as an int64, so [text] is the decimal
/// form of a value from -2^63 to 2^63-1, without a sign on zero or a positive
/// value, leading zeros, whitespace or a radix prefix. Any other text throws a
/// [FormatException] whose source is [text] and whose message holds none of
/// it, so a caller can replace the source of a mistyped secret seed.
BigInt parseOfferId(String text) {
  if (!_offerIdText.hasMatch(text)) {
    throw FormatException('An offer id is decimal int64 text', text);
  }
  final BigInt value = BigInt.parse(text);
  if (value < BitConstants.int64MinValueBigInt ||
      value > BitConstants.int64MaxValueBigInt) {
    throw FormatException('An offer id is outside the int64 range', text);
  }
  return value;
}
