import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Helper function to generate valid contract ID
  String generateValidContractId() {
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = (i * 7 + 3) % 256; // Deterministic test data
    }
    return StrKey.encodeContractId(bytes);
  }

  group('PasskeyUtils - getPublicKey', () {
    test('extract public key from attestation response with publicKey field', () {
      // Uncompressed secp256r1 public key (0x04 + 32 bytes X + 32 bytes Y)
      final publicKeyBytes = Uint8List.fromList([
        0x04,
        ...List.filled(32, 0xAA), // X coordinate
        ...List.filled(32, 0xBB), // Y coordinate
      ]);
      final publicKeyBase64 = base64Url.encode(publicKeyBytes);

      final response = AuthenticatorAttestationResponse(
        publicKey: publicKeyBase64,
      );

      final extractedKey = PasskeyUtils.getPublicKey(response);

      expect(extractedKey, isNotNull);
      expect(extractedKey!.length, equals(65));
      expect(extractedKey[0], equals(0x04));
    });

    test('extract public key from authenticatorData', () {
      // Create authenticator data with embedded public key
      // Format: 37 bytes (RP ID hash) + 1 byte (flags) + 4 bytes (sign count) +
      //         16 bytes (AAGUID) + 2 bytes (credentialIdLength) + credentialId + COSE key
      final rpIdHash = Uint8List(32);
      final flags = Uint8List.fromList([0x45]); // UP, UV, AT flags
      final signCount = Uint8List.fromList([0, 0, 0, 1]);
      final aaguid = Uint8List(16);

      final credentialIdLength = 16;
      final credentialIdLengthBytes = Uint8List.fromList([
        (credentialIdLength >> 8) & 0xFF,
        credentialIdLength & 0xFF,
      ]);
      final credentialId = Uint8List(credentialIdLength);

      // COSE key structure (simplified)
      // Starting at offset 55 (37 + 1 + 4 + 16 - 3) relative to credential end
      final xCoord = Uint8List.fromList(List.filled(32, 0xCC));
      final yCoord = Uint8List.fromList(List.filled(32, 0xDD));
      final coseKey = Uint8List.fromList([
        ...Uint8List(10), // Padding/COSE structure bytes
        ...xCoord,
        ...Uint8List(3), // Separator bytes
        ...yCoord,
      ]);

      final authData = Uint8List.fromList([
        ...rpIdHash,
        ...flags,
        ...signCount,
        ...aaguid,
        ...credentialIdLengthBytes,
        ...credentialId,
        ...coseKey,
      ]);

      final authDataBase64 = base64Url.encode(authData);

      final response = AuthenticatorAttestationResponse(
        authenticatorData: authDataBase64,
      );

      final extractedKey = PasskeyUtils.getPublicKey(response);

      expect(extractedKey, isNotNull);
      expect(extractedKey!.length, equals(65));
      expect(extractedKey[0], equals(0x04));
    });

    test('extract public key from attestationObject', () {
      // Create attestation object with COSE key
      final publicKeyPrefix = Uint8List.fromList([
        0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
      ]);
      final xCoord = Uint8List.fromList(List.filled(32, 0xEE));
      final separator = Uint8List.fromList([0x22, 0x58, 0x20]);
      final yCoord = Uint8List.fromList(List.filled(32, 0xFF));

      final attestationObject = Uint8List.fromList([
        ...Uint8List(10), // Prefix bytes
        ...publicKeyPrefix,
        ...xCoord,
        ...separator,
        ...yCoord,
        ...Uint8List(5), // Suffix bytes
      ]);

      final attestationObjectBase64 = base64Url.encode(attestationObject);

      final response = AuthenticatorAttestationResponse(
        attestationObject: attestationObjectBase64,
      );

      final extractedKey = PasskeyUtils.getPublicKey(response);

      expect(extractedKey, isNotNull);
      expect(extractedKey!.length, equals(65));
      expect(extractedKey[0], equals(0x04));
    });

    test('returns null when public key cannot be extracted', () {
      final response = AuthenticatorAttestationResponse();

      final extractedKey = PasskeyUtils.getPublicKey(response);

      expect(extractedKey, isNull);
    });

    test('returns invalid public key when format is wrong but provided', () {
      // Invalid: not starting with 0x04 or wrong length
      // Implementation will return the invalid key if no other sources available
      final invalidKey = Uint8List.fromList(List.filled(64, 0xAA));
      final response = AuthenticatorAttestationResponse(
        publicKey: base64Url.encode(invalidKey),
      );

      final extractedKey = PasskeyUtils.getPublicKey(response);

      // Returns the invalid key since no fallback sources are available
      expect(extractedKey, isNotNull);
      expect(extractedKey!.length, equals(64));
    });
  });

  group('PasskeyUtils - getContractSalt', () {
    test('generate contract salt from credentials ID', () {
      final credentialsId = base64Url.encode(Uint8List.fromList(List.filled(32, 0x12)));

      final salt = PasskeyUtils.getContractSalt(credentialsId);

      expect(salt, isNotNull);
      expect(salt.length, equals(32));
    });

    test('same credentials ID produces same salt', () {
      final credentialsId = base64Url.encode(Uint8List.fromList(List.filled(16, 0xAB)));

      final salt1 = PasskeyUtils.getContractSalt(credentialsId);
      final salt2 = PasskeyUtils.getContractSalt(credentialsId);

      expect(salt1, equals(salt2));
    });

    test('different credentials IDs produce different salts', () {
      final credentialsId1 = base64Url.encode(Uint8List.fromList(List.filled(16, 0x11)));
      final credentialsId2 = base64Url.encode(Uint8List.fromList(List.filled(16, 0x22)));

      final salt1 = PasskeyUtils.getContractSalt(credentialsId1);
      final salt2 = PasskeyUtils.getContractSalt(credentialsId2);

      expect(salt1, isNot(equals(salt2)));
    });
  });

  group('PasskeyUtils - deriveContractId', () {
    test('derive contract ID from salt and factory', () {
      final credentialsId = base64Url.encode(Uint8List.fromList(List.filled(32, 0x42)));
      final salt = PasskeyUtils.getContractSalt(credentialsId);
      final factoryId = generateValidContractId();

      final contractId = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factoryId,
        network: Network.TESTNET,
      );

      expect(contractId, isNotNull);
      expect(contractId, isA<String>());
      expect(contractId.length, greaterThan(0));
    });

    test('same inputs produce same contract ID', () {
      final credentialsId = base64Url.encode(Uint8List.fromList(List.filled(32, 0x99)));
      final salt = PasskeyUtils.getContractSalt(credentialsId);
      final factoryId = generateValidContractId();

      final contractId1 = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factoryId,
        network: Network.TESTNET,
      );
      final contractId2 = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factoryId,
        network: Network.TESTNET,
      );

      expect(contractId1, equals(contractId2));
    });

    test('different networks produce different contract IDs', () {
      final credentialsId = base64Url.encode(Uint8List.fromList(List.filled(32, 0x55)));
      final salt = PasskeyUtils.getContractSalt(credentialsId);
      final factoryId = generateValidContractId();

      final testnetId = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factoryId,
        network: Network.TESTNET,
      );
      final publicId = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factoryId,
        network: Network.PUBLIC,
      );

      expect(testnetId, isNot(equals(publicId)));
    });

    test('different factory IDs produce different contract IDs', () {
      final credentialsId = base64Url.encode(Uint8List.fromList(List.filled(32, 0x77)));
      final salt = PasskeyUtils.getContractSalt(credentialsId);

      // Generate two different valid contract IDs
      final factory1Bytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        factory1Bytes[i] = (i * 5 + 1) % 256;
      }
      final factory1 = StrKey.encodeContractId(factory1Bytes);

      final factory2Bytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        factory2Bytes[i] = (i * 11 + 7) % 256;
      }
      final factory2 = StrKey.encodeContractId(factory2Bytes);

      final contractId1 = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factory1,
        network: Network.TESTNET,
      );
      final contractId2 = PasskeyUtils.deriveContractId(
        contractSalt: salt,
        factoryContractId: factory2,
        network: Network.TESTNET,
      );

      expect(contractId1, isNot(equals(contractId2)));
    });
  });

  group('PasskeyUtils - compactSignature', () {
    test('convert DER signature to compact format', () {
      // Create a simple DER signature
      // DER format: 0x30 [total-length] 0x02 [r-length] [r-bytes] 0x02 [s-length] [s-bytes]
      final r = Uint8List.fromList(List.filled(32, 0x11));
      final s = Uint8List.fromList(List.filled(32, 0x22));

      final derSignature = Uint8List.fromList([
        0x30, // SEQUENCE tag
        0x44, // Total length (2 + 32 + 2 + 32)
        0x02, // INTEGER tag for r
        0x20, // Length of r (32 bytes)
        ...r,
        0x02, // INTEGER tag for s
        0x20, // Length of s (32 bytes)
        ...s,
      ]);

      final compactSig = PasskeyUtils.compactSignature(derSignature);

      expect(compactSig, isNotNull);
      expect(compactSig.length, equals(64));
    });

    test('ensure s value is in low-S form', () {
      // Create DER signature with high-s value
      final r = Uint8List.fromList(List.filled(32, 0x33));
      // High-s value (greater than n/2)
      final highS = Uint8List.fromList([
        0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84,
        0xF3, 0xB9, 0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x50,
      ]);

      final derSignature = Uint8List.fromList([
        0x30, // SEQUENCE tag
        0x44, // Total length
        0x02, // INTEGER tag for r
        0x20, // Length of r
        ...r,
        0x02, // INTEGER tag for s
        0x20, // Length of s
        ...highS,
      ]);

      final compactSig = PasskeyUtils.compactSignature(derSignature);

      expect(compactSig.length, equals(64));

      // Verify s is normalized (converted from high-s to low-s)
      final sBytes = compactSig.sublist(32);
      final sBigInt = BigInt.parse('0x${Util.bytesToHex(sBytes)}');
      final n = BigInt.parse('0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551');
      final halfN = n ~/ BigInt.from(2);

      expect(sBigInt <= halfN, isTrue);
    });

    test('compact signature with padded r and s values', () {
      // r and s with leading zeros (need padding to 32 bytes)
      final r = Uint8List.fromList([
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
        0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
        0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
        0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00,
      ]);
      final s = Uint8List.fromList([
        0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99,
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11,
        0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99,
        0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11,
      ]);

      final derSignature = Uint8List.fromList([
        0x30,
        0x44,
        0x02,
        0x20,
        ...r,
        0x02,
        0x20,
        ...s,
      ]);

      final compactSig = PasskeyUtils.compactSignature(derSignature);

      expect(compactSig.length, equals(64));
      // Verify each component is exactly 32 bytes
      final rCompact = compactSig.sublist(0, 32);
      final sCompact = compactSig.sublist(32, 64);
      expect(rCompact.length, equals(32));
      expect(sCompact.length, equals(32));
    });

    test('handles DER signature with varying lengths', () {
      // DER with 33-byte r (includes leading 0x00 for positive number)
      final r = Uint8List.fromList([
        0x00, // Padding byte
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
      ]);
      final s = Uint8List.fromList(List.filled(32, 0x44));

      final derSignature = Uint8List.fromList([
        0x30,
        0x45, // Total length (2 + 33 + 2 + 32)
        0x02,
        0x21, // r length is 33
        ...r,
        0x02,
        0x20,
        ...s,
      ]);

      final compactSig = PasskeyUtils.compactSignature(derSignature);

      expect(compactSig.length, equals(64));
    });
  });

  group('AuthenticatorAttestationResponse', () {
    test('create response with all fields', () {
      final response = AuthenticatorAttestationResponse(
        clientDataJSON: 'eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIn0',
        authenticatorData: 'dGVzdF9hdXRoX2RhdGE',
        attestationObject: 'dGVzdF9hdHRlc3RhdGlvbg',
        transports: ['usb', 'nfc'],
        publicKey: 'dGVzdF9wdWJsaWNfa2V5',
      );

      expect(response.clientDataJSON, isNotNull);
      expect(response.authenticatorData, isNotNull);
      expect(response.attestationObject, isNotNull);
      expect(response.transports!.length, equals(2));
      expect(response.publicKey, isNotNull);
    });

    test('create response with minimal fields', () {
      final response = AuthenticatorAttestationResponse();

      expect(response.clientDataJSON, isNull);
      expect(response.authenticatorData, isNull);
      expect(response.attestationObject, isNull);
      expect(response.transports, isNull);
      expect(response.publicKey, isNull);
    });

    test('construct from JSON', () {
      final json = {
        'clientDataJSON': 'eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIn0',
        'authenticatorData': 'dGVzdF9hdXRoX2RhdGE',
        'attestationObject': 'dGVzdF9hdHRlc3RhdGlvbg',
        'transports': ['usb', 'ble'],
        'publicKey': 'dGVzdF9wdWJsaWNfa2V5',
      };

      final response = AuthenticatorAttestationResponse.fromJson(json);

      expect(response.clientDataJSON, equals(json['clientDataJSON']));
      expect(response.authenticatorData, equals(json['authenticatorData']));
      expect(response.attestationObject, equals(json['attestationObject']));
      expect(response.transports, equals(json['transports']));
      expect(response.publicKey, equals(json['publicKey']));
    });

    test('convert to JSON', () {
      final response = AuthenticatorAttestationResponse(
        clientDataJSON: 'client_data',
        authenticatorData: 'auth_data',
        attestationObject: 'attestation',
        transports: ['internal'],
        publicKey: 'public_key',
      );

      final json = response.toJson();

      expect(json['clientDataJSON'], equals('client_data'));
      expect(json['authenticatorData'], equals('auth_data'));
      expect(json['attestationObject'], equals('attestation'));
      expect(json['transports'], equals(['internal']));
      expect(json['publicKey'], equals('public_key'));
    });

    test('JSON round-trip', () {
      final original = AuthenticatorAttestationResponse(
        clientDataJSON: 'test_client',
        authenticatorData: 'test_auth',
        attestationObject: 'test_attestation',
        transports: ['usb', 'nfc', 'ble'],
        publicKey: 'test_key',
      );

      final json = original.toJson();
      final restored = AuthenticatorAttestationResponse.fromJson(json);

      expect(restored.clientDataJSON, equals(original.clientDataJSON));
      expect(restored.authenticatorData, equals(original.authenticatorData));
      expect(restored.attestationObject, equals(original.attestationObject));
      expect(restored.transports, equals(original.transports));
      expect(restored.publicKey, equals(original.publicKey));
    });
  });

  group('IndexOfElements extension', () {
    test('find subsequence at beginning', () {
      final list = [1, 2, 3, 4, 5];
      final subsequence = [1, 2, 3];

      final index = list.indexOfElements(subsequence);

      expect(index, equals(0));
    });

    test('find subsequence in middle', () {
      final list = [1, 2, 3, 4, 5, 6];
      final subsequence = [3, 4, 5];

      final index = list.indexOfElements(subsequence);

      expect(index, equals(2));
    });

    test('find subsequence at end', () {
      final list = [1, 2, 3, 4, 5];
      final subsequence = [4, 5];

      final index = list.indexOfElements(subsequence);

      expect(index, equals(3));
    });

    test('return -1 when subsequence not found', () {
      final list = [1, 2, 3, 4, 5];
      final subsequence = [6, 7];

      final index = list.indexOfElements(subsequence);

      expect(index, equals(-1));
    });

    test('return start index for empty subsequence', () {
      final list = [1, 2, 3];
      final subsequence = <int>[];

      final index = list.indexOfElements(subsequence);

      expect(index, equals(0));
    });

    test('find with custom start position', () {
      final list = [1, 2, 3, 2, 3, 4];
      final subsequence = [2, 3];

      final index = list.indexOfElements(subsequence, 2);

      expect(index, equals(3));
    });

    test('return -1 when start position beyond list', () {
      final list = [1, 2, 3];
      final subsequence = [2];

      final index = list.indexOfElements(subsequence, 10);

      expect(index, equals(-1));
    });

    test('find single element', () {
      final list = [10, 20, 30, 40];
      final subsequence = [30];

      final index = list.indexOfElements(subsequence);

      expect(index, equals(2));
    });

    test('find Uint8List subsequence', () {
      final list = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE]);
      final subsequence = Uint8List.fromList([0xCC, 0xDD]);

      final index = list.indexOfElements(subsequence);

      expect(index, equals(2));
    });
  });
}
