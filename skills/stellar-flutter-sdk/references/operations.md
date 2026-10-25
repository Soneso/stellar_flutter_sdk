# Stellar Operations Reference

All operations use the builder pattern: `*OperationBuilder(...).build()`. Every builder supports `.setSourceAccount(accountId)` and `.setMuxedSourceAccount(muxedAccount)` for setting a custom source. All code assumes the standard SDK import.

## Account & Payment Operations

### CreateAccountOperation

Creates and funds a new account on the network.

```dart
// From your app: destinationAccountId (String), startingBalance (String)
CreateAccountOperationBuilder(destinationAccountId, startingBalance);
```

- `destinationAccountId` (String): G... account ID to create
- `startingBalance` (String): Amount in XLM (minimum 1 XLM for base reserve)

```dart
var newKeyPair = KeyPair.random();
var createOp = CreateAccountOperationBuilder(
  newKeyPair.accountId,
  '10.0',
).build();
```

### PaymentOperation

Sends an asset to an existing account.

```dart
// From your app: amount (String), asset (Asset), destinationAccountId (String)
PaymentOperationBuilder(destinationAccountId, asset, amount);
```

- `destinationAccountId` (String): G... or M... recipient
- `asset` (Asset): `Asset.NATIVE` or `AssetTypeCreditAlphaNum4`/`12`
- `amount` (String): Decimal amount to send

```dart
// From your app: issuerAccountId (String), recipientId (String)
// Send XLM
var payXlm = PaymentOperationBuilder(
  recipientId,
  Asset.NATIVE,
  '100.0',
).build();

// Send custom asset
var usd = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
var payUsd = PaymentOperationBuilder(recipientId, usd, '50.0').build();
```

### PathPaymentStrictReceiveOperation

Send payment through a path, guaranteeing the destination receives an exact amount.

```dart
// From your app: destAmount (String), destAsset (Asset), destinationAccountId (String), sendAsset (Asset), sendMax (String)
PathPaymentStrictReceiveOperationBuilder(
  sendAsset, sendMax, destinationAccountId, destAsset, destAmount,
);
```

- `sendAsset` (Asset): Asset to send from source
- `sendMax` (String): Maximum to debit from source
- `destinationAccountId` (String): Recipient account
- `destAsset` (Asset): Asset recipient receives
- `destAmount` (String): Exact amount recipient receives

The path defaults to empty, a direct conversion through one order book or liquidity pool; `setPath()` adds intermediate assets (`sdk.strictReceivePaths` finds them).

```dart
// From your app: intermediateAsset (Asset), recipientId (String)
// From the section PaymentOperation: usd (AssetTypeCreditAlphaNum4)
// Direct conversion: no setPath() needed
var pathOp = PathPaymentStrictReceiveOperationBuilder(
  Asset.NATIVE, '20.0', recipientId, usd, '10.0',
).build();

// Multi-hop: intermediate assets in order
var multiHopOp = PathPaymentStrictReceiveOperationBuilder(
  Asset.NATIVE, '20.0', recipientId, usd, '10.0',
).setPath([intermediateAsset]).build();
```

### PathPaymentStrictSendOperation

Send exact amount from source, recipient gets at least a minimum.

```dart
// From your app: destAsset (Asset), destMin (String), destinationAccountId (String), sendAmount (String), sendAsset (Asset)
PathPaymentStrictSendOperationBuilder(
  sendAsset, sendAmount, destinationAccountId, destAsset, destMin,
);
```

```dart
// From your app: recipientId (String)
// From the section PaymentOperation: usd (AssetTypeCreditAlphaNum4)
var pathSendOp = PathPaymentStrictSendOperationBuilder(
  Asset.NATIVE, '10.0', recipientId, usd, '4.5',
).build(); // direct conversion; setPath([...]) adds intermediate assets
```

### AccountMergeOperation

Merges source account into destination, transferring all XLM.

```dart
// From your app: destinationAccountId (String)
var mergeOp = AccountMergeOperationBuilder(destinationAccountId).build();
```

## DEX Trading Operations

### ManageSellOfferOperation

Creates, updates, or deletes a sell offer on the DEX. Offer ID defaults to `"0"` (new offer).

