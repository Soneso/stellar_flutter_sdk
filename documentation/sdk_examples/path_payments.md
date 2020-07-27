
### Send a native (XLM) payment

In this example we will send a custom token (IOM) from a sender account to a receiver account. 
But the receiver account can not hold the IOM asset because it has no trustline for this asset. 
The receiver can hold ECO, our second custom token. 
To send IOM but receive ECO we will send a path payment. But for this we need a path through offers so that the assets can be exchaged/traded.
In the following code, we will construct such an example and send the funds with path payment strict send and path payment strict send.

```dart
// Prepare new random key pairs, we will need them for signing.
KeyPair issuerKeyPair = KeyPair.random();
KeyPair senderKeyPair = KeyPair.random();
KeyPair firstMiddlemanKeyPair = KeyPair.random();
KeyPair secondMiddlemanKeyPair = KeyPair.random();
KeyPair receiverKeyPair = KeyPair.random();

// Account Ids.
String issuerAccoutId = issuerKeyPair.accountId;
String senderAccountId = senderKeyPair.accountId;
String firstMiddlemanAccountId = firstMiddlemanKeyPair.accountId;
String secondMiddlemanAccountId = secondMiddlemanKeyPair.accountId;
String receiverAccountId = receiverKeyPair.accountId;

// Fund the issuer account.
await FriendBot.fundTestAccount(issuerAccoutId);

// Load the issuer account so that we have it's current sequence number.
AccountResponse issuer = await sdk.accounts.account(issuerAccoutId);

// Fund sender, middleman and receiver accounts from our issuer account.
// Create the accounts for our example.
Transaction transaction = new TransactionBuilder(issuer)
    .addOperation(new CreateAccountOperationBuilder(senderAccountId, "10").build())
    .addOperation(new CreateAccountOperationBuilder(firstMiddlemanAccountId, "10").build())
    .addOperation(new CreateAccountOperationBuilder(secondMiddlemanAccountId, "10").build())
    .addOperation(new CreateAccountOperationBuilder(receiverAccountId, "10").build())
    .build();

// Sign the transaction.
transaction.sign(issuerKeyPair, Network.TESTNET);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Load the data of the accounts so that we can create the trustlines in the next step.
AccountResponse sender = await sdk.accounts.account(senderAccountId);
AccountResponse firstMiddleman = await sdk.accounts.account(firstMiddlemanAccountId);
AccountResponse secondMiddleman = await sdk.accounts.account(secondMiddlemanAccountId);
AccountResponse receiver = await sdk.accounts.account(receiverAccountId);

// Define our custom tokens.
Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccoutId);
Asset moonAsset = AssetTypeCreditAlphaNum4("MOON", issuerAccoutId);
Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", issuerAccoutId);

// Let the sender trust IOM.
ChangeTrustOperationBuilder ctIOMOp = ChangeTrustOperationBuilder(iomAsset, "200999");

// Build the transaction.
transaction = new TransactionBuilder(sender).addOperation(ctIOMOp.build()).build();

// Sign the transaction.
transaction.sign(senderKeyPair, Network.TESTNET);

// Submit the transaction to stellar.
await sdk.submitTransaction(transaction);

// Let the first middleman trust both IOM and MOON.
ChangeTrustOperationBuilder ctMOONOp = ChangeTrustOperationBuilder(moonAsset, "200999");

// Build the transaction.
transaction = new TransactionBuilder(firstMiddleman)
    .addOperation(ctIOMOp.build())
    .addOperation(ctMOONOp.build())
    .build();

// Sign the transaction.
transaction.sign(firstMiddlemanKeyPair, Network.TESTNET);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Let the second middleman trust both MOON and ECO.
ChangeTrustOperationBuilder ctECOOp =
    ChangeTrustOperationBuilder(ecoAsset, "200999");

// Build the transaction.
transaction = new TransactionBuilder(secondMiddleman)
    .addOperation(ctMOONOp.build())
    .addOperation(ctECOOp.build())
    .build();

// Sign the transaction.
transaction.sign(secondMiddlemanKeyPair, Network.TESTNET);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Let the receiver trust ECO.
transaction = new TransactionBuilder(receiver).addOperation(ctECOOp.build()).build();

// Sign.
transaction.sign(receiverKeyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// Now send assets to the accounts from the issuer, so that we can start our case.
// Send 100 IOM to sender.
// Send 100 MOON to first middleman.
// Send 100 ECO to second middleman.
transaction = new TransactionBuilder(issuer)
    .addOperation(PaymentOperationBuilder(senderAccountId, iomAsset, "100").build())
    .addOperation(PaymentOperationBuilder(firstMiddlemanAccountId, moonAsset, "100").build())
    .addOperation(PaymentOperationBuilder(secondMiddlemanAccountId, ecoAsset, "100").build())
    .build();

// Sign.
transaction.sign(issuerKeyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// Now let the first middleman offer MOON for IOM: 1 IOM = 2 MOON. Offered Amount: 100 MOON.
ManageSellOfferOperation sellOfferOp = ManageSellOfferOperation(moonAsset, iomAsset, "100", "0.5", "0");

// Build the transaction.
transaction = new TransactionBuilder(firstMiddleman).addOperation(sellOfferOp).build();

// Sign.
transaction.sign(firstMiddlemanKeyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// Now let the second middleman offer ECO for MOON: 1 MOON = 2 ECO. Offered Amount: 100 ECO.
sellOfferOp = ManageSellOfferOperation(ecoAsset, moonAsset, "100", "0.5", "0");

// Build the transaction.
transaction = new TransactionBuilder(secondMiddleman).addOperation(sellOfferOp).build();

// Sign.
transaction.sign(secondMiddlemanKeyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// In this example we are going to wait a couple of seconds to be sure that the ledger closed and the offers are available.
// In your app you should stream for the offers and continue as soon as they are available.
await Future.delayed(const Duration(seconds: 5), () {});

// Everything is prepared now. We can use path payment to send IOM but receive ECO.
// We will need to provide the path, so lets request/find it first
Page<PathResponse> strictSendPaths = await sdk.strictSendPaths
    .sourceAsset(iomAsset)
    .sourceAmount("10")
    .destinationAssets([ecoAsset]).execute();

// Here is our payment path.
List<Asset> path = strictSendPaths.records.first.path;

// First path payment strict send. Send exactly 10 IOM, receive minimum 38 ECO (it will be 40).
PathPaymentStrictSendOperation strictSend =
    PathPaymentStrictSendOperationBuilder(iomAsset, "10", receiverAccountId, ecoAsset, "38")
        .setPath(path)
        .build();

// Build the transaction.
transaction = new TransactionBuilder(sender).addOperation(strictSend).build();

//Sign.
transaction.sign(senderKeyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// Check if the receiver received the ECOs.
receiver = await sdk.accounts.account(receiverAccountId);
for (Balance balance in receiver.balances) {
  if (balance.assetType != Asset.TYPE_NATIVE &&
      balance.assetCode == "ECO") {
    print("Receiver received ${double.parse(balance.balance)} ECO");
    break;
  }
}

// And now a path payment strict receive.
// Find the path.
// We want the receiver to receive exactly 8 ECO.
Page<PathResponse> strictReceivePaths = await sdk.strictReceivePaths
    .destinationAsset(ecoAsset)
    .destinationAmount("8")
    .sourceAccount(senderAccountId)
    .execute();

// Here is our payment path.
path = strictReceivePaths.records.first.path;

// The sender sends max 2 IOM.
PathPaymentStrictReceiveOperation strictReceive =
    PathPaymentStrictReceiveOperationBuilder(iomAsset, "2", receiverAccountId, ecoAsset, "8")
        .setPath(path)
        .build();

// Build the transaction.
transaction = new TransactionBuilder(sender).addOperation(strictReceive).build();

// Sign.
transaction.sign(senderKeyPair, Network.TESTNET);

// Submit.
await sdk.submitTransaction(transaction);

// Check id the reciver received the ECOs.
receiver = await sdk.accounts.account(receiverAccountId);
for (Balance balance in receiver.balances) {
  if (balance.assetType != Asset.TYPE_NATIVE &&
      balance.assetCode == "ECO") {
    print("Receiver has ${double.parse(balance.balance)} ECO");
    break;
  }
}
print("Success! :)");
```
