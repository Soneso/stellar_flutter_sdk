# SEP-23: Strkey Encoding

SEP-23 defines how Stellar encodes addresses between raw binary data and human-readable strings. Each address type starts with a specific letter — account IDs start with "G", secret seeds with "S", muxed accounts with "M", contracts with "C", and so on.

**When to use:** Validating user-entered addresses, converting between raw bytes and string representations, working with different key types, and creating muxed accounts for sub-account tracking.

See the [SEP-23 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md) for protocol details.

## Quick example

This example demonstrates the most common strkey operations: generating a keypair, validating addresses, and converting between formats.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate a keypair
KeyPair keyPair = KeyPair.random();
String accountId = keyPair.accountId; // G...

// Validate an address
if (StrKey.isValidStellarAccountId(accountId)) {
  print('Valid account ID');
}

// Decode to raw bytes and encode back
Uint8List rawPublicKey = StrKey.decodeStellarAccountId(accountId);
String encoded = StrKey.encodeStellarAccountId(rawPublicKey);
```

## Account IDs and secret seeds

Account IDs (G...) are public keys that identify accounts on the network. Secret seeds (S...) are private keys used for signing transactions — never share these publicly.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Use a keypair with a known seed
KeyPair keyPair = KeyPair.fromSecretSeed('SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECA');
String accountId = keyPair.accountId;
String secretSeed = keyPair.secretSeed;

// Validate
StrKey.isValidStellarAccountId(accountId); // true
StrKey.isValidStellarSecretSeed(secretSeed); // true

// Decode to raw 32-byte keys
Uint8List rawPublicKey = StrKey.decodeStellarAccountId(accountId);
Uint8List rawPrivateKey = StrKey.decodeStellarSecretSeed(secretSeed);

// Encode raw bytes back to string
String encoded = StrKey.encodeStellarAccountId(rawPublicKey);
String encodedSeed = StrKey.encodeStellarSecretSeed(rawPrivateKey);

// Derive account ID from seed
String derivedAccountId = KeyPair.fromSecretSeed(secretSeed).accountId;
```

## Muxed accounts (M...)

Muxed accounts (defined in [CAP-27](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md)) allow you to multiplex multiple virtual accounts onto a single Stellar account. This is useful for exchanges, payment processors, and custodial services that need to track funds for many users without creating separate on-chain accounts.

A muxed account combines:
- An Ed25519 account ID (G-address) — the underlying Stellar account
- A 64-bit unsigned integer ID — identifies the virtual sub-account

When encoded, muxed accounts start with "M" instead of "G".

### Creating muxed accounts

You can create muxed accounts by combining a G-address with a numeric ID, or by parsing an M-address string.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String accountId = 'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';
int userId = 1234567890;

// Create a muxed account from G-address and ID
MuxedAccount muxedAccount = MuxedAccount(accountId, BigInt.from(userId));
String muxedAccountId = muxedAccount.accountId; // M...

// Parse an existing M-address
MuxedAccount? parsedMuxed = MuxedAccount.fromAccountId(
  'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ',
);
```

### Extracting muxed account components

When you receive an M-address, you can extract both the underlying G-address and the numeric ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String muxedAccountId =
    'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';

MuxedAccount? muxedAccount = MuxedAccount.fromAccountId(muxedAccountId);

// Get the underlying G-address (the actual on-chain account)
String ed25519AccountId = muxedAccount!.ed25519AccountId;
print('Underlying account: $ed25519AccountId');

// Get the 64-bit ID (identifies the virtual sub-account)
BigInt? id = muxedAccount.id;
print('User ID: $id');

// Get the M-address (same as input for muxed, or G-address if no ID)
String accountId = muxedAccount.accountId;
```

### Using muxed accounts in transactions

Muxed accounts can be used as source accounts and destinations in operations. The Stellar network processes these using the underlying G-address, while preserving the ID for tracking purposes.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Sender keypair (must control the underlying G-address)
KeyPair senderKeyPair = KeyPair.fromSecretSeed(
  'SAKEEHNTJXQTHU64TYNKP3ET56RSCB4ZHXYZRPEULNHUBDN4L2TWAECA',
);
String senderAccountId = senderKeyPair.accountId;

// Create muxed source account (sender with user ID 100)
MuxedAccount muxedSource = MuxedAccount(senderAccountId, BigInt.from(100));

// Create muxed destination (recipient with user ID 200)
String destinationAccountId =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';
MuxedAccount muxedDestination =
    MuxedAccount(destinationAccountId, BigInt.from(200));

// Build payment operation with muxed destination
PaymentOperation paymentOp = PaymentOperationBuilder(
  muxedDestination.accountId, // Can use M-address directly
  Asset.NATIVE,
  '10.0',
).build();

// Note: The source account for signing must be the underlying G-address
StellarSDK sdk = StellarSDK.TESTNET;
AccountResponse sourceAccount =
    await sdk.accounts.account(senderAccountId);

Transaction transaction = TransactionBuilder(sourceAccount)
    .addOperation(paymentOp)
    .build();