```dart
// From your app: amount (String), buying (Asset), price (String), selling (Asset)
ManageSellOfferOperationBuilder(selling, buying, amount, price);
```

- `selling` (Asset): Asset to sell
- `buying` (Asset): Asset to buy
- `amount` (String): Amount to sell (`"0"` to delete)
- `price` (String): Price per unit of selling in buying

```dart
// From your app: issuerAccountId (String)
var xlm = Asset.NATIVE;
var usd = AssetTypeCreditAlphaNum4('USD', issuerAccountId);

// Create new sell offer
var sellOp = ManageSellOfferOperationBuilder(usd, xlm, '100.0', '2.5').build();

// Update existing offer
var updateOp = ManageSellOfferOperationBuilder(usd, xlm, '150.0', '2.6')
    .setOfferId('12345')
    .build();

// Cancel offer (amount = 0)
var cancelOp = ManageSellOfferOperationBuilder(usd, xlm, '0', '2.5')
    .setOfferId('12345')
    .build();

// After submitting, get the offer ID by querying account offers:
// Page<OfferResponse> offers = await sdk.offers.forAccount(accountId).execute();
// String offerId = offers.records!.first.id;
```

### ManageBuyOfferOperation

Creates, updates, or deletes a buy offer. Same pattern as sell, but `amount` is the buying amount.

```dart
// From your app: amount (String), buying (Asset), price (String), selling (Asset)
ManageBuyOfferOperationBuilder(selling, buying, amount, price);
```

```dart
// From the section ManageSellOfferOperation: usd (AssetTypeCreditAlphaNum4), xlm (Asset)
var buyOp = ManageBuyOfferOperationBuilder(xlm, usd, '50.0', '0.4').build();
```

### CreatePassiveSellOfferOperation

Creates a passive sell offer that does not take existing offers at the same price.

```dart
// From the section ManageSellOfferOperation: usd (AssetTypeCreditAlphaNum4), xlm (Asset)
var passiveOp = CreatePassiveSellOfferOperationBuilder(
  usd, xlm, '100.0', '2.5',
).build();
```

## Account Configuration Operations

### SetOptionsOperation

Configures account flags, thresholds, signers, and home domain. All settings are optional.

```dart
// From your app: signerAccountId (String)
// Set home domain
var domainOp = SetOptionsOperationBuilder()
    .setHomeDomain('example.com')
    .build();

// Set auth flags (1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK)
var flagsOp = SetOptionsOperationBuilder()
    .setSetFlags(1)  // AUTH_REQUIRED_FLAG
    .build();

// Configure multi-sig thresholds
var thresholdOp = SetOptionsOperationBuilder()
    .setMasterKeyWeight(1)
    .setLowThreshold(1)
    .setMediumThreshold(2)
    .setHighThreshold(2)
    .build();

// Add a signer (XdrSignerKey, weight)
var signerKey = KeyPair.fromAccountId(signerAccountId).xdrSignerKey;
var signerOp = SetOptionsOperationBuilder()
    .setSigner(signerKey, 1)
    .build();

// Remove signer (set weight to 0)
var removeSignerOp = SetOptionsOperationBuilder()
    .setSigner(signerKey, 0)
    .build();
```

**Multi-sig setup must be atomic:** Each `SetOptionsOperation` can set only ONE signer. To add multiple signers and configure thresholds, include all operations in a SINGLE transaction. If you raise thresholds in a separate transaction first, subsequent operations may require more signatures than available, locking you out.

```dart
// From your app: account (AccountResponse), network (Network), primaryKeyPair (KeyPair), signerAKey (XdrSignerKey), signerBKey (XdrSignerKey)
// Correct: add 2 signers + set thresholds in ONE transaction
// The thresholds count on three signers of weight 1: the master key and two
// different new keys. Another signer would change the quorum, and a repeated
// key would leave high threshold 3 out of reach, so this setup stops.
if (account.signers.any((s) => s.key != primaryKeyPair.accountId) ||
    signerAKey.toBase64EncodedXdrString() == signerBKey.toBase64EncodedXdrString()) {
  throw StateError('Unexpected signers; compute the thresholds for this account');
}
var addA = SetOptionsOperationBuilder().setSigner(signerAKey, 1).build();
var addB = SetOptionsOperationBuilder().setSigner(signerBKey, 1).build();
var thresholds = SetOptionsOperationBuilder()
    .setMasterKeyWeight(1)
    .setLowThreshold(1)
    .setMediumThreshold(2)
    .setHighThreshold(3)
    .build();

Transaction tx = TransactionBuilder(account)
    .addOperation(addA)
    .addOperation(addB)
    .addOperation(thresholds)
    .build();
tx.sign(primaryKeyPair, network);
```

