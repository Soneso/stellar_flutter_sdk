// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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

class XdrLedgerEntryDataBase {
  XdrLedgerEntryType _type;

  XdrLedgerEntryType get discriminant => this._type;

  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrAccountEntry? _account;

  XdrAccountEntry? get account => this._account;

  XdrTrustLineEntry? _trustLine;

  XdrTrustLineEntry? get trustLine => this._trustLine;

  XdrOfferEntry? _offer;

  XdrOfferEntry? get offer => this._offer;

  XdrDataEntry? _data;

  XdrDataEntry? get data => this._data;

  XdrClaimableBalanceEntry? _claimableBalance;

  XdrClaimableBalanceEntry? get claimableBalance => this._claimableBalance;

  XdrLiquidityPoolEntry? _liquidityPool;

  XdrLiquidityPoolEntry? get liquidityPool => this._liquidityPool;

  XdrContractDataEntry? _contractData;

  XdrContractDataEntry? get contractData => this._contractData;

  XdrContractCodeEntry? _contractCode;

  XdrContractCodeEntry? get contractCode => this._contractCode;

  XdrConfigSettingEntry? _configSetting;

  XdrConfigSettingEntry? get configSetting => this._configSetting;

  XdrTTLEntry? _ttl;

  XdrTTLEntry? get ttl => this._ttl;

  XdrLedgerEntryDataBase(this._type);

  set account(XdrAccountEntry? value) => this._account = value;

  set trustLine(XdrTrustLineEntry? value) => this._trustLine = value;

  set offer(XdrOfferEntry? value) => this._offer = value;

  set data(XdrDataEntry? value) => this._data = value;

  set claimableBalance(XdrClaimableBalanceEntry? value) => this._claimableBalance = value;

  set liquidityPool(XdrLiquidityPoolEntry? value) => this._liquidityPool = value;

  set contractData(XdrContractDataEntry? value) => this._contractData = value;

  set contractCode(XdrContractCodeEntry? value) => this._contractCode = value;

  set configSetting(XdrConfigSettingEntry? value) => this._configSetting = value;

  set ttl(XdrTTLEntry? value) => this._ttl = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryDataBase encodedLedgerEntryData) {
    stream.writeInt(encodedLedgerEntryData.discriminant.value);
    switch (encodedLedgerEntryData.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrAccountEntry.encode(stream, encodedLedgerEntryData._account!);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrTrustLineEntry.encode(stream, encodedLedgerEntryData._trustLine!);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrOfferEntry.encode(stream, encodedLedgerEntryData._offer!);
        break;
      case XdrLedgerEntryType.DATA:
        XdrDataEntry.encode(stream, encodedLedgerEntryData._data!);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        XdrClaimableBalanceEntry.encode(stream, encodedLedgerEntryData._claimableBalance!);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        XdrLiquidityPoolEntry.encode(stream, encodedLedgerEntryData._liquidityPool!);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        XdrContractDataEntry.encode(stream, encodedLedgerEntryData._contractData!);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        XdrContractCodeEntry.encode(stream, encodedLedgerEntryData._contractCode!);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        XdrConfigSettingEntry.encode(stream, encodedLedgerEntryData._configSetting!);
        break;
      case XdrLedgerEntryType.TTL:
        XdrTTLEntry.encode(stream, encodedLedgerEntryData._ttl!);
        break;
      default:
        break;
    }
  }

  static XdrLedgerEntryDataBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrLedgerEntryDataBase.new);
  }

  static T decodeAs<T extends XdrLedgerEntryDataBase>(
    XdrDataInputStream stream,
    T Function(XdrLedgerEntryType) constructor,
  ) {
    T decoded = constructor(XdrLedgerEntryType.decode(stream));
    switch (decoded.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        decoded._account = XdrAccountEntry.decode(stream);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        decoded._trustLine = XdrTrustLineEntry.decode(stream);
        break;
      case XdrLedgerEntryType.OFFER:
        decoded._offer = XdrOfferEntry.decode(stream);
        break;
      case XdrLedgerEntryType.DATA:
        decoded._data = XdrDataEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        decoded._claimableBalance = XdrClaimableBalanceEntry.decode(stream);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        decoded._liquidityPool = XdrLiquidityPoolEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        decoded._contractData = XdrContractDataEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        decoded._contractCode = XdrContractCodeEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        decoded._configSetting = XdrConfigSettingEntry.decode(stream);
        break;
      case XdrLedgerEntryType.TTL:
        decoded._ttl = XdrTTLEntry.decode(stream);
        break;
      default:
        break;
    }
    return decoded;
  }
}
