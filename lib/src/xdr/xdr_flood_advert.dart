// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_tx_advert_vector.dart';

class XdrFloodAdvert {

  XdrTxAdvertVector _txHashes;
  XdrTxAdvertVector get txHashes => this._txHashes;
  set txHashes(XdrTxAdvertVector value) => this._txHashes = value;

  XdrFloodAdvert(this._txHashes);

  static void encode(XdrDataOutputStream stream, XdrFloodAdvert encodedFloodAdvert) {
    XdrTxAdvertVector.encode(stream, encodedFloodAdvert.txHashes);
  }

  static XdrFloodAdvert decode(XdrDataInputStream stream) {
    XdrTxAdvertVector txHashes = XdrTxAdvertVector.decode(stream);
    return XdrFloodAdvert(txHashes);
  }
}