### ChangeTrustOperation

Creates, updates, or removes a trustline for non-native assets.

```dart
// From your app: asset (Asset), limit (String)
ChangeTrustOperationBuilder(asset, limit);
```

- `asset` (Asset): The asset to trust
- `limit` (String): Max amount to hold (`"0"` to remove, `ChangeTrustOperationBuilder.MAX_LIMIT` for max)

```dart
// From your app: issuerAccountId (String)
var usd = AssetTypeCreditAlphaNum4('USD', issuerAccountId);

// Create trustline with max limit
var trustOp = ChangeTrustOperationBuilder(
  usd, ChangeTrustOperationBuilder.MAX_LIMIT,
).build();

// Remove trustline (balance must be 0)
var removeTrustOp = ChangeTrustOperationBuilder(usd, '0').build();
```

### AllowTrustOperation (Deprecated)

Use `SetTrustLineFlagsOperation` instead.

```dart
// From your app: assetCode (String), authorized (int), trustorAccountId (String)
AllowTrustOperationBuilder(trustorAccountId, assetCode, authorized);
```

### SetTrustLineFlagsOperation

Sets or clears flags on a trustline. Source must be the asset issuer.

```dart
// From your app: asset (Asset), clearFlags (int), setFlags (int), trustorAccountId (String)
SetTrustLineFlagsOperationBuilder(trustorAccountId, asset, clearFlags, setFlags);
```

- `clearFlags` (int): Flags to clear (1=AUTHORIZED, 2=AUTHORIZED_TO_MAINTAIN_LIABILITIES, 4=CLAWBACK_ENABLED)
- `setFlags` (int): Flags to set

```dart
// From your app: issuerAccountId (String), trustorAccountId (String)
// From the section ChangeTrustOperation: usd (AssetTypeCreditAlphaNum4)
// Authorize a trustline
var authOp = SetTrustLineFlagsOperationBuilder(
  trustorAccountId, usd, 0, 1,
).setSourceAccount(issuerAccountId).build();

// Freeze: allow maintaining liabilities only
var freezeOp = SetTrustLineFlagsOperationBuilder(
  trustorAccountId, usd, 1, 2,
).setSourceAccount(issuerAccountId).build();
```

### ManageDataOperation

Sets, updates, or deletes key-value data on an account.

```dart
import 'dart:typed_data';

// From your app: name (String), value (Uint8List)
ManageDataOperationBuilder(name, value);
```

- `name` (String): Key name (max 64 bytes)
- `value` (Uint8List?): Value bytes (null to delete)

```dart
import 'dart:typed_data';
import 'dart:convert';

// Set data
var setDataOp = ManageDataOperationBuilder(
  'my_key',
  Uint8List.fromList(utf8.encode('my_value')),
).build();

// Delete data
var deleteDataOp = ManageDataOperationBuilder('my_key', null).build();

// WRONG: utf8.encode returns List<int>, but Uint8List is required
// ManageDataOperationBuilder('key', utf8.encode('value')) // Type error!

// CORRECT: wrap in Uint8List.fromList()
ManageDataOperationBuilder('key', Uint8List.fromList(utf8.encode('value')));
```

### BumpSequenceOperation

Bumps account sequence number to a higher value.

```dart
var bumpOp = BumpSequenceOperationBuilder(BigInt.from(100000)).build();
```

## Claimable Balance Operations

### CreateClaimableBalanceOperation

Creates a claimable balance with specified claimants and predicates.

```dart
// From your app: amount (String), asset (Asset), claimants (List<Claimant>)
CreateClaimableBalanceOperationBuilder(claimants, asset, amount);
```

