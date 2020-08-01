
### SEP-0011 - Txrep: human-readable low-level representation of Stellar transactions

Txrep: human-readable low-level representation of Stellar transactions is described in [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md).

In the following examples show how to generate Txrep from a transaction and how to create a transaction object from a Txrep string. 

FeeBumpTransaction and muxed accounts are currently not supported.

### Generate Txrep from transaction

```dart

// Prepare accounts.
KeyPair sourceKeyPair = KeyPair.random();
String sourceAccountId = sourceKeyPair.accountId;

// Fund the source account
await FriendBot.fundTestAccount(sourceAccountId);

// Load the account data including the sequence number
AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);

// Generate accountId for a new account to be created.
String newAccountId = KeyPair.random().accountId;

// Build the CreateAccountOperation.
Operation createAccount = new CreateAccountOperationBuilder(newAccountId, "220.09").build();

// Add memo.
MemoText mt = MemoText("Enjoy this transaction");

// Create the transaction.
Transaction transaction = new TransactionBuilder(sourceAccount)
    .addMemo(mt)
    .addOperation(createAccount)
    .build();

// Sign the transaction.
transaction.sign(sourceKeyPair, Network.TESTNET);

// Generate and print the txrep
String txrep = TxRep.toTxRep(transaction);
print(txrep);
```
**Result:**

```
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVVTEXNKEQ7G7XVJJ2JMBIY5WUKE73PWFVMMIW4DY7Z2E6F7NXXIVUH
tx.fee: 100
tx.seqNum: 238563958456321
tx.timeBounds._present: false
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 1
tx.operation[0].sourceAccount._present: false
tx.operation[0].body.type: CREATE_ACCOUNT
tx.operation[0].body.createAccountOp.destination: GC5ICOW2G64VZXON6DNAWPZ46TZZYV6DYEKZE42KWTBMXCVNTS3EENHC
tx.operation[0].body.createAccountOp.startingBalance: 2200900000
tx.signatures.len: 1
tx.signatures[0].hint: c5fb6f74
tx.signatures[0].signature: e0611076f402005942b27807c0702e0976c14c9a9bb8bc46d1c4740060b5125da1d02c2d9ee10b58acfdaa009f57867506d188d1ee0ab3d00877db22c4101709
tx.ext.v: 0
```

### Create a transaction object from a Txrep string

```dart
String txRepString = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVVTEXNKEQ7G7XVJJ2JMBIY5WUKE73PWFVMMIW4DY7Z2E6F7NXXIVUH
tx.fee: 100
tx.seqNum: 238563958456321
tx.timeBounds._present: false
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 1
tx.operation[0].sourceAccount._present: false
tx.operation[0].body.type: CREATE_ACCOUNT
tx.operation[0].body.createAccountOp.destination: GC5ICOW2G64VZXON6DNAWPZ46TZZYV6DYEKZE42KWTBMXCVNTS3EENHC
tx.operation[0].body.createAccountOp.startingBalance: 2200900000
tx.signatures.len: 1
tx.signatures[0].hint: c5fb6f74
tx.signatures[0].signature: e0611076f402005942b27807c0702e0976c14c9a9bb8bc46d1c4740060b5125da1d02c2d9ee10b58acfdaa009f57867506d188d1ee0ab3d00877db22c4101709
tx.ext.v: 0''';

// Create a transaction object by parsing the txRepString.
Transaction tx = TxRep.fromTxRep(txRepString);

print(tx.sourceAccount.accountId);
// GAVVTEXNKEQ7G7XVJJ2JMBIY5WUKE73PWFVMMIW4DY7Z2E6F7NXXIVUH
print(tx.fee);
// 100
print(tx.sequenceNumber);
// 238563958456321
print(tx.operations.length);
// 1
```
