// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrLedgerBounds {

  XdrUint32 _minLedger;
  XdrUint32 get minLedger => this._minLedger;
  set minLedger(XdrUint32 value) => this._minLedger = value;

  XdrUint32 _maxLedger;
  XdrUint32 get maxLedger => this._maxLedger;
  set maxLedger(XdrUint32 value) => this._maxLedger = value;

  XdrLedgerBounds(this._minLedger, this._maxLedger);

  static void encode(XdrDataOutputStream stream, XdrLedgerBounds encodedLedgerBounds) {
    XdrUint32.encode(stream, encodedLedgerBounds.minLedger);
    XdrUint32.encode(stream, encodedLedgerBounds.maxLedger);
  }

  static XdrLedgerBounds decode(XdrDataInputStream stream) {
    XdrUint32 minLedger = XdrUint32.decode(stream);
    XdrUint32 maxLedger = XdrUint32.decode(stream);
    return XdrLedgerBounds(minLedger, maxLedger);
  }
}
