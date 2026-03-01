// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_asset.dart';
import 'xdr_contract_id_preimage_base.dart';
import 'xdr_contract_id_preimage_type.dart';
import 'xdr_data_io.dart';
import 'xdr_sc_address.dart';
import 'xdr_uint256.dart';

class XdrContractIDPreimage extends XdrContractIDPreimageBase {
  XdrContractIDPreimage(super.type);

  static void encode(XdrDataOutputStream stream, XdrContractIDPreimage val) {
    XdrContractIDPreimageBase.encode(stream, val);
  }

  static XdrContractIDPreimage decode(XdrDataInputStream stream) {
    return XdrContractIDPreimageBase.decodeAs(
      stream,
      XdrContractIDPreimage.new,
    );
  }

  static XdrContractIDPreimage forAddress(
    XdrSCAddress address,
    Uint8List uInt256Salt,
  ) {
    var result = XdrContractIDPreimage(
      XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
    );
    result.address = address;
    result.salt = XdrUint256(uInt256Salt);
    return result;
  }

  static XdrContractIDPreimage forAsset(XdrAsset fromAsset) {
    var result = XdrContractIDPreimage(
      XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET,
    );
    result.fromAsset = fromAsset;
    return result;
  }
}
