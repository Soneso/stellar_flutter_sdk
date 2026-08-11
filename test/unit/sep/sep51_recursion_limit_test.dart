import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Matches a [FormatException] whose message contains [fragment].
///
/// A document past the nesting cap is refused under the same exception type as
/// any other malformed XDR-JSON, and the message it carries is one this SDK
/// builds.
Matcher formatFailure(String fragment) => throwsA(
  isA<FormatException>().having(
    (FormatException e) => e.message,
    'message',
    contains(fragment),
  ),
);

/// A `ClaimPredicate` of [containers] nested `not` arms over an unconditional
/// predicate.
///
/// The `not` arm renders as `{"not": ...}`, one JSON container per level, so
/// the value nests exactly [containers] containers and the cap can be
/// approached a single level at a time.
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

/// The XDR-JSON text [nestedNot] renders to, built directly.
///
/// Building the text rather than encoding a value is what lets the text form be
/// pushed past the depth the value form refuses to render.
String nestedNotText(int containers) =>
    '${'{"not":' * containers}"unconditional"${'}' * containers}';

/// An `SCVal` of [levels] nested `vec` arms.
///
/// A `vec` renders as `{"vec":[...]}`, so each level costs two containers: the
/// arm object and the array inside it. When [innermostHoldsSymbol] is set the
/// innermost array holds one symbol, whose arm object adds a single container
/// on top of the even total.
XdrSCVal nestedVec(int levels, {bool innermostHoldsSymbol = false}) {
  XdrSCVal value = XdrSCVal.forVec(<XdrSCVal>[
    if (innermostHoldsSymbol) XdrSCVal.forSymbol('x'),
  ]);
  for (int i = 1; i < levels; i++) {
    value = XdrSCVal.forVec(<XdrSCVal>[value]);
  }
  return value;
}

/// The XDR-JSON text [nestedVec] renders to, built directly.
String nestedVecText(int levels, {bool innermostHoldsSymbol = false}) =>
    '${'{"vec":[' * levels}'
    '${innermostHoldsSymbol ? '{"symbol":"x"}' : ''}'
    '${']}' * levels}';

