// The nesting guard exists because a deeply nested document reaches the host
// JavaScript engine's own stack on this target. These tests establish that the
// guard, not the encoder and not the parser, is what refuses such a document.

@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// A `ClaimPredicate` of [containers] nested `not` arms over an unconditional
/// predicate. Each arm renders as one JSON container.
XdrClaimPredicate nestedNot(int containers) {
  XdrClaimPredicate predicate = XdrClaimPredicate(
    XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL,
  );
  for (int i = 0; i < containers; i++) {
    final XdrClaimPredicate outer = XdrClaimPredicate(
      XdrClaimPredicateType.CLAIM_PREDICATE_NOT,
    );
    outer.notPredicate = predicate;
    predicate = outer;
  }
  return predicate;
}

/// The XDR-JSON text [nestedNot] renders to, built directly so the text form can
/// be pushed past the depth the value form refuses to render.
String nestedNotText(int containers) =>
    '${'{"not":' * containers}"unconditional"${'}' * containers}';

void main() {
  const int cap = XdrJsonHelper.maxDepth;

  group('SEP-0051 nesting guard on the browser target', () {
    test('bounds nesting at the same number every target bounds it at', () {
      expect(cap, 128);
      expect(cap, XdrDataInputStream.maxRecursiveDecodeDepth);
    });

    test('accepts a document nested to exactly the limit', () {
      expect(nestedNot(cap).toXdrJson(), nestedNotText(cap));
      expect(
        XdrClaimPredicate.fromXdrJson(nestedNotText(cap)).toXdrJson(),
        nestedNotText(cap),
      );
    });

    test('refuses one level past the limit in both forms', () {
      expect(
        () => nestedNot(cap + 1).toXdrJson(),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => XdrClaimPredicate.fromXdrJson(nestedNotText(cap + 1)),
        throwsA(isA<FormatException>()),
      );
    });

    test('walks the tree before the encoder is reached', () {
      // The tree below encodes without complaint here, so nothing downstream of
      // the guard would have objected to it. The rejection is the guard's own,
      // taken ahead of the encoder, which is the order that holds on a target
      // where an encoder failure cannot be caught at all.
      final Object? tree = nestedNot(cap + 1).toXdrJsonValue();
      expect(() => jsonEncode(tree), returnsNormally);
      expect(
        () => nestedNot(cap + 1).toXdrJson(),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('nests JSON containers more than 128 deep'),
          ),
        ),
      );
    });

    test('scans the text before the parser is reached', () {
      // The document below is both over-nested and unterminated. The guard
      // reports the nesting, which it can only do by running first: a parser
      // that saw this text would report the truncation instead.
      expect(
        () => XdrClaimPredicate.fromXdrJson('{"not":' * (cap + 1)),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('nests JSON containers more than 128 deep'),
          ),
        ),
      );
    });
  });
}
