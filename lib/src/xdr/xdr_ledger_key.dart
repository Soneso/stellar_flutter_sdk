// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_account_id.dart';
import 'xdr_asset.dart';
import 'xdr_claimable_balance_id.dart';
import 'xdr_config_setting_id.dart';
import 'xdr_contract_data_durability.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_ledger_entry_type.dart';
import 'xdr_ledger_key_account.dart';
import 'xdr_ledger_key_base.dart';
import 'xdr_ledger_key_contract_code.dart';
import 'xdr_ledger_key_contract_data.dart';
import 'xdr_ledger_key_data.dart';
import 'xdr_ledger_key_offer.dart';
import 'xdr_ledger_key_trust_line.dart';
import 'xdr_ledger_key_ttl.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';
import 'xdr_trustline_asset.dart';

class XdrLedgerKey extends XdrLedgerKeyBase {
  XdrLedgerKey(super.type);

  static void encode(XdrDataOutputStream stream, XdrLedgerKey val) {
    XdrLedgerKeyBase.encode(stream, val);
  }

  static XdrLedgerKey decode(XdrDataInputStream stream) {
    return XdrLedgerKeyBase.decodeAs(stream, XdrLedgerKey.new);
  }

  String? getAccountAccountId() {
    if (account != null) {
      return KeyPair.fromXdrPublicKey(account!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getTrustlineAccountId() {
    if (trustLine != null) {
      return KeyPair.fromXdrPublicKey(trustLine!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getDataAccountId() {
    if (data != null) {
      return KeyPair.fromXdrPublicKey(data!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getOfferSellerId() {
    if (offer != null) {
      return KeyPair.fromXdrPublicKey(offer!.sellerID.accountID).accountId;
    }
    return null;
  }

  int? getOfferOfferId() {
    if (offer != null) {
      return offer!.offerID.uint64.toInt();
    }
    return null;
  }

  String? getClaimableBalanceId() {
    if (balanceID != null && balanceID!.v0 != null) {
      return Util.bytesToHex(balanceID!.v0!.hash);
    }
    return null;
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerKey.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerKey fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerKey.decode(XdrDataInputStream(bytes));
  }

  static XdrLedgerKey forAccountId(String accountId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
    result.account = XdrLedgerKeyAccount(XdrAccountID.forAccountId(accountId));
    return result;
  }

  static XdrLedgerKey forTrustLine(String accountId, XdrAsset asset) {
    var result = XdrLedgerKey(XdrLedgerEntryType.TRUSTLINE);
    var trustLine = XdrLedgerKeyTrustLine(
      XdrAccountID.forAccountId(accountId),
      XdrTrustlineAsset.fromXdrAsset(asset),
    );
    result.trustLine = trustLine;
    return result;
  }

  static XdrLedgerKey forOffer(String sellerId, int offerId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.OFFER);
    result.offer = XdrLedgerKeyOffer.forOfferId(sellerId, offerId);
    return result;
  }

  static XdrLedgerKey forData(String accountId, String dataName) {
    var result = XdrLedgerKey(XdrLedgerEntryType.DATA);
    result.data = XdrLedgerKeyData.forDataName(accountId, dataName);
    return result;
  }

  static XdrLedgerKey forClaimableBalance(String claimableBalanceId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CLAIMABLE_BALANCE);
    result.balanceID = XdrClaimableBalanceID.forId(claimableBalanceId);
    return result;
  }

  static XdrLedgerKey forLiquidityPool(String liquidityPoolId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.LIQUIDITY_POOL);

    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }
    result.liquidityPoolID = XdrHash(Util.hexToBytes(id));
    return result;
  }

  static XdrLedgerKey forContractData(
    XdrSCAddress contractAddress,
    XdrSCVal key,
    XdrContractDataDurability durability,
  ) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    result.contractData = XdrLedgerKeyContractData(
      contractAddress,
      key,
      durability,
    );
    return result;
  }

  static XdrLedgerKey forContractCode(Uint8List code) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
    result.contractCode = XdrLedgerKeyContractCode(XdrHash(code));
    return result;
  }

  static XdrLedgerKey forConfigSetting(XdrConfigSettingID configSettingId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONFIG_SETTING);
    result.configSetting = configSettingId;
    return result;
  }

  static XdrLedgerKey forTTL(Uint8List keyHash) {
    var result = XdrLedgerKey(XdrLedgerEntryType.TTL);
    result.ttl = XdrLedgerKeyTTL(XdrHash(keyHash));
    return result;
  }
}
