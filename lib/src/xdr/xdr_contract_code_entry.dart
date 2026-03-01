// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_code_entry_ext.dart';
import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_hash.dart';

class XdrContractCodeEntry {
  XdrContractCodeEntryExt _ext;
  XdrContractCodeEntryExt get ext => this._ext;
  set ext(XdrContractCodeEntryExt value) => this._ext = value;

  XdrHash _cHash;
  XdrHash get cHash => this._cHash;
  set cHash(XdrHash value) => this._cHash = value;

  XdrDataValue _code;
  XdrDataValue get code => this._code;
  set code(XdrDataValue value) => this._code = value;

  XdrContractCodeEntry(this._ext, this._cHash, this._code);

  static void encode(XdrDataOutputStream stream, XdrContractCodeEntry encoded) {
    XdrContractCodeEntryExt.encode(stream, encoded.ext);
    XdrHash.encode(stream, encoded.cHash);
    XdrDataValue.encode(stream, encoded.code);
  }

  static XdrContractCodeEntry decode(XdrDataInputStream stream) {
    return XdrContractCodeEntry(
      XdrContractCodeEntryExt.decode(stream),
      XdrHash.decode(stream),
      XdrDataValue.decode(stream),
    );
  }
}
