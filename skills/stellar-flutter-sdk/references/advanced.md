# Advanced Features

Less common but important patterns. All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

- [Multi-Signature Accounts](#multi-signature-accounts)
- [Fee-Bump Transactions](#fee-bump-transactions)
- [Sponsored Reserves](#sponsored-reserves)
- [Liquidity Pools](#liquidity-pools)
- [Muxed Accounts](#muxed-accounts)
- [Async Transaction Submission](#async-transaction-submission)
- [Manual Sequence Numbers](#manual-sequence-numbers)

## Multi-Signature Accounts

**IMPORTANT:** Always add signers and set thresholds in a SINGLE transaction. Setting thresholds first in a separate transaction may lock you out if the new thresholds require signatures you haven't added yet.

```dart
// From your app: destination (String), primarySecretSeed (String)
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

KeyPair primaryKeyPair = KeyPair.fromSecretSeed(primarySecretSeed); // S... seed of the account, from secure storage
KeyPair secondaryKeyPair = KeyPair.random();
String primaryId = primaryKeyPair.accountId;

AccountResponse account = await sdk.accounts.account(primaryId);
// The thresholds set here count on two signers: the master key and the new key.
// Any other signer would keep its weight against them, so this setup stops.
if (account.signers.any((s) => s.key != primaryId)) {
  throw StateError('The account has other signers; plan its thresholds separately');
}

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
// From the section Multi-Signature Accounts: account (AccountResponse), sdk (StellarSDK)
// From your app: destination (String), signerAKeyPair (KeyPair), signerBKeyPair (KeyPair), signerBApproves (function, shows the transaction to signer B and returns the decision)
// Signer A: Build and share unsigned XDR
Transaction tx = TransactionBuilder(account)
    .addOperation(
      PaymentOperationBuilder(destination, Asset.NATIVE, '100.0').build(),
    )
    .build();
String unsignedXdr = tx.toEnvelopeXdrBase64();
// Send unsignedXdr to Signer B

// Signer B: Decode, decide (see xdr.md for the fields), sign, return
AbstractTransaction received =
    AbstractTransaction.fromEnvelopeXdrString(unsignedXdr);
if (!await signerBApproves(received)) {
  throw StateError('Signer B declined the transaction');
}
received.sign(signerBKeyPair, Network.TESTNET);
String partiallySigned = received.toEnvelopeXdrBase64();

// Signer A: Sign only the transaction A built; a signature leaves its hash unchanged
AbstractTransaction withBSig =
    AbstractTransaction.fromEnvelopeXdrString(partiallySigned);
if (Util.bytesToHex(withBSig.hash(Network.TESTNET)) !=
    Util.bytesToHex(tx.hash(Network.TESTNET))) {
  throw StateError('The returned transaction differs from the one signer A built');
}
withBSig.sign(signerAKeyPair, Network.TESTNET);
SubmitTransactionResponse response =
    await sdk.submitTransactionEnvelopeXdrBase64(withBSig.toEnvelopeXdrBase64());
```

## Fee-Bump Transactions

Build the inner transaction with a low fee using `setMaxOperationFee`, then wrap it:

```dart
// From your app: destination (String), feePayerKeyPair (KeyPair), innerAccountId (String), innerKeyPair (KeyPair)
// From the section Multi-Signature Accounts: network (Network), sdk (StellarSDK)
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

KeyPair sponsorKeyPair = KeyPair.random(); // testnet sponsor, funded below
await FriendBot.fundTestAccount(sponsorKeyPair.accountId);
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
// From the section Multi-Signature Accounts: sdk (StellarSDK)
// From your app: sponsorId (String)
AccountResponse sponsor = await sdk.accounts.account(sponsorId);
int sponsoring = sponsor.numSponsoring; // reserves this account sponsors for others
int sponsored = sponsor.numSponsored;   // reserves others sponsor for this account
```

## Liquidity Pools

```dart
// From your app: issuerAccountId (String), secretSeed (String)
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

KeyPair keyPair = KeyPair.fromSecretSeed(secretSeed); // S... seed of an account with a USDC trustline, from secure storage
Asset assetA = Asset.NATIVE;
Asset assetB = Asset.createNonNativeAsset('USDC', issuerAccountId); // issuerAccountId: the USDC issuer's G... id

// Step 1: Establish trustline to the pool share asset
AssetTypePoolShare poolShareAsset = AssetTypePoolShare(assetA: assetA, assetB: assetB);

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
// The pool exists once a trustline to its share exists; Horizon returns its id
Page<LiquidityPoolResponse> pools =
    await sdk.liquidityPools.forReserveAssets(assetA, assetB).execute();
String poolId = pools.records.first.poolId;

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
String baseAccountId = KeyPair.random().accountId; // the G... account behind the muxed address
MuxedAccount muxed = MuxedAccount(baseAccountId, BigInt.from(12345)); // id: unsigned 64-bit BigInt
print('Muxed ID: ${muxed.accountId}');    // M... address
print('Base account: ${muxed.ed25519AccountId}');
print('Sub ID: ${muxed.id}');

// Use in payment operation (source account override)
PaymentOperationBuilder paymentBuilder =
    PaymentOperationBuilder(KeyPair.random().accountId, Asset.NATIVE, '10.0'); // any G... destination
paymentBuilder.setMuxedSourceAccount(muxed);
Operation payment = paymentBuilder.build();
```

## Async Transaction Submission

Submit without waiting for ingestion (returns immediately):

```dart
// From the section Multi-Signature Accounts: sdk (StellarSDK)
// From your app: transaction (Transaction)
SubmitAsyncTransactionResponse asyncResponse =
    await sdk.submitAsyncTransaction(transaction);

print('Hash: ${asyncResponse.hash}');
print('Status: ${asyncResponse.txStatus}');
// Possible statuses: txStatusPending, txStatusDuplicate, txStatusTryAgainLater, txStatusError
// Final result later: sdk.transactions.transaction(asyncResponse.hash), a bounded number
// of tries while Horizon answers 404 (not yet ingested)
```

## Manual Sequence Numbers

`TransactionBuilder.build()` mutates the source account's sequence number. A good practice is to reload the account from Horizon before building a new transaction. Don't increment manually unless you have a specific reason. `build()` handles it. Stale sequence numbers cause `tx_bad_seq` errors.

```dart
// From your app: accountId (String), op (Operation)
// From the section Multi-Signature Accounts: sdk (StellarSDK)
// CORRECT: reload account, build() increments sequence internally
AccountResponse account = await sdk.accounts.account(accountId); // on-chain seq N
Transaction tx = TransactionBuilder(account).addOperation(op).build(); // uses seq N+1
await sdk.submitTransaction(tx);

// WRONG: manually incrementing, build() already does this
AccountResponse account = await sdk.accounts.account(accountId); // on-chain seq N
account.incrementSequenceNumber(); // now N+1
Transaction tx = TransactionBuilder(account).addOperation(op).build(); // seq N+2: tx_bad_seq
```

`TransactionBuilder.build()` reads the source account's sequence number, puts that value plus one in the transaction, then advances the account object — never increment manually for a normal submission. For a transaction that must carry a specific future sequence (e.g., pre-authorized transactions), construct the `Account` with one less than the sequence you want the transaction to carry:

```dart
StellarSDK sdk = StellarSDK.TESTNET;
String accountId = KeyPair.random().accountId; // testnet source account, funded below
await FriendBot.fundTestAccount(accountId);
String destinationId = KeyPair.random().accountId; // whatever the transaction does
Operation op = PaymentOperationBuilder(destinationId, Asset.NATIVE, '10').build();

AccountResponse account = await sdk.accounts.account(accountId); // on-chain seq N
BigInt target = account.sequenceNumber + BigInt.from(5); // sequence the tx must carry
Account synthetic = Account(account.accountId, target - BigInt.one);
Transaction tx = TransactionBuilder(synthetic).addOperation(op).build(); // carries target
```
