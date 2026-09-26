// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'util.dart';
import 'xdr/xdr.dart';
import 'constants/bit_constants.dart';

/// Represents a price as a rational number (fraction) on Stellar.
///
/// Stellar represents prices as fractions with a numerator and denominator
/// to maintain precision. This avoids floating-point rounding errors common
/// in financial calculations.
///
/// Price representation:
/// - **Numerator (n)**: The top number of the fraction
/// - **Denominator (d)**: The bottom number of the fraction
/// - Price value = n / d
///
/// Both numerator and denominator must fit in 32-bit signed integers
/// (range: -2,147,483,648 to 2,147,483,647).
///
/// Common use cases:
/// - Order book prices in trading offers
/// - Exchange rates between assets
/// - Path payment price limits
/// - Trade aggregation prices
///
/// Creating prices:
/// ```dart
/// // Direct creation with fraction
/// Price price1 = Price(100, 1);  // 100/1 = 100
/// Price price2 = Price(1, 2);    // 1/2 = 0.5
/// Price price3 = Price(355, 113); // ~3.14159 (approximation of pi)
///
/// // From string (approximates to fraction)
/// Price price4 = Price.fromString("1.5");  // May become 3/2
/// Price price5 = Price.fromString("0.333"); // Approximates 1/3
///
/// // Exact representation preferred for precision
/// Price exactHalf = Price(1, 2); // Better than fromString("0.5")
/// ```
///
/// Using in operations:
/// ```dart
/// // Create offer with price
/// ManageBuyOfferOperation offer = ManageBuyOfferOperationBuilder(
///   selling: assetA,
///   buying: assetB,
///   amount: "100",
///   price: "1.5"  // String converted internally
/// ).build();
///
/// // Access price components
/// double value = price.numerator! / price.denominator!;
/// print("Price: ${price.numerator}/${price.denominator} = $value");
/// ```
///
/// Important notes:
/// - Always prefer direct fraction creation over [fromString] for precision
/// - [fromString] approximates decimals to fractions (may lose precision)
/// - Both n and d must fit in 32-bit signed integers
/// - Zero denominator is invalid (division by zero)
/// - The Stellar network rejects offers whose price is zero or negative,
///   and js-stellar-base refuses such values at parse time; this SDK
///   refuses zero at parse time and parses negative values faithfully
///
/// Price approximation limitations:
/// ```dart
/// // fromString uses continued fractions algorithm
/// Price pi = Price.fromString("3.14159");
/// // May not be exact due to 32-bit integer constraints
///
/// // For exact prices, use direct fractions
/// Price exact = Price(314159, 100000);
/// ```
///
/// See also:
/// - [ManageBuyOfferOperation] for creating buy offers with prices
/// - [ManageSellOfferOperation] for creating sell offers with prices
/// - [PathPaymentStrictReceiveOperation] for path payments with price limits
/// - [PathPaymentStrictSendOperation] for path payments with price limits
class Price {
  /// The numerator of the price fraction.
  int n;

  /// The denominator of the price fraction.
  int d;

  /// Creates a new Price from numerator and denominator.
  ///
  /// This is the preferred way to create prices as it maintains exact precision.
  ///
  /// Parameters:
  /// - [n] Numerator (must fit in 32-bit signed integer)
  /// - [d] Denominator (must fit in 32-bit signed integer, non-zero)
  ///
  /// Example:
  /// ```dart
  /// // Price of 1.5 (exactly represented as 3/2)
  /// Price price = Price(3, 2);
  ///
  /// // Price of 100
  /// Price highPrice = Price(100, 1);
  ///
  /// // Price of 0.001
  /// Price lowPrice = Price(1, 1000);
  /// ```
  Price(this.n, this.d);

