// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'util.dart';
import 'xdr/xdr_other.dart';
import 'xdr/xdr_type.dart';

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
/// - Negative prices are technically possible but rarely used
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

  /// Approximates a decimal price string to a rational fraction.
  ///
  /// This method uses the continued fractions algorithm to find a fraction
  /// that approximates the given decimal value, constrained by 32-bit integers.
  ///
  /// Parameters:
  /// - [price] Decimal price as string (e.g., "1.5", "0.333", "123.456")
  ///
  /// Returns: Price object with numerator and denominator approximating the input
  ///
  /// Warning: This function can give unexpected results for values that cannot
  /// be exactly represented as a fraction with 32-bit numerator and denominator.
  /// For precise prices, use the [Price] constructor directly with exact fractions.
  ///
  /// Example:
  /// ```dart
  /// // Simple decimal approximation
  /// Price p1 = Price.fromString("1.5");
  /// print("${p1.numerator}/${p1.denominator}"); // May print: 3/2
  ///
  /// // Repeating decimal approximation
  /// Price p2 = Price.fromString("0.333333");
  /// print("${p2.numerator}/${p2.denominator}"); // Approximates 1/3
  ///
  /// // Complex decimal
  /// Price p3 = Price.fromString("3.14159");
  /// // Will approximate π, but may not be exact
  ///
  /// // For exact prices, prefer direct construction
  /// Price exact = Price(355, 113); // Exact fraction for π approximation
  /// ```
  ///
  /// Algorithm notes:
  /// - Uses continued fractions for best rational approximation
  /// - Constrained by Int32.MAX_VALUE for both numerator and denominator
  /// - May not converge for some decimal values
  /// - Precision depends on the decimal's representability as a fraction
  ///
  /// See also:
  /// - [Price] constructor for creating exact fractions
  static Price fromString(String price) {

    List<String> two = price.split(".");
    BigInt number = BigInt.parse(two[0]);
    double f = 0.0;
    if (two.length == 2) {
      f = double.parse("0.${two[1]}");
    }
    BigInt maxInt = BigInt.from(Int32.MAX_VALUE.toInt());
    BigInt a;
    // List<List<BigInt>> fractions = List<List<BigInt>>();
    List<List<BigInt>> fractions = [];
    fractions.add([BigInt.zero, BigInt.one]);
    fractions.add([BigInt.one, BigInt.zero]);
    int i = 2;
    while (true) {
      if (number > maxInt) {
        break;
      }
      a = number;
      BigInt h = a * (fractions[i - 1][0]) + (fractions[i - 2][0]);
      BigInt k = a * (fractions[i - 1][1]) + (fractions[i - 2][1]);
      if (h > maxInt || k > maxInt) {
        break;
      }
      fractions.add([h, k]);
      if (f == 0.0) {
        break;
      }
      double point = 1 / f;
      number = BigInt.from(point);
      f = point - number.toDouble();
      i = i + 1;
    }
    BigInt n = fractions[fractions.length - 1][0];
    BigInt d = fractions[fractions.length - 1][1];
    return new Price(n.toInt(), d.toInt());
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
