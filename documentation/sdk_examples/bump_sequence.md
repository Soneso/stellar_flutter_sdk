
### Bump account sequence number

In this example we will bump the sequence number of an account to a higher number.

```dart
// Create a random key pair for a new account.
KeyPair accountKeyPair = KeyPair.random();

// Account Id.
String accountId = accountKeyPair.accountId;

// Create account.
await FriendBot.fundTestAccount(accountId);

// Load account data to get the current sequence number.
AccountResponse account = await sdk.accounts.account(accountId);

// Remember current sequence number.
int startSequence = account.sequenceNumber;

// Prepare the bump sequence operation to bump the sequence number to current + 10.
BumpSequenceOperationBuilder bumpSequenceOpB =
BumpSequenceOperationBuilder(startSequence + BigInt.from(10));

// Prepare the transaction.
Transaction transaction = TransactionBuilder(account)
    .addOperation(bumpSequenceOpB.build())
    .build();

// Sign the transaction.
transaction.sign(accountKeyPair, Network.TESTNET);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Load the account again.
account = await sdk.accounts.account(accountId);

// Check that the new sequence number has correctly been bumped.
if(startSequence + BigInt.from(10) == account.sequenceNumber) {
  print("success");
} else {
  print("failed");
}
```
