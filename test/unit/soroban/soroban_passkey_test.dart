import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// secp256r1 generator point G coordinates (FIPS 186-4 / SEC 2).
// These are on the curve by definition and are used as valid test inputs.
final _gxBytes = Uint8List.fromList([
  0x6b, 0x17, 0xd1, 0xf2, 0xe1, 0x2c, 0x42, 0x47,
  0xf8, 0xbc, 0xe6, 0xe5, 0x63, 0xa4, 0x40, 0xf2,
  0x77, 0x03, 0x7d, 0x81, 0x2d, 0xeb, 0x33, 0xa0,
  0xf4, 0xa1, 0x39, 0x45, 0xd8, 0x98, 0xc2, 0x96,
]);
final _gyBytes = Uint8List.fromList([
  0x4f, 0xe3, 0x42, 0xe2, 0xfe, 0x1a, 0x7f, 0x9b,
  0x8e, 0xe7, 0xeb, 0x4a, 0x7c, 0x0f, 0x9e, 0x16,
  0x2b, 0xce, 0x33, 0x57, 0x6b, 0x31, 0x5e, 0xce,
  0xcb, 0xb6, 0x40, 0x68, 0x37, 0xbf, 0x51, 0xf5,
]);

// 65-byte uncompressed secp256r1 generator point G (0x04 || Gx || Gy).
Uint8List _generatorPubkey() {
  final out = Uint8List(65);
  out[0] = 0x04;
  out.setRange(1, 33, _gxBytes);
  out.setRange(33, 65, _gyBytes);
  return out;
}

// Builds a COSE ES256 key blob for use in authenticatorData or attestationObject.
// Layout: [0xA5,0x01,0x02,0x03,0x26,0x20,0x01,0x21,0x58,0x20] || x(32) || [0x22,0x58,0x20] || y(32)
Uint8List _buildCoseKey(Uint8List x, Uint8List y) {
  return Uint8List.fromList([
    0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
    ...x,
    0x22, 0x58, 0x20,
    ...y,
  ]);
}

// Builds a minimal authenticatorData blob with the AT flag set and an embedded
// COSE ES256 key. Credential ID length defaults to 16 bytes of zeros.
Uint8List _buildAuthData({
  required Uint8List x,
  required Uint8List y,
  int credentialIdLength = 16,
}) {
  final coseKey = _buildCoseKey(x, y);
  return Uint8List.fromList([
    ...List<int>.filled(32, 0xAA), // rpIdHash (32 bytes)
    0x45, // flags: UP | UV | AT
    0x00, 0x00, 0x00, 0x01, // signCount
    ...List<int>.filled(16, 0x00), // aaguid
    (credentialIdLength >> 8) & 0xFF,
    credentialIdLength & 0xFF, // credentialIdLength (big-endian)
    ...List<int>.filled(credentialIdLength, 0x00), // credentialId
    ...coseKey,
  ]);
}

// Builds a synthetic attestation object blob that contains the COSE ES256 key
// after a short garbage prefix.
Uint8List _buildAttestationObject({required Uint8List x, required Uint8List y}) {
  final coseKey = _buildCoseKey(x, y);
  return Uint8List.fromList([
    0x99, 0x88, // garbage prefix
    ...coseKey,
    0x00, 0x00, 0x00, 0x00, 0x00, // suffix
  ]);
}

// Helper function to generate valid contract ID
String generateValidContractId() {
  final bytes = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    bytes[i] = (i * 7 + 3) % 256; // Deterministic test data
  }
  return StrKey.encodeContractId(bytes);
}

// Encodes (r, s) as a DER SEQUENCE for use with compactSignature tests.
// The encoder prepends 0x00 when the high bit of a component is set (positive
// integer convention), exactly as real authenticators produce.
Uint8List _encodeDerSignature(Uint8List r, Uint8List s) {
  Uint8List derInt(Uint8List raw) {
    // Strip leading zeros, keeping at least one byte.
    var stripped = raw;
    while (stripped.length > 1 && stripped[0] == 0x00) {
      stripped = stripped.sublist(1);
    }
    // Prepend 0x00 if high bit set (positive integer).
    if (stripped[0] & 0x80 != 0) {
      final out = Uint8List(stripped.length + 1);
      out.setRange(1, out.length, stripped);
      return out;
    }
    return stripped;
  }

  final rb = derInt(r);
  final sb = derInt(s);
  final body = <int>[
    0x02, rb.length, ...rb,
    0x02, sb.length, ...sb,
  ];
  return Uint8List.fromList([0x30, body.length, ...body]);
}

