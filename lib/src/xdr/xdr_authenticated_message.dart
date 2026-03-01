// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_authenticated_message_v0.dart';
import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrAuthenticatedMessage {
  XdrUint32 _v;
  XdrUint32 get discriminant => this._v;
  set discriminant(XdrUint32 value) => this._v = value;

  XdrAuthenticatedMessageV0? _v0;
  XdrAuthenticatedMessageV0? get v0 => this._v0;
  set v0(XdrAuthenticatedMessageV0? value) => this._v0 = value;

  XdrAuthenticatedMessage(this._v);

  static void encode(XdrDataOutputStream stream,
      XdrAuthenticatedMessage encodedAuthenticatedMessage) {
    stream.writeInt(encodedAuthenticatedMessage.discriminant.uint32);
    switch (encodedAuthenticatedMessage.discriminant.uint32) {
      case 0:
        XdrAuthenticatedMessageV0.encode(
            stream, encodedAuthenticatedMessage._v0!);
        break;
    }
  }

  static XdrAuthenticatedMessage decode(XdrDataInputStream stream) {
    XdrAuthenticatedMessage decodedAuthenticatedMessage =
        XdrAuthenticatedMessage(XdrUint32.decode(stream));
    switch (decodedAuthenticatedMessage.discriminant.uint32) {
      case 0:
        decodedAuthenticatedMessage._v0 =
            XdrAuthenticatedMessageV0.decode(stream);
        break;
    }
    return decodedAuthenticatedMessage;
  }
}
