// `jsonDecode` on this target returns a map backed by a raw JavaScript object,
// so keys that look like array indices are hoisted to the front in ascending
// numeric order. Nothing this decoder does may depend on the order a decoded
// object presents its keys in, and these tests are where that is established.

@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SEP-0051 decoded key order on the browser target', () {
    test('this target reorders the keys of a decoded object', () {
      // The premise the rest of this group rests on, asserted rather than
      // assumed: the keys come back in an order the document did not have.
      final Map<String, dynamic> decoded =
          jsonDecode('{"zebra":1,"apple":2,"10":3,"2":4}')
              as Map<String, dynamic>;
      expect(decoded.keys.toList(), <String>['2', '10', 'zebra', 'apple']);
    });

    test('reads a struct whose keys arrive in any order', () {
      // The fields are supplied in reverse declaration order, and the value
      // read is the same one the canonical order produces.
      final XdrTimeBounds bounds = XdrTimeBounds.fromXdrJson(
        '{"max_time":"1735689600","min_time":"42"}',
      );
      expect(bounds.minTime.uint64, BigInt.from(42));
      expect(bounds.maxTime.uint64, BigInt.from(1735689600));
    });

    test('renders in declaration order whatever order it read', () {
      // Output order is the type's, taken from the XDR declaration, so a
      // document that arrived in another order still renders canonically.
      expect(
        XdrTimeBounds.fromXdrJson(
          '{"max_time":"1735689600","min_time":"42"}',
        ).toXdrJson(),
        '{"min_time":"42","max_time":"1735689600"}',
      );
    });

    test('names undeclared keys in sorted order, not in decoded order', () {
      // Two of the undeclared keys below are canonical integer strings, which
      // this target hoists ahead of the rest. The report is sorted, so it reads
      // the same here as anywhere else and can be asserted at all.
      expect(
        () => XdrTimeBounds.fromXdrJson(
          '{"min_time":"0","max_time":"1","zebra":1,"10":3,"2":4}',
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains(
              'XDR-JSON XdrTimeBounds has the unknown keys '
              '"10", "2", "zebra"',
            ),
          ),
        ),
      );
    });

    test('keeps map entries in the order the value carries them', () {
      // A map-valued XDR type renders as an array of entries rather than as a
      // JSON object, so its ordering is the value's own and this target's key
      // hoisting cannot reach it.
      final XdrSCVal map = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('zebra'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('10'), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forSymbol('2'), XdrSCVal.forU32(3)),
      ]);

      const String rendered =
          '{"map":[{"key":{"symbol":"zebra"},"val":{"u32":1}},'
          '{"key":{"symbol":"10"},"val":{"u32":2}},'
          '{"key":{"symbol":"2"},"val":{"u32":3}}]}';

      expect(map.toXdrJson(), rendered);
      expect(XdrSCVal.fromXdrJson(rendered).toXdrJson(), rendered);
    });
  });
}
