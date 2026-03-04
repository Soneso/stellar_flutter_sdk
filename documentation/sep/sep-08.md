# SEP-08: Regulated Assets

SEP-08 defines a protocol for assets that require issuer approval for every transaction. These "regulated assets" enable compliance with securities laws, KYC/AML requirements, velocity limits, and jurisdiction-based restrictions.

**Use SEP-08 when:**
- Transacting with assets marked as `regulated=true` in stellar.toml
- Working with securities tokens or compliance-controlled assets
- Building wallets that support regulated asset transfers

**How it works:** Before submitting a transaction involving a regulated asset to the Stellar network, you must first submit it to the issuer's approval server. The server evaluates the transaction against compliance rules and, if approved, signs it with the issuer's key.

**Spec:** [SEP-0008 v1.7.4](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md)

## Quick example

This example shows the basic flow: discovering a regulated asset and submitting a transaction for approval:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create service from anchor domain - loads stellar.toml automatically
final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');

// Get regulated assets defined in stellar.toml
final regulatedAssets = service.regulatedAssets;
print('Found ${regulatedAssets.length} regulated asset(s)');

// Submit a transaction for approval
String signedTxXdr = 'AAAAAgAAAA...'; // Your signed transaction as base64 XDR
final response = await service.postTransaction(
  signedTxXdr,
  regulatedAssets.first.approvalServer,
);

if (response is PostTransactionSuccess) {
  print('Approved! Submit this transaction: ${response.tx}');
} else if (response is PostTransactionRejected) {
  print('Rejected: ${response.error}');
}
```

## How regulated assets work

Per SEP-08, regulated assets require a specific setup and workflow:

1. **Issuer flags**: Asset issuer account has `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags set. This allows the issuer to grant and revoke transaction authorization atomically.
2. **stellar.toml discovery**: The issuer's stellar.toml (SEP-01) defines the asset as `regulated=true` and specifies an `approval_server` URL.
3. **Transaction composition**: Transactions are structured with operations that authorize accounts, perform the transfer, and deauthorize accounts—all atomically. Wallets can either submit simple payment transactions and let the approval server add the authorization operations (returning a `revised` transaction), or build compliant transactions manually using `SetTrustLineFlags` operations.
4. **Approval flow**: Wallet submits the signed transaction to the approval server (not the Stellar network). Note that approval servers must support CORS to allow browser-based wallets to interact with them directly.
5. **Compliance check**: The server evaluates the transaction against its regulatory rules.
6. **Signing**: If approved, the server signs and returns the transaction.
7. **Network submission**: Wallet submits the fully-signed transaction to the Stellar network.

## Creating the service

### From domain

Load stellar.toml from the issuer's domain and extract all regulated asset definitions:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Loads stellar.toml and extracts regulated assets
final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');

// Access discovered regulated assets
for (final asset in service.regulatedAssets) {
  print('${asset.code} issued by ${asset.issuerId}');
}
```

### From StellarToml data

If you've already loaded the stellar.toml data, pass it directly to the constructor. The stellar.toml must contain a `NETWORK_PASSPHRASE` field:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml toml = await StellarToml.fromDomain('regulated-asset-issuer.com');
final service = RegulatedAssetsService(toml);
```

### With custom HTTP client

You can provide a custom `http.Client` for approval server requests. Useful for testing, proxying, or custom timeout configuration:

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final httpClient = http.Client();

