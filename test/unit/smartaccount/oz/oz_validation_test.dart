// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_validation.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String _kValidContractId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

const String _kVerifierContract =
    'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';

const String _kAccountAddress =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

Uint8List _keyData(int length) =>
    Uint8List.fromList(List<int>.filled(length, 0x01));

void main() {
  group('requireContractAddress', () {
    test('test_requireContractAddress_validC_address_returnsNoThrow', () {
      expect(
        () => requireContractAddress(_kValidContractId,
            fieldName: 'policyAddress'),
        returnsNormally,
      );
    });

    test('test_requireContractAddress_invalidAddress_throwsInvalidAddress7001',
        () {
      SmartAccountInvalidAddress? captured;
      try {
        requireContractAddress('not-a-valid-address',
            fieldName: 'policyAddress');
        fail('Expected SmartAccountInvalidAddress to be thrown');
      } on SmartAccountInvalidAddress catch (e) {
        captured = e;
      }
      expect(captured, isA<SmartAccountInvalidAddress>());
      final exception = captured;
      expect(exception.code, SmartAccountErrorCode.invalidAddress);
      expect(exception.code.code, 7001);
      expect(
        exception.message,
        'policyAddress must be a valid contract address (C...), '
        'got: not-a-valid-address',
      );
    });
  });

  group('requireStellarAddress', () {
    test('test_requireStellarAddress_validG_address_returnsNoThrow', () {
      final accountId = KeyPair.random().accountId;
      expect(
        () => requireStellarAddress(accountId, fieldName: 'recipient'),
        returnsNormally,
      );
    });

    test('test_requireStellarAddress_validC_address_returnsNoThrow', () {
      expect(
        () => requireStellarAddress(_kValidContractId, fieldName: 'recipient'),
        returnsNormally,
      );
    });

    test('test_requireStellarAddress_muxedM_address_throwsInvalidAddress7001',
        () {
      final muxed = MuxedAccount(KeyPair.random().accountId, BigInt.from(1234));
      final muxedAddress = muxed.accountId;
      expect(muxedAddress.startsWith('M'), isTrue,
          reason: 'Test fixture must produce an M-prefixed muxed address');

      SmartAccountInvalidAddress? captured;
      try {
        requireStellarAddress(muxedAddress, fieldName: 'recipient');
        fail('Expected SmartAccountInvalidAddress to be thrown');
      } on SmartAccountInvalidAddress catch (e) {
        captured = e;
      }
      expect(captured, isA<SmartAccountInvalidAddress>());
      final exception = captured;
      expect(exception.code, SmartAccountErrorCode.invalidAddress);
      expect(exception.code.code, 7001);
      expect(
        exception.message,
        'recipient must be a valid Stellar address (G... or C...), '
        'got: $muxedAddress',
      );
    });
  });

  group('isLocalhostUrl', () {
    test(
        'test_isLocalhostUrl_localhost_root_localhost_port_localhost_path_accepted_localhostEvilCom_rejected_https_rejected',
        () {
      expect(isLocalhostUrl('http://localhost'), isTrue,
          reason: 'bare localhost should be accepted');
      expect(isLocalhostUrl('http://localhost:8080'), isTrue,
          reason: 'localhost with port should be accepted');
      expect(isLocalhostUrl('http://localhost/api'), isTrue,
          reason: 'localhost with path should be accepted');
      expect(isLocalhostUrl('http://localhost.evil.com'), isFalse,
          reason: 'localhost.evil.com boundary attack should be rejected');
      expect(isLocalhostUrl('https://localhost'), isFalse,
          reason: 'https scheme should be rejected');
      expect(isLocalhostUrl('http://example.com'), isFalse,
          reason: 'non-localhost host should be rejected');
    });

    test('testIsLocalhostUrl_userinfoBypass_rejected', () {
      expect(isLocalhostUrl('http://localhost:8080@evil.com/'), isFalse,
          reason:
              'userinfo-smuggled host (localhost:8080 as userinfo) must be rejected');
      expect(isLocalhostUrl('http://localhost@evil.com'), isFalse,
          reason: 'userinfo-smuggled host (localhost as userinfo) must be rejected');
      expect(isLocalhostUrl('http://localhost:1@evil.com/'), isFalse,
          reason:
              'userinfo-smuggled host (localhost:1 as userinfo) must be rejected');
    });

    test('testIsLocalhostUrl_loopbackHosts_accepted', () {
      expect(isLocalhostUrl('http://127.0.0.1'), isTrue,
          reason: 'IPv4 loopback should be accepted');
      expect(isLocalhostUrl('http://127.0.0.1:8080'), isTrue,
          reason: 'IPv4 loopback with port should be accepted');
      expect(isLocalhostUrl('http://[::1]'), isTrue,
          reason: 'IPv6 loopback should be accepted');
      expect(isLocalhostUrl('http://[::1]:8080'), isTrue,
          reason: 'IPv6 loopback with port should be accepted');
    });
  });

  group('requireValidContextRuleName', () {
    test('testContextRuleName_empty_throws', () {
      expect(
        () => requireValidContextRuleName(''),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('testContextRuleName_at20Bytes_ok', () {
      // 20 ASCII characters == 20 UTF-8 bytes: at the limit, accepted.
      expect(
        () => requireValidContextRuleName('a' * OZConstants.maxNameSize),
        returnsNormally,
      );
    });

    test('testContextRuleName_21Bytes_throws', () {
      expect(
        () => requireValidContextRuleName('a' * (OZConstants.maxNameSize + 1)),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('testContextRuleName_multiByteUtf8_measuredInBytesNotChars', () {
      // "ä" is 2 UTF-8 bytes. 10 chars == 20 bytes: at the limit, accepted.
      expect(() => requireValidContextRuleName('ä' * 10), returnsNormally);
      // 11 chars == 22 bytes: over the byte limit even though the character
      // count is <= 20.
      expect(
        () => requireValidContextRuleName('ä' * 11),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('requireValidSigners', () {
    test('testExternalSigner_at256Bytes_ok', () {
      final signer = OZExternalSigner(
        _kVerifierContract,
        _keyData(OZConstants.maxExternalKeySize),
      );
      expect(
        () => requireValidSigners(<OZSmartAccountSigner>[signer]),
        returnsNormally,
      );
    });

    test('testExternalSigner_257Bytes_throws', () {
      final signer = OZExternalSigner(
        _kVerifierContract,
        _keyData(OZConstants.maxExternalKeySize + 1),
      );
      expect(
        () => requireValidSigners(<OZSmartAccountSigner>[signer]),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('testDelegatedSigner_hasNoKeyData_skipped', () {
      // Delegated signers carry no key data and must never trip the
      // external-key check.
      expect(
        () => requireValidSigners(
          <OZSmartAccountSigner>[OZDelegatedSigner(_kAccountAddress)],
        ),
        returnsNormally,
      );
    });

    test('testMixedSigners_oversizedExternal_throws', () {
      final delegated = OZDelegatedSigner(_kAccountAddress);
      final oversized = OZExternalSigner(
        _kVerifierContract,
        _keyData(OZConstants.maxExternalKeySize + 1),
      );
      expect(
        () => requireValidSigners(
          <OZSmartAccountSigner>[delegated, oversized],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });
}
