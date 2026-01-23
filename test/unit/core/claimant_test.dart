import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('Claimant', () {
    final testAccountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
    final testAccountId2 = 'GDK6OLPXZSQXJQPPSLQVDKRZYN7HN22W2DKRWVOXIUFM7RJLMB3GVWVA';

    group('Claimant creation', () {
      test('creates Claimant with unconditional predicate', () {
        final predicate = Claimant.predicateUnconditional();
        final claimant = Claimant(testAccountId, predicate);

        expect(claimant.destination, equals(testAccountId));
        expect(claimant.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));
      });

      test('creates Claimant with different destination', () {
        final predicate = Claimant.predicateUnconditional();
        final claimant = Claimant(testAccountId2, predicate);

        expect(claimant.destination, equals(testAccountId2));
      });
    });

    group('Claimant predicates - unconditional', () {
      test('predicateUnconditional creates correct predicate type', () {
        final predicate = Claimant.predicateUnconditional();

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));
      });
    });

    group('Claimant predicates - time-based', () {
      test('predicateBeforeAbsoluteTime creates correct predicate', () {
        final unixTime = 1735689600;
        final predicate = Claimant.predicateBeforeAbsoluteTime(unixTime);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
        expect(predicate.absBefore!.int64, equals(BigInt.from(unixTime)));
      });

      test('predicateBeforeAbsoluteTime with zero time', () {
        final predicate = Claimant.predicateBeforeAbsoluteTime(0);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
        expect(predicate.absBefore!.int64, equals(BigInt.zero));
      });

      test('predicateBeforeAbsoluteTime with large timestamp', () {
        final unixTime = 2147483647;
        final predicate = Claimant.predicateBeforeAbsoluteTime(unixTime);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
        expect(predicate.absBefore!.int64, equals(BigInt.from(unixTime)));
      });

      test('predicateBeforeRelativeTime creates correct predicate', () {
        final seconds = 604800;
        final predicate = Claimant.predicateBeforeRelativeTime(seconds);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME));
        expect(predicate.relBefore!.int64, equals(BigInt.from(seconds)));
      });

      test('predicateBeforeRelativeTime with zero seconds', () {
        final predicate = Claimant.predicateBeforeRelativeTime(0);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME));
        expect(predicate.relBefore!.int64, equals(BigInt.zero));
      });

      test('predicateBeforeRelativeTime with one year in seconds', () {
        final oneYear = 31536000;
        final predicate = Claimant.predicateBeforeRelativeTime(oneYear);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME));
        expect(predicate.relBefore!.int64, equals(BigInt.from(oneYear)));
      });
    });

    group('Claimant predicates - logical operations', () {
      test('predicateAnd creates correct predicate with two conditions', () {
        final left = Claimant.predicateUnconditional();
        final right = Claimant.predicateBeforeAbsoluteTime(1000000);
        final predicate = Claimant.predicateAnd(left, right);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND));
        expect(predicate.andPredicates, isNotNull);
        expect(predicate.andPredicates!.length, equals(2));
      });

      test('predicateOr creates correct predicate with two conditions', () {
        final left = Claimant.predicateBeforeAbsoluteTime(1000000);
        final right = Claimant.predicateBeforeRelativeTime(604800);
        final predicate = Claimant.predicateOr(left, right);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR));
        expect(predicate.orPredicates, isNotNull);
        expect(predicate.orPredicates!.length, equals(2));
      });

      test('predicateNot creates correct predicate', () {
        final inner = Claimant.predicateBeforeAbsoluteTime(1000000);
        final predicate = Claimant.predicateNot(inner);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
        expect(predicate.notPredicate, isNotNull);
        expect(predicate.notPredicate!.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
      });

      test('predicateNot with unconditional predicate', () {
        final inner = Claimant.predicateUnconditional();
        final predicate = Claimant.predicateNot(inner);

        expect(predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
        expect(predicate.notPredicate!.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));
      });
    });

    group('Claimant predicates - nested operations', () {
      test('nested AND and OR predicates', () {
        final time1 = Claimant.predicateBeforeAbsoluteTime(1000000);
        final time2 = Claimant.predicateBeforeRelativeTime(604800);
        final andPredicate = Claimant.predicateAnd(time1, time2);

        final time3 = Claimant.predicateBeforeAbsoluteTime(2000000);
        final orPredicate = Claimant.predicateOr(andPredicate, time3);

        expect(orPredicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR));
        expect(orPredicate.orPredicates!.length, equals(2));
        expect(orPredicate.orPredicates![0].discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND));
      });

      test('nested NOT operations', () {
        final time = Claimant.predicateBeforeAbsoluteTime(1000000);
        final not1 = Claimant.predicateNot(time);
        final not2 = Claimant.predicateNot(not1);

        expect(not2.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
        expect(not2.notPredicate!.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
        expect(not2.notPredicate!.notPredicate!.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
      });

      test('complex nested predicate structure', () {
        final time1 = Claimant.predicateBeforeAbsoluteTime(1000000);
        final time2 = Claimant.predicateBeforeRelativeTime(604800);
        final andPredicate = Claimant.predicateAnd(time1, time2);
        final notPredicate = Claimant.predicateNot(andPredicate);

        final time3 = Claimant.predicateBeforeAbsoluteTime(2000000);
        final orPredicate = Claimant.predicateOr(notPredicate, time3);

        expect(orPredicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR));
        expect(orPredicate.orPredicates![0].discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
      });
    });

    group('Claimant XDR serialization', () {
      test('XDR round-trip for unconditional claimant', () {
        final predicate = Claimant.predicateUnconditional();
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));
      });

      test('XDR round-trip for time-based claimant', () {
        final unixTime = 1735689600;
        final predicate = Claimant.predicateBeforeAbsoluteTime(unixTime);
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
        expect(restored.predicate.absBefore!.int64, equals(BigInt.from(unixTime)));
      });

      test('XDR round-trip for relative time claimant', () {
        final seconds = 604800;
        final predicate = Claimant.predicateBeforeRelativeTime(seconds);
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME));
        expect(restored.predicate.relBefore!.int64, equals(BigInt.from(seconds)));
      });

      test('XDR round-trip for AND predicate claimant', () {
        final left = Claimant.predicateUnconditional();
        final right = Claimant.predicateBeforeAbsoluteTime(1000000);
        final predicate = Claimant.predicateAnd(left, right);
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND));
        expect(restored.predicate.andPredicates!.length, equals(2));
      });

      test('XDR round-trip for OR predicate claimant', () {
        final left = Claimant.predicateBeforeAbsoluteTime(1000000);
        final right = Claimant.predicateBeforeRelativeTime(604800);
        final predicate = Claimant.predicateOr(left, right);
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR));
        expect(restored.predicate.orPredicates!.length, equals(2));
      });

      test('XDR round-trip for NOT predicate claimant', () {
        final inner = Claimant.predicateBeforeAbsoluteTime(1000000);
        final predicate = Claimant.predicateNot(inner);
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
        expect(restored.predicate.notPredicate!.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
      });

      test('XDR round-trip for nested complex predicate', () {
        final time1 = Claimant.predicateBeforeAbsoluteTime(1000000);
        final time2 = Claimant.predicateBeforeRelativeTime(604800);
        final andPredicate = Claimant.predicateAnd(time1, time2);
        final notPredicate = Claimant.predicateNot(andPredicate);
        final claimant = Claimant(testAccountId, notPredicate);

        final xdr = claimant.toXdr();
        final restored = Claimant.fromXdr(xdr);

        expect(restored.destination, equals(testAccountId));
        expect(restored.predicate.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
        expect(restored.predicate.notPredicate!.discriminant, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND));
      });

      test('XDR claimant type is CLAIMANT_TYPE_V0', () {
        final predicate = Claimant.predicateUnconditional();
        final claimant = Claimant(testAccountId, predicate);
        final xdr = claimant.toXdr();

        expect(xdr.discriminant, equals(XdrClaimantType.CLAIMANT_TYPE_V0));
      });
    });

    group('Claimant destination handling', () {
      test('destination is preserved in claimant', () {
        final predicate = Claimant.predicateUnconditional();
        final claimant = Claimant(testAccountId, predicate);

        expect(claimant.destination, equals(testAccountId));
      });

      test('different destinations create different claimants', () {
        final predicate = Claimant.predicateUnconditional();
        final claimant1 = Claimant(testAccountId, predicate);
        final claimant2 = Claimant(testAccountId2, predicate);

        expect(claimant1.destination, isNot(equals(claimant2.destination)));
      });
    });
  });
}
