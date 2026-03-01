// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_id.dart';
import 'xdr_config_setting_id.dart';
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

class XdrLedgerKeyBase {
  XdrLedgerKeyBase(this._type);
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
    XdrDataOutputStream stream,
    XdrLedgerKeyBase encodedLedgerKey,
  ) {
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

  static XdrLedgerKeyBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrLedgerKeyBase.new);
  }

  static T decodeAs<T extends XdrLedgerKeyBase>(
    XdrDataInputStream stream,
    T Function(XdrLedgerEntryType) constructor,
  ) {
    XdrLedgerEntryType discriminant = XdrLedgerEntryType.decode(stream);
    T decodedLedgerKey = constructor(discriminant);
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
}
