// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_data_durability.dart';
import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';

class XdrContractDataEntry {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrSCAddress _contract;
  XdrSCAddress get contract => this._contract;
  set contract(XdrSCAddress value) => this._contract = value;

  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrContractDataDurability _durability;
  XdrContractDataDurability get durability => this._durability;
  set durability(XdrContractDataDurability value) => this._durability = value;

  XdrSCVal _val;
  XdrSCVal get val => this._val;
  set val(XdrSCVal value) => this._val = value;

  XdrContractDataEntry(
    this._ext,
    this._contract,
    this._key,
    this._durability,
    this._val,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrContractDataEntry encodedContractDataEntry,
  ) {
    XdrExtensionPoint.encode(stream, encodedContractDataEntry.ext);
    XdrSCAddress.encode(stream, encodedContractDataEntry.contract);
    XdrSCVal.encode(stream, encodedContractDataEntry.key);
    XdrContractDataDurability.encode(
      stream,
      encodedContractDataEntry.durability,
    );
    XdrSCVal.encode(stream, encodedContractDataEntry.val);
  }

  static XdrContractDataEntry decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrSCAddress contract = XdrSCAddress.decode(stream);
    XdrSCVal key = XdrSCVal.decode(stream);
    XdrContractDataDurability durability = XdrContractDataDurability.decode(
      stream,
    );
    XdrSCVal val = XdrSCVal.decode(stream);
    return XdrContractDataEntry(ext, contract, key, durability, val);
  }
}
