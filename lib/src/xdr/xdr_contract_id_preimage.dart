// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_asset.dart';
import 'xdr_contract_id_preimage_type.dart';
import 'xdr_data_io.dart';
import 'xdr_sc_address.dart';
import 'xdr_uint256.dart';

class XdrContractIDPreimage {
  XdrContractIDPreimage(this._type);
  XdrContractIDPreimageType _type;
  XdrContractIDPreimageType get type => this._type;
  set type(XdrContractIDPreimageType value) => this._type = value;

  XdrUint256? _salt;
  XdrUint256? get salt => this._salt;
  set salt(XdrUint256? value) => this._salt = value;

  XdrSCAddress? _address;
  XdrSCAddress? get address => this._address;
  set address(XdrSCAddress? value) => this._address = value;

  XdrAsset? _fromAsset;
  XdrAsset? get fromAsset => this._fromAsset;
  set fromAsset(XdrAsset? value) => this._fromAsset = value;

  static void encode(
      XdrDataOutputStream stream, XdrContractIDPreimage encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS:
        XdrSCAddress.encode(stream, encoded.address!);
        XdrUint256.encode(stream, encoded.salt!);
        break;
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET:
        XdrAsset.encode(stream, encoded.fromAsset!);
        break;
    }
  }

  static XdrContractIDPreimage decode(XdrDataInputStream stream) {
    XdrContractIDPreimage decoded =
        XdrContractIDPreimage(XdrContractIDPreimageType.decode(stream));
    switch (decoded.type) {
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS:
        decoded.address = XdrSCAddress.decode(stream);
        decoded.salt = XdrUint256.decode(stream);
        break;
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET:
        decoded.fromAsset = XdrAsset.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrContractIDPreimage forAddress(
      XdrSCAddress address, Uint8List uInt256Salt) {
    var result = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    result.address = address;
    result.salt = XdrUint256(uInt256Salt);
    return result;
  }

  static XdrContractIDPreimage forAsset(XdrAsset fromAsset) {
    var result = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
    result.fromAsset = fromAsset;
    return result;
  }
}
