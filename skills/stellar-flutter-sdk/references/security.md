# Security Best Practices

Security patterns and guidelines for production Stellar Flutter SDK applications. All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## Secret Key Management

Secret keys (S... seeds) give full control over an account. Compromised keys lead to irreversible fund loss.

### Never Hardcode Keys

```dart
// WRONG -- secret key exposed in source code
// KeyPair pair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6GR...');

// CORRECT -- load from secure storage
Future<KeyPair> loadKeyPair(SecureKeyStore store) async {
  String seed = await store.read('stellar_secret_seed');
  KeyPair keyPair = KeyPair.fromSecretSeed(seed);
  // Clear seed from memory when done
  seed = '';
  return keyPair;
}
```

### Platform-Specific Secure Storage

Use `flutter_secure_storage` (or equivalent) which delegates to platform-native secure storage:

- **iOS:** Keychain Services (hardware-backed on devices with Secure Enclave)
- **Android:** Android Keystore with EncryptedSharedPreferences
- **Web:** No truly secure local storage exists -- see Web Platform section below

### Key Management Rules

1. Generate keys on-device, never on a server
2. Never log, print, or transmit secret seeds
3. Clear secret seeds from memory when no longer needed
4. Use `KeyPair.fromAccountId()` (public key only) for read-only operations
5. For HD wallets, store only the mnemonic and derive keys on demand via `Wallet` (SEP-0005)

## Input Validation

Validate all user-provided data before constructing Stellar transactions.

### Address Validation

```dart
bool isValidStellarAddress(String address) {
  if (StrKey.isValidStellarAccountId(address)) return true;   // G...
  if (StrKey.isValidStellarMuxedAccountId(address)) return true; // M...
  if (StrKey.isValidContractId(address)) return true;          // C...
  return false;
}

// Validate secret seeds (S... addresses)
bool isValidSeed(String seed) {
  return StrKey.isValidStellarSecretSeed(seed);
}
```

### Asset Code Validation

```dart
String? validateAssetCode(String code) {
  if (code.isEmpty || code.length > 12) {
    return 'Asset code must be 1-12 characters';
  }
  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(code)) {
    return 'Asset code must be alphanumeric only';
  }
  return null; // Valid
}
```

### Amount Validation

```dart
String? validateAmount(String input) {
  if (input.isEmpty) return 'Amount is required';

  double? amount = double.tryParse(input);
  if (amount == null) return 'Amount must be a number';
  if (amount <= 0) return 'Amount must be positive';

  // Stellar supports max 7 decimal places (stroops)
  List<String> parts = input.split('.');
  if (parts.length == 2 && parts[1].length > 7) {
    return 'Maximum 7 decimal places';
  }

  // Stellar maximum: 922,337,203,685.4775807
  if (amount > 922337203685.4775807) {
    return 'Amount exceeds Stellar maximum';
  }

  return null; // Valid
}
```

### Memo Validation

```dart
import 'dart:convert';

String? validateMemoText(String value) {
  // MemoText max 28 bytes UTF-8
  if (utf8.encode(value).length > 28) {
    return 'Memo text exceeds 28 bytes';
  }
  return null;
}
```

## Transaction Verification Before Signing

Always inspect transaction contents before calling `sign()`, especially when receiving XDR from external sources (SEP-0007 URIs, SEP-0010 challenges, multi-sig coordination). See [XDR Reference](./xdr.md) for the inspection pattern.

Key checks before signing:
- Source account matches expectations
- Operations are expected types with expected parameters
- Fee is reasonable (e.g., under 0.001 XLM per operation)
- No unexpected Soroban resource fees attached
- Signature count is as expected (no extra signatures)

## Network Selection and Validation

Mixing testnet and public network configurations leads to invalid signatures or unintentional real-fund transfers.

```dart
// Validate Horizon server matches expected network at startup
Future<void> validateNetwork(StellarSDK sdk, Network expectedNetwork) async {
  // WRONG: just trust the URL matches the network
  // CORRECT: verify the server's reported passphrase
  // Use sdk.root to check network passphrase matches
}
```

Always pass the `Network` object from a single configuration source. Never construct `Network` objects with raw passphrase strings -- use `Network.TESTNET` and `Network.PUBLIC`.

```dart
class StellarConfig {
  final StellarSDK sdk;
  final Network network;
  final SorobanServer? rpcServer;

  StellarConfig._({required this.sdk, required this.network, this.rpcServer});

  factory StellarConfig.testnet() => StellarConfig._(
    sdk: StellarSDK.TESTNET,
    network: Network.TESTNET,
    rpcServer: SorobanServer('https://soroban-testnet.stellar.org:443'),
  );

  factory StellarConfig.publicNet() => StellarConfig._(
    sdk: StellarSDK.PUBLIC,
    network: Network.PUBLIC,
    rpcServer: SorobanServer('https://rpc.stellar.org'),
  );
}
```

