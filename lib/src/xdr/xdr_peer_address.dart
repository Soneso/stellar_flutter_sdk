// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_peer_address_ip.dart';
import 'xdr_uint32.dart';

class XdrPeerAddress {
  XdrPeerAddress(this._ip, this._port, this._numFailures);
  XdrPeerAddressIp _ip;
  XdrPeerAddressIp get ip => this._ip;
  set ip(XdrPeerAddressIp value) => this._ip = value;

  XdrUint32 _port;
  XdrUint32 get port => this._port;
  set port(XdrUint32 value) => this._port = value;

  XdrUint32 _numFailures;
  XdrUint32 get numFailures => this._numFailures;
  set numFailures(XdrUint32 value) => this._numFailures = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrPeerAddress encodedPeerAddress,
  ) {
    XdrPeerAddressIp.encode(stream, encodedPeerAddress.ip);
    XdrUint32.encode(stream, encodedPeerAddress.port);
    XdrUint32.encode(stream, encodedPeerAddress.numFailures);
  }

  static XdrPeerAddress decode(XdrDataInputStream stream) {
    XdrPeerAddressIp ip = XdrPeerAddressIp.decode(stream);
    XdrUint32 port = XdrUint32.decode(stream);
    XdrUint32 numFailures = XdrUint32.decode(stream);
    return XdrPeerAddress(ip, port, numFailures);
  }
}
