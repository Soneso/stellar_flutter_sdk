// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_claimable_balance_id_type.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrClaimableBalanceID {
  XdrClaimableBalanceIDType _type;
  XdrClaimableBalanceIDType get discriminant => this._type;
  set discriminant(XdrClaimableBalanceIDType value) => this._type = value;

  XdrHash? _v0;
  XdrHash? get v0 => this._v0;
  set v0(XdrHash? value) => this._v0 = value;

  XdrClaimableBalanceID(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceID encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0:
        XdrHash.encode(stream, encoded.v0!);
        break;
    }
  }

  static XdrClaimableBalanceID decode(XdrDataInputStream stream) {
    XdrClaimableBalanceID decoded =
        XdrClaimableBalanceID(XdrClaimableBalanceIDType.decode(stream));
    switch (decoded.discriminant) {
      case XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0:
        decoded.v0 = XdrHash.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrClaimableBalanceID forId(String claimableBalanceId) {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID(
        XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);

    var id = claimableBalanceId;
    if (id.startsWith("B")) {
      try {
        var bytes = StrKey.decodeClaimableBalanceId(claimableBalanceId);
        if (bytes.length == 33) { // has discriminant in front
          // remove discriminant since we only have CLAIMABLE_BALANCE_ID_TYPE_V0
          bytes = bytes.sublist(1);
        }
        id = Util.bytesToHex(bytes);

      } catch (_) {}
    }
    bId.v0 = Util.stringIdToXdrHash(id);
    return bId;
  }

  String get claimableBalanceIdString {
    return Util.bytesToHex(Uint8List.fromList([discriminant.value, ...v0!.hash]));
  }
}