```dart
// From your app: recipientAccountId (String)
// Unconditional claimant
var claimant = Claimant(
  recipientAccountId,
  Claimant.predicateUnconditional(),
);

var createBalanceOp = CreateClaimableBalanceOperationBuilder(
  [claimant], Asset.NATIVE, '100.0',
).build();

// Time-locked claimant (claimable after a specific time)
var unlockTime = DateTime.now()
    .add(Duration(hours: 24))
    .millisecondsSinceEpoch ~/ 1000;
var timedClaimant = Claimant(
  recipientAccountId,
  Claimant.predicateNot(
    Claimant.predicateBeforeAbsoluteTime(unlockTime),
  ),
);
```

### ClaimClaimableBalanceOperation

Claims an existing claimable balance by its ID.

```dart
// From your app: claimableBalanceResponse (ClaimableBalanceResponse)
// WRONG: ClaimableBalanceResponse does NOT have .id
// CORRECT: use .balanceId to get the balance ID string
String balanceId = claimableBalanceResponse.balanceId;

var claimOp = ClaimClaimableBalanceOperationBuilder(balanceId).build();
```

### ClawbackClaimableBalanceOperation

Issuer claws back a claimable balance (requires clawback enabled).

```dart
// From the section ClaimClaimableBalanceOperation: balanceId (String)
var clawbackBalanceOp = ClawbackClaimableBalanceOperationBuilder(balanceId).build();
```

## Sponsorship Operations

### BeginSponsoringFutureReservesOperation

Begins sponsoring reserves for another account.

```dart
// From your app: sponsoredAccountId (String)
var beginSponsorOp = BeginSponsoringFutureReservesOperationBuilder(
  sponsoredAccountId,
).build();
```

### EndSponsoringFutureReservesOperation

Ends the current sponsorship. Must be signed by the sponsored account.

```dart
var endSponsorOp = EndSponsoringFutureReservesOperationBuilder().build();
```

**Sponsorship sandwich pattern** (all operations in one transaction):

```dart
// From the setup above: beginSponsorOp (BeginSponsoringFutureReservesOperation), endSponsorOp (EndSponsoringFutureReservesOperation)
// From your app: createAccountOp (Operation), transaction (TransactionBuilder)
transaction
  .addOperation(beginSponsorOp)         // source: sponsor
  .addOperation(createAccountOp)         // sponsored action
  .addOperation(endSponsorOp);           // source: sponsored account
```

### RevokeSponsorshipOperation

Revokes sponsorship of ledger entries or signers. One method call per builder.

```dart
// From your app: accountId (String), asset (Asset), dataName (String), ed25519AccountId (String), offerId (int), preAuthTxHash (String), sha256Hash (String), signerAccountId (String), sponsorAccountId (String)
// From the section ClaimClaimableBalanceOperation: balanceId (String)
var builder = RevokeSponsorshipOperationBuilder();

// Revoke account sponsorship
builder.revokeAccountSponsorship(accountId);

// Revoke trustline sponsorship
builder.revokeTrustlineSponsorship(accountId, asset);

// Revoke data entry sponsorship
builder.revokeDataSponsorship(accountId, dataName);

// Revoke offer sponsorship
builder.revokeOfferSponsorship(accountId, offerId);  // offerId is int

// Revoke claimable balance sponsorship
builder.revokeClaimableBalanceSponsorship(balanceId);

// Revoke Ed25519 signer sponsorship
builder.revokeEd25519Signer(signerAccountId, ed25519AccountId);

// Revoke pre-auth tx signer sponsorship
builder.revokePreAuthTxSigner(signerAccountId, preAuthTxHash);

// Revoke SHA256 hash signer sponsorship
builder.revokeSha256HashSigner(signerAccountId, sha256Hash);

var revokeOp = builder.setSourceAccount(sponsorAccountId).build();
```

## Clawback Operations

### ClawbackOperation

Issuer claws back (burns) assets from an account.

```dart
// From your app: amount (String), asset (Asset), fromAccountId (String)
ClawbackOperationBuilder(asset, fromAccountId, amount);
```

