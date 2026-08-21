import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/src/sep/shared/sep_request_amount.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SepRequestAmount.format', () {
    test('renders a small amount as a plain decimal', () {
      // 123 stroops, an ordinary amount.
      expect(SepRequestAmount.format(0.0000123), equals("0.0000123"));
    });

    test('renders one stroop with all seven decimals', () {
      expect(SepRequestAmount.format(1e-7), equals("0.0000001"));
    });

    test('suppresses the decimal point for whole amounts', () {
      expect(SepRequestAmount.format(100.0), equals("100"));
      expect(SepRequestAmount.format(1.0), equals("1"));
      // The trim stops at the decimal point, so zeroes in the integer part
      // survive.
      expect(SepRequestAmount.format(120.0), equals("120"));
      expect(SepRequestAmount.format(1e15), equals("1000000000000000"));
    });

    test('trims trailing zeroes in the fraction', () {
      expect(SepRequestAmount.format(0.0000120), equals("0.000012"));
      expect(SepRequestAmount.format(0.0000100), equals("0.00001"));
    });

    test('renders large amounts as plain decimals', () {
      // double.toString spells 1e16 as "10000000000000000.0" and 1e21 as
      // "1e+21".
      expect(SepRequestAmount.format(1e16), equals("10000000000000000"));
      expect(SepRequestAmount.format(1e21),
          equals("1000000000000000000000"));
      expect(SepRequestAmount.format(-1e21),
          equals("-1000000000000000000000"));
    });

    test('rounds more than seven decimals to seven', () {
      expect(SepRequestAmount.format(1.23456789), equals("1.2345679"));
    });

    test('is rounded at the seventh digit, not truncated', () {
      // The double here is 780615714.94290959835052490234375, so rendering
      // more digits and cutting at the seventh yields ...9429095 while
      // rounding yields ...9429096.
      expect(SepRequestAmount.format(780615714.9429096),
          equals("780615714.9429096"));
    });

    test('rounds from the stored double, not the written literal', () {
      // The double nearest 1.5e-7 is 0.000000149999999999999993, so the
      // nearer seven-decimal value is one stroop, not two.
      expect(SepRequestAmount.format(1.5e-7), equals("0.0000001"));
    });

    test('rounds a true midpoint away from zero', () {
      // 0.00390625 is 1/256, exactly representable, and its seventh decimal
      // ends exactly halfway.
      expect(SepRequestAmount.format(0.00390625), equals("0.0039063"));
      expect(SepRequestAmount.format(-0.00390625), equals("-0.0039063"));
    });

    test('rounds below half a stroop to zero', () {
      expect(SepRequestAmount.format(0.00000004), equals("0"));
      expect(SepRequestAmount.format(1e-10), equals("0"));
    });

    test('keeps the sign of a negative amount', () {
      expect(SepRequestAmount.format(-0.0000123), equals("-0.0000123"));
    });

    test('renders zero without a sign', () {
      expect(SepRequestAmount.format(0.0), equals("0"));
      expect(SepRequestAmount.format(-0.0), equals("0"));
      // An amount below half a stroop rounds away, and zero carries no sign.
      expect(SepRequestAmount.format(-0.00000001), equals("0"));
    });

    test('renders a non-finite amount as the empty string', () {
      expect(SepRequestAmount.format(double.nan), equals(""));
      expect(SepRequestAmount.format(double.infinity), equals(""));
      expect(SepRequestAmount.format(double.negativeInfinity), equals(""));
    });

    test('no finite amount renders an exponent', () {
      for (final amount in [
        1e-7,
        0.0000123,
        1e-10,
        1e16,
        1e21,
        1e60,
        double.maxFinite,
        -1e21,
        -0.0000123,
      ]) {
        final rendered = SepRequestAmount.format(amount);
        expect(rendered.contains("e"), isFalse,
            reason: 'exponent in "$rendered"');
        expect(rendered.contains("E"), isFalse,
            reason: 'exponent in "$rendered"');
      }
    });
  });

  group('fee request amount on the wire', () {
    test('SEP-24 fee sends the amount as a plain decimal', () async {
      String? capturedAmount;
      final mockClient = MockClient((request) async {
        capturedAmount = request.url.queryParameters['amount'];
        return http.Response(json.encode({'fee': 0.013}), 200);
      });

      final service = TransferServerSEP24Service('https://anchor.example.com',
          httpClient: mockClient);

      // One stroop: double.toString spells it "1e-7".
      final request = SEP24FeeRequest();
      request.operation = "deposit";
      request.assetCode = "ETH";
      request.amount = 1e-7;
      await service.fee(request);
      expect(capturedAmount, equals("0.0000001"));

      request.amount = 3e-7;
      await service.fee(request);
      expect(capturedAmount, equals("0.0000003"));
    });

    test('SEP-6 fee sends the amount as a plain decimal', () async {
      String? capturedAmount;
      final mockClient = MockClient((request) async {
        capturedAmount = request.url.queryParameters['amount'];
        return http.Response(json.encode({'fee': 0.013}), 200);
      });

      final service = TransferServerService('https://anchor.example.com',
          httpClient: mockClient);

      // One stroop: double.toString spells it "1e-7".
      await service.fee(FeeRequest(
          operation: "deposit", assetCode: "ETH", amount: 1e-7));
      expect(capturedAmount, equals("0.0000001"));

      await service.fee(FeeRequest(
          operation: "deposit", assetCode: "ETH", amount: 3e-7));
      expect(capturedAmount, equals("0.0000003"));
    });
  });
}
