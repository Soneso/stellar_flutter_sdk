// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_data_durability.dart';
import 'xdr_data_io.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';

class XdrLedgerKeyContractData {
  XdrSCAddress _contract;
  XdrSCAddress get contract => this._contract;
  set contract(XdrSCAddress value) => this._contract = value;

  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrContractDataDurability _durability;
  XdrContractDataDurability get durability => this._durability;
  set durability(XdrContractDataDurability value) => this._durability = value;

  XdrLedgerKeyContractData(this._contract, this._key, this._durability);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerKeyContractData encodedLedgerKeyContractData,
  ) {
    XdrSCAddress.encode(stream, encodedLedgerKeyContractData.contract);
    XdrSCVal.encode(stream, encodedLedgerKeyContractData.key);
    XdrContractDataDurability.encode(
      stream,
      encodedLedgerKeyContractData.durability,
    );
  }

  static XdrLedgerKeyContractData decode(XdrDataInputStream stream) {
    XdrSCAddress contract = XdrSCAddress.decode(stream);
    XdrSCVal key = XdrSCVal.decode(stream);
    XdrContractDataDurability durability = XdrContractDataDurability.decode(
      stream,
    );
    return XdrLedgerKeyContractData(contract, key, durability);
  }
}
