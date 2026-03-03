// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_sequence_number.dart';
import 'xdr_uint32.dart';

class XdrHashIDPreimageOperationID {
  XdrAccountID _sourceAccount;
  XdrAccountID get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrAccountID value) => this._sourceAccount = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _opNum;
  XdrUint32 get opNum => this._opNum;
  set opNum(XdrUint32 value) => this._opNum = value;

  XdrHashIDPreimageOperationID(this._sourceAccount, this._seqNum, this._opNum);

  static void encode(
    XdrDataOutputStream stream,
    XdrHashIDPreimageOperationID encodedHashIDPreimageOperationID,
  ) {
    XdrAccountID.encode(stream, encodedHashIDPreimageOperationID.sourceAccount);
    XdrSequenceNumber.encode(stream, encodedHashIDPreimageOperationID.seqNum);
    XdrUint32.encode(stream, encodedHashIDPreimageOperationID.opNum);
  }

  static XdrHashIDPreimageOperationID decode(XdrDataInputStream stream) {
    XdrAccountID sourceAccount = XdrAccountID.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrUint32 opNum = XdrUint32.decode(stream);
    return XdrHashIDPreimageOperationID(sourceAccount, seqNum, opNum);
  }
}
