// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import "dart:typed_data";

class XdrNodeID {
  XdrPublicKey _nodeID;
  XdrPublicKey get nodeID => this._nodeID;
  set nodeID(XdrPublicKey value) => this._nodeID = value;

  static void encode(XdrDataOutputStream stream, XdrNodeID encodedNodeID) {
    XdrPublicKey.encode(stream, encodedNodeID._nodeID);
  }

  static XdrNodeID decode(XdrDataInputStream stream) {
    XdrNodeID decodedNodeID = XdrNodeID();
    decodedNodeID._nodeID = XdrPublicKey.decode(stream);
    return decodedNodeID;
  }
}

class XdrPeerAddress {
  XdrPeerAddress();
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
      XdrDataOutputStream stream, XdrPeerAddress encodedPeerAddress) {
    XdrPeerAddressIp.encode(stream, encodedPeerAddress.ip);
    XdrUint32.encode(stream, encodedPeerAddress.port);
    XdrUint32.encode(stream, encodedPeerAddress.numFailures);
  }

  static XdrPeerAddress decode(XdrDataInputStream stream) {
    XdrPeerAddress decodedPeerAddress = XdrPeerAddress();
    decodedPeerAddress.ip = XdrPeerAddressIp.decode(stream);
    decodedPeerAddress.port = XdrUint32.decode(stream);
    decodedPeerAddress.numFailures = XdrUint32.decode(stream);
    return decodedPeerAddress;
  }
}

class XdrPeerAddressIp {
  XdrPeerAddressIp();
  XdrIPAddrType _type;
  XdrIPAddrType get discriminant => this._type;
  set discriminant(XdrIPAddrType value) => this._type = value;

  Uint8List _ipv4;
  Uint8List get ipv4 => this._ipv4;
  set ipv4(Uint8List value) => this._ipv4 = value;

  Uint8List _ipv6;
  Uint8List get ipv6 => this._ipv6;
  set ipv6(Uint8List value) => this._ipv6 = value;

  static void encode(
      XdrDataOutputStream stream, XdrPeerAddressIp encodedPeerAddressIp) {
    stream.writeInt(encodedPeerAddressIp.discriminant.value);
    switch (encodedPeerAddressIp.discriminant) {
      case XdrIPAddrType.IPv4:
        stream.write(encodedPeerAddressIp.ipv4);
        break;
      case XdrIPAddrType.IPv6:
        stream.write(encodedPeerAddressIp.ipv6);
        break;
    }
  }

  static XdrPeerAddressIp decode(XdrDataInputStream stream) {
    XdrPeerAddressIp decodedPeerAddressIp = XdrPeerAddressIp();
    XdrIPAddrType discriminant = XdrIPAddrType.decode(stream);
    decodedPeerAddressIp.discriminant = discriminant;
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

class XdrIPAddrType {
  final _value;
  const XdrIPAddrType._internal(this._value);
  toString() => 'IPAddrType.$_value';
  XdrIPAddrType(this._value);
  get value => this._value;

  static const IPv4 = const XdrIPAddrType._internal(0);
  static const IPv6 = const XdrIPAddrType._internal(1);

  static XdrIPAddrType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return IPv4;
      case 1:
        return IPv6;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrIPAddrType value) {
    stream.writeInt(value.value);
  }
}
