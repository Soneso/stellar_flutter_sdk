// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('XDR Network Types - Deep Branch Testing', () {
    test('XdrIPAddrType IPv4 encode and decode', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrIPAddrType.encode(output, XdrIPAddrType.IPv4);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrIPAddrType decoded = XdrIPAddrType.decode(input);
      
      expect(decoded.value, equals(XdrIPAddrType.IPv4.value));
      expect(decoded.toString(), contains('IPAddrType'));
    });

    test('XdrIPAddrType IPv6 encode and decode', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrIPAddrType.encode(output, XdrIPAddrType.IPv6);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrIPAddrType decoded = XdrIPAddrType.decode(input);
      
      expect(decoded.value, equals(XdrIPAddrType.IPv6.value));
    });

    test('XdrIPAddrType decode throws on invalid value', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(99);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      
      expect(() => XdrIPAddrType.decode(input), throwsException);
    });

    test('XdrPeerAddressIp IPv4 encode and decode', () {
      Uint8List ipv4 = Uint8List.fromList([192, 168, 1, 100]);
      
      XdrPeerAddressIp original = XdrPeerAddressIp(XdrIPAddrType.IPv4);
      original.ipv4 = ipv4;
      
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPeerAddressIp.encode(output, original);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrPeerAddressIp decoded = XdrPeerAddressIp.decode(input);
      
      expect(decoded.discriminant.value, equals(XdrIPAddrType.IPv4.value));
      expect(decoded.ipv4, isNotNull);
      expect(decoded.ipv4!.length, equals(4));
      expect(decoded.ipv4![0], equals(192));
      expect(decoded.ipv4![1], equals(168));
      expect(decoded.ipv4![2], equals(1));
      expect(decoded.ipv4![3], equals(100));
    });

    test('XdrPeerAddressIp IPv6 encode and decode', () {
      Uint8List ipv6 = Uint8List.fromList([
        32, 1, 13, 184, 133, 163, 0, 0, 
        0, 0, 138, 46, 3, 112, 115, 52
      ]);
      
      XdrPeerAddressIp original = XdrPeerAddressIp(XdrIPAddrType.IPv6);
      original.ipv6 = ipv6;
      
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPeerAddressIp.encode(output, original);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrPeerAddressIp decoded = XdrPeerAddressIp.decode(input);
      
      expect(decoded.discriminant.value, equals(XdrIPAddrType.IPv6.value));
      expect(decoded.ipv6, isNotNull);
      expect(decoded.ipv6!.length, equals(16));
      expect(decoded.ipv6![0], equals(32));
      expect(decoded.ipv6![15], equals(52));
    });

    test('XdrPeerAddress encode and decode with IPv4', () {
      Uint8List ipv4 = Uint8List.fromList([10, 0, 0, 1]);
      XdrPeerAddressIp ip = XdrPeerAddressIp(XdrIPAddrType.IPv4);
      ip.ipv4 = ipv4;
      
      XdrUint32 port = XdrUint32(8000);
      XdrUint32 numFailures = XdrUint32(5);
      
      XdrPeerAddress original = XdrPeerAddress(ip, port, numFailures);
      
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPeerAddress.encode(output, original);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrPeerAddress decoded = XdrPeerAddress.decode(input);
      
      expect(decoded.ip.discriminant.value, equals(XdrIPAddrType.IPv4.value));
      expect(decoded.ip.ipv4, isNotNull);
      expect(decoded.port.uint32, equals(8000));
      expect(decoded.numFailures.uint32, equals(5));
    });

    test('XdrPeerAddress encode and decode with IPv6', () {
      Uint8List ipv6 = Uint8List.fromList([
        254, 128, 0, 0, 0, 0, 0, 0, 
        2, 23, 54, 255, 254, 156, 44, 5
      ]);
      XdrPeerAddressIp ip = XdrPeerAddressIp(XdrIPAddrType.IPv6);
      ip.ipv6 = ipv6;
      
      XdrUint32 port = XdrUint32(11625);
      XdrUint32 numFailures = XdrUint32(0);
      
      XdrPeerAddress original = XdrPeerAddress(ip, port, numFailures);
      
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPeerAddress.encode(output, original);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrPeerAddress decoded = XdrPeerAddress.decode(input);
      
      expect(decoded.ip.discriminant.value, equals(XdrIPAddrType.IPv6.value));
      expect(decoded.ip.ipv6, isNotNull);
      expect(decoded.ip.ipv6!.length, equals(16));
      expect(decoded.port.uint32, equals(11625));
      expect(decoded.numFailures.uint32, equals(0));
    });

    test('XdrPeerAddress with high port number', () {
      Uint8List ipv4 = Uint8List.fromList([127, 0, 0, 1]);
      XdrPeerAddressIp ip = XdrPeerAddressIp(XdrIPAddrType.IPv4);
      ip.ipv4 = ipv4;
      
      XdrUint32 port = XdrUint32(65535);
      XdrUint32 numFailures = XdrUint32(100);
      
      XdrPeerAddress original = XdrPeerAddress(ip, port, numFailures);
      
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPeerAddress.encode(output, original);
      
      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrPeerAddress decoded = XdrPeerAddress.decode(input);
      
      expect(decoded.port.uint32, equals(65535));
      expect(decoded.numFailures.uint32, equals(100));
    });

    test('XdrNodeID encode and decode', () {
      KeyPair keyPair = KeyPair.random();
      XdrPublicKey publicKey = keyPair.xdrPublicKey;

      XdrNodeID original = XdrNodeID(publicKey);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrNodeID.encode(output, original);

      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      XdrNodeID decoded = XdrNodeID.decode(input);

      expect(decoded.nodeID.getDiscriminant(), equals(publicKey.getDiscriminant()));
    });

    test('XdrPeerAddressIp setters and getters', () {
      XdrPeerAddressIp peerIp = XdrPeerAddressIp(XdrIPAddrType.IPv4);
      
      Uint8List ipv4Data = Uint8List.fromList([172, 16, 0, 1]);
      peerIp.ipv4 = ipv4Data;
      
      expect(peerIp.ipv4, equals(ipv4Data));
      expect(peerIp.discriminant.value, equals(XdrIPAddrType.IPv4.value));
      
      peerIp.discriminant = XdrIPAddrType.IPv6;
      expect(peerIp.discriminant.value, equals(XdrIPAddrType.IPv6.value));
      
      Uint8List ipv6Data = Uint8List(16);
      peerIp.ipv6 = ipv6Data;
      expect(peerIp.ipv6, equals(ipv6Data));
    });

    test('XdrPeerAddress setters and getters', () {
      Uint8List ipv4 = Uint8List.fromList([192, 168, 0, 1]);
      XdrPeerAddressIp ip = XdrPeerAddressIp(XdrIPAddrType.IPv4);
      ip.ipv4 = ipv4;
      
      XdrPeerAddress peerAddr = XdrPeerAddress(
        ip, 
        XdrUint32(9000), 
        XdrUint32(3)
      );
      
      expect(peerAddr.ip.ipv4, equals(ipv4));
      expect(peerAddr.port.uint32, equals(9000));
      expect(peerAddr.numFailures.uint32, equals(3));
      
      XdrUint32 newPort = XdrUint32(8080);
      peerAddr.port = newPort;
      expect(peerAddr.port.uint32, equals(8080));
      
      XdrUint32 newFailures = XdrUint32(10);
      peerAddr.numFailures = newFailures;
      expect(peerAddr.numFailures.uint32, equals(10));
    });
  });
}
