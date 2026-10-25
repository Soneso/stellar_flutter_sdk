# SEP-53: Sign/Verify Messages

**Purpose:** Sign and verify arbitrary messages using Stellar Ed25519 keypairs without on-chain transactions.
**Prerequisites:** None
**SDK Class:** `KeyPair`

## Overview

SEP-53 enables proof-of-ownership and off-chain authentication by defining a standard signing procedure for arbitrary messages. The four methods are instance methods on `KeyPair`:

| Method | Input | Returns | Throws |
|--------|-------|---------|--------|
| `signMessage(Uint8List)` | Raw bytes | `Uint8List` (64-byte signature) | `Exception` if no private key |
| `signMessageString(String)` | UTF-8 string | `Uint8List` (64-byte signature) | `Exception` if no private key |
| `verifyMessage(Uint8List, Uint8List)` | Message bytes + signature | `bool` | Never throws |
| `verifyMessageString(String, Uint8List)` | String + signature | `bool` | Never throws |

**Signing always requires a private key.** Verification only requires the public key — `KeyPair.fromAccountId()` is sufficient.

## Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  // Sign with a full keypair (has private key)
  KeyPair signer = KeyPair.fromSecretSeed('SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW'); // SEP-0053 spec test vector, public, never fund
  Uint8List signature = signer.signMessageString('Hello, World!');

  // Transmit the signature as base64 or hex
  String base64Sig = base64.encode(signature);
  String hexSig = Util.bytesToHex(signature);

  // Verify with public key only (no private key needed)
  KeyPair verifier = KeyPair.fromAccountId(signer.accountId);
  bool valid = verifier.verifyMessageString('Hello, World!', signature);
  print('Valid: $valid'); // true
}
```

## Signing Messages

### Sign a String

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

KeyPair keyPair = KeyPair.fromSecretSeed('SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW'); // SEP-0053 spec test vector, public, never fund

// Sign a UTF-8 string — SDK handles UTF-8 encoding internally
Uint8List signature = keyPair.signMessageString('Hello, World!');

// Encode for transmission (SEP-53 does not mandate a specific encoding)
String asBase64 = base64.encode(signature); // base64 encoding
String asHex = Util.bytesToHex(signature);  // hex encoding
```

### Sign Binary Data

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

KeyPair keyPair = KeyPair.fromSecretSeed('SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW'); // SEP-0053 spec test vector, public, never fund

// Sign raw bytes directly
Uint8List messageBytes = Uint8List.fromList([0xDB, 0x36, 0x43, 0x3F]);
Uint8List signature = keyPair.signMessage(messageBytes);

// Sign a JSON payload as bytes
Map<String, dynamic> payload = {'timestamp': 1234567890, 'action': 'login'};
Uint8List jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
Uint8List jsonSig = keyPair.signMessage(jsonBytes);
```

### Check Before Signing

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

KeyPair keyPair = KeyPair.fromSecretSeed('SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW'); // SEP-0053 spec test vector, public, never fund

// canSign() returns true only if the keypair has a private key
if (keyPair.canSign()) {
  Uint8List signature = keyPair.signMessageString('my message');
}

// KeyPair.fromAccountId() creates a public-key-only keypair — canSign() returns false
KeyPair publicOnly = KeyPair.fromAccountId('GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L');
print(publicOnly.canSign()); // false — signMessage() would throw Exception
```

## Verifying Messages

Verification only requires the public key. Use `KeyPair.fromAccountId()` to create a verify-only keypair:

### Verify a String Signature

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

// Receiver side: only needs the signer's account ID
KeyPair verifier = KeyPair.fromAccountId('GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L');

// Decode signature from the transport encoding used by the sender
String receivedBase64 = 'fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA==';
Uint8List signature = base64.decode(receivedBase64);
// or from hex: Uint8List signature = Util.hexToBytes(receivedHex);

bool valid = verifier.verifyMessageString('Hello, World!', signature);
if (valid) {
  print('Authenticated: message is from the expected signer');
} else {
  print('Verification failed');
}
```

### Verify Binary Data

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

KeyPair verifier = KeyPair.fromAccountId('GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L');

Uint8List message = base64.decode('2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=');
Uint8List signature = Util.hexToBytes(
  '540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff'
  '8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d'
);

bool valid = verifier.verifyMessage(message, signature);
```

## Signature Serialization

Signatures are 64-byte `Uint8List`. SEP-53 does not mandate a specific string encoding — use whatever the application requires:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

KeyPair keyPair = KeyPair.fromSecretSeed('SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW'); // SEP-0053 spec test vector, public, never fund
Uint8List signature = keyPair.signMessageString('Hello, World!');