## Safe Error Handling

Never expose secret keys in error messages, logs, or stack traces.

```dart
// WRONG -- seed could appear in stack trace if fromSecretSeed throws
void unsafeSign(String seed) {
  KeyPair kp = KeyPair.fromSecretSeed(seed);
  // If later code throws, seed is in the stack frame
}

// CORRECT -- isolate key handling, catch and sanitize errors
Future<void> safeSign(SecureKeyStore store) async {
  String seed = '';
  try {
    seed = await store.read('stellar_secret_seed');
    KeyPair kp = KeyPair.fromSecretSeed(seed);
    // ... build and sign transaction
  } on ErrorResponse catch (e) {
    // Log only safe information, never the seed
    print('Stellar error: HTTP ${e.code}');
    rethrow;
  } finally {
    seed = ''; // Clear from memory
  }
}
```

## Multi-Signature Security

Security rules for multi-sig accounts:
- Set appropriate thresholds via `SetOptionsOperation` (low, medium, high) -- see [Advanced Features](./advanced.md)
- Distribute signing across different devices or parties
- Never collect all signer keys in one place
- Use time bounds (`TransactionPreconditions.timeBounds`) to limit signing windows
- Always inspect transaction contents before co-signing (see XDR sharing pattern in advanced.md)

## SEP-10 Authentication Security

SEP-10 (Web Authentication) proves account ownership to anchor services.

```dart
Future<String> authenticateWithAnchor(
  String domain,
  KeyPair clientKeyPair,
  Network network,
) async {
  WebAuth webAuth = await WebAuth.fromDomain(domain, network);
  String jwtToken = await webAuth.jwtToken(
    clientKeyPair.accountId,
    [clientKeyPair],
  );
  return jwtToken;
}
```

SEP-10 security considerations:
- `WebAuth` verifies the challenge came from the expected server signing key
- Challenge transactions must have a `ManageDataOperation` with the correct domain
- Never sign challenges that contain unexpected operations
- Token expiry is set by the server -- do not cache tokens beyond their lifetime
- Use `WebAuth.fromDomain()` to ensure the auth endpoint is resolved from the official stellar.toml

## Web Platform Considerations

Flutter web has unique security constraints:

1. **No secure local storage.** Browser `localStorage` and `sessionStorage` are accessible to any JavaScript on the page. Never store secret seeds in the browser. For web wallets, consider hardware wallet integrations or server-side key custody with SEP-10 authentication.

2. **HTTPS required.** All Horizon and Soroban RPC endpoints must be accessed over HTTPS.

3. **CORS restrictions.** Horizon servers must include appropriate CORS headers. Public Horizon and Soroban RPC endpoints support CORS. Custom Horizon instances may need CORS configuration.

4. **No `httpOverrides`.** The `StellarSDK.httpOverrides` setter and `SorobanServer.httpOverrides` throw `UnsupportedError` on web.

## HTTPS and Endpoint Security

- Always use HTTPS endpoints for Horizon and Soroban RPC
- Use `StellarSDK.PUBLIC` or `StellarSDK.TESTNET` which point to official endpoints
- When using custom Horizon instances, validate the URL scheme is HTTPS
- Pin or validate TLS certificates in high-security mobile apps (requires platform-specific code outside the SDK)

## Dependency Security

The SDK uses pure Dart cryptographic libraries (`pointycastle`, `pinenacl`) with no native FFI:

1. Run `dart pub outdated` regularly to check for updates
2. Review changelogs of cryptographic dependencies for security patches
3. Lock dependency versions in `pubspec.lock` and commit to source control

## Security Checklist

- [ ] Secret keys loaded from platform secure storage, never hardcoded
- [ ] Secret keys cleared from memory after use
- [ ] All user-supplied addresses validated with `StrKey` methods
- [ ] Asset codes validated (1-12 alphanumeric characters)
- [ ] Amounts validated as positive decimals with at most 7 decimal places
- [ ] All transactions inspected before signing (source, operations, fee)
- [ ] Error messages sanitized -- no secrets in logs or user-facing errors
- [ ] Network configuration sourced from a single place (testnet vs public)
- [ ] Web platform avoids storing secrets in browser storage
- [ ] All endpoints use HTTPS
- [ ] SEP-10 challenges verified before signing
- [ ] Multi-sig thresholds configured for high-value accounts
- [ ] Dependencies audited and pinned
