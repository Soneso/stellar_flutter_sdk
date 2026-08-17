// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/constants/stellar_protocol_constants.dart';
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_account_id.dart';
import 'xdr_claimable_balance_id.dart';
import 'xdr_data_io.dart';
import 'xdr_json_helper.dart';
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

  static XdrSCAddress fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrSCAddressBase.fromTxRep(map, prefix);
    var result = XdrSCAddress(b.discriminant);
    result.accountId = b.accountId;
    result.contractId = b.contractId;
    result.muxedAccount = b.muxedAccount;
    result.claimableBalanceId = b.claimableBalanceId;
    result.liquidityPoolId = b.liquidityPoolId;
    return result;
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

  /// Builds a contract address from [contractId], given either as the strkey
  /// rendering of the id (C...) or as the hex of its 32 byte hash.
  ///
  /// Throws:
  /// - [FormatException]: if a strkey is not one this codec accepts, or if a
  ///   hex rendering is not hexadecimal or renders a byte count other than 32
  static XdrSCAddress forContractId(String contractId) {
    XdrSCAddress result = XdrSCAddress(
      XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
    );
    var contractIdHex = contractId;
    // 'C' is a hexadecimal digit, so only a string of the strkey's exact
    // length reads as one; a 64-character hex id may lead with 'C' too.
    if (contractId.startsWith('C') &&
        contractId.length ==
            StellarProtocolConstants.STRKEY_CONTRACT_ID_LENGTH) {
      contractIdHex = StrKey.decodeContractIdHex(contractIdHex);
    }
    result.contractId = Util.hexIdToXdrHash(contractIdHex, "Contract id");
    return result;
  }

  static XdrSCAddress forClaimableBalanceId(String claimableBalanceId) {
    XdrSCAddress result = XdrSCAddress(
      XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE,
    );
    result.claimableBalanceId = XdrClaimableBalanceID.forId(claimableBalanceId);
    return result;
  }

  /// Builds a liquidity pool address from [liquidityPoolId], given either as
  /// the strkey rendering of the id (L...) or as the hex of its 32 byte hash.
  ///
  /// Throws:
  /// - [FormatException]: if a strkey is not one this codec accepts, or if a
  ///   hex rendering is not hexadecimal or renders a byte count other than 32
  static XdrSCAddress forLiquidityPoolId(String liquidityPoolId) {
    XdrSCAddress result = XdrSCAddress(
      XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL,
    );
    result.liquidityPoolId = Util.liquidityPoolIdToXdrHash(liquidityPoolId);
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

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrSCAddress.
  ///
  /// Dart does not inherit statics, so this narrows the base class rendering to
  /// this type rather than relying on the one the base declares.
  static XdrSCAddress fromXdrJson(String json) => fromXdrJsonValue(
    XdrJsonHelper.decodeDocument(json, type: 'XdrSCAddress'),
  );

  static XdrSCAddress fromXdrJsonValue(Object? value) =>
      XdrSCAddressBase.fromXdrJsonValueAs(value, XdrSCAddress.new);
}
