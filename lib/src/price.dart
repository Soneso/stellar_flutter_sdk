// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'util.dart';
import 'xdr/xdr_other.dart';
import 'xdr/xdr_type.dart';

/// Represents Price. Price in Stellar is represented as a fraction.
class Price {
  int n;
  int d;

  /// Create a new price. Price in Stellar is represented as a fraction.
  Price(this.n, this.d);

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

  Map<String, dynamic> toJson() => <String, dynamic>{'n': n, 'd': d};

  /// Returns numerator.
  int? get numerator => n;

  /// Returns denominator.
  int? get denominator => d;

  /// Approximates <code>price</code> to a fraction.
  /// Please remember that this function can give unexpected results for values that cannot be represented as a
  /// fraction with 32-bit numerator and denominator. It's safer to create a Price object using the constructor.
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

  /// Generates Price XDR object.
  XdrPrice toXdr() {

    XdrInt32 n = new XdrInt32(this.n);
    XdrInt32 d = new XdrInt32(this.d);
    return new XdrPrice(n, d);
  }

  @override
  bool operator ==(Object object) {
    if (!(object is Price)) {
      return false;
    }

    return this.numerator == object.numerator &&
        this.denominator == object.denominator;
  }
}
