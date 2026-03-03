// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_public_key.dart';

class XdrNodeID {
  XdrNodeID(this._nodeID);

  XdrPublicKey _nodeID;
  XdrPublicKey get nodeID => this._nodeID;
  set nodeID(XdrPublicKey value) => this._nodeID = value;

  static void encode(XdrDataOutputStream stream, XdrNodeID encodedNodeID) {
    XdrPublicKey.encode(stream, encodedNodeID.nodeID);
  }

  static XdrNodeID decode(XdrDataInputStream stream) {
    return XdrNodeID(XdrPublicKey.decode(stream));
  }
}
