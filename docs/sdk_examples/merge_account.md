
### Merge account

In this example we will merge an account Y into another account X. After merging, account Y will not exist any more and account X will posses the funds of accountY.

First we create two random accounts (X and Y) by asking Freindbot. Then we merge Y into X and check the result.

```dart
// Create random key pairs for two accounts.
KeyPair keyPairX = KeyPair.random();
KeyPair keyPairY = KeyPair.random();

// Account Ids.
String accountXId = keyPairX.accountId;
String accountYId = keyPairY.accountId;

// Create both accounts.
await FriendBot.fundTestAccount(accountXId);
await FriendBot.fundTestAccount(accountYId);

// Prepare the operation for merging account Y into account X.
AccountMergeOperationBuilder accMergeOp =
AccountMergeOperationBuilder(accountXId);

// Load the data of account Y so that we have it's current sequence number.
AccountResponse accountY = await sdk.accounts.account(accountYId);

// Build the transaction to merge account Y into account X.
Transaction transaction = TransactionBuilder(accountY, Network.TESTNET)
    .addOperation(accMergeOp.build())
    .build();

// Account Y signs the transaction - R.I.P :)
transaction.sign(keyPairY);

// Submit the transaction.
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

if (response.success) {
  print("successfully merged");
}

// Check that account Y has been removed.
await sdk.accounts.account(accountYId).then((response) {
  print("account still exists: ${accountYId}");
}).catchError((error) {
  print(error.toString());
  if(error is ErrorResponse && error.code == 404) {
     print("success, account not found");
  }
});

// Check if accountX received the funds from accountY.
AccountResponse accountX = await sdk.accounts.account(accountXId);
for (Balance balance in accountX.balances) {
  if (balance.assetType == Asset.TYPE_NATIVE) {
    print("X has ${double.parse(balance.balance)} XLM");
    break;
  }
}
```