void main() {
  group('PasskeyUtils - getPublicKey', () {
    test('extract public key from attestation response with publicKey field', () {
      // secp256r1 generator point G in uncompressed SEC1 form (0x04 || Gx || Gy).
      // On-curve by definition; real authenticators produce keys in this format.
      final publicKeyBytes = _generatorPubkey();
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
      // Builds authenticatorData with the COSE ES256 key for generator point G.
      // The structure follows the WebAuthn spec: rpIdHash || flags || signCount ||
      // aaguid || credentialIdLen || credentialId || COSE key.
      final authData = _buildAuthData(x: _gxBytes, y: _gyBytes);
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
      // Synthetic attestation object with COSE ES256 key using generator point G.
      final attestationObject = _buildAttestationObject(
        x: _gxBytes,
        y: _gyBytes,
      );
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

    test('returns null when publicKey field is malformed', () {
      // 64-byte blob without the 0x04 prefix is not a valid uncompressed key.
      // The rigorous validator rejects it; getPublicKey returns null.
      final invalidKey = Uint8List.fromList(List.filled(64, 0xAA));
      final response = AuthenticatorAttestationResponse(
        publicKey: base64Url.encode(invalidKey),
      );

      final extractedKey = PasskeyUtils.getPublicKey(response);

      // Off-curve / malformed input: extraction fails, returns null.
      expect(extractedKey, isNull);
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
      // r and s well below the secp256r1 curve order (n starts with 0xFF...).
      // Values 0x11×32 and 0x22×32 are tiny compared to n — no low-S flip needed.
      final r = Uint8List.fromList(List.filled(32, 0x11));
      final s = Uint8List.fromList(List.filled(32, 0x22));

      final compactSig = PasskeyUtils.compactSignature(_encodeDerSignature(r, s));

      expect(compactSig, isNotNull);
      expect(compactSig.length, equals(64));
    });

    test('ensure s value is in low-S form', () {
      // r = 0x33×32, within curve order.
      // highS = n - 1, which is the largest valid s and triggers low-S normalisation.
      final r = Uint8List.fromList(List.filled(32, 0x33));
      // n - 1 (secp256r1 curve order minus one): triggers the s > n/2 branch.
      final highS = Uint8List.fromList([
        0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84,
        0xF3, 0xB9, 0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x50,
      ]);

      final compactSig = PasskeyUtils.compactSignature(_encodeDerSignature(r, highS));

      expect(compactSig.length, equals(64));

      // Verify s is normalised to low-S form.
      final sBytes = compactSig.sublist(32);
      final sBigInt = BigInt.parse('0x${Util.bytesToHex(sBytes)}');
      final n = BigInt.parse('0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551');
      final halfN = n ~/ BigInt.from(2);

      expect(sBigInt <= halfN, isTrue);
    });

    test('compact signature with padded r and s values', () {
      // r has its leading byte at 0x00 in the 32-byte representation (the effective
      // value starts at the second byte). DER encodes this without the leading zero.
      // s is a fully populated 32-byte value well below the curve order.
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

      final compactSig = PasskeyUtils.compactSignature(_encodeDerSignature(r, s));

      expect(compactSig.length, equals(64));
      // Verify each component is exactly 32 bytes
      final rCompact = compactSig.sublist(0, 32);
      final sCompact = compactSig.sublist(32, 64);
      expect(rCompact.length, equals(32));
      expect(sCompact.length, equals(32));
    });

    test('handles DER signature with varying lengths', () {
      // r has the high bit set (0x80 prefix), so DER encoding prepends a 0x00
      // byte, producing a 33-byte r component in the DER blob. The normaliser
      // must strip that padding and produce a 32-byte compact output.
      // 0x80... values are well below the curve order (n starts with 0xFF...),
      // so this is a valid secp256r1 r value.
      final r = Uint8List.fromList([
        0x80, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
        0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
        0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
        0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
      ]);
      // s is small and well within the curve order — no low-S flip.
      final s = Uint8List.fromList(List.filled(32, 0x44));

      final compactSig = PasskeyUtils.compactSignature(_encodeDerSignature(r, s));

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