void main() {
  // The cap is a single number shared by both forms and by the binary decoder,
  // so the boundary below is one boundary rather than three that happen to
  // coincide.
  const int cap = XdrJsonHelper.maxDepth;

  group('SEP-0051 nesting limit', () {
    test('bounds JSON nesting at the number the binary decoder bounds', () {
      expect(cap, 128);
      expect(cap, XdrDataInputStream.maxRecursiveDecodeDepth);
    });

    test('accepts a document nested to exactly the limit', () {
      // Text scan: the document arrives as text and is scanned before it is
      // parsed.
      final XdrClaimPredicate parsed = XdrClaimPredicate.fromXdrJson(
        nestedNotText(cap),
      );
      expect(parsed.discriminant, XdrClaimPredicateType.CLAIM_PREDICATE_NOT);

      // Tree walk: the value is rendered to a tree and the tree is walked
      // before it reaches the encoder.
      expect(nestedNot(cap).toXdrJson(), nestedNotText(cap));
    });

    test('rejects a document nested one level past the limit', () {
      expect(
        () => XdrClaimPredicate.fromXdrJson(nestedNotText(cap + 1)),
        formatFailure(
          'XDR-JSON XdrClaimPredicate nests JSON containers more than 128 '
          'deep, which is the limit',
        ),
      );
      expect(
        () => nestedNot(cap + 1).toXdrJson(),
        formatFailure(
          'XDR-JSON XdrClaimPredicate nests JSON containers more than 128 '
          'deep, which is the limit',
        ),
      );
    });

    test('places the boundary identically in both forms', () {
      // The two guards run over different representations of the same value.
      // They agree on the last accepted depth and on the first refused one, so
      // a document this SDK emits is one it can read back.
      final String atLimit = nestedNot(cap).toXdrJson();
      expect(atLimit, nestedNotText(cap));
      expect(
        XdrClaimPredicate.fromXdrJson(atLimit).toXdrJson(),
        atLimit,
        reason: 'a value at the cap does not survive its own rendering',
      );

      expect(() => nestedNot(cap - 1).toXdrJson(), returnsNormally);
      expect(
        () => XdrClaimPredicate.fromXdrJson(nestedNotText(cap - 1)),
        returnsNormally,
      );
      expect(() => nestedNot(cap + 1).toXdrJson(), formatFailure('128'));
      expect(
        () => XdrClaimPredicate.fromXdrJson(nestedNotText(cap + 1)),
        formatFailure('128'),
      );
    });

    test('counts containers rather than levels of a generated type', () {
      // A `vec` costs two containers per level, so the cap arrives after half
      // as many levels. Both forms count the same way.
      expect(nestedVec(cap ~/ 2).toXdrJson(), nestedVecText(cap ~/ 2));
      expect(
        XdrSCVal.fromXdrJson(nestedVecText(cap ~/ 2)).toXdrJson(),
        nestedVecText(cap ~/ 2),
      );

      expect(() => nestedVec(cap ~/ 2 + 1).toXdrJson(), formatFailure('128'));
      expect(
        () => XdrSCVal.fromXdrJson(nestedVecText(cap ~/ 2 + 1)),
        formatFailure('128'),
      );
    });

    test('refuses the odd container that carries a value past the cap', () {
      // Sixty-four `vec` levels sit exactly at the cap. One more container
      // inside the innermost array, the symbol's own arm object, is the
      // single container that crosses it.
      final XdrSCVal atLimit = nestedVec(cap ~/ 2);
      final XdrSCVal pastLimit = nestedVec(
        cap ~/ 2,
        innermostHoldsSymbol: true,
      );

      expect(atLimit.toXdrJson(), nestedVecText(cap ~/ 2));
      expect(() => pastLimit.toXdrJson(), formatFailure('128'));
      expect(
        () => XdrSCVal.fromXdrJson(
          nestedVecText(cap ~/ 2, innermostHoldsSymbol: true),
        ),
        formatFailure('128'),
      );
    });

    test('admits an odd container count immediately below the cap', () {
      // A `vec` level costs two containers, so nesting alone reaches only even
      // totals and the last accepted depth would go unpinned on this type. The
      // symbol's arm object supplies the odd container: sixty-three levels plus
      // it total 127, one below the cap, and both forms accept it.
      final XdrSCVal belowLimit = nestedVec(
        cap ~/ 2 - 1,
        innermostHoldsSymbol: true,
      );
      final String text = nestedVecText(
        cap ~/ 2 - 1,
        innermostHoldsSymbol: true,
      );

      expect(belowLimit.toXdrJson(), text);
      expect(XdrSCVal.fromXdrJson(text).toXdrJson(), text);
    });

    test('counts nothing but containers, whatever a container holds', () {
      // Breadth is not depth: a shallow document with many elements is
      // accepted, so the guard bounds recursion rather than size.
      final XdrSCVal wide = XdrSCVal.forVec(
        List<XdrSCVal>.generate(500, (int i) => XdrSCVal.forU32(i)),
      );
      expect(() => wide.toXdrJson(), returnsNormally);
      expect(() => XdrSCVal.fromXdrJson(wide.toXdrJson()), returnsNormally);
    });
  });

  group('SEP-0051 nesting guard placement', () {
    test('scans the text before the parser is reached', () {
      // The document below is both over-nested and unterminated. The guard
      // reports the nesting, which it can only do by running first: a parser
      // that saw this text would report the truncation instead.
      expect(
        () => XdrClaimPredicate.fromXdrJson('{"not":' * (cap + 1)),
        formatFailure('nests JSON containers more than 128 deep'),
      );
      // The same text within the cap is left to the parser: the scan
      // establishes nesting and duplicate keys and nothing else, so the
      // truncation is reported in the parser's own words rather than the
      // guard's.
      expect(
        () => XdrClaimPredicate.fromXdrJson('{"not":' * cap),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            isNot(contains('nests JSON containers')),
          ),
        ),
      );
    });

    test('walks the tree before the encoder is reached', () {
      // The tree below encodes without complaint, so nothing downstream of the
      // guard would have objected to it. The rejection is therefore the
      // guard's own, taken ahead of the encoder, which is the only order that
      // helps on a target where an encoder failure cannot be caught at all.
      final Object? tree = nestedNot(cap + 1).toXdrJsonValue();
      expect(() => jsonEncode(tree), returnsNormally);
      expect(
        () => nestedNot(cap + 1).toXdrJson(),
        formatFailure('nests JSON containers more than 128 deep'),
      );
    });

    test('leaves a value at the cap encodable and readable', () {
      // The guard admits everything below its boundary; it is a bound, not a
      // margin taken out of the usable range.
      final String rendered = nestedNot(cap).toXdrJson();
      expect(rendered.startsWith('{"not":{"not":'), isTrue);
      expect(rendered.endsWith('"unconditional"${'}' * cap}'), isTrue);
      expect(XdrClaimPredicate.fromXdrJson(rendered).toXdrJson(), rendered);
    });
  });
}
