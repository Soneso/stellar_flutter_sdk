# SEP-23: Strkey Encoding

SEP-23 defines how Stellar encodes addresses between raw binary data and human-readable strings. Each address type starts with a specific letter — account IDs start with "G", secret seeds with "S", muxed accounts with "M", contracts with "C", and so on.

**When to use:** Validating user-entered addresses, converting between raw bytes and string representations, working with different key types, and creating muxed accounts for sub-account tracking.

See the [SEP-23 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md) for protocol details.

## Quick example

This example demonstrates the most common strkey operations: generating a keypair, validating addresses, and converting between formats.

```dart
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
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.random();
Uint8List payload = Uint8List(32); // 4-64 bytes of application data

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

## Liquidity pool and claimable balance IDs

Pool IDs (L...) identify AMM liquidity pools. Claimable balance IDs (B...) reference claimable balance entries. Both support hex encoding for interoperability with APIs.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Liquidity pool ID (L...)
String poolHex =
    'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
String poolId = StrKey.encodeLiquidityPoolIdHex(poolHex);
StrKey.isValidLiquidityPoolId(poolId); // true
Uint8List decodedPool = StrKey.decodeLiquidityPoolId(poolId);

// Claimable balance ID (B...)
String balanceHex =
    '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfd';
String balanceId = StrKey.encodeClaimableBalanceIdHex(balanceHex);
StrKey.isValidClaimableBalanceId(balanceId); // true
Uint8List decodedBalance = StrKey.decodeClaimableBalanceId(balanceId);
```

## Version bytes reference

Each strkey type has a unique version byte that determines its prefix character:

| Prefix | Type | Description |
|--------|------|-------------|
| G | Account ID | Ed25519 public key |
| S | Secret Seed | Ed25519 private key |
| M | Muxed Account | Account ID + 64-bit ID |
| T | Pre-Auth TX | Pre-authorized transaction hash |
| X | SHA-256 Hash | Hash signer |
| P | Signed Payload | Public key + payload |
| C | Contract ID | Soroban smart contract |
| L | Liquidity Pool ID | AMM liquidity pool |
| B | Claimable Balance | Claimable balance entry |

## Error handling

Invalid addresses throw exceptions. Use validation methods to check addresses before decoding to avoid exceptions in user-facing code.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Invalid checksum or wrong version byte throws
try {
  StrKey.decodeStellarAccountId('GINVALIDADDRESS...');
} catch (e) {
  print('Invalid: $e');
}

// Use validation to avoid exceptions
String input = 'user-provided-address';
if (StrKey.isValidStellarAccountId(input)) {
  Uint8List raw = StrKey.decodeStellarAccountId(input);
} else if (StrKey.isValidStellarMuxedAccountId(input)) {
  MuxedAccount? muxed = MuxedAccount.fromAccountId(input);
  Uint8List raw = StrKey.decodeStellarAccountId(muxed!.ed25519AccountId);
} else {
  print('Invalid address format');
}

// MuxedAccount validates on construction
try {
  // Must start with G (Ed25519 account ID)
  MuxedAccount muxed = MuxedAccount('INVALID', BigInt.from(123));
} catch (e) {
  print('Invalid: $e');
}
```

### Common validation errors

The SEP-23 spec defines several invalid strkey cases that implementations must reject:

- **Invalid length**: Strkey length must match the expected format
- **Invalid checksum**: The CRC-16 checksum at the end must be valid
- **Wrong version byte**: The first character must match the expected type
- **Invalid base32 characters**: Only A-Z and 2-7 are valid
- **Invalid padding**: Strkeys must not contain `=` padding characters

## Related specifications

- [SEP-05 Key Derivation](sep-05.md) — Deriving keypairs from mnemonic phrases
- [SEP-10 Web Authentication](sep-10.md) — Uses account IDs for authentication challenges
- [SEP-45 Web Authentication for Contract Accounts](sep-45.md) — Authentication for Soroban contract accounts (C... addresses)

---

[Back to SEP Overview](README.md)