  /// Deserializes a Price from JSON data.
  ///
  /// This factory method creates a Price instance from a JSON map, typically
  /// received from Horizon API responses. The JSON must contain 'n' (numerator)
  /// and 'd' (denominator) fields.
  ///
  /// Parameters:
  /// - [json] Map containing price data with keys:
  ///   - 'n': Numerator (int or string)
  ///   - 'd': Denominator (int or string)
  ///
  /// Returns: Price instance with the numerator and denominator
  ///
  /// Throws:
  /// - [Exception] If the JSON format is invalid or required fields are missing
  ///
  /// Example:
  /// ```dart
  /// // From Horizon API response with integer values
  /// Map<String, dynamic> json1 = {'n': 3, 'd': 2};
  /// Price price1 = Price.fromJson(json1);
  /// print("${price1.numerator}/${price1.denominator}"); // 3/2
  ///
  /// // From JSON with string values
  /// Map<String, dynamic> json2 = {'n': '100', 'd': '1'};
  /// Price price2 = Price.fromJson(json2);
  /// print("${price2.numerator}/${price2.denominator}"); // 100/1
  ///
  /// // Parse offer price from API
  /// var offer = await sdk.offers.forAccount(accountId).execute();
  /// Price offerPrice = Price.fromJson(offer.price);
  /// ```
  ///
  /// See also:
  /// - [toJson] for serializing prices to JSON
  factory Price.fromJson(Map<String, dynamic> json) {
    if (json['n'] is int && json['d'] is int) {
      return new Price(json['n'], json['d']);
    } else if (json['n'] is String && json['d'] is String) {
      int pN = checkNotNull(
          int.tryParse(json['n']), "invalid price in horizon response");
      int pD = checkNotNull(
          int.tryParse(json['d']), "invalid price in horizon response");
      return new Price(pN, pD);
    }
    throw Exception("invalid price in horizon response");
  }

  /// Converts the Price to a JSON map.
  ///
  /// Returns: Map with 'n' (numerator) and 'd' (denominator) keys
  ///
  /// Example:
  /// ```dart
  /// Price price = Price(3, 2);
  /// Map<String, dynamic> json = price.toJson();
  /// // Returns: {'n': 3, 'd': 2}
  /// ```
  Map<String, dynamic> toJson() => <String, dynamic>{'n': n, 'd': d};

  /// Returns the numerator of the price fraction.
  ///
  /// The numerator is the top number in the fraction representation.
  int? get numerator => n;

  /// Returns the denominator of the price fraction.
  ///
  /// The denominator is the bottom number in the fraction representation.
  int? get denominator => d;

