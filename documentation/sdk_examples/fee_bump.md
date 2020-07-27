
### Fee bump transaction

In this example we will let a payer account pay the fee for another transaction by using the fee bump transaction.

```dart
// Create 3 random Keypairs, we will need them later for signing.
KeyPair sourceKeyPair = KeyPair.random();
KeyPair destinationKeyPair = KeyPair.random();
KeyPair payerKeyPair = KeyPair.random();

// Account Ids.
String payerId = payerKeyPair.accountId;
String sourceId = sourceKeyPair.accountId;
String destinationId = destinationKeyPair.accountId;

// Create the source and the payer account.
await FriendBot.fundTestAccount(sourceId);
await FriendBot.fundTestAccount(payerId);

// Load the current data of the source account so that we can create the inner transaction.
AccountResponse sourceAccount = await sdk.accounts.account(sourceId);

// Build the inner transaction which will create the the destination account by using the source account.
Transaction innerTx = new TransactionBuilder(sourceAccount)
    .addOperation(
    new CreateAccountOperationBuilder(destinationId, "10").build())
    .build();

// Sign the inner transaction with the source account key pair.
innerTx.sign(sourceKeyPair, Network.TESTNET);

// Build the fee bump transaction to let the payer account pay the fee for the inner transaction.
// The base fee for the fee bump transaction must be higher than the fee of the inner transaction.
FeeBumpTransaction feeBump = new FeeBumpTransactionBuilder(innerTx)
    .setBaseFee(200)
    .setFeeAccount(payerId)
    .build();

// Sign the fee bump transaction with the payer keypair
feeBump.sign(payerKeyPair, Network.TESTNET);

// Submit the fee bump transaction containing the inner transaction.
SubmitTransactionResponse response = await sdk.submitFeeBumpTransaction(feeBump);

// Let's check if the destination account has been created and received the funds.
AccountResponse destination = await sdk.accounts.account(destinationId);
for (Balance balance in destination.balances) {
  if (balance.assetType == Asset.TYPE_NATIVE) {
    if (double.parse(balance.balance) > 9) {
      print("Success :)");
    }
  }
}

// You can load the transaction data with sdk.transactions
TransactionResponse transaction = await sdk.transactions.transaction(response.hash);

// Same for the inner transaction.
transaction = await sdk.transactions.transaction(transaction.innerTransaction.hash);
```
