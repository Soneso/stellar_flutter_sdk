# SEP-11: Txrep (Transaction Representation)

**Purpose:** Convert Stellar transactions between binary XDR and human-readable key-value text format for inspection, debugging, manual construction, and round-trip editing.
**Prerequisites:** None

## Table of Contents

1. [API — two static methods](#1-api)
2. [XDR to Txrep](#2-xdr-to-txrep)
3. [Txrep to XDR](#3-txrep-to-xdr)
4. [Fee bump transactions](#4-fee-bump-transactions)
5. [Format reference — field names](#5-format-reference)
6. [All supported operation types](#6-all-supported-operation-types)
7. [Preconditions](#7-preconditions)
8. [Soroban / Invoke Host Function fields](#8-soroban-fields)
9. [Error handling](#9-error-handling)
10. [Common pitfalls](#10-common-pitfalls)

---

## 1. API

The entire SEP-11 implementation is in one class with two public static methods:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// XDR base64 string  ->  human-readable Txrep string
TxRep.fromTransactionEnvelopeXdrBase64(String transactionEnvelopeXdrBase64): String

// Human-readable Txrep string  ->  XDR base64 string
TxRep.transactionEnvelopeXdrBase64FromTxRep(String txRep): String
```

Both methods handle `ENVELOPE_TYPE_TX`, `ENVELOPE_TYPE_TX_V0`, and `ENVELOPE_TYPE_TX_FEE_BUMP` transparently.

---

## 2. XDR to Txrep

Convert a base64-encoded XDR transaction envelope to Txrep for display or inspection:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From an existing base64 XDR string
String xdrBase64 = 'AAAAAgAAAAArFkuQQ4QuQY6SkLc5xx...';
String txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdrBase64);
print(txRep);
```

Build a transaction programmatically and convert it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Fund and load account
KeyPair sourceKP = KeyPair.fromSecretSeed('SBXXX...');
await FriendBot.fundTestAccount(sourceKP.accountId);
AccountResponse sourceAccount = await StellarSDK.TESTNET.accounts.account(sourceKP.accountId);

// Build a payment transaction
Asset usdc = Asset.createNonNativeAsset('USDC', 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN');
PaymentOperation payment = PaymentOperationBuilder(
  'GDEST...',
  usdc,
  '50',
).build();

Transaction tx = TransactionBuilder(sourceAccount)
    .addOperation(payment)
    .addMemo(MemoText('Invoice #1234'))
    .build();

tx.sign(sourceKP, Network.TESTNET);

// Inspect the signed transaction before submitting
String txRep = TxRep.fromTransactionEnvelopeXdrBase64(tx.toEnvelopeXdrBase64());
print(txRep);
```

---

## 3. Txrep to XDR

Parse a Txrep string back into an XDR base64 string that can be submitted:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
tx.fee: 100
tx.seqNum: 46489056724385793
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1535756672
tx.cond.timeBounds.maxTime: 1567292672
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O
tx.operations[0].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operations[0].body.paymentOp.amount: 400004000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 4aa07ed0
signatures[0].signature: defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d31b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c
''';

String xdrBase64 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
print(xdrBase64);

// Submit directly if already signed
SubmitTransactionResponse response =
    await StellarSDK.TESTNET.submitTransactionEnvelopeXdrBase64(xdrBase64);
```

> **Note:** Trailing comments in Txrep values are silently stripped during parsing. Values like `1535756672 (Fri Aug 31 2018)` are parsed as `1535756672`. This makes Txrep produced by tools like Stellar Lab round-trippable even if it includes annotations.

### Round-trip verification

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String originalXdr = 'AAAAAgAAAAArFkuQQ4QuQY...';
String txRep = TxRep.fromTransactionEnvelopeXdrBase64(originalXdr);
String reconstructed = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

if (originalXdr == reconstructed) {
  print('Round-trip successful.');
} else {
  print('XDR mismatch — conversion is lossy.');
}
```

---

## 4. Fee Bump Transactions

Fee bump transactions use the `feeBump.` prefix hierarchy. The inner transaction is nested under `feeBump.tx.innerTx.tx.`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String feeBumpXdr = 'AAAABQAAAABkfT0dQuoYYNgS...';
String txRep = TxRep.fromTransactionEnvelopeXdrBase64(feeBumpXdr);
print(txRep);
```

Output structure:

```
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GBD4KWT3HXUGS4ACUZZELY67UJXLOFTZAPR5DT5QIMBO6BX53FXFSLQS
feeBump.tx.fee: 1515
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.fee: 1400
feeBump.tx.innerTx.tx.seqNum: 1102902109202
feeBump.tx.innerTx.tx.cond.type: PRECOND_TIME
feeBump.tx.innerTx.tx.cond.timeBounds.minTime: 1595282368
feeBump.tx.innerTx.tx.cond.timeBounds.maxTime: 1595284000
feeBump.tx.innerTx.tx.memo.type: MEMO_TEXT
feeBump.tx.innerTx.tx.memo.text: "Enjoy this transaction"
feeBump.tx.innerTx.tx.operations.len: 1
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.destination: G...
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 1
feeBump.tx.innerTx.signatures[0].hint: 7b21e7e3
feeBump.tx.innerTx.signatures[0].signature: 085a2ee6...
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: 7b21e7e3
feeBump.signatures[0].signature: 085a2ee6...
```

Key structural rules for fee bump Txrep:
- Outer fee payer fields use `feeBump.tx.feeSource` and `feeBump.tx.fee`
- Inner transaction fields use prefix `feeBump.tx.innerTx.tx.`
- Inner signatures use prefix `feeBump.tx.innerTx.` (not `feeBump.tx.innerTx.tx.`)
- Outer fee bump signatures use prefix `feeBump.`
- `feeBump.tx.ext.v: 0` always appears after the inner signatures

---

## 5. Format Reference

### Envelope type (first line)

```
type: ENVELOPE_TYPE_TX           # Standard transaction (V1) — most common
type: ENVELOPE_TYPE_TX_V0        # Legacy V0 transaction
type: ENVELOPE_TYPE_TX_FEE_BUMP  # Fee bump wrapper
```

### Core transaction fields

For a standard (non-fee-bump) transaction, prefix is `tx.`. Amounts are in **stroops** (1 XLM = 10,000,000 stroops).

```
tx.sourceAccount: G...        # Source account (G... or M... muxed)
tx.fee: 100                   # Total fee in stroops
tx.seqNum: 46489056724385793  # Sequence number (64-bit integer as BigInt in Dart)
```

### Memo types

```
tx.memo.type: MEMO_NONE

tx.memo.type: MEMO_TEXT
tx.memo.text: "Hello"          # UTF-8 string in JSON double quotes, max 28 bytes

tx.memo.type: MEMO_ID
tx.memo.id: 12345              # Unsigned 64-bit integer

tx.memo.type: MEMO_HASH
tx.memo.hash: 0102030405...    # 32 bytes, lowercase hex (64 hex chars)

tx.memo.type: MEMO_RETURN
tx.memo.retHash: 0102030405... # 32 bytes, lowercase hex (64 hex chars)
```

> The SDK uses `JsonEncoder` to output memo text values, so special characters are escaped (`"` becomes `\"`). The parser strips surrounding double quotes when reading.

### Asset format

```
XLM                                # Native asset — SDK outputs "XLM"
native                             # Also accepted by parser
USD:GISSUER...                     # 1-4 char alphanumeric code + issuer G...
LONGCODE12:GISSUER...              # 5-12 char alphanumeric code + issuer G...
```

### Signatures

```
signatures.len: 2
signatures[0].hint: 4aa07ed0        # Last 4 bytes of signing key (8 hex chars)
signatures[0].signature: defb4f1f...  # 64-byte Ed25519 signature (128 hex chars)
signatures[1].hint: 1234abcd
signatures[1].signature: abcdef01...
```

---

## 6. All Supported Operation Types

Every operation follows this pattern:

```
tx.operations[N].sourceAccount._present: false
tx.operations[N].body.type: OPTYPE
tx.operations[N].body.<opNameCamelCase>.<field>: value
```

**WRONG/CORRECT — operation source account:**

```
# WRONG: tx.operations[0].body.type: PAYMENT  (without _present line first)
# CORRECT: always emit _present before the value

tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: G...

# If using the transaction's source account (no per-operation override):
tx.operations[0].sourceAccount._present: false
```

### CREATE_ACCOUNT

```
tx.operations[0].body.type: CREATE_ACCOUNT
tx.operations[0].body.createAccountOp.destination: G...
tx.operations[0].body.createAccountOp.startingBalance: 10000000  # 1 XLM
```

### PAYMENT

```
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: G...
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 10000000
```

### PATH_PAYMENT_STRICT_RECEIVE

```
tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operations[0].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GISSUER...
tx.operations[0].body.pathPaymentStrictReceiveOp.sendMax: 20000000
tx.operations[0].body.pathPaymentStrictReceiveOp.destination: G...
tx.operations[0].body.pathPaymentStrictReceiveOp.destAsset: MOON:GISSUER...
tx.operations[0].body.pathPaymentStrictReceiveOp.destAmount: 80000000
tx.operations[0].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operations[0].body.pathPaymentStrictReceiveOp.path[0]: ECO:GISSUER...
tx.operations[0].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GISSUER...
```

### PATH_PAYMENT_STRICT_SEND

```
tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND
tx.operations[0].body.pathPaymentStrictSendOp.sendAsset: IOM:GISSUER...
tx.operations[0].body.pathPaymentStrictSendOp.sendAmount: 4000000000
tx.operations[0].body.pathPaymentStrictSendOp.destination: G...
tx.operations[0].body.pathPaymentStrictSendOp.destAsset: MOON:GISSUER...
tx.operations[0].body.pathPaymentStrictSendOp.destMin: 12000000000
tx.operations[0].body.pathPaymentStrictSendOp.path.len: 0
```

### MANAGE_SELL_OFFER

```
tx.operations[0].body.type: MANAGE_SELL_OFFER
tx.operations[0].body.manageSellOfferOp.selling: ECO:GISSUER...
tx.operations[0].body.manageSellOfferOp.buying: XLM
tx.operations[0].body.manageSellOfferOp.amount: 82820000000
tx.operations[0].body.manageSellOfferOp.price.n: 7      # numerator
tx.operations[0].body.manageSellOfferOp.price.d: 10     # denominator
tx.operations[0].body.manageSellOfferOp.offerID: 0      # 0 = create new
```

### MANAGE_BUY_OFFER

```
tx.operations[0].body.type: MANAGE_BUY_OFFER
tx.operations[0].body.manageBuyOfferOp.selling: MOON:GISSUER...
tx.operations[0].body.manageBuyOfferOp.buying: ECO:GISSUER...
tx.operations[0].body.manageBuyOfferOp.buyAmount: 120000000  # WRONG: amount — CORRECT: buyAmount
tx.operations[0].body.manageBuyOfferOp.price.n: 1
tx.operations[0].body.manageBuyOfferOp.price.d: 5
tx.operations[0].body.manageBuyOfferOp.offerID: 9298298398334
```

### CREATE_PASSIVE_SELL_OFFER

```
tx.operations[0].body.type: CREATE_PASSIVE_SELL_OFFER
tx.operations[0].body.createPassiveSellOfferOp.selling: ASTRO:GISSUER...
tx.operations[0].body.createPassiveSellOfferOp.buying: MOON:GISSUER...
tx.operations[0].body.createPassiveSellOfferOp.amount: 28280000000
tx.operations[0].body.createPassiveSellOfferOp.price.n: 1
tx.operations[0].body.createPassiveSellOfferOp.price.d: 2
```

### SET_OPTIONS

All SET_OPTIONS fields use `._present` guards. Every field must have a `._present` line, even when `false`.

```
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: true
tx.operations[0].body.setOptionsOp.clearFlags: 2
tx.operations[0].body.setOptionsOp.setFlags._present: true
tx.operations[0].body.setOptionsOp.setFlags: 4
tx.operations[0].body.setOptionsOp.masterWeight._present: true
tx.operations[0].body.setOptionsOp.masterWeight: 122
tx.operations[0].body.setOptionsOp.lowThreshold._present: true
tx.operations[0].body.setOptionsOp.lowThreshold: 10
tx.operations[0].body.setOptionsOp.medThreshold._present: true
tx.operations[0].body.setOptionsOp.medThreshold: 50
tx.operations[0].body.setOptionsOp.highThreshold._present: true
tx.operations[0].body.setOptionsOp.highThreshold: 122
tx.operations[0].body.setOptionsOp.homeDomain._present: true
tx.operations[0].body.setOptionsOp.homeDomain: "example.com"  # quoted string
tx.operations[0].body.setOptionsOp.signer._present: true
tx.operations[0].body.setOptionsOp.signer.key: GALKCFFI...    # G..., T..., or X...
tx.operations[0].body.setOptionsOp.signer.weight: 50
```

### CHANGE_TRUST

```
tx.operations[0].body.type: CHANGE_TRUST
tx.operations[0].body.changeTrustOp.line: ASTRO:GISSUER...
tx.operations[0].body.changeTrustOp.limit: 100000000000
```

### ALLOW_TRUST

```
tx.operations[0].body.type: ALLOW_TRUST
tx.operations[0].body.allowTrustOp.trustor: G...
tx.operations[0].body.allowTrustOp.asset: MOON           # asset code only, no issuer
tx.operations[0].body.allowTrustOp.authorize: 1          # 0=revoke, 1=authorize, 2=authorize_to_maintain_liabilities
```

### ACCOUNT_MERGE

```
# WRONG: tx.operations[0].body.accountMergeOp.destination: G...
# CORRECT: no "accountMergeOp" sub-prefix — destination goes directly under body
tx.operations[0].body.type: ACCOUNT_MERGE
tx.operations[0].body.destination: GALKCFFI...
```

### MANAGE_DATA

```
tx.operations[0].body.type: MANAGE_DATA
tx.operations[0].body.manageDataOp.dataName: "Sommer"        # quoted string
tx.operations[0].body.manageDataOp.dataValue._present: true
tx.operations[0].body.manageDataOp.dataValue: 446965204df6...  # hex-encoded bytes

# Delete data entry (set value to absent):
tx.operations[0].body.manageDataOp.dataValue._present: false
```

### BUMP_SEQUENCE

```
tx.operations[0].body.type: BUMP_SEQUENCE
tx.operations[0].body.bumpSequenceOp.bumpTo: 1102902109211
```

### CREATE_CLAIMABLE_BALANCE

```
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 2900000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: G...
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL
```

Predicate types: `CLAIM_PREDICATE_UNCONDITIONAL`, `CLAIM_PREDICATE_BEFORE_RELATIVE_TIME` (+ `relBefore`), `CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME` (+ `absBefore`), `CLAIM_PREDICATE_AND` (+ `andPredicates.len`), `CLAIM_PREDICATE_OR` (+ `orPredicates.len`), `CLAIM_PREDICATE_NOT` (+ `notPredicate._present`).

### CLAIM_CLAIMABLE_BALANCE

```
tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE
tx.operations[0].body.claimClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[0].body.claimClaimableBalanceOp.balanceID.v0: <64 hex chars>
```

### BEGIN_SPONSORING_FUTURE_RESERVES

```
tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
tx.operations[0].body.beginSponsoringFutureReservesOp.sponsoredID: G...
```

### END_SPONSORING_FUTURE_RESERVES

```
# No fields beyond the type
tx.operations[0].body.type: END_SPONSORING_FUTURE_RESERVES
```

### REVOKE_SPONSORSHIP (ledger entry)

```
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: ACCOUNT
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.account.accountID: G...

# For trustline:
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: TRUSTLINE
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.trustLine.accountID: G...
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.trustLine.asset: USDC:GISSUER...

# For offer:
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: OFFER
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.offer.sellerID: G...
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.offer.offerID: 12345

# For data:
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: DATA
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.data.accountID: G...
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.data.dataName: "myKey"

# For claimable balance:
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: CLAIMABLE_BALANCE
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.claimableBalance.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.claimableBalance.balanceID.v0: <64 hex>
```

### REVOKE_SPONSORSHIP (signer)

```
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
tx.operations[0].body.revokeSponsorshipOp.signer.accountID: G...
tx.operations[0].body.revokeSponsorshipOp.signer.signerKey: G...   # or T... or X...
```

### CLAWBACK

```
tx.operations[0].body.type: CLAWBACK
tx.operations[0].body.clawbackOp.asset: USD:GISSUER...
tx.operations[0].body.clawbackOp.from: G...
tx.operations[0].body.clawbackOp.amount: 10000000
```

### CLAWBACK_CLAIMABLE_BALANCE

```
tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.v0: <64 hex chars>
```

### SET_TRUST_LINE_FLAGS

```
tx.operations[0].body.type: SET_TRUST_LINE_FLAGS
tx.operations[0].body.setTrustLineFlagsOp.trustor: G...
tx.operations[0].body.setTrustLineFlagsOp.asset: USDC:GISSUER...
tx.operations[0].body.setTrustLineFlagsOp.clearFlags: 6
tx.operations[0].body.setTrustLineFlagsOp.setFlags: 1
```

### LIQUIDITY_POOL_DEPOSIT

```
tx.operations[0].body.type: LIQUIDITY_POOL_DEPOSIT
tx.operations[0].body.liquidityPoolDepositOp.liquidityPoolID: <64 hex chars>
tx.operations[0].body.liquidityPoolDepositOp.maxAmountA: 1000000000
tx.operations[0].body.liquidityPoolDepositOp.maxAmountB: 2000000000
tx.operations[0].body.liquidityPoolDepositOp.minPrice.n: 1
tx.operations[0].body.liquidityPoolDepositOp.minPrice.d: 2
tx.operations[0].body.liquidityPoolDepositOp.maxPrice.n: 2
tx.operations[0].body.liquidityPoolDepositOp.maxPrice.d: 1
```

### LIQUIDITY_POOL_WITHDRAW

```
tx.operations[0].body.type: LIQUIDITY_POOL_WITHDRAW
tx.operations[0].body.liquidityPoolWithdrawOp.liquidityPoolID: <64 hex chars>
tx.operations[0].body.liquidityPoolWithdrawOp.amount: 500000000
tx.operations[0].body.liquidityPoolWithdrawOp.minAmountA: 200000000
tx.operations[0].body.liquidityPoolWithdrawOp.minAmountB: 100000000
```

### EXTEND_FOOTPRINT_TTL

```
tx.operations[0].body.type: EXTEND_FOOTPRINT_TTL
tx.operations[0].body.extendFootprintTTLOp.ext.v: 0
tx.operations[0].body.extendFootprintTTLOp.extendTo: 100000
```

### RESTORE_FOOTPRINT

```
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
```

---

## 7. Preconditions

### No preconditions

```
tx.cond.type: PRECOND_NONE
```

### Time bounds only (PRECOND_TIME)

```
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1595282368   # Unix timestamp; 0 = no minimum
tx.cond.timeBounds.maxTime: 1595284000   # Unix timestamp; 0 = no maximum
```

> Note: the SDK outputs `tx.cond.timeBounds.minTime` (no `v2.` prefix) for `PRECOND_TIME`. The `v2.` prefix only applies inside `PRECOND_V2`.

### Advanced preconditions (PRECOND_V2)

Used when setting ledger bounds, min sequence number, min sequence age, min sequence ledger gap, or extra signers. Uses `v2.` sub-prefix and `._present` guards:

```
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: true       # or false if no time bounds
tx.cond.v2.timeBounds.minTime: 0
tx.cond.v2.timeBounds.maxTime: 0
tx.cond.v2.ledgerBounds._present: true
tx.cond.v2.ledgerBounds.minLedger: 1000
tx.cond.v2.ledgerBounds.maxLedger: 2000
tx.cond.v2.minSeqNum._present: true
tx.cond.v2.minSeqNum: 1234567880
tx.cond.v2.minSeqAge: 3600               # seconds; 0 = no minimum
tx.cond.v2.minSeqLedgerGap: 10           # ledgers; 0 = no minimum
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: G...         # G..., T..., X..., or P... (signed payload)
```

---

## 8. Soroban Fields

### Transaction extension

Non-Soroban transactions end with `tx.ext.v: 0`. Soroban transactions use `tx.ext.v: 1` and include resource accounting:

```
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 2
tx.sorobanData.resources.footprint.readOnly[0].type: CONTRACT_DATA
tx.sorobanData.resources.footprint.readOnly[0].contractData.contract.type: SC_ADDRESS_TYPE_CONTRACT
tx.sorobanData.resources.footprint.readOnly[0].contractData.contract.contractId: <64 hex>
tx.sorobanData.resources.footprint.readOnly[0].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_INSTANCE
tx.sorobanData.resources.footprint.readOnly[0].contractData.durability: PERSISTENT
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000000
tx.sorobanData.resources.diskReadBytes: 1000
tx.sorobanData.resources.writeBytes: 500
tx.sorobanData.resourceFee: 10000
```

### INVOKE_HOST_FUNCTION

```
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.contractAddress.contractId: <64 hex>
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.functionName: transfer
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args.len: 3
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[0].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[0].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[0].address.accountId: G...
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[1].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[1].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[1].address.accountId: G...
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[2].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[2].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.hostFunction.invokeContract.args[2].i128.lo: 100000000
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
```

### HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM

```
tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM
tx.operations[0].body.invokeHostFunctionOp.hostFunction.wasm: 0061736d...  # hex-encoded WASM bytes
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
```

### HOST_FUNCTION_TYPE_CREATE_CONTRACT

```
tx.operations[0].body.invokeHostFunctionOp.hostFunction.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.contractIDPreimage.type: CONTRACT_ID_PREIMAGE_FROM_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.contractIDPreimage.fromAddress.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.contractIDPreimage.fromAddress.address.accountId: G...
tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.contractIDPreimage.fromAddress.salt: <64 hex>
tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.executable.type: CONTRACT_EXECUTABLE_WASM
tx.operations[0].body.invokeHostFunctionOp.hostFunction.createContract.executable.wasm_hash: <64 hex>
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
```

### SCVal types in Txrep

| SCVal type | Txrep type string | Field name(s) |
|------------|-------------------|---------------|
| bool | `SCV_BOOL` | `b: true` or `b: false` |
| void | `SCV_VOID` | _(no value field)_ |
| uint32 | `SCV_U32` | `u32: 42` |
| int32 | `SCV_I32` | `i32: -1` |
| uint64 | `SCV_U64` | `u64: 9999` |
| int64 | `SCV_I64` | `i64: -9999` |
| timepoint | `SCV_TIMEPOINT` | `timepoint: ...` |
| duration | `SCV_DURATION` | `duration: ...` |
| uint128 | `SCV_U128` | `u128.hi: ...` `u128.lo: ...` |
| int128 | `SCV_I128` | `i128.hi: ...` `i128.lo: ...` |
| uint256 | `SCV_U256` | `u256.hi_hi: ...` `u256.hi_lo: ...` `u256.lo_hi: ...` `u256.lo_lo: ...` |
| int256 | `SCV_I256` | `i256.hi_hi: ...` (same pattern) |
| bytes | `SCV_BYTES` | `bytes: <hex>` |
| string | `SCV_STRING` | `str: hello` |
| symbol | `SCV_SYMBOL` | `sym: transfer` |
| address | `SCV_ADDRESS` | `address.type: ...` `address.accountId/contractId: ...` |
| vec | `SCV_VEC` | `vec._present: true` `vec.len: 2` `vec[0].type: ...` |
| map | `SCV_MAP` | `map._present: true` `map.len: 2` `map[0].key.type: ...` `map[0].val.type: ...` |
| contract instance | `SCV_CONTRACT_INSTANCE` | `contractInstance.executable.type: ...` |
| ledger key contract instance | `SCV_LEDGER_KEY_CONTRACT_INSTANCE` | _(no value field)_ |
| ledger key nonce | `SCV_LEDGER_KEY_NONCE` | `nonce_key.nonce: 0` |

---

## 9. Error Handling

Both methods throw `Exception` on invalid input. Catch with a standard `try/catch`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// XDR -> Txrep: invalid base64 or malformed XDR
try {
  String txRep = TxRep.fromTransactionEnvelopeXdrBase64('not-valid-base64!');
} catch (e) {
  print('Failed to parse XDR: $e');
}

// Txrep -> XDR: missing required fields
try {
  String incompleteTxrep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
''';
  // throws Exception('missing tx.fee')
  String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(incompleteTxrep);
} catch (e) {
  print('Missing field: $e');
}

// Txrep -> XDR: invalid account ID
try {
  String badTxrep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: NOT_VALID
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
  // throws Exception('invalid tx.sourceAccount')
  String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(badTxrep);
} catch (e) {
  print('Invalid account: $e');
}
```

Common `Exception` messages from the parser:
- `'missing tx.fee'` / `'invalid tx.fee'`
- `'missing tx.seqNum'` / `'invalid tx.seqNum'`
- `'missing tx.sourceAccount'` / `'invalid tx.sourceAccount'`
- `'missing tx.memo.type'`
- `'missing tx.operations.len'` / `'invalid tx.operations.len'`
- `'missing feeBump.tx.fee'` / `'missing feeBump.tx.feeSource'`
- Per-field errors like `'missing tx.operations[0].body.paymentOp.destination'`
- `'invalid or unsupported [prefix].type - UNKNOWN_OP'` for unrecognized operation types

---

## 10. Common Pitfalls

**ACCOUNT_MERGE has no `accountMergeOp` sub-prefix:**

```
# WRONG: tx.operations[N].body.accountMergeOp.destination: G...
# CORRECT: destination goes directly under body — no sub-prefix for account merge
tx.operations[N].body.destination: G...
```

**MANAGE_BUY_OFFER uses `buyAmount`, not `amount`:**

```
# WRONG: tx.operations[N].body.manageBuyOfferOp.amount: 120000000
# CORRECT: uses buyAmount (unlike manageSellOfferOp which uses amount)
tx.operations[N].body.manageBuyOfferOp.buyAmount: 120000000
```

**SET_OPTIONS: all 9 optional fields require `._present` guards:**

```
# WRONG (parser throws — missing _present line):
tx.operations[N].body.setOptionsOp.homeDomain: "example.com"

# CORRECT: _present must appear before each optional field value
tx.operations[N].body.setOptionsOp.homeDomain._present: true
tx.operations[N].body.setOptionsOp.homeDomain: "example.com"
```

**PRECOND_V2 sub-fields use `v2.` prefix; PRECOND_TIME does not:**

```
# WRONG: mixing prefix styles
tx.cond.type: PRECOND_V2
tx.cond.timeBounds.minTime: 0   # missing v2. prefix

# CORRECT: always use v2. prefix inside PRECOND_V2
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 0
```

**Amounts are in stroops, not XLM:**

```
# WRONG: tx.operations[0].body.paymentOp.amount: 10  (interpreted as 0.000001 XLM)
# CORRECT: 10 XLM = 100000000 stroops
tx.operations[0].body.paymentOp.amount: 100000000
```

**Method name: `fromTransactionEnvelopeXdrBase64`, not `toTxRep`:**

```dart
// WRONG: TxRep.toTxRep(xdr)
// CORRECT:
String txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdrBase64);
```

**Method name: `transactionEnvelopeXdrBase64FromTxRep`, not `fromTxRep`:**

```dart
// WRONG: TxRep.fromTxRep(txRep)
// CORRECT:
String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
```

**Memo text field uses JSON double-quoted string:**

```
# WRONG: tx.memo.text: Hello world
# CORRECT: must be JSON-quoted
tx.memo.text: "Hello world"
```

**Memo hash / retHash is lowercase hex, not base64:**

```
# WRONG: tx.memo.hash: <base64-encoded-hash>
# CORRECT: 64 lowercase hex chars
tx.memo.hash: 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
```

**Signature hint is 8 hex chars (4 bytes); signature is 128 hex chars (64 bytes):**

```
signatures[0].hint: b51d604e         # 8 hex chars — last 4 bytes of signing key
signatures[0].signature: c52a9c15... # 128 hex chars — 64-byte Ed25519 signature
```

**`diskReadBytes` vs `readBytes` in Soroban resources:**

The SDK outputs `diskReadBytes`. The parser also accepts `readBytes` as a legacy alias for backward compatibility.

---
