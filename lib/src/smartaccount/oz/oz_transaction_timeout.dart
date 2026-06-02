// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../transaction.dart';

/// Builds the TimeBounds preconditions for a smart-account transaction from
/// the configured timeout.
///
/// A [timeoutInSeconds] of 0 produces `max_time = 0` (no upper bound =
/// infinite validity; the transaction never expires by time); a positive
/// value sets `max_time = now + timeoutInSeconds`. `min_time` is always 0.
///
/// Callers are expected to pass a non-negative value; configuration
/// validation rejects negatives before this point.
TransactionPreconditions buildTimeoutPreconditions(int timeoutInSeconds) {
  final maxTime = timeoutInSeconds == 0
      ? 0
      : DateTime.now().millisecondsSinceEpoch ~/ 1000 + timeoutInSeconds;
  return TransactionPreconditions()..timeBounds = TimeBounds(0, maxTime);
}
