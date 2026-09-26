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
      });

      test('refuses a value no int32 fraction can carry', () {
        // Beyond the int32 boundaries the expansion ends before recording a
        // convergent, and zero or a value too small for any int32 fraction
        // ends at 0/1. Neither encodes a price the network accepts, so both
        // are refused locally.
        for (final value in [
          "2147483648",
          "-2147483649",
          "3000000000",
          "12345678901234567890.5",
          "0",
          "0.",
          "0.0000000001",
        ]) {
          expect(() => Price.fromString(value), throwsA(isA<Exception>()),
              reason: 'expected "$value" to be refused');
        }

        // The boundaries themselves are int32 values and are kept.
        expect(Price.fromString("2147483647").numerator, equals(2147483647));
        expect(Price.fromString("2147483647").denominator, equals(1));
      });

      test('stops at the whole part when the next quotient exceeds int32', () {
        // With 308 to 322 leading zeros the value is 1/10^309 to 1/10^323.
        // Its whole part is 0 and the next partial quotient is 10^309 to
        // 10^323, far beyond int32, so the expansion stops at 0/1 and the
        // value is refused with the documented exception.
        for (final zeros in [308, 315, 322]) {
          final value = "0.${"0" * zeros}1";
          expect(
            () => Price.fromString(value),
            throwsA(predicate((e) =>
                e is Exception &&
                e
                    .toString()
                    .contains("Not a price an int32 fraction can carry"))),
            reason: 'expected the $zeros-zeros value to be refused',
          );
        }

        // With a whole part of 12345 the next partial quotient is 10^311,
        // so the expansion stops at 12345/1.
        final kept = Price.fromString("12345.${"0" * 310}1");
        expect(kept.numerator, equals(12345));
        expect(kept.denominator, equals(1));
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

    group('Price.toDecimalString', () {
      test('writes a small price without exponent notation', () {
        expect(Price(1, 10000000).toDecimalString(), equals("0.0000001"));
      });

      test('writes a terminating fraction', () {
        expect(Price(3, 2).toDecimalString(), equals("1.5"));
      });

      test('writes a whole price without a decimal point', () {
        expect(Price(1, 1).toDecimalString(), equals("1"));
        expect(Price(100, 1).toDecimalString(), equals("100"));
        expect(Price(2147483647, 1).toDecimalString(), equals("2147483647"));
      });

      test('cuts a non-terminating fraction after 20 digits', () {
        expect(Price(1, 3).toDecimalString(), equals("0.33333333333333333333"));
        expect(Price(355, 113).toDecimalString(), equals("3.14159292035398230088"));
        expect(Price(2, 3).toDecimalString(), equals("0.66666666666666666666"));
      });

      test('writes the smallest int32 fraction to 20 digits', () {
        expect(Price(1, 2147483647).toDecimalString(), equals("0.00000000046566128752"));
      });

      test('removes zeros left at the cut', () {
        // The first 20 digits of 1/111 are 00900900900900900900.
        expect(Price(1, 111).toDecimalString(), equals("0.009009009009009009"));
      });

      test('writes a negative price with a leading sign', () {
        expect(Price(-1, 2).toDecimalString(), equals("-0.5"));
        expect(Price(1, -2).toDecimalString(), equals("-0.5"));
        expect(Price(-1, -2).toDecimalString(), equals("0.5"));
      });

      test('writes zero as 0', () {
        expect(Price(0, 1).toDecimalString(), equals("0"));
        expect(Price(0, -1).toDecimalString(), equals("0"));
      });

      test('rejects a zero denominator', () {
        expect(() => Price(1, 0).toDecimalString(), throwsArgumentError);
      });

      test('is parsed back by Price.fromString', () {
        final price = Price.fromString(Price(1, 10000000).toDecimalString());
        expect(price.n, equals(1));
        expect(price.d, equals(10000000));
      });
    });

    group('Price.fromString decimal round trips', () {
      // Each price is rendered by toDecimalString and parsed back. A fraction
      // whose lowest terms fit an int32 fraction comes back in lowest terms;
      // any other comes back as its closest int32 convergent.
      void expectRoundTrip(int n, int d, int expectedN, int expectedD) {
        final decimal = Price(n, d).toDecimalString();
        final parsed = Price.fromString(decimal);
        expect([parsed.n, parsed.d], equals([expectedN, expectedD]),
            reason: '$n/$d rendered as "$decimal"');
      }

      test('recovers fractions with large powers of five', () {
        expectRoundTrip(1, 244140625, 1, 244140625);
        expectRoundTrip(-1, 48828125, -1, 48828125);
        expectRoundTrip(2147483647, 244140625, 2147483647, 244140625);
        expectRoundTrip(-1, 19531250, -1, 19531250);
        expectRoundTrip(1, 1220703125, 1, 1220703125);
      });

      test('recovers a power of two cut after 20 digits', () {
        // 1/2^30 has 30 fractional digits; the first 20 still lead back to it.
        expectRoundTrip(1, 1073741824, 1, 1073741824);
      });

      test('recovers fractions next to one', () {
        expectRoundTrip(2147483646, 2147483647, 2147483646, 2147483647);
        expectRoundTrip(99999999, 100000000, 99999999, 100000000);
      });

      test('recovers a fraction in lowest terms', () {
        // 123456789/987654321 reduces by 9.
        expectRoundTrip(123456789, 987654321, 13717421, 109739369);
      });

      test('gives the closest convergent when the fraction does not fit', () {
        // The sign moves to the numerator, and 2147483648 does not fit a
        // positive int32 denominator.
        expectRoundTrip(2147483647, -2147483648, -2147483646, 2147483647);
      });

      test('parses a value just above 1/2147483648 to 1/2147483647', () {
        // The value is above 1/2147483648, so the closest int32 fraction is
        // 1/2147483647.
        final price = Price.fromString("0.0000000004656612873077392578126");
        expect([price.n, price.d], equals([1, 2147483647]));
      });

      test('refuses a value just below -2147483648', () {
        // The value is below INT32_MIN, so no int32 fraction carries it.
        final value = "-2147483648.${"0" * 323}1";
        expect(
          () => Price.fromString(value),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  "Exception: Not a price an int32 fraction can carry: $value")),
        );
      });

      test('parses an exact decimal to its exact fraction', () {
        final price = Price.fromString("0.99999999");
        expect([price.n, price.d], equals([99999999, 100000000]));
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
