import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';

void main() {
  group('KeyPair', () {
    group('generation', () {
      test('random generates valid keypair', () {
        final keyPair = KeyPair.random();

        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.accountId.startsWith('G'), isTrue);
        expect(keyPair.accountId.length, equals(56));
        expect(keyPair.secretSeed, isNotEmpty);
        expect(keyPair.secretSeed.startsWith('S'), isTrue);
        expect(keyPair.secretSeed.length, equals(56));
        expect(keyPair.canSign(), isTrue);
        expect(keyPair.publicKey.length, equals(32));
        expect(keyPair.privateKey, isNotNull);
      });

      test('random generates unique keypairs', () {
        final keyPair1 = KeyPair.random();
        final keyPair2 = KeyPair.random();

        expect(keyPair1.accountId, isNot(equals(keyPair2.accountId)));
        expect(keyPair1.secretSeed, isNot(equals(keyPair2.secretSeed)));
      });
    });

    group('fromSecretSeed', () {
      test('creates keypair from known seed', () {
        final seed = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
        final keyPair = KeyPair.fromSecretSeed(seed);

        expect(keyPair.accountId, equals('GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D'));
        expect(keyPair.secretSeed, equals(seed));
        expect(keyPair.canSign(), isTrue);
      });

      test('round-trip seed encoding', () {
        final originalSeed = 'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY';
        final keyPair = KeyPair.fromSecretSeed(originalSeed);

        expect(keyPair.secretSeed, equals(originalSeed));
      });

      test('throws on invalid secret seed', () {
        expect(
          () => KeyPair.fromSecretSeed('INVALID_SEED'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws on account ID instead of seed', () {
        expect(
          () => KeyPair.fromSecretSeed('GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromSecretSeedList', () {
      test('creates keypair from raw seed bytes', () {
        final seedBytes = Util.hash(
          Uint8List.fromList(Network.TESTNET.networkPassphrase.codeUnits),
        );
        final keyPair = KeyPair.fromSecretSeedList(seedBytes);

        expect(keyPair.canSign(), isTrue);
        expect(keyPair.publicKey.length, equals(32));
        expect(keyPair.privateKey, isNotNull);
      });
    });

    group('fromAccountId', () {
      test('creates verify-only keypair from account ID', () {
        final accountId = 'GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB';
        final keyPair = KeyPair.fromAccountId(accountId);

        expect(keyPair.accountId, equals(accountId));
        expect(keyPair.canSign(), isFalse);
        expect(keyPair.privateKey, isNull);
      });

      test('creates verify-only keypair from muxed account', () {
        final muxedAccountId = 'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK';
        final keyPair = KeyPair.fromAccountId(muxedAccountId);

        expect(keyPair.accountId, equals('GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ'));
        expect(keyPair.canSign(), isFalse);
      });

      test('throws on invalid account ID', () {
        expect(
          () => KeyPair.fromAccountId('INVALID_ACCOUNT_ID'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromPublicKey', () {
      test('creates keypair from raw public key bytes', () {
        final fullKeyPair = KeyPair.random();
        final publicKeyBytes = fullKeyPair.publicKey;

        final verifyOnlyKeyPair = KeyPair.fromPublicKey(publicKeyBytes);

        expect(verifyOnlyKeyPair.accountId, equals(fullKeyPair.accountId));
        expect(verifyOnlyKeyPair.canSign(), isFalse);
        expect(ListEquality().equals(verifyOnlyKeyPair.publicKey, publicKeyBytes), isTrue);
      });

      test('creates keypair with 32-byte public key', () {
        final publicKey = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          publicKey[i] = i;
        }

        final keyPair = KeyPair.fromPublicKey(publicKey);

        expect(keyPair.canSign(), isFalse);
        expect(ListEquality().equals(keyPair.publicKey, publicKey), isTrue);
      });
    });

    group('signing and verification', () {
      test('sign and verify round-trip', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

        final signature = keyPair.sign(data);

        expect(signature.length, equals(64));
        expect(keyPair.verify(data, signature), isTrue);
      });

      test('sign with one keypair, verify with same keys', () {
        final seed = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
        final keyPair1 = KeyPair.fromSecretSeed(seed);
        final keyPair2 = KeyPair.fromSecretSeed(seed);
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final signature = keyPair1.sign(data);

        expect(keyPair2.verify(data, signature), isTrue);
      });

      test('verify with wrong public key fails', () {
        final keyPair1 = KeyPair.random();
        final keyPair2 = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final signature = keyPair1.sign(data);

        expect(keyPair2.verify(data, signature), isFalse);
      });

      test('verify tampered data fails', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final tamperedData = Uint8List.fromList([1, 2, 3, 4, 6]);

        final signature = keyPair.sign(data);

        expect(keyPair.verify(tamperedData, signature), isFalse);
      });

      test('sign transaction hash (32 bytes)', () {
        final keyPair = KeyPair.random();
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }

        final signature = keyPair.sign(hash);

        expect(signature.length, equals(64));
        expect(keyPair.verify(hash, signature), isTrue);
      });

      test('multiple signatures with same keypair are deterministic', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final signature1 = keyPair.sign(data);
        final signature2 = keyPair.sign(data);

        expect(ListEquality().equals(signature1, signature2), isTrue);
      });

      test('sign empty data', () {
        final keyPair = KeyPair.random();
        final data = Uint8List(0);

        final signature = keyPair.sign(data);

        expect(signature.length, equals(64));
        expect(keyPair.verify(data, signature), isTrue);
      });

      test('sign large data', () {
        final keyPair = KeyPair.random();
        final data = Uint8List(1024);
        for (int i = 0; i < 1024; i++) {
          data[i] = i % 256;
        }

        final signature = keyPair.sign(data);

        expect(signature.length, equals(64));
        expect(keyPair.verify(data, signature), isTrue);
      });

      test('sign without private key throws exception', () {
        final keyPair = KeyPair.fromAccountId('GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB');
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        expect(
          () => keyPair.sign(data),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('decorated signature', () {
      test('signDecorated creates decorated signature', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final decoratedSig = keyPair.signDecorated(data);

        expect(decoratedSig.signature.signature.length, equals(64));
        expect(decoratedSig.hint.signatureHint.length, equals(4));
        expect(keyPair.verify(data, decoratedSig.signature.signature), isTrue);
      });

      test('signDecorated hint matches last 4 bytes of public key', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);

        final decoratedSig = keyPair.signDecorated(data);
        final xdrOutputStream = XdrDataOutputStream();
        XdrPublicKey.encode(xdrOutputStream, keyPair.xdrPublicKey);
        final publicKeyBytes = Uint8List.fromList(xdrOutputStream.bytes);
        final expectedHint = Uint8List.fromList(
          publicKeyBytes.getRange(publicKeyBytes.length - 4, publicKeyBytes.length).toList(),
        );

        expect(
          ListEquality().equals(decoratedSig.hint.signatureHint, expectedHint),
          isTrue,
        );
      });

      test('signPayloadDecorated creates correct signature', () {
        final seed = "1123740522f11bfef6b3671f51e159ccf589ccf8965262dd5f97d1721d383dd4";
        final keyPair = KeyPair.fromSecretSeedList(Uint8List.fromList(Util.hexToBytes(seed)));
        final payload = Uint8List.fromList([1, 2, 3, 4, 5]);

        final decoratedSig = keyPair.signPayloadDecorated(payload);

        expect(
          ListEquality().equals(
            decoratedSig.hint.signatureHint,
            Uint8List.fromList([0xFF & 252, 65, 0, 50]),
          ),
          isTrue,
        );
      });
    });

    group('canSign', () {
      test('returns true for full keypair', () {
        final keyPair = KeyPair.random();

        expect(keyPair.canSign(), isTrue);
      });

      test('returns true for keypair from secret seed', () {
        final keyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');

        expect(keyPair.canSign(), isTrue);
      });

      test('returns false for verify-only keypair from account ID', () {
        final keyPair = KeyPair.fromAccountId('GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB');

        expect(keyPair.canSign(), isFalse);
      });

      test('returns false for verify-only keypair from public key', () {
        final publicKey = Uint8List(32);
        final keyPair = KeyPair.fromPublicKey(publicKey);

        expect(keyPair.canSign(), isFalse);
      });
    });

    group('account ID extraction', () {
      test('account ID format starts with G', () {
        final keyPair = KeyPair.random();

        expect(keyPair.accountId.startsWith('G'), isTrue);
      });

      test('account ID has correct length', () {
        final keyPair = KeyPair.random();

        expect(keyPair.accountId.length, equals(56));
      });

      test('account ID is valid', () {
        final keyPair = KeyPair.random();

        expect(StrKey.isValidStellarAccountId(keyPair.accountId), isTrue);
      });
    });

    group('secret seed extraction', () {
      test('secret seed format starts with S', () {
        final keyPair = KeyPair.random();

        expect(keyPair.secretSeed.startsWith('S'), isTrue);
      });

      test('secret seed has correct length', () {
        final keyPair = KeyPair.random();

        expect(keyPair.secretSeed.length, equals(56));
      });

      test('secret seed is valid', () {
        final keyPair = KeyPair.random();

        expect(StrKey.isValidStellarSecretSeed(keyPair.secretSeed), isTrue);
      });

      test('secret seed throws for verify-only keypair', () {
        final keyPair = KeyPair.fromAccountId('GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB');

        expect(() => keyPair.secretSeed, throwsA(anything));
      });
    });

    group('XDR conversions', () {
      test('toXdrPublicKey round-trip', () {
        final keyPair = KeyPair.random();

        final xdrPublicKey = keyPair.xdrPublicKey;
        final restoredKeyPair = KeyPair.fromXdrPublicKey(xdrPublicKey);

        expect(restoredKeyPair.accountId, equals(keyPair.accountId));
        expect(
          ListEquality().equals(restoredKeyPair.publicKey, keyPair.publicKey),
          isTrue,
        );
      });

      test('xdrPublicKey has correct type', () {
        final keyPair = KeyPair.random();

        final xdrPublicKey = keyPair.xdrPublicKey;

        expect(xdrPublicKey.getDiscriminant(), equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        expect(
          ListEquality().equals(xdrPublicKey.getEd25519()!.uint256, keyPair.publicKey),
          isTrue,
        );
      });

      test('xdrMuxedAccount has correct type', () {
        final keyPair = KeyPair.random();

        final xdrMuxedAccount = keyPair.xdrMuxedAccount;

        expect(xdrMuxedAccount.discriminant, equals(XdrCryptoKeyType.KEY_TYPE_ED25519));
        expect(
          ListEquality().equals(xdrMuxedAccount.ed25519!.uint256, keyPair.publicKey),
          isTrue,
        );
      });

      test('fromXdrAccountId creates keypair', () {
        final keyPair = KeyPair.random();
        final xdrAccountId = XdrAccountID(keyPair.xdrPublicKey);

        final restoredKeyPair = KeyPair.fromXdrAccountId(xdrAccountId);

        expect(restoredKeyPair.accountId, equals(keyPair.accountId));
        expect(restoredKeyPair.canSign(), isFalse);
      });

      test('fromXdrSignerKey creates keypair', () {
        final keyPair = KeyPair.random();
        final xdrSignerKey = keyPair.xdrSignerKey;

        final restoredKeyPair = KeyPair.fromXdrSignerKey(xdrSignerKey);

        expect(restoredKeyPair.accountId, equals(keyPair.accountId));
        expect(restoredKeyPair.canSign(), isFalse);
      });

      test('xdrSignerKey has correct type', () {
        final keyPair = KeyPair.random();

        final xdrSignerKey = keyPair.xdrSignerKey;

        expect(xdrSignerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519));
        expect(
          ListEquality().equals(xdrSignerKey.ed25519!.uint256, keyPair.publicKey),
          isTrue,
        );
      });
    });

    group('signature hint', () {
      test('signatureHint is 4 bytes', () {
        final keyPair = KeyPair.random();

        final hint = keyPair.signatureHint;

        expect(hint.signatureHint.length, equals(4));
      });

      test('signatureHint matches last 4 bytes of encoded public key', () {
        final keyPair = KeyPair.random();

        final hint = keyPair.signatureHint;
        final xdrOutputStream = XdrDataOutputStream();
        XdrPublicKey.encode(xdrOutputStream, keyPair.xdrPublicKey);
        final publicKeyBytes = Uint8List.fromList(xdrOutputStream.bytes);
        final expectedHint = Uint8List.fromList(
          publicKeyBytes.getRange(publicKeyBytes.length - 4, publicKeyBytes.length).toList(),
        );

        expect(
          ListEquality().equals(hint.signatureHint, expectedHint),
          isTrue,
        );
      });
    });

    group('properties', () {
      test('publicKey getter returns correct bytes', () {
        final keyPair = KeyPair.random();

        expect(keyPair.publicKey.length, equals(32));
      });

      test('privateKey getter returns correct bytes for full keypair', () {
        final keyPair = KeyPair.random();

        expect(keyPair.privateKey, isNotNull);
        expect(keyPair.privateKey!.length, equals(64));
      });

      test('privateKey getter returns null for verify-only keypair', () {
        final keyPair = KeyPair.fromAccountId('GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB');

        expect(keyPair.privateKey, isNull);
      });
    });

    group('edge cases', () {
      test('verify with invalid signature length', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final invalidSignature = Uint8List(32); // Wrong length

        expect(keyPair.verify(data, invalidSignature), isFalse);
      });

      test('verify with empty signature', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final emptySignature = Uint8List(0);

        expect(keyPair.verify(data, emptySignature), isFalse);
      });

      test('verify with corrupted signature', () {
        final keyPair = KeyPair.random();
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final originalSignature = keyPair.sign(data);

        // Create a corrupted copy of the signature
        final corruptedSignature = Uint8List.fromList(originalSignature);
        corruptedSignature[0] = corruptedSignature[0] ^ 0xFF;

        expect(keyPair.verify(data, corruptedSignature), isFalse);
      });
    });

    group('SEP-53 message signing', () {
      final specSeed = 'SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW';
      final specAddress = 'GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L';
      final asciiSigHex =
          '7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd'
          '6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04';
      final japaneseSigHex =
          '083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980'
          'e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604';
      final binarySigHex =
          '540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff'
          '8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d';
      final binaryMessageBase64 = '2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=';

      // Spec vector tests

      test('sign ASCII message matches spec vector', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        final signature = keyPair.signMessage(message);

        expect(Util.bytesToHex(signature), equals(asciiSigHex));
      });

      test('verify ASCII message with spec signature', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        final result = keyPair.verifyMessage(message, Util.hexToBytes(asciiSigHex));

        expect(result, isTrue);
      });

      test('sign Japanese message matches spec vector', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('こんにちは、世界！'));

        final signature = keyPair.signMessage(message);

        expect(Util.bytesToHex(signature), equals(japaneseSigHex));
      });

      test('verify Japanese message with spec signature', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('こんにちは、世界！'));

        final result = keyPair.verifyMessage(message, Util.hexToBytes(japaneseSigHex));

        expect(result, isTrue);
      });

      test('sign binary message matches spec vector', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = base64.decode(binaryMessageBase64);

        final signature = keyPair.signMessage(message);

        expect(Util.bytesToHex(signature), equals(binarySigHex));
      });

      test('verify binary message with spec signature', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = base64.decode(binaryMessageBase64);

        final result = keyPair.verifyMessage(message, Util.hexToBytes(binarySigHex));

        expect(result, isTrue);
      });

      // String convenience method tests

      test('signMessageString matches signMessage for ASCII', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final stringSig = keyPair.signMessageString('Hello, World!');
        final binarySig = keyPair.signMessage(Uint8List.fromList(utf8.encode('Hello, World!')));

        expect(ListEquality().equals(stringSig, binarySig), isTrue);
      });

      test('verifyMessageString returns true for valid ASCII signature', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);

        final result = keyPair.verifyMessageString('Hello, World!', Util.hexToBytes(asciiSigHex));

        expect(result, isTrue);
      });

      test('verifyMessageString with Japanese message', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);

        final result = keyPair.verifyMessageString(
            'こんにちは、世界！', Util.hexToBytes(japaneseSigHex));

        expect(result, isTrue);
      });

      // Round-trip and cross-path tests

      test('round-trip with random keypair', () {
        final keyPair = KeyPair.random();
        final message = Uint8List.fromList(utf8.encode('test message for round-trip'));

        final signature = keyPair.signMessage(message);
        final result = keyPair.verifyMessage(message, signature);

        expect(result, isTrue);
      });

      test('cross-construction-path: sign with seed, verify with account ID', () {
        final signingKeyPair = KeyPair.fromSecretSeed(specSeed);
        final verifyKeyPair = KeyPair.fromAccountId(specAddress);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        final signature = signingKeyPair.signMessage(message);
        final result = verifyKeyPair.verifyMessage(message, signature);

        expect(result, isTrue);
      });

      // Failure tests

      test('wrong message fails verification', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        final signature = keyPair.signMessage(message);
        final wrongMessage = Uint8List.fromList(utf8.encode('Goodbye, World!'));

        expect(keyPair.verifyMessage(wrongMessage, signature), isFalse);
      });

      test('wrong signature fails verification', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        // Use the binary test vector's signature instead of the ASCII one
        expect(keyPair.verifyMessage(message, Util.hexToBytes(binarySigHex)), isFalse);
      });

      test('wrong keypair fails verification', () {
        final keyPairA = KeyPair.random();
        final keyPairB = KeyPair.random();
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        final signature = keyPairA.signMessage(message);

        expect(keyPairB.verifyMessage(message, signature), isFalse);
      });

      test('truncated signature fails verification', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));
        final truncatedSig = Uint8List(32); // 32 bytes instead of 64

        expect(keyPair.verifyMessage(message, truncatedSig), isFalse);
      });

      test('signMessage without private key throws exception', () {
        final publicOnlyKeyPair = KeyPair.fromAccountId(specAddress);
        final message = Uint8List.fromList(utf8.encode('Hello, World!'));

        expect(
          () => publicOnlyKeyPair.signMessage(message),
          throwsA(isA<Exception>()),
        );
      });

      test('signMessageString without private key throws exception', () {
        final publicOnlyKeyPair = KeyPair.fromAccountId(specAddress);

        expect(
          () => publicOnlyKeyPair.signMessageString('Hello, World!'),
          throwsA(isA<Exception>()),
        );
      });

      // Edge case tests

      test('empty byte array sign and verify round-trip', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final emptyMessage = Uint8List(0);

        final signature = keyPair.signMessage(emptyMessage);
        final result = keyPair.verifyMessage(emptyMessage, signature);

        expect(result, isTrue);
      });

      test('empty string sign and verify round-trip', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);

        final signature = keyPair.signMessageString('');
        final result = keyPair.verifyMessageString('', signature);

        expect(result, isTrue);
      });

      // Signature encoding round-trip tests

      test('sign and verify via base64 encoded signature', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final signature = keyPair.signMessageString('Hello, World!');

        // Encode signature to base64 (as a sender would transmit it)
        final base64Signature = base64.encode(signature);
        expect(base64Signature,
            equals('fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA=='));

        // Decode from base64 and verify (as a receiver would consume it)
        final decoded = base64.decode(base64Signature);
        expect(keyPair.verifyMessageString('Hello, World!', decoded), isTrue);
      });

      test('sign and verify via hex encoded signature', () {
        final keyPair = KeyPair.fromSecretSeed(specSeed);
        final signature = keyPair.signMessageString('Hello, World!');

        // Encode signature to hex (as a sender would transmit it)
        final hexSignature = Util.bytesToHex(signature);
        expect(hexSignature, equals(asciiSigHex));

        // Decode from hex and verify (as a receiver would consume it)
        final decoded = Util.hexToBytes(hexSignature);
        expect(keyPair.verifyMessageString('Hello, World!', decoded), isTrue);
      });

      test('verify spec vector from base64 encoded signature', () {
        final verifier = KeyPair.fromAccountId(specAddress);
        final base64Sig =
            'CDU265Xs8y3OWbB/56H9jPgUss5G9A0qFuTqH2zs2YDgTm+++dIfmAEceFqB7bhfN3am59lCtDXrCtwH2k1GBA==';

        final signature = base64.decode(base64Sig);
        expect(verifier.verifyMessageString('こんにちは、世界！', signature), isTrue);
      });

      test('verify spec vector from hex encoded signature', () {
        final verifier = KeyPair.fromAccountId(specAddress);

        final signature = Util.hexToBytes(binarySigHex);
        final message = base64.decode(binaryMessageBase64);
        expect(verifier.verifyMessage(message, signature), isTrue);
      });
    });
  });

  group('KeyPair Deep Branch Testing', () {
    test('KeyPair.fromSecretSeed with valid seed', () {
      KeyPair original = KeyPair.random();
      String secretSeed = original.secretSeed;

      KeyPair restored = KeyPair.fromSecretSeed(secretSeed);

      expect(restored.accountId, equals(original.accountId));
      expect(restored.secretSeed, equals(secretSeed));
      expect(restored.canSign(), isTrue);
    });

    test('KeyPair.fromAccountId with standard account', () {
      KeyPair original = KeyPair.random();
      String accountId = original.accountId;

      KeyPair publicOnly = KeyPair.fromAccountId(accountId);

      expect(publicOnly.accountId, equals(accountId));
      expect(publicOnly.canSign(), isFalse);
    });

    test('KeyPair.fromAccountId with muxed account M address', () {
      KeyPair original = KeyPair.random();
      MuxedAccount muxed = MuxedAccount(original.accountId, BigInt.from(123));
      String muxedAccountId = muxed.accountId;

      KeyPair fromMuxed = KeyPair.fromAccountId(muxedAccountId);

      expect(fromMuxed.accountId, equals(original.accountId));
      expect(fromMuxed.canSign(), isFalse);
    });

    test('KeyPair.fromPublicKey creates verification-only keypair', () {
      KeyPair original = KeyPair.random();
      Uint8List publicKey = original.publicKey;

      KeyPair publicOnly = KeyPair.fromPublicKey(publicKey);

      expect(publicOnly.accountId, equals(original.accountId));
      expect(publicOnly.canSign(), isFalse);
    });

    test('KeyPair sign and verify', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      Uint8List signature = keyPair.sign(data);

      expect(signature.length, equals(64));
      expect(keyPair.verify(data, signature), isTrue);
    });

    test('KeyPair sign throws when no private key', () {
      KeyPair publicOnly = KeyPair.fromAccountId("GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H");
      Uint8List data = Uint8List.fromList([1, 2, 3, 4]);

      expect(() => publicOnly.sign(data), throwsException);
    });

    test('KeyPair verify with wrong signature', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List data = Uint8List.fromList([1, 2, 3, 4]);
      Uint8List wrongSignature = Uint8List(64);

      expect(keyPair.verify(data, wrongSignature), isFalse);
    });

    test('KeyPair signDecorated', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      XdrDecoratedSignature decorated = keyPair.signDecorated(data);

      expect(decorated.signature.signature.length, equals(64));
      expect(decorated.hint.signatureHint.length, equals(4));
    });

    test('KeyPair signPayloadDecorated', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List payload = Uint8List.fromList([10, 20, 30, 40, 50]);

      XdrDecoratedSignature decorated = keyPair.signPayloadDecorated(payload);

      expect(decorated.signature.signature.length, equals(64));
      expect(decorated.hint.signatureHint.length, equals(4));
    });

    test('KeyPair xdrPublicKey', () {
      KeyPair keyPair = KeyPair.random();

      XdrPublicKey xdrPubKey = keyPair.xdrPublicKey;

      expect(xdrPubKey.getDiscriminant(), equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      expect(xdrPubKey.getEd25519(), isNotNull);
    });

    test('KeyPair xdrSignerKey', () {
      KeyPair keyPair = KeyPair.random();

      XdrSignerKey xdrSignerKey = keyPair.xdrSignerKey;

      expect(xdrSignerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519));
      expect(xdrSignerKey.ed25519, isNotNull);
    });

    test('KeyPair xdrMuxedAccount', () {
      KeyPair keyPair = KeyPair.random();

      XdrMuxedAccount xdrMuxed = keyPair.xdrMuxedAccount;

      expect(xdrMuxed.discriminant, equals(XdrCryptoKeyType.KEY_TYPE_ED25519));
      expect(xdrMuxed.ed25519, isNotNull);
    });

    test('KeyPair signatureHint', () {
      KeyPair keyPair = KeyPair.random();

      XdrSignatureHint hint = keyPair.signatureHint;

      expect(hint.signatureHint.length, equals(4));
    });

    test('KeyPair.fromXdrPublicKey', () {
      KeyPair original = KeyPair.random();
      XdrPublicKey xdrPubKey = original.xdrPublicKey;

      KeyPair restored = KeyPair.fromXdrPublicKey(xdrPubKey);

      expect(restored.accountId, equals(original.accountId));
      expect(restored.canSign(), isFalse);
    });

    test('KeyPair.fromXdrAccountId', () {
      KeyPair original = KeyPair.random();
      XdrAccountID xdrAccountId = XdrAccountID(original.xdrPublicKey);

      KeyPair restored = KeyPair.fromXdrAccountId(xdrAccountId);

      expect(restored.accountId, equals(original.accountId));
      expect(restored.canSign(), isFalse);
    });

    test('KeyPair.fromXdrSignerKey', () {
      KeyPair original = KeyPair.random();
      XdrSignerKey xdrSignerKey = original.xdrSignerKey;

      KeyPair restored = KeyPair.fromXdrSignerKey(xdrSignerKey);

      expect(restored.accountId, equals(original.accountId));
      expect(restored.canSign(), isFalse);
    });

    test('SignedPayloadSigner.fromAccountId', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List payload = Uint8List.fromList([1, 2, 3, 4]);

      SignedPayloadSigner signer = SignedPayloadSigner.fromAccountId(
        keyPair.accountId,
        payload
      );

      expect(signer.payload, equals(payload));
      expect(signer.signerAccountID, isNotNull);
    });

    test('SignedPayloadSigner.fromPublicKey', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List payload = Uint8List.fromList([5, 6, 7, 8]);

      SignedPayloadSigner signer = SignedPayloadSigner.fromPublicKey(
        keyPair.publicKey,
        payload
      );

      expect(signer.payload, equals(payload));
      expect(signer.signerAccountID, isNotNull);
    });

    test('SignedPayloadSigner throws on payload too long', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List longPayload = Uint8List(65);

      expect(
        () => SignedPayloadSigner.fromAccountId(keyPair.accountId, longPayload),
        throwsException
      );
    });

    test('SignerKey.ed25519PublicKey', () {
      KeyPair keyPair = KeyPair.random();

      XdrSignerKey signerKey = SignerKey.ed25519PublicKey(keyPair);

      expect(signerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519));
      expect(signerKey.ed25519, isNotNull);
    });

    test('SignerKey.sha256Hash', () {
      Uint8List hash = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        hash[i] = i;
      }

      XdrSignerKey signerKey = SignerKey.sha256Hash(hash);

      expect(signerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X));
      expect(signerKey.hashX, isNotNull);
    });

    test('SignerKey.preAuthTx', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      Transaction tx = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .build();

      XdrSignerKey signerKey = SignerKey.preAuthTx(tx, Network.TESTNET);

      expect(signerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX));
      expect(signerKey.preAuthTx, isNotNull);
    });

    test('SignerKey.preAuthTxHash', () {
      Uint8List hash = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        hash[i] = i + 10;
      }

      XdrSignerKey signerKey = SignerKey.preAuthTxHash(hash);

      expect(signerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX));
      expect(signerKey.preAuthTx, isNotNull);
    });

    test('SignerKey.signedPayload', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List payload = Uint8List.fromList([10, 20, 30]);

      SignedPayloadSigner payloadSigner = SignedPayloadSigner.fromAccountId(
        keyPair.accountId,
        payload
      );

      XdrSignerKey signerKey = SignerKey.signedPayload(payloadSigner);

      expect(signerKey.discriminant, equals(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD));
      expect(signerKey.signedPayload, isNotNull);
    });

    test('StrKey.encodeSignedPayload and decodeSignedPayload', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List payload = Uint8List.fromList([11, 22, 33, 44]);

      SignedPayloadSigner original = SignedPayloadSigner.fromAccountId(
        keyPair.accountId,
        payload
      );

      String encoded = StrKey.encodeSignedPayload(original);
      SignedPayloadSigner decoded = StrKey.decodeSignedPayload(encoded);

      expect(decoded.payload, equals(payload));
      expect(encoded.startsWith('P'), isTrue);
    });

    test('StrKey.isValidSignedPayload', () {
      KeyPair keyPair = KeyPair.random();
      Uint8List payload = Uint8List.fromList([1, 2, 3]);

      SignedPayloadSigner signer = SignedPayloadSigner.fromAccountId(
        keyPair.accountId,
        payload
      );

      String encoded = StrKey.encodeSignedPayload(signer);

      expect(StrKey.isValidSignedPayload(encoded), isTrue);
      expect(StrKey.isValidSignedPayload("INVALID"), isFalse);
    });

    test('VersionByte constants', () {
      expect(VersionByte.ACCOUNT_ID, isNotNull);
      expect(VersionByte.MUXED_ACCOUNT_ID, isNotNull);
      expect(VersionByte.SEED, isNotNull);
      expect(VersionByte.PRE_AUTH_TX, isNotNull);
      expect(VersionByte.SHA256_HASH, isNotNull);
      expect(VersionByte.SIGNED_PAYLOAD, isNotNull);
      expect(VersionByte.CONTRACT_ID, isNotNull);
      expect(VersionByte.LIQUIDITY_POOL, isNotNull);
      expect(VersionByte.CLAIMABLE_BALANCE, isNotNull);

      VersionByte vb = VersionByte.ACCOUNT_ID;
      expect(vb.toString(), contains('VersionByte'));
    });

    test('KeyPair.fromSecretSeedList', () {
      KeyPair original = KeyPair.random();
      Uint8List seed = StrKey.decodeStellarSecretSeed(original.secretSeed);

      KeyPair restored = KeyPair.fromSecretSeedList(seed);

      expect(restored.accountId, equals(original.accountId));
      expect(restored.canSign(), isTrue);
    });
  });
}