  /// Converts a decimal price string to a fraction of two int32 values.
  ///
  /// The decimal is read exactly, as an integer over a power of ten, and
  /// expanded into a continued fraction with integer arithmetic. The result
  /// is the last convergent whose numerator and denominator both fit an
  /// int32, so it is always in lowest terms:
  /// - A nonzero decimal whose fraction in lowest terms, with a positive
  ///   denominator, fits int32 yields that fraction: "0.000000004096" is
  ///   1/244140625 and "0.99999999" is 99999999/100000000.
  /// - Any other decimal yields the closest convergent within the int32
  ///   bounds: "0.33333333333333333333" is 1/3.
  ///
  /// Surrounding whitespace is removed. What remains must be digits, then
  /// optionally a decimal point and any further digits, after at most one
  /// leading sign.
  ///
  /// Parameters:
  /// - [price] Decimal price as string (e.g., "1.5", "0.333", "123.456")
  ///
  /// Returns: Price object with the numerator and denominator of the value
  /// or of its closest int32 convergent
  ///
  /// Throws:
  /// - [Exception] If the price is not a decimal number
  /// - [Exception] If no int32 fraction can carry the value: zero, a value
  ///   too small for any int32 fraction, or a value beyond the int32
  ///   boundaries
  ///
  /// Example:
  /// ```dart
  /// Price p1 = Price.fromString("1.5");
  /// print("${p1.numerator}/${p1.denominator}"); // 3/2
  ///
  /// Price p2 = Price.fromString("0.0000001");
  /// print("${p2.numerator}/${p2.denominator}"); // 1/10000000
  ///
  /// // A decimal beyond int32 precision yields its closest convergent
  /// Price p3 = Price.fromString("3.14159265358979");
  /// ```
  ///
  /// Algorithm notes:
  /// - Numerator and denominator are bounded by INT32_MAX_VALUE, and the
  ///   numerator also by INT32_MIN_VALUE
  /// - A negative value is expanded from its floor, so its numerator carries
  ///   the sign and its denominator stays positive
  ///
  /// See also:
  /// - [Price] constructor for creating exact fractions
  static Price fromString(String price) {
    // A price is decimal digits, so the value is validated before BigInt.parse
    // sees it: BigInt.parse also reads hex and honours a sign of its own, and
    // the split below reads a fraction only from a value in exactly two parts.
    final String trimmed = price.trim();
    if (!RegExp(r'^[+-]?\d+(\.\d*)?$').hasMatch(trimmed)) {
      throw Exception("Not a decimal price: $price");
    }

    // The value is exactly numerator / denominator, with the sign on the
    // numerator and a power of ten as the denominator.
    List<String> two = trimmed.split(".");
    String fractionDigits = two.length == 2 ? two[1] : "";
    BigInt numerator = BigInt.parse(two[0] + fractionDigits);
    BigInt denominator = BigInt.from(10).pow(fractionDigits.length);

    BigInt maxInt = BigInt.from(BitConstants.INT32_MAX_VALUE);
    BigInt minInt = BigInt.from(BitConstants.INT32_MIN_VALUE);
    List<List<BigInt>> fractions = [];
    fractions.add([BigInt.zero, BigInt.one]);
    fractions.add([BigInt.one, BigInt.zero]);
    int i = 2;
    while (true) {
      // Each term is the floor of the remaining quotient. BigInt division
      // truncates towards zero, which for a negative value is one too high:
      // -1.5 is floor -2 with remainder 0.5, not -1 with remainder -0.5.
      BigInt a = numerator ~/ denominator;
      BigInt remainder = numerator - a * denominator;
      if (remainder.isNegative) {
        a -= BigInt.one;
        remainder += denominator;
      }
      if (a > maxInt) {
        break;
      }
      BigInt h = a * (fractions[i - 1][0]) + (fractions[i - 2][0]);
      BigInt k = a * (fractions[i - 1][1]) + (fractions[i - 2][1]);
      // A negative price leaves no numerator positive, so an upper bound alone
      // would let one run past the int32 floor, where XdrInt32 keeps only its
      // low 32 bits. Each convergent denominator is at least 1, so only the
      // numerator needs a floor.
      if (h > maxInt || k > maxInt || h < minInt) {
        break;
      }
      fractions.add([h, k]);
      // A zero remainder means the convergent just recorded is the value.
      if (remainder == BigInt.zero) {
        break;
      }
      numerator = denominator;
      denominator = remainder;
      i = i + 1;
    }
    BigInt n = fractions[fractions.length - 1][0];
    BigInt d = fractions[fractions.length - 1][1];
    // Beyond the int32 boundaries the expansion ends before recording a
    // convergent, leaving the 1/0 seed; zero and values too small for any
    // int32 fraction end at 0/1. Neither encodes a price the network
    // accepts, so both are refused locally.
    if (n == BigInt.zero || d == BigInt.zero) {
      throw Exception("Not a price an int32 fraction can carry: $price");
    }
    return new Price(n.toInt(), d.toInt());
  }

  /// The number of fractional digits after which [toDecimalString] stops.
  ///
  /// Cutting after 20 digits keeps the string within 10^-20 of n / d. For a
  /// nonzero n / d whose lowest terms, with a positive denominator, fit int32,
  /// that is closer than half the square of 1 / d, so the continued fraction
  /// of the string passes through n / d in lowest terms and the convergent
  /// after it no longer fits an int32: [Price.fromString] recovers n / d.
  static const int _maxDecimalFractionDigits = 20;

