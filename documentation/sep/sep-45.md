# SEP-45: Web Authentication for Contract Accounts

Authenticate Soroban smart contract accounts (C... addresses) with anchor services.

## Overview

SEP-45 enables wallets and clients to prove control of a Soroban contract account by signing authorization entries provided by an anchor's authentication server. Upon successful verification, the server returns a JWT token for accessing protected SEP services.

Use SEP-45 when:

- Authenticating a Soroban contract with an anchor
- Accessing SEP-24 deposits/withdrawals from a contract account
- Using SEP-12 KYC or SEP-38 quotes with contract accounts

**SEP-45 vs SEP-10:**
- SEP-45: For contract accounts (C... addresses)
- SEP-10: For traditional accounts (G... and M... addresses)

Services supporting all account types should implement both protocols.

### How it works

1. Client requests a challenge from the server
2. Server returns authorization entries calling `web_auth_verify` on its web-auth contract
3. Client validates and signs the entries with keypairs registered in the contract
4. Client submits signed entries to server
5. Server simulates the transaction -- this invokes the client contract's `__check_auth`
6. If `__check_auth` succeeds, server returns a JWT token

## Quick example

The `jwtToken()` method handles the entire flow automatically. This example loads configuration from the anchor's stellar.toml file.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Your contract account (must implement __check_auth)
const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';

// Signer registered in your contract's __check_auth implementation
final signer = KeyPair.fromSecretSeed('SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');

// Create instance from domain and authenticate in one step
final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);
final jwtToken = await webAuth.jwtToken(contractId, [signer]);

print('Authenticated! Token: ${jwtToken.substring(0, 50)}...');
```

## Prerequisites

Before using SEP-45, ensure:

1. **Server Configuration**: The service must have a stellar.toml with:
   - `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`: URL for the authentication endpoint
   - `WEB_AUTH_CONTRACT_ID`: The server's web-auth contract address (C...)
   - `SIGNING_KEY`: The server's signing key (G...)

2. **Client Contract Requirements**: Your contract account must:
   - Be deployed on the Stellar network (testnet or pubnet)
   - Implement `__check_auth` to define authorization rules
   - Have the signer's public key registered in its contract storage

3. **Signer Keypairs**: You need the secret keys for the signers registered in your contract's `__check_auth` implementation

## Creating the service

### From stellar.toml

The `fromDomain()` factory method loads configuration from the anchor's stellar.toml file. This is the typical approach since it pulls the correct endpoint and contract information automatically.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);
```

### Manual configuration

You can also provide all configuration values directly, which works well for testing or when you have the configuration cached.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = WebAuthForContracts(
  'https://anchor.example.com/auth/sep45',
  'CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG', // webAuthContractId (C...)
  'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP', // serverSigningKey (G...)
  'anchor.example.com',
  Network.TESTNET,
);
```

### Custom Soroban RPC URL

By default, the SDK uses `soroban-testnet.stellar.org` for testnet and `soroban.stellar.org` for pubnet. Specify a custom URL if you run a private RPC server.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = WebAuthForContracts(
  'https://anchor.example.com/auth/sep45',
  'CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG',
  'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
  'anchor.example.com',
  Network.TESTNET,
  sorobanRpcUrl: 'https://your-custom-rpc.example.com',
);
```

## Basic authentication