final service = await RegulatedAssetsService.fromDomain(
  'regulated-asset-issuer.com',
  httpClient: httpClient,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

### Service properties

After initialization, the service exposes these properties:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');

// List of RegulatedAsset objects discovered from stellar.toml
final assets = service.regulatedAssets;

// The StellarToml data used to initialize the service
final tomlData = service.tomlData;

// The configured StellarSDK instance (for Horizon requests)
final sdk = service.sdk;

// The network (used for transaction signing context)
final network = service.network;
```

## Discovering regulated assets

The `RegulatedAsset` class extends `AssetTypeCreditAlphaNum`, so it can be used wherever a standard asset is expected. It adds approval server information required for the compliance workflow:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');

for (final asset in service.regulatedAssets) {
  // Standard asset properties (inherited from AssetTypeCreditAlphaNum)
  print('Asset: ${asset.code}');
  print('Issuer: ${asset.issuerId}');
  print('Type: ${asset.type}');  // credit_alphanum4 or credit_alphanum12

  // SEP-08 specific properties
  print('Approval server: ${asset.approvalServer}');

  if (asset.approvalCriteria != null) {
    print('Criteria: ${asset.approvalCriteria}');
  }
}
```

## Checking authorization requirements

Before transacting, verify the issuer account has proper authorization flags set. Per SEP-08, regulated asset issuers must have both `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags enabled:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final asset = service.regulatedAssets.first;

// Checks that issuer has AUTH_REQUIRED and AUTH_REVOCABLE flags
try {
  final needsApproval = await service.authorizationRequired(asset);

  if (needsApproval) {
    print('Asset requires approval server for all transactions');
  } else {
    print('Warning: Issuer flags not properly configured for regulated assets');
  }
} on IssuerAccountNotFound catch (e) {
  print('Issuer account not found: $e');
}
```

## Building a transaction for approval

Create and sign your transaction normally, then submit the base64-encoded XDR to the approval server:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final sdk = StellarSDK.TESTNET;
final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final regulatedAsset = service.regulatedAssets.first;

// Sender's keypair
final senderKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG...');
final senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

// Build the payment transaction using the regulated asset
final payment = PaymentOperationBuilder(
  'GDEST...',
  regulatedAsset,
  '100',
).build();

final transaction = TransactionBuilder(senderAccount)
    .addOperation(payment)
    .build();

// Sign with sender's key
transaction.sign(senderKeyPair, Network.TESTNET);

// Convert to base64 XDR for submission to approval server
final txXdr = transaction.toEnvelopeXdrBase64();
final response = await service.postTransaction(
  txXdr,
  regulatedAsset.approvalServer,
);
```

### Multiple regulated assets

When a transaction involves multiple regulated assets from different issuers (e.g., a path payment through several assets), each issuer's approval server must sign the transaction. Submit the transaction to each approval server sequentially, using the signed output from one server as input to the next. All issuers must approve before the transaction can be submitted to the Stellar network.

## Handling approval responses

The approval server returns one of five response types. Use `is` checks to determine the response type and handle it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final response = await service.postTransaction(txXdr, approvalServer);

if (response is PostTransactionSuccess) {
  // Transaction approved and signed by issuer - submit to network
  print('Approved!');
  if (response.message != null) {
    print('Message: ${response.message}');
  }
  final sdk = StellarSDK.TESTNET;
  final result = await sdk.submitTransactionEnvelopeXdrBase64(response.tx);

} else if (response is PostTransactionRevised) {
  // Transaction was modified for compliance - REVIEW CAREFULLY before submitting
  print('Revised for compliance: ${response.message}');
  // WARNING: Always inspect the revised transaction to ensure it matches your intent
  // The issuer may have added operations (fees, compliance ops) but should not change
  // the core intent of your transaction

} else if (response is PostTransactionPending) {
  // Approval pending - retry after the timeout period
  // Note: timeout is in MILLISECONDS per SEP-08 spec
  final timeoutMs = response.timeout;
  print('Pending. Check again in ${timeoutMs / 1000} seconds');
  if (response.message != null) {
    print('Message: ${response.message}');
  }

} else if (response is PostTransactionActionRequired) {
  // User action needed - see "Handling Action Required" section
  print('Action required: ${response.message}');
  print('Action URL: ${response.actionUrl}');

} else if (response is PostTransactionRejected) {
  // Transaction rejected - cannot be made compliant
  print('Rejected: ${response.error}');
}
```

### Response types reference

| Response Class | Status | HTTP Code | Meaning |
|---------------|--------|-----------|---------|
| `PostTransactionSuccess` | `success` | 200 | Approved and signed—submit to network |
| `PostTransactionRevised` | `revised` | 200 | Modified for compliance—review before submitting |
| `PostTransactionPending` | `pending` | 200 | Check back after `timeout` milliseconds |
| `PostTransactionActionRequired` | `action_required` | 200 | User must complete action at URL |
| `PostTransactionRejected` | `rejected` | 400 | Denied—see error message |

## Handling action required

When the approval server needs additional information (KYC data, terms acceptance, etc.), it returns an `action_required` status. The SDK supports both GET and POST action methods:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final response = await service.postTransaction(txXdr, approvalServer);

if (response is PostTransactionActionRequired) {
  print('Action needed: ${response.message}');

  // Check what SEP-9 KYC fields are requested
  if (response.actionFields != null) {
    print('Requested fields:');
    for (final field in response.actionFields!) {
      print('  - $field');
    }
  }

  // Handle based on action method (GET or POST)
  if (response.actionMethod == 'POST') {
    // Submit fields programmatically if you have them
    final actionResponse = await service.postAction(
      response.actionUrl,
      {
        'email_address': 'user@example.com',
        'mobile_number': '+1234567890',
      },
    );

    if (actionResponse is PostActionDone) {
      // Action complete - resubmit the original transaction
      print('Action complete. Resubmitting transaction...');
      final retryResponse = await service.postTransaction(txXdr, approvalServer);

    } else if (actionResponse is PostActionNextUrl) {
      // More steps needed - user must complete action in browser
      print('Further action required at: ${actionResponse.nextUrl}');
      if (actionResponse.message != null) {
        print('Message: ${actionResponse.message}');
      }
    }
  } else {
    // action_method is GET (or not specified) - open URL in browser
    // You can append action fields as query parameters
    print('Open in browser: ${response.actionUrl}');
  }
}
```

## Complete workflow example

This example shows the full approval flow for a regulated asset transfer, including all response type handling:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Setup
final sdk = StellarSDK.TESTNET;
final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
final regulatedAsset = service.regulatedAssets.first;

final senderKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG...');
String recipientId = 'GDESTINATION...';

// Verify asset requires approval (issuer has proper flags)
try {
  final authRequired = await service.authorizationRequired(regulatedAsset);
  if (!authRequired) {
    throw Exception('Asset issuer not properly configured for regulation');
  }
} on IssuerAccountNotFound catch (e) {
  throw Exception('Issuer account not found: $e');
}

// Build transaction
final senderAccount = await sdk.accounts.account(senderKeyPair.accountId);

final transaction = TransactionBuilder(senderAccount)
    .addOperation(
      PaymentOperationBuilder(recipientId, regulatedAsset, '100').build(),
    )
    .build();

transaction.sign(senderKeyPair, Network.TESTNET);
final txXdr = transaction.toEnvelopeXdrBase64();

// Submit for approval
final response = await service.postTransaction(txXdr, regulatedAsset.approvalServer);

// Handle response
String? approvedTx;

if (response is PostTransactionSuccess) {
  approvedTx = response.tx;

} else if (response is PostTransactionRevised) {
  // IMPORTANT: Review revised transaction before accepting
  // The message should explain what was modified
  print('Transaction revised: ${response.message}');
  approvedTx = response.tx;

} else if (response is PostTransactionPending) {
  // Timeout is in milliseconds
  final waitSeconds = response.timeout / 1000;
  print('Try again in $waitSeconds seconds');

} else if (response is PostTransactionActionRequired) {
  print('User action needed at: ${response.actionUrl}');

} else if (response is PostTransactionRejected) {
  throw Exception('Transaction rejected: ${response.error}');
}

// Submit approved transaction to Stellar network
if (approvedTx != null) {
  final result = await sdk.submitTransactionEnvelopeXdrBase64(approvedTx);
  if (result.success) {
    print('Transaction submitted: ${result.hash}');
  }
}
```

## Error handling

The SDK throws specific exceptions for different error conditions:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  final service = await RegulatedAssetsService.fromDomain('regulated-asset-issuer.com');
  final response = await service.postTransaction(txXdr, approvalServer);

} on IncompleteInitData catch (e) {
  // stellar.toml is missing required NETWORK_PASSPHRASE or HORIZON_URL
  // and the SDK couldn't determine them from other sources
  print('stellar.toml incomplete: $e');

} on UnknownPostTransactionResponse catch (e) {
  // Approval server returned unexpected HTTP response
  // e.code contains HTTP status, e.body contains response body
  print('Invalid response from approval server: ${e.body}');
  print('HTTP status: ${e.code}');

} on UnknownPostTransactionResponseStatus catch (e) {
  // Approval server returned an unknown status value
  print('Unknown approval status: $e');

} on UnknownPostActionResponse catch (e) {
  // Action endpoint returned unexpected HTTP response
  print('Invalid action response (HTTP ${e.code}): ${e.body}');

} on UnknownPostActionResponseResult catch (e) {
  // Action endpoint returned unknown result value
  print('Unknown action result: $e');

} on IssuerAccountNotFound catch (e) {
  // Failed to load issuer account (for authorizationRequired check)
  print('Issuer not found: $e');

} catch (e) {
  // stellar.toml loading failed, network error, or other unexpected error
  print('Error: $e');
}
```

### Exception reference

| Exception | When Thrown |
|-----------|-------------|
| `IncompleteInitData` | Service can't determine network passphrase or Horizon URL |
| `UnknownPostTransactionResponse` | Approval server HTTP response is unexpected (not 200 or 400 with error) |
| `UnknownPostTransactionResponseStatus` | Approval server returned an unknown `status` value |
| `UnknownPostActionResponse` | Action URL HTTP response is unexpected (not 200) |
| `UnknownPostActionResponseResult` | Action URL returned an unknown `result` value |
| `IssuerAccountNotFound` | Issuer account does not exist on the Stellar network |

## Security considerations

### Reviewing revised transactions

When you receive a `revised` response, **always inspect the transaction before submitting**. Per SEP-08, the approval server should only add operations (like authorization ops), not modify your original operations' intent. However, malicious servers could attempt to:

- Add operations that spend funds from your account
- Change payment destinations or amounts
- Add unexpected fees

Best practice: Compare the revised transaction with your original to ensure only expected operations were added.

### Authorization flags

The `AUTH_REQUIRED` and `AUTH_REVOCABLE` flags on the issuer account are required for security. They ensure:
- No one can transact the asset without explicit authorization
- Authorization can be revoked if compliance issues arise
- Transactions are atomic (authorize -> transact -> deauthorize happens together)

## Related SEPs

- [SEP-01](sep-01.md) - stellar.toml (defines regulated assets with `regulated`, `approval_server`, `approval_criteria`)
- [SEP-09](sep-09.md) - Standard KYC fields (used in `action_required` flows)
- [SEP-10](sep-10.md) - Web authentication (approval servers may require this for identity verification)

---

[Back to SEP Overview](README.md)
