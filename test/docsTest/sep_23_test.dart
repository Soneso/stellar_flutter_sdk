@Timeout(const Duration(seconds: 300))

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('sep-23: Quick example - keypair, validate, encode/decode', () {
    // Snippet from sep-23.md "Quick example"
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId; // G...

    expect(accountId, startsWith('G'));
    expect(StrKey.isValidStellarAccountId(accountId), true);

    Uint8List rawPublicKey = StrKey.decodeStellarAccountId(accountId);
    expect(rawPublicKey.length, 32);

    String encoded = StrKey.encodeStellarAccountId(rawPublicKey);
    expect(encoded, accountId);
  });

  test('sep-23: Account IDs and secret seeds', () {
    // Snippet from sep-23.md "Account IDs and secret seeds"
    // Use a runtime-generated keypair to ensure valid seed
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;
    String secretSeed = keyPair.secretSeed;

    // Validate
    expect(StrKey.isValidStellarAccountId(accountId), true);
    expect(StrKey.isValidStellarSecretSeed(secretSeed), true);

    // Decode to raw 32-byte keys
    Uint8List rawPublicKey = StrKey.decodeStellarAccountId(accountId);
    Uint8List rawPrivateKey = StrKey.decodeStellarSecretSeed(secretSeed);
    expect(rawPublicKey.length, 32);
    expect(rawPrivateKey.length, 32);

    // Encode raw bytes back to string
    String encoded = StrKey.encodeStellarAccountId(rawPublicKey);
    String encodedSeed = StrKey.encodeStellarSecretSeed(rawPrivateKey);
    expect(encoded, accountId);
    expect(encodedSeed, secretSeed);

    // Derive account ID from seed
    String derivedAccountId = KeyPair.fromSecretSeed(secretSeed).accountId;
    expect(derivedAccountId, accountId);
  });

  test('sep-23: Creating muxed accounts', () {
    // Snippet from sep-23.md "Creating muxed accounts"
    // Use the underlying G-address of the known M-address
    String accountId =
        'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';
    int userId = 1234567890;

    MuxedAccount muxedAccount = MuxedAccount(accountId, BigInt.from(userId));
    String muxedAccountId = muxedAccount.accountId; // M...

    expect(muxedAccountId, startsWith('M'));
    expect(muxedAccount.ed25519AccountId, accountId);
    expect(muxedAccount.id, BigInt.from(userId));

    // Parse an existing M-address
    MuxedAccount? parsedMuxed = MuxedAccount.fromAccountId(
      'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ',
    );
    expect(parsedMuxed, isNotNull);
    expect(parsedMuxed!.accountId, startsWith('M'));
  });

  test('sep-23: Extracting muxed account components', () {
    // Snippet from sep-23.md "Extracting muxed account components"
    String muxedAccountId =
        'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';

    MuxedAccount? muxedAccount = MuxedAccount.fromAccountId(muxedAccountId);
    expect(muxedAccount, isNotNull);

    // Get the underlying G-address
    String ed25519AccountId = muxedAccount!.ed25519AccountId;
    expect(ed25519AccountId, startsWith('G'));

    // Get the 64-bit ID
    BigInt? id = muxedAccount.id;
    expect(id, isNotNull);

    // Get the M-address
    String accountId = muxedAccount.accountId;
    expect(accountId, startsWith('M'));
  });

  test('sep-23: Low-level muxed account encoding', () {
    // Snippet from sep-23.md "Low-level muxed account encoding"
    String muxedAccountId =
        'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';

    // Validate M-address format
    expect(StrKey.isValidStellarMuxedAccountId(muxedAccountId), true);

    // Decode to raw binary
    Uint8List rawData = StrKey.decodeStellarMuxedAccountId(muxedAccountId);
    expect(rawData.length, 40); // 8-byte ID + 32-byte public key

    // Encode raw binary back to M-address
    String encoded = StrKey.encodeStellarMuxedAccountId(rawData);
    expect(encoded, muxedAccountId);
  });

  test('sep-23: Pre-auth TX and SHA-256 hashes', () {
    // Snippet from sep-23.md "Pre-auth TX and SHA-256 hashes"
    var random = Random.secure();

    // Pre-auth TX (T...)
    Uint8List transactionHash = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    String preAuthTx = StrKey.encodePreAuthTx(transactionHash);
    expect(preAuthTx, startsWith('T'));
    expect(StrKey.isValidPreAuthTx(preAuthTx), true);
    Uint8List decoded = StrKey.decodePreAuthTx(preAuthTx);
    expect(decoded, transactionHash);

    // SHA-256 hash signer (X...)
    Uint8List hash = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    String hashSigner = StrKey.encodeSha256Hash(hash);
    expect(hashSigner, startsWith('X'));
    expect(StrKey.isValidSha256Hash(hashSigner), true);
    Uint8List decodedHash = StrKey.decodeSha256Hash(hashSigner);
    expect(decodedHash, hash);
  });

  test('sep-23: Contract IDs', () {
    // Snippet from sep-23.md "Contract IDs (C...)"
    // Generate a valid contract ID from a known public key
    KeyPair kp = KeyPair.random();
    String contractId = StrKey.encodeContractId(kp.publicKey);

    // Validate
    expect(StrKey.isValidContractId(contractId), true);

    // Decode to raw bytes or hex
    Uint8List raw = StrKey.decodeContractId(contractId);
    expect(raw.length, 32);
    String hex = StrKey.decodeContractIdHex(contractId);
    expect(hex.length, 64);

    // Encode from raw bytes or hex
    String encoded = StrKey.encodeContractId(raw);
    expect(encoded, contractId);
    String encodedFromHex = StrKey.encodeContractIdHex(hex);
    expect(encodedFromHex, contractId);
  });

  test('sep-23: Signed payloads', () {
    // Snippet from sep-23.md "Signed payloads (P...)"
    KeyPair keyPair = KeyPair.random();
    Uint8List payload = Uint8List(32);

    SignedPayloadSigner signer = SignedPayloadSigner.fromAccountId(
      keyPair.accountId,
      payload,
    );
    String signedPayload = StrKey.encodeSignedPayload(signer);
    expect(signedPayload, startsWith('P'));
    expect(StrKey.isValidSignedPayload(signedPayload), true);

    SignedPayloadSigner decoded = StrKey.decodeSignedPayload(signedPayload);
    String signerAccountId = KeyPair.fromXdrPublicKey(
      decoded.signerAccountID.accountID,
    ).accountId;
    expect(signerAccountId, keyPair.accountId);
  });

  test('sep-23: Signed payload length bound on construction', () {
    // Snippet from sep-23.md "Signed payloads (P...)"
    KeyPair keyPair = KeyPair.random();

    try {
      SignedPayloadSigner.fromAccountId(keyPair.accountId, Uint8List(0));
      fail('an empty payload has no strkey rendering');
    } on Exception catch (e) {
      expect(
        e.toString(),
        'Exception: invalid payload length, must be at least 1',
      );
    }
  });

  test('sep-23: Liquidity pool and claimable balance IDs', () {
    // Snippet from sep-23.md "Liquidity pool and claimable balance IDs"

    // Liquidity pool ID (L...)
    String poolHex =
        'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
    String poolId = StrKey.encodeLiquidityPoolIdHex(poolHex);
    expect(poolId, startsWith('L'));
    expect(StrKey.isValidLiquidityPoolId(poolId), true);
    Uint8List decodedPool = StrKey.decodeLiquidityPoolId(poolId);
    expect(decodedPool.length, 32);

    // Claimable balance ID (B...), from the bare 32-byte hash. The 33-byte tagged
    // form and the 36-byte XDR form Horizon reports encode the same way.
    String balanceHex =
        '3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a';
    String balanceId = StrKey.encodeClaimableBalanceIdHex(balanceHex);
    expect(balanceId, startsWith('B'));
    expect(StrKey.isValidClaimableBalanceId(balanceId), true);
    Uint8List decodedBalance = StrKey.decodeClaimableBalanceId(balanceId);
    // A one-byte discriminant followed by the 32-byte hash.
    expect(decodedBalance.length, 33);
  });

  test('sep-23: Claimable balance encoding rejects a bad discriminant', () {
    // Snippet from sep-23.md "Liquidity pool and claimable balance IDs"
    Uint8List tagged = Uint8List(33);
    tagged[0] = 1; // names no claimable balance ID type

    try {
      StrKey.encodeClaimableBalanceId(tagged);
      fail('a discriminant of 1 names no claimable balance id type');
    } on Exception catch (e) {
      expect(
        e.toString(),
        'Exception: claimable balance id carries the discriminant 1, '
        'which names no claimable balance id type',
      );
    }
  });

  test('sep-23: Error handling', () {
    // Snippet from sep-23.md "Error handling"
    try {
      Uint8List raw = StrKey.decodeStellarAccountId('GINVALIDADDRESS');
      fail('decoded ${raw.length} bytes from a 15 character string');
    } on FormatException catch (e) {
      expect(e.message, 'Encoded string must be 56 characters, got 15');
    }
  });

  test('sep-23: Error handling - classifying with the isValid methods', () {
    // Snippet from sep-23.md "Error handling"
    String input =
        'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';

    expect(StrKey.isValidStellarAccountId(input), false);
    expect(StrKey.isValidStellarMuxedAccountId(input), true);

    MuxedAccount muxed = MuxedAccount.fromAccountId(input)!;
    expect(
      muxed.ed25519AccountId,
      'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
    );

    // fromAccountId returns null for a string starting with neither G nor M.
    expect(MuxedAccount.fromAccountId('user-provided-address'), isNull);
  });

  test('sep-23: StrKey validation methods', () {
    // Test all isValid* methods with known valid values
    KeyPair kp = KeyPair.random();

    expect(StrKey.isValidStellarAccountId(kp.accountId), true);
    expect(StrKey.isValidStellarSecretSeed(kp.secretSeed), true);

    // Invalid inputs
    expect(StrKey.isValidStellarAccountId('INVALID'), false);
    expect(StrKey.isValidStellarSecretSeed('INVALID'), false);
    expect(StrKey.isValidStellarMuxedAccountId('INVALID'), false);
    expect(StrKey.isValidPreAuthTx('INVALID'), false);
    expect(StrKey.isValidSha256Hash('INVALID'), false);
    expect(StrKey.isValidContractId('INVALID'), false);
    expect(StrKey.isValidSignedPayload('INVALID'), false);
    expect(StrKey.isValidLiquidityPoolId('INVALID'), false);
    expect(StrKey.isValidClaimableBalanceId('INVALID'), false);
  });
}
