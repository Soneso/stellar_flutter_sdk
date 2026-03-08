// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_account_id.dart';
import 'xdr_claimable_balance_id.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_muxed_account_med25519.dart';
import 'xdr_sc_address_base.dart';
import 'xdr_sc_address_type.dart';

class XdrSCAddress extends XdrSCAddressBase {
  XdrSCAddress(super.type);

  static void encode(XdrDataOutputStream stream, XdrSCAddress val) {
    XdrSCAddressBase.encode(stream, val);
  }

  static XdrSCAddress decode(XdrDataInputStream stream) {
    return XdrSCAddressBase.decodeAs(stream, XdrSCAddress.new);
  }

  static XdrSCAddress forAccountId(String accountId) {
    if (accountId.startsWith("G")) {
      XdrSCAddress result = XdrSCAddress(
        XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT,
      );
      result.accountId = XdrAccountID(
        KeyPair.fromAccountId(accountId).xdrPublicKey,
      );
      return result;
    } else if (accountId.startsWith("M")) {
      XdrSCAddress result = XdrSCAddress(
        XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT,
      );
      Uint8List bytes = StrKey.decodeStellarMuxedAccountId(accountId);
      result.muxedAccount = XdrMuxedAccountMed25519.decodeInverted(
        XdrDataInputStream(bytes),
      );
      return result;
    } else {
      throw Exception("invalid account id: $accountId");
    }
  }

  static XdrSCAddress forContractId(String contractId) {
    XdrSCAddress result = XdrSCAddress(
      XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
    );
    var contractIdHex = contractId;
    if (contractId.startsWith('C')) {
      contractIdHex = StrKey.decodeContractIdHex(contractIdHex);
    }
    result.contractId = XdrHash(Util.hexToBytes(contractIdHex));
    return result;
  }

  static XdrSCAddress forClaimableBalanceId(String claimableBalanceId) {
    XdrSCAddress result = XdrSCAddress(
      XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE,
    );
    result.claimableBalanceId = XdrClaimableBalanceID.forId(claimableBalanceId);
    return result;
  }

  static XdrSCAddress forLiquidityPoolId(String liquidityPoolId) {
    XdrSCAddress result = XdrSCAddress(
      XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL,
    );
    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }

    result.liquidityPoolId = XdrHash(Util.hexToBytes(id));
    return result;
  }

  String toStrKey() {
    switch (discriminant) {
      case XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
        KeyPair kp = KeyPair.fromXdrPublicKey(accountId!.accountID);
        return kp.accountId;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT:
        return StrKey.encodeContractId(contractId!.hash);
      case XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT:
        return muxedAccount!.accountId;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE:
        return StrKey.encodeClaimableBalanceIdHex(
          claimableBalanceId!.claimableBalanceIdString,
        );
      case XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL:
        return StrKey.encodeLiquidityPoolId(liquidityPoolId!.hash);
    }
    throw Exception("unknown address type: $discriminant");
  }
}
