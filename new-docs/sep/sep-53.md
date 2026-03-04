# SEP-53: Sign and Verify Messages

Prove ownership of a Stellar private key by signing arbitrary messages.

## Overview

> **Note:** SEP-53 is currently in Draft status (v0.0.1). The specification may evolve before reaching final status.

SEP-53 defines how to sign and verify messages with Stellar keypairs. Use it when you need to:

- Authenticate users by proving key ownership
- Sign attestations or consent agreements
- Verify signatures from other Stellar SDKs
- Create provable off-chain statements

The protocol adds a prefix (`"Stellar Signed Message:\n"`) before hashing, which prevents signed messages from being confused with transaction signatures.

## Quick example

Sign a message and verify the signature:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate a random keypair (or use KeyPair.fromSecretSeed() for an existing key)
KeyPair keyPair = KeyPair.random();

// Sign a message
Uint8List signature = keyPair.signMessageString("I agree to the terms of service");

// Verify the signature
bool isValid = keyPair.verifyMessageString("I agree to the terms of service", signature);
print(isValid ? "Valid" : "Invalid");
```

## Detailed usage

### Signing messages

Sign a message and encode the signature for transmission. The raw signature is 64 bytes, so you'll typically encode it as base64 or hex:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

KeyPair keyPair = KeyPair.fromSecretSeed("SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");

String message = "User consent granted at 2025-01-15T12:00:00Z";
Uint8List signature = keyPair.signMessageString(message);

// Encode as base64 for transmission
String base64Signature = base64.encode(signature);
print("Signature: $base64Signature");

// Or encode as hex
String hexSignature = Util.bytesToHex(signature);
print("Signature (hex): $hexSignature");
```

### Verifying messages

Verify a signature using only the public key. This is typically done server-side after receiving a signed message from a client:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

// Create keypair from public key only (no private key needed for verification)
KeyPair publicKey = KeyPair.fromAccountId("GABC...");

String message = "User consent granted at 2025-01-15T12:00:00Z";
String base64Signature = "..."; // Received from client

Uint8List signature = base64.decode(base64Signature);
bool isValid = publicKey.verifyMessageString(message, signature);

if (isValid) {
  print("Signature verified");
} else {
  print("Invalid signature");
}
```

### Verifying hex-encoded signatures

If the signature was transmitted as a hex string, decode it with `Util.hexToBytes()` before verification:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair publicKey = KeyPair.fromAccountId("GABC...");

String message = "Cross-platform message";
String hexSignature = "a1b2c3d4..."; // Received as hex
Uint8List signature = Util.hexToBytes(hexSignature);

bool isValid = publicKey.verifyMessageString(message, signature);
```

### Signing binary data

The message doesn't have to be text. You can sign any binary data such as file contents:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:io';

KeyPair keyPair = KeyPair.fromSecretSeed("SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");

// Sign file contents
Uint8List fileContents = File("document.pdf").readAsBytesSync();
Uint8List signature = keyPair.signMessage(fileContents);

String base64Signature = base64.encode(signature);
print("Document signature: $base64Signature");
```

### Authentication flow example

A complete authentication flow where the server generates a challenge and the client proves key ownership:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:math';

// === SERVER: Generate a challenge ===
String challenge = "authenticate:${Util.bytesToHex(Uint8List.fromList(List.generate(16, (_) => Random.secure().nextInt(256))))}:${DateTime.now().millisecondsSinceEpoch ~/ 1000}";

// === CLIENT: Sign the challenge ===
KeyPair clientKeyPair = KeyPair.fromSecretSeed("SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
Uint8List signature = clientKeyPair.signMessageString(challenge);

Map<String, String> response = {
  'account_id': clientKeyPair.accountId,
  'signature': base64.encode(signature),
  'challenge': challenge,
};

// === SERVER: Verify the response ===
KeyPair publicKey = KeyPair.fromAccountId(response['account_id']!);
Uint8List decodedSignature = base64.decode(response['signature']!);

if (publicKey.verifyMessageString(response['challenge']!, decodedSignature)) {
  print("User authenticated as ${response['account_id']}");
} else {
  print("Authentication failed");
}
```

## Error handling

### Signing without a private key

Attempting to sign with a public-key-only keypair throws an `Exception`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// This keypair has no private key
KeyPair publicKeyOnly = KeyPair.fromAccountId("GABC...");

try {
  // Throws Exception - no private key available
  Uint8List signature = publicKeyOnly.signMessageString("test");
} catch (e) {
  print("Cannot sign: keypair has no private key");
}
```

### Checking before signing

Use `canSign()` to check whether a keypair has a private key before attempting to sign:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.fromSecretSeed("SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");

if (keyPair.canSign()) {
  Uint8List signature = keyPair.signMessageString("Important message");
  String base64Signature = base64.encode(signature);
} else {
  print("Signing not possible - no private key");
}
```

