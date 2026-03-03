// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_contract_code_entry_ext.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrContractCodeEntry {
  XdrContractCodeEntryExt _ext;
  XdrContractCodeEntryExt get ext => this._ext;
  set ext(XdrContractCodeEntryExt value) => this._ext = value;

  XdrHash _hash;
  XdrHash get hash => this._hash;
  set hash(XdrHash value) => this._hash = value;

  Uint8List _code;
  Uint8List get code => this._code;
  set code(Uint8List value) => this._code = value;

  XdrContractCodeEntry(this._ext, this._hash, this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCodeEntry encodedContractCodeEntry,
  ) {
    XdrContractCodeEntryExt.encode(stream, encodedContractCodeEntry.ext);
    XdrHash.encode(stream, encodedContractCodeEntry.hash);
    int codesize = encodedContractCodeEntry.code.length;
    stream.writeInt(codesize);
    stream.write(encodedContractCodeEntry.code);
  }

  static XdrContractCodeEntry decode(XdrDataInputStream stream) {
    XdrContractCodeEntryExt ext = XdrContractCodeEntryExt.decode(stream);
    XdrHash hash = XdrHash.decode(stream);
    int codesize = stream.readInt();
    Uint8List code = stream.readBytes(codesize);
    return XdrContractCodeEntry(ext, hash, code);
  }
}
