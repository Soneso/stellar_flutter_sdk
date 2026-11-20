// Transaction preconditions and their bytes on the browser target, where
// `int` is a JavaScript number and holds integers exactly only up to 2^53.
// The cases are shared with test/unit/core/transaction_preconditions_exact_test.dart.

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import '../../core/transaction_preconditions_exact_cases.dart';

void main() {
  group('transaction preconditions on the browser target', () {
    test('this target holds integers in a JavaScript number', () {
      expect(identical(0, 0.0), isTrue);
    });
    preconditionsExactCases();
  });
}
