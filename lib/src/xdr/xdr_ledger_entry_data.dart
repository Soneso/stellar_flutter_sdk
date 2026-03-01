// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_account_entry.dart';
import 'xdr_claimable_balance_entry.dart';
import 'xdr_config_setting_entry.dart';
import 'xdr_contract_code_entry.dart';
import 'xdr_contract_data_entry.dart';
import 'xdr_data_entry.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_entry_type.dart';
import 'xdr_liquidity_pool_entry.dart';
import 'xdr_offer_entry.dart';
import 'xdr_trust_line_entry.dart';
import 'xdr_ttl_entry.dart';

class XdrLedgerEntryData {
  XdrLedgerEntryData(this._type);

  XdrLedgerEntryType _type;
  XdrLedgerEntryType get discriminant => this._type;
  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrAccountEntry? _account;
  XdrAccountEntry? get account => this._account;
  set account(XdrAccountEntry? value) => this._account = value;

  XdrTrustLineEntry? _trustLine;
  XdrTrustLineEntry? get trustLine => this._trustLine;
  set trustLine(XdrTrustLineEntry? value) => this._trustLine = value;

  XdrOfferEntry? _offer;
  XdrOfferEntry? get offer => this._offer;
  set offer(XdrOfferEntry? value) => this._offer = value;

  XdrDataEntry? _data;
  XdrDataEntry? get data => this._data;
  set data(XdrDataEntry? value) => this._data = value;

  XdrClaimableBalanceEntry? _claimableBalance;
  XdrClaimableBalanceEntry? get claimableBalance => this._claimableBalance;
  set claimableBalance(XdrClaimableBalanceEntry? value) =>
      this._claimableBalance = value;

  XdrLiquidityPoolEntry? _liquidityPool;
  XdrLiquidityPoolEntry? get liquidityPool => this._liquidityPool;
  set liquidityPool(XdrLiquidityPoolEntry? value) =>
      this._liquidityPool = value;

  XdrContractDataEntry? _contractData;
  XdrContractDataEntry? get contractData => this._contractData;
  set contractData(XdrContractDataEntry? value) => this._contractData = value;

  XdrContractCodeEntry? _contractCode;
  XdrContractCodeEntry? get contractCode => this._contractCode;
  set contractCode(XdrContractCodeEntry? value) => this._contractCode = value;

  XdrConfigSettingEntry? _configSetting;
  XdrConfigSettingEntry? get configSetting => this._configSetting;
  set configSetting(XdrConfigSettingEntry? value) =>
      this._configSetting = value;

  XdrTTLEntry? _expiration;
  XdrTTLEntry? get expiration => this._expiration;
  set expiration(XdrTTLEntry? value) => this._expiration = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntryData encodedLedgerEntryData) {
    stream.writeInt(encodedLedgerEntryData.discriminant.value);
    switch (encodedLedgerEntryData.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrAccountEntry.encode(stream, encodedLedgerEntryData.account!);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrTrustLineEntry.encode(stream, encodedLedgerEntryData.trustLine!);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrOfferEntry.encode(stream, encodedLedgerEntryData.offer!);
        break;
      case XdrLedgerEntryType.DATA:
        XdrDataEntry.encode(stream, encodedLedgerEntryData.data!);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        XdrClaimableBalanceEntry.encode(
            stream, encodedLedgerEntryData.claimableBalance!);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        XdrLiquidityPoolEntry.encode(
            stream, encodedLedgerEntryData.liquidityPool!);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        XdrContractDataEntry.encode(
            stream, encodedLedgerEntryData.contractData!);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        XdrContractCodeEntry.encode(
            stream, encodedLedgerEntryData.contractCode!);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        XdrConfigSettingEntry.encode(
            stream, encodedLedgerEntryData.configSetting!);
        break;
      case XdrLedgerEntryType.TTL:
        XdrTTLEntry.encode(stream, encodedLedgerEntryData.expiration!);
        break;
    }
  }

  static XdrLedgerEntryData decode(XdrDataInputStream stream) {
    XdrLedgerEntryData decodedLedgerEntryData =
        XdrLedgerEntryData(XdrLedgerEntryType.decode(stream));
    switch (decodedLedgerEntryData.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        decodedLedgerEntryData.account = XdrAccountEntry.decode(stream);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        decodedLedgerEntryData.trustLine = XdrTrustLineEntry.decode(stream);
        break;
      case XdrLedgerEntryType.OFFER:
        decodedLedgerEntryData.offer = XdrOfferEntry.decode(stream);
        break;
      case XdrLedgerEntryType.DATA:
        decodedLedgerEntryData.data = XdrDataEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        decodedLedgerEntryData.claimableBalance =
            XdrClaimableBalanceEntry.decode(stream);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        decodedLedgerEntryData.liquidityPool =
            XdrLiquidityPoolEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        decodedLedgerEntryData.contractData =
            XdrContractDataEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        decodedLedgerEntryData.contractCode =
            XdrContractCodeEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        decodedLedgerEntryData.configSetting =
            XdrConfigSettingEntry.decode(stream);
        break;
      case XdrLedgerEntryType.TTL:
        decodedLedgerEntryData.expiration = XdrTTLEntry.decode(stream);
        break;
    }
    return decodedLedgerEntryData;
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntryData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerEntryData fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerEntryData.decode(XdrDataInputStream(bytes));
  }
}
