import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
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
  });
}