transaction.sign(senderKeyPair, Network.TESTNET);
```

### Low-level muxed account encoding

For direct manipulation of muxed account binary data, use the StrKey class methods.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String muxedAccountId =
    'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';

// Validate M-address format
StrKey.isValidStellarMuxedAccountId(muxedAccountId); // true

// Decode to raw binary (40 bytes: 8-byte ID + 32-byte public key)
Uint8List rawData = StrKey.decodeStellarMuxedAccountId(muxedAccountId);

// Encode raw binary back to M-address
String encoded = StrKey.encodeStellarMuxedAccountId(rawData);
```

## Pre-auth TX and SHA-256 hashes

Pre-auth transaction hashes (T...) authorize specific transactions in advance. SHA-256 hashes (X...) are for hash-locked transactions that require revealing a preimage to sign.

```dart
import 'dart:math';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Pre-auth TX (T...)
// In practice, this would be a real transaction hash
var random = Random.secure();
Uint8List transactionHash = Uint8List.fromList(
  List<int>.generate(32, (_) => random.nextInt(256)),
);
String preAuthTx = StrKey.encodePreAuthTx(transactionHash);
StrKey.isValidPreAuthTx(preAuthTx); // true
Uint8List decoded = StrKey.decodePreAuthTx(preAuthTx);

// SHA-256 hash signer (X...)
// Use any 32-byte hash value
Uint8List hash = Uint8List.fromList(
  List<int>.generate(32, (_) => random.nextInt(256)),
);
String hashSigner = StrKey.encodeSha256Hash(hash);
StrKey.isValidSha256Hash(hashSigner); // true
Uint8List decodedHash = StrKey.decodeSha256Hash(hashSigner);
```

## Contract IDs (C...)

Soroban smart contracts are identified by C-addresses. These encode the 32-byte contract hash.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Encode a 32-byte hash as a contract ID
Uint8List contractHash = KeyPair.random().publicKey; // any 32 bytes
String contractId = StrKey.encodeContractId(contractHash); // C...

// Validate
StrKey.isValidContractId(contractId); // true

// Decode to raw bytes or hex
Uint8List raw = StrKey.decodeContractId(contractId);
String hex = StrKey.decodeContractIdHex(contractId);

// Encode from raw bytes or hex
String encoded = StrKey.encodeContractId(raw);
String encodedFromHex = StrKey.encodeContractIdHex(hex);
```

## Signed payloads (P...)

Signed payloads (defined in [CAP-40](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md)) combine a public key with arbitrary payload data. They're used for delegated signing scenarios where a signature covers both the transaction and additional application-specific data.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.random();
Uint8List payload = Uint8List(32); // 1 to 64 bytes of application data

SignedPayloadSigner signer = SignedPayloadSigner.fromAccountId(
  keyPair.accountId,
  payload,
);
String signedPayload = StrKey.encodeSignedPayload(signer); // P...

SignedPayloadSigner decoded = StrKey.decodeSignedPayload(signedPayload);
String signerAccountId = KeyPair.fromXdrPublicKey(
  decoded.signerAccountID.accountID,
).accountId;
print(signerAccountId);
```

Behind a P-address sit three fields: the 32-byte signer key, the payload length as a 4-byte big-endian integer, and the payload padded with NUL bytes up to a multiple of four. `decodeSignedPayload` and `decodeXdrSignedPayload` hold an address to exactly that shape:

- The declared length is 1 to 64 bytes. `opaque payload<64>` sets the ceiling, and an empty payload has no P-address the ecosystem reads back.
- The decoded bytes total exactly 32 + 4 plus the padded payload, so nothing rides along behind it.
- The padding bytes are NUL.

An address that breaks any of those throws a `FormatException`.

`SignedPayloadSigner` applies the same length bound when you build one, so an out-of-range payload fails before you encode it:

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.random();

try {
  SignedPayloadSigner.fromAccountId(keyPair.accountId, Uint8List(0));
} on Exception catch (e) {
  print(e); // Exception: invalid payload length, must be at least 1
}
```

## Liquidity pool and claimable balance IDs

Pool IDs (L...) identify AMM liquidity pools. Claimable balance IDs (B...) reference claimable balance entries. Both support hex encoding for interoperability with APIs.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Liquidity pool ID (L...)
String poolHex =
    'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
String poolId = StrKey.encodeLiquidityPoolIdHex(poolHex);
StrKey.isValidLiquidityPoolId(poolId); // true
Uint8List decodedPool = StrKey.decodeLiquidityPoolId(poolId);

// Claimable balance ID (B...), from the bare 32-byte hash. The 33-byte tagged
// form and the 36-byte XDR form Horizon reports encode the same way.
String balanceHex =
    '3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a';
String balanceId = StrKey.encodeClaimableBalanceIdHex(balanceHex);
StrKey.isValidClaimableBalanceId(balanceId); // true
Uint8List decodedBalance = StrKey.decodeClaimableBalanceId(balanceId);
```

A pool ID carries the bare 32-byte hash. A claimable balance ID carries 33 bytes: a one-byte discriminant naming the balance ID type, then the 32-byte hash. `CLAIMABLE_BALANCE_ID_TYPE_V0` is the only type the protocol defines, its discriminant is zero, and both directions insist on it.