The `jwtToken()` method executes the complete SEP-45 flow: requesting the challenge, validating entries, signing with your keypairs, and submitting for a JWT.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed('SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);
final jwtToken = await webAuth.jwtToken(contractId, [signer]);
```

## Signature expiration

Signatures include an expiration ledger for replay protection. Per SEP-45, this should be set to a near-future ledger to limit the replay window.

### Automatic expiration (default)

When you don't specify an expiration ledger, the SDK automatically fetches the current ledger from Soroban RPC and sets expiration to current ledger + 10 (~50-60 seconds).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

// Expiration is auto-filled (current ledger + 10)
final jwtToken = await webAuth.jwtToken(contractId, [signer]);
```

### Custom expiration

You can also set a custom expiration ledger when you need more control over the signature validity window.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

final jwtToken = await webAuth.jwtToken(
  contractId,
  [signer],
  signatureExpirationLedger: 1500000,
);
```

## Contracts without signature requirements

Some contracts implement `__check_auth` without requiring signature verification (e.g., contracts using other authorization mechanisms). Per SEP-45, client signatures are optional in such cases.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

// Empty signers list - no signatures will be added
final jwtToken = await webAuth.jwtToken(contractId, []);
```

**Note:** When the signers list is empty, the SDK skips the Soroban RPC call since no signature expiration is needed. This only works if both the anchor and your contract support signature-less authentication.

## Client domain verification

Non-custodial wallets can prove their domain to the anchor, letting the anchor attribute requests to a specific wallet application. Your domain needs a stellar.toml with a `SIGNING_KEY`.

### Local signing

When you have direct access to the client domain's signing key, you can sign locally.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed('SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');

// Your wallet's SIGNING_KEY from stellar.toml
final clientDomainKeyPair = KeyPair.fromSecretSeed('SYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY');

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

final jwtToken = await webAuth.jwtToken(
  contractId,
  [signer],
  homeDomain: 'anchor.example.com',
  clientDomain: 'wallet.example.com',
  clientDomainAccountKeyPair: clientDomainKeyPair,
);
```

### Remote signing via callback

If the client domain signing key is on a remote server, use a callback function. The callback receives a `SorobanAuthorizationEntry` and returns the signed entry.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const contractId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signer = KeyPair.fromSecretSeed('SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');

Future<SorobanAuthorizationEntry> signingCallback(SorobanAuthorizationEntry entry) async {
  // Send the entry to your remote signing service
  final client = http.Client();
  try {
    final response = await client.post(
      Uri.parse('https://your-signing-server.com/sign-sep-45'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: json.encode({
        'authorization_entry': entry.toBase64EncodedXdrString(),
        'network_passphrase': 'Test SDF Network ; September 2015',
      }),
    );

    final data = json.decode(response.body) as Map<String, dynamic>;
    return SorobanAuthorizationEntry.fromBase64EncodedXdr(
      data['authorization_entry'] as String,
    );
  } finally {
    client.close();
  }
}

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

final jwtToken = await webAuth.jwtToken(
  contractId,
  [signer],
  clientDomain: 'wallet.example.com',
  clientDomainSigningCallback: signingCallback,
);
```

## Step-by-step authentication

For more control, you can execute each step individually. Helpful for debugging or when you need to customize the flow.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const contractAccountId = 'CCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ';
final signerKeyPair = KeyPair.fromSecretSeed('SXXXXX...');
const homeDomain = 'anchor.example.com';

final webAuth = await WebAuthForContracts.fromDomain(homeDomain, Network.TESTNET);

try {
  // Step 1: Get challenge from server
  final challengeResponse = await webAuth.getChallenge(contractAccountId, homeDomain: homeDomain);

  // Step 2: Decode authorization entries from base64 XDR
  final authEntries = webAuth.decodeAuthorizationEntries(
    challengeResponse.authorizationEntries,
  );

  // Step 3: Validate challenge (security checks)
  webAuth.validateChallenge(authEntries, contractAccountId, homeDomain: homeDomain);

  // Step 4: Get current ledger for signature expiration
  final sorobanServer = SorobanServer('https://soroban-testnet.stellar.org');
  final latestLedger = await sorobanServer.getLatestLedger();
  final expirationLedger = latestLedger.sequence! + 10;

  // Step 5: Sign authorization entries
  final signedEntries = await webAuth.signAuthorizationEntries(
    authEntries,
    contractAccountId,
    [signerKeyPair],
    expirationLedger,
    null, // clientDomainKeyPair
    null, // clientDomainAccountId
    null, // clientDomainSigningCallback
  );

  // Step 6: Submit signed entries for JWT token
  final jwtToken = await webAuth.sendSignedChallenge(signedEntries);

  print('JWT Token: $jwtToken');
} catch (e) {
  print('Error: $e');
}
```

## Request format configuration

The SDK supports both `application/x-www-form-urlencoded` and `application/json` when submitting signed challenges. Form URL encoding is used by default.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

// Use JSON format instead of form-urlencoded
webAuth.useFormUrlEncoded = false;

final jwtToken = await webAuth.jwtToken(contractId, [signer]);
```

## Error handling

The SDK throws specific exception types for different failure scenarios:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final webAuth = await WebAuthForContracts.fromDomain('anchor.example.com', Network.TESTNET);

try {
  final jwtToken = await webAuth.jwtToken(contractId, [signer]);

} on ContractChallengeValidationErrorInvalidContractAddress catch (e) {
  // Server's contract address doesn't match stellar.toml - potential security issue
  print('Security error: contract address mismatch');

} on ContractChallengeValidationErrorSubInvocationsFound catch (e) {
  // Challenge contains unauthorized sub-invocations - do NOT sign
  print('Security error: sub-invocations detected. Report to anchor.');

} on ContractChallengeValidationErrorInvalidServerSignature catch (e) {
  // Server's signature is invalid - potential man-in-the-middle attack
  print('Security error: invalid server signature');

} on ContractChallengeValidationErrorInvalidNetworkPassphrase catch (e) {
  // Network passphrase mismatch - wrong network configuration
  print('Configuration error: network passphrase mismatch');

} on ContractChallengeValidationErrorInvalidFunctionName catch (e) {
  // Function name is not 'web_auth_verify' - invalid challenge
  print('Invalid challenge: wrong function name');

} on ContractChallengeValidationErrorMissingServerEntry catch (e) {
  // No authorization entry for server account
  print('Invalid challenge: missing server entry');

} on ContractChallengeValidationErrorMissingClientEntry catch (e) {
  // No authorization entry for client account
  print('Invalid challenge: missing client entry');

} on ContractChallengeRequestErrorResponse catch (e) {
  // Server returned an error for challenge request
  print('Challenge request failed: ${e.message}');

} on SubmitContractChallengeErrorResponseException catch (e) {
  // Server rejected the signed challenge
  // Common cause: signer not registered in contract's __check_auth
  print('Authentication failed: ${e.error}');

} on SubmitContractChallengeTimeoutResponseException {
  // Server timed out processing the challenge
  print('Server timeout - please try again');

} on SubmitContractChallengeUnknownResponseException catch (e) {
  // Unexpected server response
  print('Unexpected error (HTTP ${e.code}): ${e.body}');

} catch (e) {
  print('Unexpected error: $e');
}
```

### Common issues

| Error | Cause | Solution |
|-------|-------|----------|
| `SubmitContractChallengeErrorResponseException` | Signer not in contract's `__check_auth` | Verify signer is registered in contract storage |
| `ContractChallengeValidationErrorInvalidContractAddress` | Contract address mismatch | Check stellar.toml `WEB_AUTH_CONTRACT_ID` |
| `ContractChallengeValidationErrorSubInvocationsFound` | Malicious challenge | Don't sign; report to anchor |
| `ContractChallengeValidationErrorInvalidNetworkPassphrase` | Wrong network | Check you're using testnet vs pubnet correctly |
| `ContractChallengeValidationErrorInvalidServerSignature` | Invalid server signature | Server may be compromised or misconfigured |

## Security notes

- **Store JWT tokens securely** -- Never expose them in logs, URLs, or insecure storage. Use HTTPS for all requests.
- **Report suspicious challenges** -- If authentication fails with `ContractChallengeValidationErrorSubInvocationsFound`, the anchor may be compromised. Do not sign and report the issue.
- **Nonce validation** -- The SDK automatically validates nonce consistency across all authorization entries for replay protection.
- **Network passphrase validation** -- The SDK verifies that the network passphrase in the challenge matches your configured network, preventing cross-network replay attacks.

The SDK automatically validates challenges (contract address, server signature, function name, network passphrase, nonce consistency) and throws specific exceptions if anything looks wrong.

## Using the JWT token

Once authenticated, include the JWT token in the `Authorization` header when making requests to protected SEP services.

```dart
import 'package:http/http.dart' as http;

final jwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
final client = http.Client();

// Use token with SEP-24 deposit
final depositResponse = await client.post(
  Uri.parse('https://anchor.example.com/sep24/transactions/deposit/interactive'),
  headers: {'Authorization': 'Bearer $jwtToken'},
  body: {'asset_code': 'USDC'},
);

// Use token with SEP-12 KYC
final kycResponse = await client.get(
  Uri.parse('https://anchor.example.com/kyc/customer'),
  headers: {'Authorization': 'Bearer $jwtToken'},
);

client.close();
```

## Network support

The SDK supports both testnet and public (mainnet) networks. Use the appropriate network constant when creating the service.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Testnet
final webAuthTestnet = await WebAuthForContracts.fromDomain('testnet.anchor.com', Network.TESTNET);

// Public network (mainnet)
final webAuthPubnet = await WebAuthForContracts.fromDomain('anchor.com', Network.PUBLIC);
```

## Reference contracts

Your contract account must implement `__check_auth` to define authorization rules. The Stellar Anchor Platform provides a reference implementation:

- [Account Contract](https://github.com/stellar/anchor-platform/tree/main/soroban/contracts/account) - Sample contract with Ed25519 signature verification in `__check_auth`

**Server-side web auth contract:** Anchors deploy a web auth contract at `WEB_AUTH_CONTRACT_ID`. The reference implementation is deployed on pubnet at `CALI6JC3MSNDGFRP7Z2OKUEPREHOJRRXKMJEWQDEFZPFGXALA45RAUTH`.

## Related SEPs

- [SEP-10](sep-10.md) - Authentication for traditional accounts (G... addresses)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal
- [SEP-12](sep-12.md) - KYC API
- [SEP-38](sep-38.md) - Quotes API

## Reference

- [SEP-45 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md)
- [Stellar Flutter SDK](https://github.com/Soneso/stellar_flutter_sdk)

---

[Back to SEP Overview](README.md)
