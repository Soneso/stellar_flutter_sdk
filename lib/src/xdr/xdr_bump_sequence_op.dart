// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sequence_number.dart';

class XdrBumpSequenceOp {
  XdrSequenceNumber _bumpTo;
  XdrSequenceNumber get bumpTo => this._bumpTo;
  set bumpTo(XdrSequenceNumber value) => this._bumpTo = value;

  XdrBumpSequenceOp(this._bumpTo);

  static void encode(
    XdrDataOutputStream stream,
    XdrBumpSequenceOp encodedBumpSequenceOp,
  ) {
    XdrSequenceNumber.encode(stream, encodedBumpSequenceOp.bumpTo);
  }

  static XdrBumpSequenceOp decode(XdrDataInputStream stream) {
    XdrSequenceNumber bumpTo = XdrSequenceNumber.decode(stream);
    return XdrBumpSequenceOp(bumpTo);
  }
}
