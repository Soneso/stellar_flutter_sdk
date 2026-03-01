// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_id_preimage.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrHashIDPreimageContractID {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrContractIDPreimage _contractIDPreimage;
  XdrContractIDPreimage get contractIDPreimage => this._contractIDPreimage;
  set contractIDPreimage(XdrContractIDPreimage value) =>
      this._contractIDPreimage = value;

  XdrHashIDPreimageContractID(this._networkID, this._contractIDPreimage);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageContractID encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrContractIDPreimage.encode(stream, encoded.contractIDPreimage);
  }

  static XdrHashIDPreimageContractID decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrContractIDPreimage contractIDPreimage =
        XdrContractIDPreimage.decode(stream);
    return XdrHashIDPreimageContractID(networkID, contractIDPreimage);
  }
}
