// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_address.dart';
import 'xdr_uint256.dart';

class XdrContractIDPreimageFromAddress {
  XdrSCAddress _address;
  XdrSCAddress get address => this._address;
  set address(XdrSCAddress value) => this._address = value;

  XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  XdrContractIDPreimageFromAddress(this._address, this._salt);

  static void encode(
    XdrDataOutputStream stream,
    XdrContractIDPreimageFromAddress encodedContractIDPreimageFromAddress,
  ) {
    XdrSCAddress.encode(stream, encodedContractIDPreimageFromAddress.address);
    XdrUint256.encode(stream, encodedContractIDPreimageFromAddress.salt);
  }

  static XdrContractIDPreimageFromAddress decode(XdrDataInputStream stream) {
    XdrSCAddress address = XdrSCAddress.decode(stream);
    XdrUint256 salt = XdrUint256.decode(stream);
    return XdrContractIDPreimageFromAddress(address, salt);
  }
}
