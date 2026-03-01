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
import 'xdr_ledger_key_contract_code.dart';
import 'xdr_ledger_key_contract_data.dart';
import 'xdr_ledger_key_data.dart';
import 'xdr_ledger_key_offer.dart';
import 'xdr_ledger_key_trust_line.dart';
import 'xdr_ledger_key_ttl.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';
import 'xdr_trustline_asset.dart';

class XdrLedgerKey {
  XdrLedgerKey(this._type);
  XdrLedgerEntryType _type;
  XdrLedgerEntryType get discriminant => this._type;

  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrLedgerKeyAccount? _account;
  XdrLedgerKeyAccount? get account => this._account;
  set account(XdrLedgerKeyAccount? value) => this._account = value;

  XdrLedgerKeyTrustLine? _trustLine;
  XdrLedgerKeyTrustLine? get trustLine => this._trustLine;
  set trustLine(XdrLedgerKeyTrustLine? value) => this._trustLine = value;

  XdrLedgerKeyOffer? _offer;
  XdrLedgerKeyOffer? get offer => this._offer;
  set offer(XdrLedgerKeyOffer? value) => this._offer = value;

  XdrLedgerKeyData? _data;
  XdrLedgerKeyData? get data => this._data;
  set data(XdrLedgerKeyData? value) => this._data = value;

  XdrClaimableBalanceID? _balanceID;
  XdrClaimableBalanceID? get balanceID => this._balanceID;
  set balanceID(XdrClaimableBalanceID? value) => this._balanceID = value;

  XdrHash? _liquidityPoolID;
  XdrHash? get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash? value) => this._liquidityPoolID = value;

  XdrConfigSettingID? _configSetting;
  XdrConfigSettingID? get configSetting => this._configSetting;
  set configSetting(XdrConfigSettingID? value) => this._configSetting = value;

  XdrLedgerKeyContractData? _contractData;
  XdrLedgerKeyContractData? get contractData => this._contractData;
  set contractData(XdrLedgerKeyContractData? value) =>
      this._contractData = value;

  XdrLedgerKeyContractCode? _contractCode;
  XdrLedgerKeyContractCode? get contractCode => this._contractCode;
  set contractCode(XdrLedgerKeyContractCode? value) =>
      this._contractCode = value;

  XdrLedgerKeyTTL? _ttl;
  XdrLedgerKeyTTL? get ttl => this._ttl;
  set ttl(XdrLedgerKeyTTL? value) => this._ttl = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKey encodedLedgerKey) {
    stream.writeInt(encodedLedgerKey.discriminant.value);
    switch (encodedLedgerKey.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrLedgerKeyAccount.encode(stream, encodedLedgerKey.account!);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrLedgerKeyTrustLine.encode(stream, encodedLedgerKey.trustLine!);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrLedgerKeyOffer.encode(stream, encodedLedgerKey.offer!);
        break;
      case XdrLedgerEntryType.DATA:
        XdrLedgerKeyData.encode(stream, encodedLedgerKey.data!);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        XdrClaimableBalanceID.encode(stream, encodedLedgerKey.balanceID!);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        XdrHash.encode(stream, encodedLedgerKey.liquidityPoolID!);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        XdrLedgerKeyContractData.encode(stream, encodedLedgerKey.contractData!);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        XdrLedgerKeyContractCode.encode(stream, encodedLedgerKey.contractCode!);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        XdrConfigSettingID.encode(stream, encodedLedgerKey.configSetting!);
        break;
      case XdrLedgerEntryType.TTL:
        XdrLedgerKeyTTL.encode(stream, encodedLedgerKey.ttl!);
        break;
    }
  }

  static XdrLedgerKey decode(XdrDataInputStream stream) {
    XdrLedgerEntryType discriminant = XdrLedgerEntryType.decode(stream);
    XdrLedgerKey decodedLedgerKey = XdrLedgerKey(discriminant);
    switch (decodedLedgerKey.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        decodedLedgerKey.account = XdrLedgerKeyAccount.decode(stream);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        decodedLedgerKey.trustLine = XdrLedgerKeyTrustLine.decode(stream);
        break;
      case XdrLedgerEntryType.OFFER:
        decodedLedgerKey.offer = XdrLedgerKeyOffer.decode(stream);
        break;
      case XdrLedgerEntryType.DATA:
        decodedLedgerKey.data = XdrLedgerKeyData.decode(stream);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        decodedLedgerKey.balanceID = XdrClaimableBalanceID.decode(stream);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        decodedLedgerKey.liquidityPoolID = XdrHash.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        decodedLedgerKey.contractData = XdrLedgerKeyContractData.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        decodedLedgerKey.contractCode = XdrLedgerKeyContractCode.decode(stream);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        decodedLedgerKey.configSetting = XdrConfigSettingID.decode(stream);
        break;
      case XdrLedgerEntryType.TTL:
        decodedLedgerKey.ttl = XdrLedgerKeyTTL.decode(stream);
        break;
    }
    return decodedLedgerKey;
  }

  String? getAccountAccountId() {
    if (_account != null) {
      return KeyPair.fromXdrPublicKey(_account!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getTrustlineAccountId() {
    if (_trustLine != null) {
      return KeyPair.fromXdrPublicKey(_trustLine!.accountID.accountID)
          .accountId;
    }
    return null;
  }

  String? getDataAccountId() {
    if (_data != null) {
      return KeyPair.fromXdrPublicKey(_data!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getOfferSellerId() {
    if (_offer != null) {
      return KeyPair.fromXdrPublicKey(_offer!.sellerID.accountID).accountId;
    }
    return null;
  }

  int? getOfferOfferId() {
    if (_offer != null) {
      return _offer!.offerID.uint64.toInt();
    }
    return null;
  }

  String? getClaimableBalanceId() {
    if (_balanceID != null && _balanceID!.v0 != null) {
      return Util.bytesToHex(_balanceID!.v0!.hash);
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
    var trustLine = XdrLedgerKeyTrustLine(XdrAccountID.forAccountId(accountId),
        XdrTrustlineAsset.fromXdrAsset(asset));
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
        id = Util.bytesToHex(
            StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }
    result.liquidityPoolID = XdrHash(Util.hexToBytes(id));
    return result;
  }

  static XdrLedgerKey forContractData(XdrSCAddress contractAddress,
      XdrSCVal key, XdrContractDataDurability durability) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    result.contractData =
        XdrLedgerKeyContractData(contractAddress, key, durability);
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
