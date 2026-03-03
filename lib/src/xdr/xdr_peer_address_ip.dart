// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ip_addr_type.dart';

class XdrPeerAddressIp {
  XdrIPAddrType _type;

  XdrIPAddrType get discriminant => this._type;

  set discriminant(XdrIPAddrType value) => this._type = value;

  Uint8List? _ipv4;

  Uint8List? get ipv4 => this._ipv4;

  Uint8List? _ipv6;

  Uint8List? get ipv6 => this._ipv6;

  XdrPeerAddressIp(this._type);

  set ipv4(Uint8List? value) => this._ipv4 = value;

  set ipv6(Uint8List? value) => this._ipv6 = value;

  static void encode(XdrDataOutputStream stream, XdrPeerAddressIp encodedPeerAddressIp) {
    stream.writeInt(encodedPeerAddressIp.discriminant.value);
    switch (encodedPeerAddressIp.discriminant) {
      case XdrIPAddrType.IPv4:
        stream.write(encodedPeerAddressIp._ipv4!);
        break;
      case XdrIPAddrType.IPv6:
        stream.write(encodedPeerAddressIp._ipv6!);
        break;
      default:
        break;
    }
  }

  static XdrPeerAddressIp decode(XdrDataInputStream stream) {
    XdrPeerAddressIp decodedPeerAddressIp = XdrPeerAddressIp(XdrIPAddrType.decode(stream));
    switch (decodedPeerAddressIp.discriminant) {
      case XdrIPAddrType.IPv4:
        decodedPeerAddressIp._ipv4 = stream.readBytes(stream.readInt());
        break;
      case XdrIPAddrType.IPv6:
        decodedPeerAddressIp._ipv6 = stream.readBytes(stream.readInt());
        break;
      default:
        break;
    }
    return decodedPeerAddressIp;
  }
}
