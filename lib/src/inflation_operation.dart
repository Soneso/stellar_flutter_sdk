// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'xdr/xdr.dart';

/// The inflation operation, which has no parameters.
///
/// The network refuses this operation with `opNOT_SUPPORTED` since protocol
/// 12 (CAP-26). The class represents it in transactions read from XDR, such
/// as historical transactions, so they can be read, re-encoded and hashed.
///
/// See also:
/// - [Operation.fromXdr] which creates this operation from XDR
/// - [CAP-26](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0026.md)
class InflationOperation extends Operation {
  /// Creates an InflationOperation.
  InflationOperation();

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody of type INFLATION, which has no fields.
  @override
  XdrOperationBody toOperationBody() {
    return XdrOperationBody(XdrOperationType.INFLATION);
  }
}
