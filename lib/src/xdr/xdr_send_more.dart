// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrSendMore {

  XdrUint32 _numMessages;
  XdrUint32 get numMessages => this._numMessages;
  set numMessages(XdrUint32 value) => this._numMessages = value;

  XdrSendMore(this._numMessages);

  static void encode(XdrDataOutputStream stream, XdrSendMore encodedSendMore) {
    XdrUint32.encode(stream, encodedSendMore.numMessages);
  }

  static XdrSendMore decode(XdrDataInputStream stream) {
    XdrUint32 numMessages = XdrUint32.decode(stream);
    return XdrSendMore(numMessages);
  }
}