`decodeClaimableBalanceId` throws a `FormatException` on any other discriminant, and returns all 33 bytes: drop the first for the hash. `encodeClaimableBalanceId` takes the bare 32-byte hash, which it prefixes with the discriminant for you, the 33-byte form, or the 36-byte XDR encoding Horizon reports, whose four-byte union discriminant it verifies and strips. Any other width throws, as does a discriminant that names no balance ID type. The encode direction raises a plain `Exception` rather than a `FormatException`, so catch `Exception` around it:

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List tagged = Uint8List(33);
tagged[0] = 1; // names no claimable balance ID type

try {
  StrKey.encodeClaimableBalanceId(tagged);
} on Exception catch (e) {
  print(e);
  // Exception: claimable balance id carries the discriminant 1,
  // which names no claimable balance id type
}
```

`XdrClaimableBalanceID.forId` reads the same rule. It takes a B-address or the hex rendering of the ID, and rejects a non-zero discriminant in either.

## Version bytes reference

Each strkey type has a unique version byte that determines its prefix character. Every type admits a fixed encoded length and payload width except `P`, which admits a range, and the decoder holds an address to both: it measures the string before decoding it, and the payload again after the checksum.

| Prefix | Type | Description | Encoded length | Payload |
|--------|------|-------------|----------------|---------|
| G | Account ID | Ed25519 public key | 56 | 32 bytes |
| S | Secret Seed | Ed25519 private key | 56 | 32 bytes |
| M | Muxed Account | Account ID + 64-bit ID | 69 | 40 bytes |
| T | Pre-Auth TX | Pre-authorized transaction hash | 56 | 32 bytes |
| X | SHA-256 Hash | Hash signer | 56 | 32 bytes |
| P | Signed Payload | Public key + payload | 69 to 165 | 40 to 100 bytes |
| C | Contract ID | Soroban smart contract | 56 | 32 bytes |
| L | Liquidity Pool ID | AMM liquidity pool | 56 | 32 bytes |
| B | Claimable Balance | Claimable balance entry | 58 | 33 bytes |

P is the only type with a range. Its payload is the 32-byte signer key, the 4-byte length prefix, and 1 to 64 payload bytes padded to a multiple of four.

## Error handling

Every `decode*` method throws a `FormatException` when the address does not hold up, so that is the only type to catch. The `encode*` methods raise a plain `Exception` for a payload of a width their type does not admit. The decoder rejects, in order: a version byte it does not know, an encoded length that is wrong for the type, a base32 body that does not re-encode to the string it came from, a version byte belonging to a different type, a bad CRC-16 checksum, a decoded payload of the wrong width as a backstop on the length check, and last the per-type framing rules for `P...` and `B...`.

Because the length comes first, an empty string or a single character is a length failure like any other. Short input needs no special case.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  Uint8List raw = StrKey.decodeStellarAccountId('GINVALIDADDRESS');
  print('Decoded ${raw.length} bytes');
} on FormatException catch (e) {
  print(e.message); // Encoded string must be 56 characters, got 15
}
```

The `isValid*` methods run the matching decoder and return false instead of throwing. Reach for them when you are classifying input rather than handling one expected type.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String input =
    'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';

if (StrKey.isValidStellarAccountId(input)) {
  Uint8List raw = StrKey.decodeStellarAccountId(input);
  print('Account ID carrying ${raw.length} bytes');
} else if (StrKey.isValidStellarMuxedAccountId(input)) {
  MuxedAccount muxed = MuxedAccount.fromAccountId(input)!;
  print('Muxed account over ${muxed.ed25519AccountId}');
} else {
  print('Not an address this SDK reads');
}
```

`MuxedAccount.fromAccountId` returns null for a string that starts with neither G nor M, and throws the decoder's `FormatException` for an M-address that does not hold up.

### Common validation errors

The SEP-23 spec defines several invalid strkey cases that implementations must reject. All of them arrive as `FormatException`:

- **Invalid length**: the encoded string must be a length its type admits, and the decoded payload the matching width (see the table above)
- **Invalid checksum**: the CRC-16 checksum at the end must match the payload
- **Wrong version byte**: the first character must match the expected type
- **Invalid base32 characters**: only A-Z and 2-7 are valid
- **Invalid padding**: strkeys must not contain `=` padding characters
- **Malformed signed payload**: a `P...` address must declare 1 to 64 payload bytes, be exactly as wide as that payload needs, and pad with NUL
- **Unknown claimable balance discriminant**: a `B...` address must lead with the `CLAIMABLE_BALANCE_ID_TYPE_V0` discriminant

## Related specifications

- [SEP-05 Key Derivation](sep-05.md) — Deriving keypairs from mnemonic phrases
- [SEP-10 Web Authentication](sep-10.md) — Uses account IDs for authentication challenges
- [SEP-45 Web Authentication for Contract Accounts](sep-45.md) — Authentication for Soroban contract accounts (C... addresses)

---

[Back to SEP Overview](README.md)
