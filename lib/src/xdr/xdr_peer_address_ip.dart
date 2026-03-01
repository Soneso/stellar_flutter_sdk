// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ip_addr_type.dart';

class XdrPeerAddressIp {
  XdrPeerAddressIp(this._type);
  XdrIPAddrType _type;
  XdrIPAddrType get discriminant => this._type;
  set discriminant(XdrIPAddrType value) => this._type = value;

  Uint8List? _ipv4;
  Uint8List? get ipv4 => this._ipv4;
  set ipv4(Uint8List? value) => this._ipv4 = value;

  Uint8List? _ipv6;
  Uint8List? get ipv6 => this._ipv6;
  set ipv6(Uint8List? value) => this._ipv6 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrPeerAddressIp encodedPeerAddressIp,
  ) {
    stream.writeInt(encodedPeerAddressIp.discriminant.value);
    switch (encodedPeerAddressIp.discriminant) {
      case XdrIPAddrType.IPv4:
        stream.write(encodedPeerAddressIp.ipv4!);
        break;
      case XdrIPAddrType.IPv6:
        stream.write(encodedPeerAddressIp.ipv6!);
        break;
    }
  }

  static XdrPeerAddressIp decode(XdrDataInputStream stream) {
    XdrPeerAddressIp decodedPeerAddressIp = XdrPeerAddressIp(
      XdrIPAddrType.decode(stream),
    );
    switch (decodedPeerAddressIp.discriminant) {
      case XdrIPAddrType.IPv4:
        int ipv4size = 4;
        decodedPeerAddressIp.ipv4 = stream.readBytes(ipv4size);
        break;
      case XdrIPAddrType.IPv6:
        int ipv6size = 16;
        decodedPeerAddressIp.ipv6 = stream.readBytes(ipv6size);
        break;
    }
    return decodedPeerAddressIp;
  }
}
