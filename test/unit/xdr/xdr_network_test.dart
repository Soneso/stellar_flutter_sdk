// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('XDR Network Types - Deep Branch Testing', () {
    test('XdrIPAddrType toString', () {
      expect(XdrIPAddrType.IPv4.toString(), contains('IPAddrType'));
    });

    test('XdrIPAddrType decode throws on invalid value', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(99);

      XdrDataInputStream input = XdrDataInputStream(Uint8List.fromList(output.bytes));

      expect(() => XdrIPAddrType.decode(input), throwsException);
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
