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
      this._ext, this._contract, this._key, this._durability, this._val);

  static void encode(XdrDataOutputStream stream, XdrContractDataEntry encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrSCAddress.encode(stream, encoded.contract);
    XdrSCVal.encode(stream, encoded.key);
    XdrContractDataDurability.encode(stream, encoded.durability);
    XdrSCVal.encode(stream, encoded.val);
  }

  static XdrContractDataEntry decode(XdrDataInputStream stream) {
    return XdrContractDataEntry(
        XdrExtensionPoint.decode(stream),
        XdrSCAddress.decode(stream),
        XdrSCVal.decode(stream),
        XdrContractDataDurability.decode(stream),
        XdrSCVal.decode(stream));
  }
}