### Common verification failures

When verification fails, several causes are possible:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

KeyPair publicKey = KeyPair.fromAccountId("GABC...");
Uint8List signature = base64.decode(receivedSignature);

if (!publicKey.verifyMessageString(message, signature)) {
  // Possible causes:
  // 1. Message was modified after signing
  // 2. Signature was modified or corrupted in transit
  // 3. Wrong public key used for verification
  // 4. Signature was created for a different message
  print("Invalid signature");
}

// Verification never throws - it returns false on failure
bool result = publicKey.verifyMessageString("Hello", Uint8List(64)); // false, not an exception
```

## Protocol details

SEP-53 signing works like this:

```
signature = Ed25519Sign(privateKey, SHA256("Stellar Signed Message:\n" + message))
```

Verification reverses it:

```
valid = Ed25519Verify(publicKey, SHA256("Stellar Signed Message:\n" + message), signature)
```

The `"Stellar Signed Message:\n"` prefix provides domain separation. A signed message can never be confused with a Stellar transaction signature.

## Test vectors

Use these official test vectors from the SEP-53 specification to validate your implementation:

### ASCII message

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

String seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW";
String expectedAccountId = "GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L";
String message = "Hello, World!";

KeyPair keyPair = KeyPair.fromSecretSeed(seed);
assert(keyPair.accountId == expectedAccountId);

Uint8List signature = keyPair.signMessageString(message);
String base64Signature = base64.encode(signature);
String hexSignature = Util.bytesToHex(signature);

// Expected signatures:
String expectedBase64 = "fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA==";
String expectedHex = "7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04";

assert(base64Signature == expectedBase64);
assert(hexSignature == expectedHex);

print("ASCII test vector passed");
```

### Japanese (UTF-8) message

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

String seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW";
String message = "こんにちは、世界！";

KeyPair keyPair = KeyPair.fromSecretSeed(seed);
Uint8List signature = keyPair.signMessageString(message);

String expectedBase64 = "CDU265Xs8y3OWbB/56H9jPgUss5G9A0qFuTqH2zs2YDgTm+++dIfmAEceFqB7bhfN3am59lCtDXrCtwH2k1GBA==";
String expectedHex = "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604";

assert(base64.encode(signature) == expectedBase64);
assert(Util.bytesToHex(signature) == expectedHex);

print("Japanese test vector passed");
```

### Binary data message

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

String seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW";

// Binary data (base64-decoded)
Uint8List message = base64.decode("2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=");

KeyPair keyPair = KeyPair.fromSecretSeed(seed);
Uint8List signature = keyPair.signMessage(message);

String expectedBase64 = "VA1+7hefNwv2NKScH6n+Sljj15kLAge+M2wE7fzFOf+L0MMbssA1mwfJZRyyrhBORQRle10X1Dxpx+UOI4EbDQ==";
String expectedHex = "540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d";

assert(base64.encode(signature) == expectedBase64);
assert(Util.bytesToHex(signature) == expectedHex);

print("Binary test vector passed");
```

## Security notes

### Display messages before signing

Always show users the full message before signing. Never auto-sign without user review. This prevents phishing where users sign malicious content.

### Key ownership vs account control

A valid signature proves the signer has the private key. It doesn't prove they control the account:

- **Multi-sig accounts**: One signature doesn't mean transaction authority
- **Revoked signers**: A key may have been removed from the account
- **Weight thresholds**: The key may lack sufficient weight

For critical operations, check the account's current state on-chain.

### Signature encoding

SEP-53 doesn't specify an encoding format. Common choices:

| Encoding | Pros | Cons |
|----------|------|------|
| Base64 | Compact, URL-safe variant available | Needs decode |
| Hex | Human-readable, simple | 2x larger |

Pick one and document it. The raw signature is always 64 bytes.

## Cross-SDK compatibility

SEP-53 signatures work across all Stellar SDKs. A signature created in Java, Python, or PHP can be verified in Flutter, and vice versa.

**Compatible SDKs:** Java, Python, PHP, JavaScript, Kotlin (KMP), and this Flutter SDK.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

// Signature from Java/Python/PHP SDK
String base64Signature = "...";
String message = "Cross-platform message";

KeyPair publicKey = KeyPair.fromAccountId("GABC...");
Uint8List signature = base64.decode(base64Signature);

if (publicKey.verifyMessageString(message, signature)) {
  print("Verified across SDKs");
}
```

## Related SEPs

- [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) - Web authentication for accounts
- [SEP-45](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md) - Web authentication for contract accounts

## Reference

- [SEP-53 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md)
- [KeyPair Source Code](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/key_pair.dart)

---

[Back to SEP Overview](README.md)
