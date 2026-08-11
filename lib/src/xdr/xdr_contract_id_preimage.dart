// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_asset.dart';
import 'xdr_contract_id_preimage_base.dart';
import 'xdr_contract_id_preimage_from_address.dart';
import 'xdr_contract_id_preimage_type.dart';
import 'xdr_data_io.dart';
import 'xdr_json_helper.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_address_type.dart';
import 'xdr_uint256.dart';

class XdrContractIDPreimage extends XdrContractIDPreimageBase {
  XdrContractIDPreimage(super.type);

  /// Convenience accessor for [fromAddress].address.
  XdrSCAddress? get address => fromAddress?.address;
  set address(XdrSCAddress? value) {
    if (fromAddress == null) {
      fromAddress = XdrContractIDPreimageFromAddress(
        value!,
        XdrUint256(Uint8List(32)),
      );
    } else {
      fromAddress!.address = value!;
    }
  }

  /// Convenience accessor for [fromAddress].salt.
  XdrUint256? get salt => fromAddress?.salt;
  set salt(XdrUint256? value) {
    if (fromAddress == null) {
      fromAddress = XdrContractIDPreimageFromAddress(
        XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT),
        value!,
      );
    } else {
      fromAddress!.salt = value!;
    }
  }

  static void encode(XdrDataOutputStream stream, XdrContractIDPreimage val) {
    XdrContractIDPreimageBase.encode(stream, val);
  }

  static XdrContractIDPreimage decode(XdrDataInputStream stream) {
    return XdrContractIDPreimageBase.decodeAs(
      stream,
      XdrContractIDPreimage.new,
    );
  }

  static XdrContractIDPreimage fromTxRep(
    Map<String, String> map,
    String prefix,
  ) {
    var b = XdrContractIDPreimageBase.fromTxRep(map, prefix);
    var result = XdrContractIDPreimage(b.discriminant);
    result.fromAddress = b.fromAddress;
    result.fromAsset = b.fromAsset;
    return result;
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

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrContractIDPreimage.
  ///
  /// Dart does not inherit statics, so this narrows the base class rendering to
  /// this type rather than relying on the one the base declares.
  static XdrContractIDPreimage fromXdrJson(String json) => fromXdrJsonValue(
    XdrJsonHelper.decodeDocument(json, type: 'XdrContractIDPreimage'),
  );

  static XdrContractIDPreimage fromXdrJsonValue(Object? value) =>
      XdrContractIDPreimageBase.fromXdrJsonValueAs(
        value,
        XdrContractIDPreimage.new,
      );
}