```dart
// From your app: holderAccountId (String), issuerAccountId (String)
// From the section ChangeTrustOperation: usd (AssetTypeCreditAlphaNum4)
var clawbackOp = ClawbackOperationBuilder(
  usd, holderAccountId, '100.0',
).setSourceAccount(issuerAccountId).build();
```

## Liquidity Pool Operations

### LiquidityPoolDepositOperation

Deposits both assets into an AMM liquidity pool.

```dart
// From your app: poolId (String)
LiquidityPoolDepositOperationBuilder(
  liquidityPoolId: poolId,
  maxAmountA: '1000.0',
  maxAmountB: '500.0',
  minPrice: '0.49',
  maxPrice: '0.51',
).build();
```

### LiquidityPoolWithdrawOperation

Withdraws assets from a liquidity pool by redeeming pool shares.

```dart
// From your app: poolId (String)
LiquidityPoolWithdrawOperationBuilder(
  liquidityPoolId: poolId,
  amount: '100.0',        // pool shares to redeem
  minAmountA: '450.0',
  minAmountB: '225.0',
).build();
```

## Soroban Operations

### InvokeHostFunctionOperation

Invokes Soroban smart contract functions. Wraps a `HostFunction` subclass.

```dart
// From your app: hostFunction (HostFunction)
InvokeHostFuncOpBuilder(hostFunction);
```

**Upload WASM:**

```dart
import 'dart:typed_data';

// From your app: wasmBytes (Uint8List)
var uploadFn = UploadContractWasmHostFunction(wasmBytes);
var uploadOp = InvokeHostFuncOpBuilder(uploadFn).build();
```

**Create contract from WASM hash:**

```dart
// From your app: deployerAccountId (String), wasmId (String)
var deployerAddress = Address.forAccountId(deployerAccountId);
var createFn = CreateContractHostFunction(deployerAddress, wasmId);
var createOp = InvokeHostFuncOpBuilder(createFn).build();
```

**Create contract with constructor args:**

```dart
// From the setup above: deployerAddress (Address)
// From your app: wasmHash (String)
var createFn = CreateContractWithConstructorHostFunction(
  deployerAddress, wasmHash, [XdrSCVal.forU32(42)],
);
var createOp = InvokeHostFuncOpBuilder(createFn).build();
```

**Invoke contract function:**

```dart
// From your app: contractId (String), fromId (String), toId (String)
var invokeFn = InvokeContractHostFunction(
  contractId,
  'transfer',
  arguments: [
    XdrSCVal.forAddress(Address.forAccountId(fromId).toXdr()),
    XdrSCVal.forAddress(Address.forAccountId(toId).toXdr()),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000)),
  ],
);
var invokeOp = InvokeHostFuncOpBuilder(invokeFn).build();
```

**Deploy Stellar Asset Contract (SAC):**

```dart
// From the section ChangeTrustOperation: usd (AssetTypeCreditAlphaNum4)
var sacFn = DeploySACWithAssetHostFunction(usd);
var sacOp = InvokeHostFuncOpBuilder(sacFn).build();
```

### ExtendFootprintTTLOperation

Extends the time-to-live of Soroban contract state entries.

```dart
var extendOp = ExtendFootprintTTLOperationBuilder(100000).build();
```

`extendTo` is a number of ledgers: after the operation the entries live until at least the current ledger plus `extendTo`. The maximum is the network's `maxEntryTTL` minus 1. The transaction must include a `sorobanTransactionData` footprint specifying which entries to extend.

### RestoreFootprintOperation

Restores archived Soroban contract state entries.

```dart
var restoreOp = RestoreFootprintOperationBuilder().build();
```

## Common Result Codes

**Transaction-level:** `tx_success`, `tx_failed` (check op codes), `tx_bad_seq` (stale sequence), `tx_bad_auth` (missing/invalid signatures), `tx_insufficient_balance`, `tx_insufficient_fee`, `tx_too_early`/`tx_too_late` (time bounds).

**Operation-level:** `op_underfunded` (insufficient balance), `op_no_destination` (account doesn't exist), `op_no_trust` (missing trustline), `op_line_full` (trustline limit reached), `op_bad_auth` (insufficient signature weight for multi-sig).

For full error catalog and debugging: [Troubleshooting Guide](./troubleshooting.md)