// Encode for storage or transmission
String base64Sig = base64.encode(signature);        // base64 standard encoding
String hexSig    = Util.bytesToHex(signature);      // lowercase hex

// Decode when verifying
Uint8List fromBase64 = base64.decode(base64Sig);
Uint8List fromHex    = Util.hexToBytes(hexSig);
```

## Verifying the Specification Vector

The SEP-53 specification publishes test vectors (Spec Test Vectors below). This fence verifies its UTF-8 vector:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

// SEP-53 test vector signature of the UTF-8 message, as base64
String vectorSignatureBase64 = 'CDU265Xs8y3OWbB/56H9jPgUss5G9A0qFuTqH2zs2YDgTm+++dIfmAEceFqB7bhfN3am59lCtDXrCtwH2k1GBA==';

KeyPair verifier = KeyPair.fromAccountId('GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L');
Uint8List signature = base64.decode(vectorSignatureBase64);

bool valid = verifier.verifyMessageString('こんにちは、世界！', signature);
print('Vector verification: $valid'); // true
```

## Protocol Details

SEP-53 defines the signing procedure as:

1. **Prefix:** Prepend `"Stellar Signed Message:\n"` (UTF-8 bytes) to the message
2. **Hash:** SHA-256 hash the concatenated payload
3. **Sign:** Ed25519 sign the hash with the private key

```
signature = Ed25519.sign(privateKey, SHA256("Stellar Signed Message:\n" + message))
```

The prefix provides domain separation — message signatures cannot be confused with transaction signatures even if the raw bytes happen to match a transaction hash.

### Spec Test Vectors

These vectors from the SEP-53 specification can be used to validate interoperability:

```
Secret seed: SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW  # SEP-0053 spec test vector, public, never fund
Account ID:  GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L

Message: "Hello, World!" (ASCII)
Signature (hex): 7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd
                 6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04

Message: "こんにちは、世界！" (UTF-8)
Signature (hex): 083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980
                 e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604
```

## Error Handling

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

KeyPair publicOnly = KeyPair.fromAccountId('GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L');

// Signing with a public-only keypair throws Exception
try {
  Uint8List sig = publicOnly.signMessageString('Hello');
} catch (e) {
  print('Cannot sign: $e');
  // "KeyPair does not contain secret key. Use KeyPair.fromSecretSeed..."
}

// Verification never throws — returns false on failure instead
bool result = publicOnly.verifyMessageString('Hello', Uint8List(64)); // false, not an exception
```

## Common Pitfalls

```dart
import 'dart:typed_data';
import 'dart:convert';

// From your app: base64SignatureString (String)
// From the section Verifying the Specification Vector: verifier (KeyPair)
// WRONG: passing a base64 string directly to verifyMessageString as the signature
bool bad = verifier.verifyMessageString('Hello', Uint8List.fromList('abc123'.codeUnits));

// CORRECT: decode the base64 or hex string to Uint8List first
Uint8List sig = base64.decode(base64SignatureString);
bool good = verifier.verifyMessageString('Hello', sig);
```

```dart
import 'dart:typed_data';
import 'dart:convert';

// From the section Signature Serialization: keyPair (KeyPair)
// WRONG: using signMessage with a pre-encoded UTF-8 string when signMessageString is available
Uint8List sig1 = keyPair.signMessage(Uint8List.fromList(utf8.encode('Hello')));

// CORRECT: use signMessageString for string messages (same result, less boilerplate)
Uint8List sig2 = keyPair.signMessageString('Hello');
// sig1 and sig2 produce identical signatures — but signMessageString is cleaner for strings
```

```dart
import 'dart:typed_data';

// From your app: badSignature (Uint8List)
// From the section Signature Serialization: keyPair (KeyPair)
// WRONG: assuming verify throws on invalid signature
try {
  keyPair.verifyMessageString('msg', badSignature); // does NOT throw
} catch (e) { /* handle the error */ }

// CORRECT: check the return value
bool valid = keyPair.verifyMessageString('msg', badSignature);
if (!valid) { /* handle invalid signature */ }
```

```dart
import 'dart:typed_data';
import 'dart:convert';

// From the section Signature Serialization: keyPair (KeyPair)
// WRONG: using sign() directly for message signing (bypasses the SEP-53 prefix/hash)
Uint8List sig = keyPair.sign(utf8.encode('Hello') as Uint8List);

// CORRECT: use signMessageString() or signMessage() which apply the SEP-53 prefix
Uint8List sig = keyPair.signMessageString('Hello');
```
