# Advanced Features

Less common but important patterns. All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## Multi-Signature Accounts

**IMPORTANT:** Always add signers and set thresholds in a SINGLE transaction. Setting thresholds first in a separate transaction may lock you out if the new thresholds require signatures you haven't added yet.

```dart
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

KeyPair primaryKeyPair = KeyPair.fromSecretSeed('SXXXXX...');
KeyPair secondaryKeyPair = KeyPair.random();
String primaryId = primaryKeyPair.accountId;

AccountResponse account = await sdk.accounts.account(primaryId);

// Add signer + set thresholds in ONE transaction
XdrSignerKey signerKey =
    KeyPair.fromAccountId(secondaryKeyPair.accountId).xdrSignerKey;

Transaction tx = TransactionBuilder(account)
    .addOperation(SetOptionsOperationBuilder()
        .setSigner(signerKey, 1)
        .setMasterKeyWeight(1)
        .setLowThreshold(1)
        .setMediumThreshold(2)  // payments require 2 signers
        .setHighThreshold(2)
        .build())
    .build();

tx.sign(primaryKeyPair, network);
SubmitTransactionResponse response = await sdk.submitTransaction(tx);
print('Multi-sig configured: ${response.success}');

// Verify signers
AccountResponse updated = await sdk.accounts.account(primaryId);
for (Signer signer in updated.signers) {
  print('Signer: ${signer.key} weight: ${signer.weight}');
}

// Multi-sig payment (requires 2 signatures to meet medium threshold)
AccountResponse sourceAccount = await sdk.accounts.account(primaryId);
Transaction paymentTx = TransactionBuilder(sourceAccount)
    .addOperation(
      PaymentOperationBuilder(destination, Asset.NATIVE, '50.0').build(),
    )
    .build();

// Both signers sign the same transaction
paymentTx.sign(primaryKeyPair, network);
paymentTx.sign(secondaryKeyPair, network);

SubmitTransactionResponse payResponse = await sdk.submitTransaction(paymentTx);
print('Multi-sig tx hash: ${payResponse.hash}');
```

### Multi-Sig XDR Sharing (Remote Signers)

When co-signers are on different machines, use XDR serialization to pass the transaction:

```dart
// Signer A: Build and share unsigned XDR
Transaction tx = TransactionBuilder(account)
    .addOperation(
      PaymentOperationBuilder(destination, Asset.NATIVE, '100.0').build(),
    )
    .build();
String unsignedXdr = tx.toEnvelopeXdrBase64();
// Send unsignedXdr to Signer B

// Signer B: Decode, inspect (see xdr.md), sign, return
AbstractTransaction received =
    AbstractTransaction.fromEnvelopeXdrString(unsignedXdr);
received.sign(signerBKeyPair, Network.TESTNET);
String partiallySigned = received.toEnvelopeXdrBase64();

// Signer A: Add final signature and submit
AbstractTransaction withBSig =
    AbstractTransaction.fromEnvelopeXdrString(partiallySigned);
withBSig.sign(signerAKeyPair, Network.TESTNET);
SubmitTransactionResponse response =
    await sdk.submitTransactionEnvelopeXdrBase64(withBSig.toEnvelopeXdrBase64());
```

## Fee-Bump Transactions

Build the inner transaction with a low fee using `setMaxOperationFee`, then wrap it:

```dart
// Step 1: Build inner transaction with low fee
AccountResponse innerSource = await sdk.accounts.account(innerAccountId);
Transaction innerTx = TransactionBuilder(innerSource)
    .addOperation(
      PaymentOperationBuilder(destination, Asset.NATIVE, '10.0').build(),
    )
    .setMaxOperationFee(100) // low fee: 100 stroops per operation
    .build();
innerTx.sign(innerKeyPair, network);

// Step 2: Wrap in fee bump with higher fee
// IMPORTANT: Use setBaseFee on FeeBumpTransactionBuilder (NOT TransactionBuilder)
// Use setMaxOperationFee on TransactionBuilder for regular transactions
FeeBumpTransaction feeBump = FeeBumpTransactionBuilder(innerTx)
    .setBaseFee(1000) // higher fee per operation
    .setFeeAccount(feePayerKeyPair.accountId)
    .build();

feeBump.sign(feePayerKeyPair, network);

SubmitTransactionResponse response =
    await sdk.submitFeeBumpTransaction(feeBump);
print('Fee bump success: ${response.success}');
```

