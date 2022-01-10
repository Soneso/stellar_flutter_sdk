
### Create a trustline

In this example we will set a data entry (key value pair) into an account within the stellar network.
To do so, we will create a new account and add the data entry by submitting a transaction that contains the prepared manage data operation.
After that, we will reload the account from stellar, read and compare the data entry.
In the last step we will delete the entry.

```dart
// Create a random keypair for our new account.
KeyPair keyPair = KeyPair.random();

// Account Id.
String accountId = keyPair.accountId;

// Create account.
await FriendBot.fundTestAccount(accountId);

// Load account data including it's current sequence number.
AccountResponse account = await sdk.accounts.account(accountId);

// Define a key value pair to save as a data entry.
String key = "Sommer";
String value = "Die Möbel sind heiß!";

// Convert the value to bytes.
List<int> list = value.codeUnits;
Uint8List valueBytes = Uint8List.fromList(list);

// Prepare the manage data operation.
ManageDataOperationBuilder
manageDataOperationBuilder =
ManageDataOperationBuilder(key, valueBytes);

// Create the transaction.
Transaction transaction = TransactionBuilder(account)
    .addOperation(manageDataOperationBuilder.build())
    .build();

// Sign the transaction.
transaction.sign(keyPair, Network.TESTNET);

// Submit the transaction to stellar.
await sdk.submitTransaction(transaction);

// Reload the account.
account = await sdk.accounts.account(accountId);

// Get the value for our key as bytes.
Uint8List resultBytes = account.data.getDecoded(key);

// Convert it back to a string.
String restltValue = String.fromCharCodes(resultBytes);

// Compare.
if(value == restltValue) {
  print("okay");
} else {
  print("failed");
}

// In the next step we prepare the operation to delete the entry by passing null as a value.
manageDataOperationBuilder =
    ManageDataOperationBuilder(key, null);

// Prepare the transaction.
transaction = TransactionBuilder(account)
    .addOperation(manageDataOperationBuilder.build())
    .build();

// Sign the transaction.
transaction.sign(keyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// Reload account.
account = await sdk.accounts.account(accountId);

// Check if the entry still exists. It should not be there any more.
if(!account.data.keys.contains(key)){
    print("success");
}
```
