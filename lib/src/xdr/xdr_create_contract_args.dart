// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_executable.dart';
import 'xdr_contract_id_preimage.dart';
import 'xdr_data_io.dart';

class XdrCreateContractArgs {
  XdrContractIDPreimage _contractIDPreimage;
  XdrContractIDPreimage get contractIDPreimage => this._contractIDPreimage;
  set contractIDPreimage(XdrContractIDPreimage value) =>
      this._contractIDPreimage = value;

  XdrContractExecutable _executable;
  XdrContractExecutable get executable => this._executable;
  set executable(XdrContractExecutable value) => this._executable = value;

  XdrCreateContractArgs(this._contractIDPreimage, this._executable);

  static void encode(
      XdrDataOutputStream stream, XdrCreateContractArgs encoded) {
    XdrContractIDPreimage.encode(stream, encoded.contractIDPreimage);
    XdrContractExecutable.encode(stream, encoded.executable);
  }

  static XdrCreateContractArgs decode(XdrDataInputStream stream) {
    return XdrCreateContractArgs(XdrContractIDPreimage.decode(stream),
        XdrContractExecutable.decode(stream));
  }
}
