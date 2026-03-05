# [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk)

![Dart](https://img.shields.io/badge/Dart-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-blue.svg)
[![codecov](https://codecov.io/gh/Soneso/stellar_flutter_sdk/branch/master/graph/badge.svg)](https://codecov.io/gh/Soneso/stellar_flutter_sdk)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Soneso/stellar_flutter_sdk)

Build and sign Stellar transactions, query [Horizon](https://developers.stellar.org/docs/data/apis/horizon), and interact with [Soroban](https://developers.stellar.org/docs/build/smart-contracts/overview) smart contracts via RPC. Communicate with anchors and external services using built-in support for 17 SEPs.

## Installation

```yaml
dependencies:
  stellar_flutter_sdk: ^3.0.2
```

```bash
flutter pub get
```

Requires Dart SDK >=3.8.0 <4.0.0.

## Quick examples

### Send a payment

Transfer XLM between accounts:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(PaymentOperationBuilder(receiverId, Asset.NATIVE, '100').build())
    .build();
transaction.sign(senderKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
```

### Trust an asset

Enable your account to receive a token (like USDC):

```dart
Asset usdc = Asset.createNonNativeAsset('USDC', issuerAccountId);
Transaction transaction = TransactionBuilder(account)
    .addOperation(ChangeTrustOperationBuilder(usdc, ChangeTrustOperationBuilder.MAX_LIMIT).build())
    .build();
transaction.sign(accountKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
```

### Call a smart contract

Invoke a Soroban contract method:

```dart
SorobanClient client = await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CABC...',
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org',
    ),
);
XdrSCVal result = await client.invokeMethod(name: 'hello', args: [XdrSCVal.forSymbol('World')]);
```

For complete walkthroughs, see the [documentation](documentation/).

## Agent Skill

This repository includes an [Agent Skill](https://agentskills.io) that teaches AI coding agents how to use this SDK. See [skills/](skills/) for installation instructions.

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick start](documentation/quick-start.md) | Your first transaction in 15 minutes |
| [Getting started](documentation/getting-started.md) | Keys, accounts, and fundamentals |
| [SDK usage](documentation/sdk-usage.md) | Transactions, operations, Horizon queries, streaming |
| [Soroban](documentation/soroban.md) | Smart contract deployment and interaction |
| [SEPs](documentation/sep/) | Anchor integration, authentication, KYC, etc. |

## Web Support

Starting with version 3.0.0, this SDK fully supports Flutter web. All 64-bit integer types have been migrated to BigInt to address JavaScript's 53-bit number precision limitation.

If you are upgrading from version 2.x, please refer to the [Migration Guide](v3_migration_guide.md) for details on breaking changes and how to update your code.

## Compatibility

- [Horizon API compatibility matrix](compatibility/horizon/HORIZON_COMPATIBILITY_MATRIX.md)
- [RPC API compatibility matrix](compatibility/rpc/RPC_COMPATIBILITY_MATRIX.md)
- [SEP support matrices](compatibility/sep/)


## Feedback

If you're using this SDK, feedback helps improve it:

- [Report a bug](https://github.com/Soneso/stellar_flutter_sdk/issues/new?template=bug_report.yml)
- [Request a feature](https://github.com/Soneso/stellar_flutter_sdk/issues/new?template=feature_request.yml)
- [Start a discussion](https://github.com/Soneso/stellar_flutter_sdk/discussions)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
