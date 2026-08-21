import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('Price', () {
    group('Price creation', () {
      test('creates Price from numerator and denominator integers', () {
        final price = Price(3, 2);

        expect(price.numerator, equals(3));
        expect(price.denominator, equals(2));
      });

      test('creates Price with numerator 1 and denominator 1', () {
        final price = Price(1, 1);

        expect(price.numerator, equals(1));
        expect(price.denominator, equals(1));
      });

      test('creates Price with large numerator and denominator', () {
        final price = Price(2147483647, 2147483646);

        expect(price.numerator, equals(2147483647));
        expect(price.denominator, equals(2147483646));
      });

      test('creates Price with zero numerator', () {
        final price = Price(0, 1);

        expect(price.numerator, equals(0));
        expect(price.denominator, equals(1));
      });
    });

    group('Price.fromString', () {
      test('throws on a value that is not a decimal price', () {
        // A price is decimal digits, so hex, exponents, thousands separators
        // and a repeated decimal point are all refused.
        for (final value in [
          "0x10",
          "0X1F",
          "-0x10",
          "+0x10",
          "--1",
          "++5",
          "+-1",
          "1.2.3",
          "1..2",
          "1.5.",
          "1.5e2",
          "1 . 5",
          "abc",
          "1e3",
          "1,5",
          "",
          ".",
          ".5",
        ]) {
          expect(
            () => Price.fromString(value),
            throwsA(predicate((e) =>
                e is Exception &&
                e.toString().contains("Not a decimal price"))),
            reason: 'expected "$value" to be refused',
          );
        }
      });

      test('accepts a sign and surrounding whitespace', () {
        expect(Price.fromString("+1.5").numerator, equals(3));
        expect(Price.fromString("+1.5").denominator, equals(2));
        expect(Price.fromString("+100").numerator, equals(100));

        final padded = Price.fromString(" 1.5 ");
        expect(padded.numerator, equals(3));
        expect(padded.denominator, equals(2));
      });

      test('approximates a negative price from its floor', () {
        // The expansion consumes the floor and the remainder above it, so a
        // negative price with a fraction takes one lower than the part
        // truncated towards zero.
        expect(Price.fromString("-1.5").numerator, equals(-3));
        expect(Price.fromString("-1.5").denominator, equals(2));

        expect(Price.fromString("-0.5").numerator, equals(-1));
        expect(Price.fromString("-0.5").denominator, equals(2));

        expect(Price.fromString("-2.25").numerator, equals(-9));
        expect(Price.fromString("-2.25").denominator, equals(4));

        expect(Price.fromString("-0.001").numerator, equals(-1));
        expect(Price.fromString("-0.001").denominator, equals(1000));

        // A negative whole number has no fraction to carry.
        expect(Price.fromString("-1").numerator, equals(-1));
        expect(Price.fromString("-1").denominator, equals(1));
        expect(Price.fromString("-100").numerator, equals(-100));
        expect(Price.fromString("-100").denominator, equals(1));
      });

      test('keeps a negative price inside the int32 range', () {
        // Every numerator of a negative price is negative, so an upper bound
        // alone would let the expansion run past the int32 floor. Seven
        // decimal places is the precision a price arrives in.
        for (final value in ["-7.0217221", "-50.9702439", "-7.6150891"]) {
          final price = Price.fromString(value);

          expect(price.numerator, greaterThanOrEqualTo(-2147483648));
          expect(price.denominator, lessThanOrEqualTo(2147483647));
          expect(price.numerator! / price.denominator!,
              closeTo(double.parse(value), 1e-9),
              reason: 'expected "$value" to approximate its own value');
        }

        // The floor itself is representable, so it is kept rather than
        // broken on. A bound one short of it yields a zero denominator.
        expect(Price.fromString("-2147483648").numerator, equals(-2147483648));
        expect(Price.fromString("-2147483648").denominator, equals(1));
        expect(
            Price.fromString("-2147483647.5").numerator, equals(-2147483648));
        expect(Price.fromString("-2147483647.5").denominator, equals(1));
      });

      test('accepts a value with nothing after the decimal point', () {
        expect(Price.fromString("1.").numerator, equals(1));
        expect(Price.fromString("1.").denominator, equals(1));
        expect(Price.fromString("0.").numerator, equals(0));
      });

      test('creates Price from string "1.5"', () {
        final price = Price.fromString("1.5");

        expect(price.numerator, equals(3));
        expect(price.denominator, equals(2));
      });

      test('creates Price from string "0.5"', () {
        final price = Price.fromString("0.5");

        expect(price.numerator, equals(1));
        expect(price.denominator, equals(2));
      });

      test('creates Price from string "1.0"', () {
        final price = Price.fromString("1.0");

        expect(price.numerator, equals(1));
        expect(price.denominator, equals(1));
      });

      test('creates Price from string "100"', () {
        final price = Price.fromString("100");

        expect(price.numerator, equals(100));
        expect(price.denominator, equals(1));
      });

      test('creates Price from string with very small decimals', () {
        final price = Price.fromString("0.001");

        final decimalValue = price.numerator! / price.denominator!;
        expect(decimalValue, closeTo(0.001, 0.0001));
      });

      test('creates Price from string with very large number', () {
        final price = Price.fromString("1000000");

        expect(price.numerator, equals(1000000));
        expect(price.denominator, equals(1));
      });

      test('creates Price from string "0.333333" approximating 1/3', () {
        final price = Price.fromString("0.333333");

        final decimalValue = price.numerator! / price.denominator!;
        expect(decimalValue, closeTo(0.333333, 0.00001));
      });

      test('creates Price from string "3.14159" approximating pi', () {
        final price = Price.fromString("3.14159");

        final decimalValue = price.numerator! / price.denominator!;
        expect(decimalValue, closeTo(3.14159, 0.0001));
      });
    });

    group('Price XDR serialization', () {
      test('Price XDR round-trip with simple fraction', () {
        final price = Price(3, 2);
        final xdr = price.toXdr();

        expect(xdr.n.int32, equals(3));
        expect(xdr.d.int32, equals(2));
      });

      test('Price XDR round-trip with large values', () {
        final price = Price(1000000, 999999);
        final xdr = price.toXdr();

        expect(xdr.n.int32, equals(1000000));
        expect(xdr.d.int32, equals(999999));
      });

      test('Price XDR round-trip with zero numerator', () {
        final price = Price(0, 1);
        final xdr = price.toXdr();

        expect(xdr.n.int32, equals(0));
        expect(xdr.d.int32, equals(1));
      });
    });

    group('Price equality', () {
      test('equal prices with same numerator and denominator', () {
        final price1 = Price(3, 2);
        final price2 = Price(3, 2);

        expect(price1 == price2, isTrue);
      });

      test('unequal prices with different numerators', () {
        final price1 = Price(3, 2);
        final price2 = Price(6, 2);

        expect(price1 == price2, isFalse);
      });

      test('unequal prices with different denominators', () {
        final price1 = Price(3, 2);
        final price2 = Price(3, 4);

        expect(price1 == price2, isFalse);
      });

      test('equivalent fractions are not equal without reduction', () {
        final price1 = Price(3, 2);
        final price2 = Price(6, 4);

        expect(price1 == price2, isFalse);
      });

      test('Price not equal to non-Price object', () {
        final price = Price(3, 2);

        expect(price == "3/2", isFalse);
        expect(price == 1.5, isFalse);
      });
    });

    group('Price.fromJson', () {
      test('creates Price from JSON with integer values', () {
        final json = {'n': 3, 'd': 2};
        final price = Price.fromJson(json);

        expect(price.numerator, equals(3));
        expect(price.denominator, equals(2));
      });

      test('creates Price from JSON with string values', () {
        final json = {'n': '100', 'd': '1'};
        final price = Price.fromJson(json);

        expect(price.numerator, equals(100));
        expect(price.denominator, equals(1));
      });

      test('throws exception for invalid JSON format', () {
        final json = {'n': 'invalid', 'd': 'invalid'};

        expect(
          () => Price.fromJson(json),
          throwsException,
        );
      });

      test('throws exception for missing fields', () {
        final json = {'n': 3};

        expect(
          () => Price.fromJson(json),
          throwsException,
        );
      });
    });

    group('Price.toJson', () {
      test('converts Price to JSON map', () {
        final price = Price(3, 2);
        final json = price.toJson();

        expect(json['n'], equals(3));
        expect(json['d'], equals(2));
      });

      test('converts Price with large values to JSON', () {
        final price = Price(1000000, 999999);
        final json = price.toJson();

        expect(json['n'], equals(1000000));
        expect(json['d'], equals(999999));
      });
    });

    group('Price getters', () {
      test('numerator getter returns correct value', () {
        final price = Price(355, 113);

        expect(price.numerator, equals(355));
      });

      test('denominator getter returns correct value', () {
        final price = Price(355, 113);

        expect(price.denominator, equals(113));
      });
    });
  });
}
