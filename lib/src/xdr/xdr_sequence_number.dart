// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_big_int64.dart';

class XdrSequenceNumber {
  XdrSequenceNumber(this._sequenceNumber);

  XdrBigInt64 _sequenceNumber;
  XdrBigInt64 get sequenceNumber => this._sequenceNumber;
  set sequenceNumber(XdrBigInt64 value) => this._sequenceNumber = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSequenceNumber encodedSequenceNumber,
  ) {
    XdrBigInt64.encode(stream, encodedSequenceNumber.sequenceNumber);
  }

  static XdrSequenceNumber decode(XdrDataInputStream stream) {
    return XdrSequenceNumber(XdrBigInt64.decode(stream));
  }
}
