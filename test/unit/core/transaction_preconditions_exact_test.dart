// Transaction preconditions and their bytes on the Dart VM. The browser entry
// test/unit/sep/web/transaction_preconditions_exact_web_test.dart runs the
// same cases where `int` is a JavaScript number.

@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import 'transaction_preconditions_exact_cases.dart';

void main() {
  group('transaction preconditions on the Dart VM', preconditionsExactCases);
}
