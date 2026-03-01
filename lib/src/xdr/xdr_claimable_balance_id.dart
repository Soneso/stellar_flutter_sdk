// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_claimable_balance_id_base.dart';
import 'xdr_claimable_balance_id_type.dart';
import 'xdr_data_io.dart';

class XdrClaimableBalanceID extends XdrClaimableBalanceIDBase {
  XdrClaimableBalanceID(super.type);

  static void encode(XdrDataOutputStream stream, XdrClaimableBalanceID val) {
    XdrClaimableBalanceIDBase.encode(stream, val);
  }

  static XdrClaimableBalanceID decode(XdrDataInputStream stream) {
    return XdrClaimableBalanceIDBase.decodeAs(
      stream,
      XdrClaimableBalanceID.new,
    );
  }

  static XdrClaimableBalanceID forId(String claimableBalanceId) {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID(
      XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0,
    );

    var id = claimableBalanceId;
    if (id.startsWith("B")) {
      try {
        var bytes = StrKey.decodeClaimableBalanceId(claimableBalanceId);
        if (bytes.length == 33) {
          // has discriminant in front
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
    return Util.bytesToHex(
      Uint8List.fromList([discriminant.value, ...v0!.hash]),
    );
  }
}