  /// Returns the value n / d as a plain decimal string.
  ///
  /// The string is the form [Price.fromString] parses, which accepts plain
  /// decimal digits only, so the expansion is computed by integer long
  /// division and never uses exponent notation: 1/10000000 is "0.0000001".
  /// The fractional digits end where the division terminates or, for a
  /// non-terminating value such as 1/3, after 20 digits (truncated, not
  /// rounded). Trailing zeros are removed and a whole value has no decimal
  /// point: 3/1 is "3" and 0/1 is "0". A negative value starts with "-".
  ///
  /// Throws:
  /// - [ArgumentError] If the denominator is zero
  ///
  /// Example:
  /// ```dart
  /// Price(3, 2).toDecimalString(); // "1.5"
  /// Price(1, 3).toDecimalString(); // "0.33333333333333333333"
  /// ```
  String toDecimalString() {
    if (d == 0) {
      throw ArgumentError("Price denominator must not be zero: $n/$d");
    }
    BigInt numerator = BigInt.from(n).abs();
    BigInt denominator = BigInt.from(d).abs();
    bool negative = n != 0 && (n < 0) != (d < 0);

    String integerPart = (numerator ~/ denominator).toString();
    BigInt remainder = numerator.remainder(denominator);
    StringBuffer fraction = StringBuffer();
    for (int i = 0;
        i < _maxDecimalFractionDigits && remainder != BigInt.zero;
        i++) {
      remainder *= BigInt.from(10);
      fraction.write(remainder ~/ denominator);
      remainder = remainder.remainder(denominator);
    }
    // A terminating expansion ends on a non-zero digit; only the cut after
    // the last digit taken can leave zeros behind.
    String fractionDigits =
        fraction.toString().replaceFirst(RegExp(r'0+$'), '');

    String value = fractionDigits.isEmpty
        ? integerPart
        : "$integerPart.$fractionDigits";
    return negative ? "-$value" : value;
  }

  /// Converts this Price to its XDR (External Data Representation) format.
  ///
  /// XDR is the binary format used by Stellar protocol for serializing
  /// data structures.
  ///
  /// Returns: XdrPrice object containing the numerator and denominator
  ///
  /// Example:
  /// ```dart
  /// Price price = Price(3, 2);
  /// XdrPrice xdrPrice = price.toXdr();
  /// // Used internally when building transactions
  /// ```
  ///
  /// See also:
  /// - [fromJson] for creating Price from JSON response
  XdrPrice toXdr() {

    XdrInt32 n = new XdrInt32(this.n);
    XdrInt32 d = new XdrInt32(this.d);
    return new XdrPrice(n, d);
  }

  /// Compares this Price with another object for equality.
  ///
  /// Two prices are considered equal if both their numerators and denominators
  /// are equal. Note that equivalent fractions are NOT considered equal unless
  /// they have the exact same numerator and denominator values.
  ///
  /// Parameters:
  /// - [object] Object to compare with
  ///
  /// Returns: true if both numerator and denominator match, false otherwise
  ///
  /// Example:
  /// ```dart
  /// Price price1 = Price(3, 2);
  /// Price price2 = Price(3, 2);
  /// Price price3 = Price(6, 4); // Equivalent to 3/2 but different representation
  ///
  /// print(price1 == price2); // true (exact match)
  /// print(price1 == price3); // false (different numerator/denominator)
  ///
  /// // Both represent 1.5, but equality checks exact values
  /// print(price1.numerator! / price1.denominator!); // 1.5
  /// print(price3.numerator! / price3.denominator!); // 1.5
  /// ```
  ///
  /// Note: For comparing price values mathematically, compute the decimal
  /// values and compare those instead:
  /// ```dart
  /// double value1 = price1.numerator! / price1.denominator!;
  /// double value2 = price3.numerator! / price3.denominator!;
  /// print(value1 == value2); // true (same value)
  /// ```
  @override
  bool operator ==(Object object) {
    if (!(object is Price)) {
      return false;
    }

    return this.numerator == object.numerator &&
        this.denominator == object.denominator;
  }
}