## Sponsored Reserves

```dart
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

KeyPair sponsorKeyPair = KeyPair.fromSecretSeed('SXXXXX...');
KeyPair sponsoredKeyPair = KeyPair.random();

AccountResponse sponsorAccount =
    await sdk.accounts.account(sponsorKeyPair.accountId);

// Sponsor creation of a new account (sandwich pattern)
Transaction tx = TransactionBuilder(sponsorAccount)
    .addOperation(
      BeginSponsoringFutureReservesOperationBuilder(sponsoredKeyPair.accountId)
          .build(),
    )
    .addOperation(
      CreateAccountOperationBuilder(sponsoredKeyPair.accountId, '0').build(),
    )
    .addOperation(
      EndSponsoringFutureReservesOperationBuilder()
          .setSourceAccount(sponsoredKeyPair.accountId)
          .build(),
    )
    .build();

// Both parties must sign
tx.sign(sponsorKeyPair, network);
tx.sign(sponsoredKeyPair, network);

SubmitTransactionResponse response = await sdk.submitTransaction(tx);
print('Sponsorship success: ${response.success}');

// Verify sponsorship
AccountResponse sponsoredAccount =
    await sdk.accounts.account(sponsoredKeyPair.accountId);
print('Sponsored account exists with 0 XLM (reserves are sponsored)');
```

To check sponsorship counts after the sponsoring transaction:

```dart
AccountResponse sponsor = await sdk.accounts.account(sponsorId);
int sponsoring = sponsor.numSponsoring; // reserves this account sponsors for others
int sponsored = sponsor.numSponsored;   // reserves others sponsor for this account
```

## Liquidity Pools

```dart
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

KeyPair keyPair = KeyPair.fromSecretSeed('SXXXXX...');
Asset assetA = Asset.NATIVE;
Asset assetB = Asset.createNonNativeAsset('USDC', issuerAccountId);

// Step 1: Establish trustline to the pool share asset
AssetTypePoolShare poolShareAsset = AssetTypePoolShare();
poolShareAsset.assetA = assetA;
poolShareAsset.assetB = assetB;

AccountResponse account = await sdk.accounts.account(keyPair.accountId);
Transaction trustTx = TransactionBuilder(account)
    .addOperation(
      ChangeTrustOperationBuilder(poolShareAsset,
          ChangeTrustOperationBuilder.MAX_LIMIT).build(),
    )
    .build();

trustTx.sign(keyPair, network);
await sdk.submitTransaction(trustTx);

// Step 2: Deposit into the pool
account = await sdk.accounts.account(keyPair.accountId); // refresh sequence
String poolId = poolShareAsset.poolId; // compute pool ID from asset pair

Transaction depositTx = TransactionBuilder(account)
    .addOperation(
      LiquidityPoolDepositOperationBuilder(
        liquidityPoolId: poolId,
        maxAmountA: '100.0',
        maxAmountB: '100.0',
        minPrice: '0.5',
        maxPrice: '2.0',
      ).build(),
    )
    .build();

depositTx.sign(keyPair, network);
SubmitTransactionResponse response = await sdk.submitTransaction(depositTx);
print('Deposited to pool: $poolId');
```

## Muxed Accounts

```dart
// Create a muxed account (virtual sub-account under a G... account)
// v3.0.0: id parameter is BigInt
MuxedAccount muxed = MuxedAccount('GABC...', BigInt.from(12345));
print('Muxed ID: ${muxed.accountId}');    // M... address
print('Base account: ${muxed.ed25519AccountId}');
print('Sub ID: ${muxed.id}');

// Use in payment operation (source account override)
PaymentOperationBuilder paymentBuilder =
    PaymentOperationBuilder('GDESTINATION...', Asset.NATIVE, '10.0');
paymentBuilder.setMuxedSourceAccount(muxed);
Operation payment = paymentBuilder.build();
```

## Async Transaction Submission

Submit without waiting for ingestion (returns immediately):

```dart
SubmitAsyncTransactionResponse asyncResponse =
    await sdk.submitAsyncTransaction(transaction);

print('Hash: ${asyncResponse.hash}');
print('Status: ${asyncResponse.txStatus}');
// Possible statuses: txStatusPending, txStatusDuplicate, txStatusTryAgainLater, txStatusError
// Poll getTransaction() later to check final result
```
