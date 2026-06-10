import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_transaction_timeout.dart';

void main() {
  group('buildTimeoutPreconditions', () {
    test('testZeroProducesInfiniteMaxTime', () {
      final preconditions = buildTimeoutPreconditions(0);
      final bounds = preconditions.timeBounds;
      expect(bounds, isNotNull);
      expect(bounds!.minTime, equals(0));
      // max_time = 0 is Stellar's "no upper bound" (infinite validity).
      expect(bounds.maxTime, equals(0));
    });

    test('testPositiveProducesNowPlusTimeout', () {
      const timeout = 30;
      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final preconditions = buildTimeoutPreconditions(timeout);
      final after = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final bounds = preconditions.timeBounds;
      expect(bounds, isNotNull);
      expect(bounds!.minTime, equals(0));
      // max_time should be now + timeout, allowing for clock movement during
      // the call. A small tolerance window absorbs second-boundary crossings.
      expect(bounds.maxTime, greaterThanOrEqualTo(before + timeout));
      expect(bounds.maxTime, lessThanOrEqualTo(after + timeout + 2));
    });

    test('testLargeValueAccepted', () {
      const timeout = 100000;
      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final preconditions = buildTimeoutPreconditions(timeout);
      final bounds = preconditions.timeBounds;
      expect(bounds, isNotNull);
      expect(bounds!.minTime, equals(0));
      expect(bounds.maxTime, greaterThanOrEqualTo(before + timeout));
    });
  });
}
