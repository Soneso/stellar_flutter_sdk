@Timeout(const Duration(seconds: 300))

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Test vector constants from SEP-53 specification
  final String seed =
      "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW";
  final String expectedAccountId =
      "GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L";

  test('sep-53: Quick example - sign and verify', () {
    // Snippet from sep-53.md "Quick example"
    KeyPair keyPair = KeyPair.random();

    // Sign a message
    Uint8List signature =
        keyPair.signMessageString("I agree to the terms of service");

    // Verify the signature
    bool isValid = keyPair.verifyMessageString(
        "I agree to the terms of service", signature);

    expect(isValid, true);
  });

  test('sep-53: Signing messages with base64 and hex encoding', () {
    // Snippet from sep-53.md "Signing messages"
    KeyPair keyPair = KeyPair.fromSecretSeed(seed);

    String message = "User consent granted at 2025-01-15T12:00:00Z";
    Uint8List signature = keyPair.signMessageString(message);

    // Encode as base64 for transmission
    String base64Signature = base64.encode(signature);
    expect(base64Signature.isNotEmpty, true);

    // Or encode as hex
    String hexSignature = Util.bytesToHex(signature);
    expect(hexSignature.length, 128); // 64 bytes = 128 hex chars
  });

  test('sep-53: Verifying messages with public key only', () {
    // Snippet from sep-53.md "Verifying messages"
    KeyPair signer = KeyPair.fromSecretSeed(seed);
    String message = "User consent granted at 2025-01-15T12:00:00Z";
    Uint8List signature = signer.signMessageString(message);
    String base64Signature = base64.encode(signature);

    // Create keypair from public key only (no private key needed)
    KeyPair publicKey = KeyPair.fromAccountId(signer.accountId);
    Uint8List decodedSignature = base64.decode(base64Signature);
    bool isValid = publicKey.verifyMessageString(message, decodedSignature);

    expect(isValid, true);
  });

  test('sep-53: Verifying hex-encoded signatures', () {
    // Snippet from sep-53.md "Verifying hex-encoded signatures"
    KeyPair signer = KeyPair.fromSecretSeed(seed);
    String message = "Cross-platform message";
    Uint8List signature = signer.signMessageString(message);
    String hexSignature = Util.bytesToHex(signature);

    KeyPair publicKey = KeyPair.fromAccountId(signer.accountId);
    Uint8List decodedSignature = Util.hexToBytes(hexSignature);
    bool isValid = publicKey.verifyMessageString(message, decodedSignature);

    expect(isValid, true);
  });

  test('sep-53: Signing binary data', () {
    // Snippet from sep-53.md "Signing binary data"
    KeyPair keyPair = KeyPair.fromSecretSeed(seed);

    // Sign binary data
    Uint8List fileContents = Uint8List.fromList([0x00, 0x01, 0x02, 0xFF]);
    Uint8List signature = keyPair.signMessage(fileContents);

    expect(signature.length, 64);

    String base64Signature = base64.encode(signature);
    expect(base64Signature.isNotEmpty, true);

    // Verify binary data signature
    bool isValid = keyPair.verifyMessage(fileContents, signature);
    expect(isValid, true);
  });

  test('sep-53: Authentication flow', () {
    // Snippet from sep-53.md "Authentication flow example"

    // === SERVER: Generate a challenge ===
    String challenge =
        "authenticate:${Util.bytesToHex(Uint8List.fromList(List.generate(16, (_) => Random.secure().nextInt(256))))}:${DateTime.now().millisecondsSinceEpoch ~/ 1000}";

    // === CLIENT: Sign the challenge ===
    KeyPair clientKeyPair = KeyPair.fromSecretSeed(seed);
    Uint8List signature = clientKeyPair.signMessageString(challenge);

    Map<String, String> response = {
      'account_id': clientKeyPair.accountId,
      'signature': base64.encode(signature),
      'challenge': challenge,
    };

    // === SERVER: Verify the response ===
    KeyPair publicKey = KeyPair.fromAccountId(response['account_id']!);
    Uint8List decodedSignature = base64.decode(response['signature']!);

    bool isAuthenticated = publicKey.verifyMessageString(
        response['challenge']!, decodedSignature);

    expect(isAuthenticated, true);
    expect(response['account_id'], expectedAccountId);
  });

  test('sep-53: Error handling - signing without private key', () {
    // Snippet from sep-53.md "Signing without a private key"
    KeyPair publicKeyOnly = KeyPair.fromAccountId(expectedAccountId);

    expect(() => publicKeyOnly.signMessageString("test"), throwsException);
  });

  test('sep-53: canSign check', () {
    // Snippet from sep-53.md "Checking before signing"
    KeyPair keyPair = KeyPair.fromSecretSeed(seed);
    expect(keyPair.canSign(), true);

    KeyPair publicOnly = KeyPair.fromAccountId(expectedAccountId);
    expect(publicOnly.canSign(), false);
  });

  test('sep-53: Verification never throws on invalid signature', () {
    // Snippet from sep-53.md "Common verification failures"
    KeyPair publicKey = KeyPair.fromAccountId(expectedAccountId);

    // Verification returns false, does not throw
    bool result = publicKey.verifyMessageString("Hello", Uint8List(64));
    expect(result, false);
  });

  test('sep-53: Test vector - ASCII message', () {
    // Snippet from sep-53.md "ASCII message"
    String message = "Hello, World!";

    KeyPair keyPair = KeyPair.fromSecretSeed(seed);
    expect(keyPair.accountId, expectedAccountId);

    Uint8List signature = keyPair.signMessageString(message);
    String base64Signature = base64.encode(signature);
    String hexSignature = Util.bytesToHex(signature);

    String expectedBase64 =
        "fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA==";
    String expectedHex =
        "7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04";

    expect(base64Signature, expectedBase64);
    expect(hexSignature, expectedHex);

    // Verify the signature
    bool isValid = keyPair.verifyMessageString(message, signature);
    expect(isValid, true);
  });

  test('sep-53: Test vector - Japanese (UTF-8) message', () {
    // Snippet from sep-53.md "Japanese (UTF-8) message"
    String message = "\u3053\u3093\u306b\u3061\u306f\u3001\u4e16\u754c\uff01";

    KeyPair keyPair = KeyPair.fromSecretSeed(seed);
    Uint8List signature = keyPair.signMessageString(message);

    String expectedBase64 =
        "CDU265Xs8y3OWbB/56H9jPgUss5G9A0qFuTqH2zs2YDgTm+++dIfmAEceFqB7bhfN3am59lCtDXrCtwH2k1GBA==";
    String expectedHex =
        "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604";

    expect(base64.encode(signature), expectedBase64);
    expect(Util.bytesToHex(signature), expectedHex);

    // Verify the signature
    bool isValid = keyPair.verifyMessageString(message, signature);
    expect(isValid, true);
  });

  test('sep-53: Test vector - Binary data message', () {
    // Snippet from sep-53.md "Binary data message"

    // Binary data (base64-decoded)
    Uint8List message =
        base64.decode("2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=");

    KeyPair keyPair = KeyPair.fromSecretSeed(seed);
    Uint8List signature = keyPair.signMessage(message);

    String expectedBase64 =
        "VA1+7hefNwv2NKScH6n+Sljj15kLAge+M2wE7fzFOf+L0MMbssA1mwfJZRyyrhBORQRle10X1Dxpx+UOI4EbDQ==";
    String expectedHex =
        "540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d";

    expect(base64.encode(signature), expectedBase64);
    expect(Util.bytesToHex(signature), expectedHex);

    // Verify the signature
    bool isValid = keyPair.verifyMessage(message, signature);
    expect(isValid, true);
  });

  test('sep-53: Cross-SDK verification', () {
    // Snippet from sep-53.md "Cross-SDK compatibility"
    // Verify a known signature produced by any SEP-53 compliant SDK
    KeyPair publicKey = KeyPair.fromAccountId(expectedAccountId);

    String base64Signature =
        "fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA==";
    Uint8List signature = base64.decode(base64Signature);

    bool isValid = publicKey.verifyMessageString("Hello, World!", signature);
    expect(isValid, true);
  });

  test('sep-53: Wrong message fails verification', () {
    KeyPair keyPair = KeyPair.fromSecretSeed(seed);
    Uint8List signature = keyPair.signMessageString("Original message");

    // Verification with a different message should fail
    bool isValid = keyPair.verifyMessageString("Tampered message", signature);
    expect(isValid, false);
  });

  test('sep-53: Wrong key fails verification', () {
    KeyPair signer = KeyPair.fromSecretSeed(seed);
    Uint8List signature = signer.signMessageString("Hello, World!");

    // Verification with a different public key should fail
    KeyPair otherKey = KeyPair.random();
    bool isValid =
        otherKey.verifyMessageString("Hello, World!", signature);
    expect(isValid, false);
  });
}
