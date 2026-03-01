// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_muxed_account.dart';
import 'xdr_sequence_number.dart';
import 'xdr_uint32.dart';

class XdrHashIDPreimageOperationID {
  XdrHashIDPreimageOperationID(this._sourceAccount, this._seqNum, this._opNum);

  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _opNum;
  XdrUint32 get opNum => this._opNum;
  set opNum(XdrUint32 value) => this._opNum = value;

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageOperationID encoded) {
    XdrMuxedAccount.encode(stream, encoded.sourceAccount);
    XdrSequenceNumber.encode(stream, encoded.seqNum);
    XdrUint32.encode(stream, encoded.opNum);
  }

  static XdrHashIDPreimageOperationID decode(XdrDataInputStream stream) {
    XdrMuxedAccount sourceAccount = XdrMuxedAccount.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrUint32 opNum = XdrUint32.decode(stream);
    return XdrHashIDPreimageOperationID(sourceAccount, seqNum, opNum);
  }
}
