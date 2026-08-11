// The browser target compiles `int` to a JavaScript number, so a 64-bit value
// that reaches `int` at any point loses digits there and nowhere else. These
// tests run only where that is true; the same properties hold on the Dart VM
// for reasons that would not catch the mistake.

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String timeBounds(String minTime, String maxTime) =>
    '{"min_time":$minTime,"max_time":$maxTime}';

String liabilities(String buying, String selling) =>
    '{"buying":$buying,"selling":$selling}';

void main() {
  group('SEP-0051 64-bit values on the browser target', () {
    test('renders a uint64 maximum with every digit intact', () {
      final XdrTimeBounds bounds = XdrTimeBounds(
        XdrUint64(XdrJsonHelper.uint64Max),
        XdrUint64(BigInt.zero),
      );

      expect(bounds.toXdrJson(), timeBounds('"18446744073709551615"', '"0"'));
    });

    test('renders an int64 minimum and maximum with every digit intact', () {
      final XdrLiabilities values = XdrLiabilities(
        XdrInt64(XdrJsonHelper.int64Min),
        XdrInt64(XdrJsonHelper.int64Max),
      );

      expect(
        values.toXdrJson(),
        liabilities('"-9223372036854775808"', '"9223372036854775807"'),
      );
    });

    test('reads back the digits it was given', () {
      final XdrTimeBounds bounds = XdrTimeBounds.fromXdrJson(
        timeBounds('"18446744073709551615"', '"9223372036854775807"'),
      );
      expect(bounds.minTime.uint64, XdrJsonHelper.uint64Max);
      expect(bounds.maxTime.uint64, XdrJsonHelper.int64Max);

      final XdrLiabilities values = XdrLiabilities.fromXdrJson(
        liabilities('"-9223372036854775808"', '"9223372036854775807"'),
      );
      expect(values.buying.int64, XdrJsonHelper.int64Min);
      expect(values.selling.int64, XdrJsonHelper.int64Max);
    });

    test('crosses into the binary codec with the digits unchanged', () {
      // A value that survives the JSON round trip but not the encoder would be
      // a rendering of something this SDK cannot write, so the crossing is what
      // makes the digits mean anything.
      final String json = timeBounds('"18446744073709551615"', '"0"');
      final XdrTimeBounds bounds = XdrTimeBounds.fromXdrJson(json);

      expect(
        XdrTimeBounds.fromBase64EncodedXdrString(
          bounds.toBase64EncodedXdrString(),
        ).toXdrJson(),
        json,
      );
    });

    test(
      'bounds the version 1 number path where a number stops being exact',
      () {
        // XDR-JSON version 1 rendered a 64-bit value as a JSON number, so one is
        // still read below 2^53. Past that the parser has already rounded, and
        // magnitude is the only signal left. Magnitude is the same number on
        // every target, which is what makes it assertable here.
        final XdrTimeBounds fromNumber = XdrTimeBounds.fromXdrJson(
          timeBounds('9007199254740992', '0'),
        );
        expect(fromNumber.minTime.uint64, BigInt.from(9007199254740992));
        expect(fromNumber.toXdrJson(), timeBounds('"9007199254740992"', '"0"'));

        expect(
          () => XdrTimeBounds.fromXdrJson(timeBounds('9007199254740994', '0')),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('accepts a whole double for a 32-bit field on this target', () {
      // `1.0` and `1` are one value here, and its text is `1`, so a 32-bit
      // field takes it. The Dart VM decodes the same document to a double
      // whose text is `1.0` and rejects it. The asymmetry cannot be closed
      // from this side, because this target carries no signal that tells the
      // two apart, so it is documented rather than fixed and pinned here,
      // where the behaviour is the target's own.
      final XdrLedgerBounds bounds = XdrLedgerBounds.fromXdrJson(
        '{"min_ledger":1.0,"max_ledger":2}',
      );
      expect(bounds.minLedger.uint32, 1);
      expect(bounds.toXdrJson(), '{"min_ledger":1,"max_ledger":2}');
    });

    test('refuses a fractional value for a 32-bit field on every target', () {
      // A value with a fraction is not an integer on any target, so the
      // rejection is the same everywhere and the field is not simply lenient.
      expect(
        () => XdrLedgerBounds.fromXdrJson('{"min_ledger":1.5,"max_ledger":2}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('reassembles a 128-bit value from its two limbs', () {
      // The parts types render as one decimal string, so the reassembly runs
      // over BigInt from end to end. Both limbs at their extremes put the
      // result far past anything a JavaScript number could hold.
      const String rendered = '"-170141183460469231713240559642174554113"';
      final XdrInt128Parts parts = XdrInt128Parts(
        XdrInt64(XdrJsonHelper.int64Min),
        XdrUint64(XdrJsonHelper.uint64Max),
      );

      expect(parts.toXdrJson(), rendered);

      final XdrInt128Parts read = XdrInt128Parts.fromXdrJson(rendered);
      expect(read.hi.int64, XdrJsonHelper.int64Min);
      expect(read.lo.uint64, XdrJsonHelper.uint64Max);
    });
  });
}
