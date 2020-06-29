
### Send a native (XLM) payment

In this example we will send a custom token (IOM) from a sender account to a receiver account. 
But the receiver account can not hold the IOM asset because it has no trustline for this asset. 
The receiver can hold ECO, our second custom token. 
To send IOM but receive ECO we will send a path payment. But for this we need a middleman who offers ECO for IOM.
In the following code, we will construct such an example and send the funds with path payment strict send and path payment strict send.

```dart
// Prepare new random key pairs, we will need them for signing.
KeyPair issuerKeyPair = KeyPair.random();
KeyPair senderKeyPair = KeyPair.random();
KeyPair middlemanKeyPair = KeyPair.random();
KeyPair receiverKeyPair = KeyPair.random();

// Account Ids.
String issuerAccoutId = issuerKeyPair.accountId;
String senderAccountId = senderKeyPair.accountId;
String middlemanAccountId = middlemanKeyPair.accountId;
String receiverAccountId = receiverKeyPair.accountId;

// Fund the issuer account.
await FriendBot.fundTestAccount(issuerAccoutId);

// Load the issuer account so that we have it's current sequence number.
AccountResponse issuer = await sdk.accounts.account(issuerAccoutId);

// Fund sender, middleman and receiver from our issuer account.
// Create the accounts for our example.
Transaction transaction = new TransactionBuilder(issuer, Network.TESTNET)
    .addOperation(
        new CreateAccountOperationBuilder(senderAccountId, "10").build())
    .addOperation(
        new CreateAccountOperationBuilder(middlemanAccountId, "10").build())
    .addOperation(
        new CreateAccountOperationBuilder(receiverAccountId, "10").build())
    .build();

// Sign the transaction.
transaction.sign(issuerKeyPair);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Load the data of the accounts so that we can create the trustlines in the next step.
AccountResponse sender = await sdk.accounts.account(senderAccountId);
AccountResponse middleman = await sdk.accounts.account(middlemanAccountId);
AccountResponse receiver = await sdk.accounts.account(receiverAccountId);

// Define our custom tokens.
Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccoutId);
Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", issuerAccoutId);

// Let the sender trust IOM.
ChangeTrustOperationBuilder ctIOMOp =
    ChangeTrustOperationBuilder(iomAsset, "200999");

// Build the transaction.
transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(ctIOMOp.build())
    .build();

// Sign the transaction.
transaction.sign(senderKeyPair);

// Submit the transaction to stellar.
await sdk.submitTransaction(transaction);

// Let the middleman trust both IOM and ECO.
ChangeTrustOperationBuilder ctECOOp =
    ChangeTrustOperationBuilder(ecoAsset, "200999");

// Build the transaction.
transaction = new TransactionBuilder(middleman, Network.TESTNET)
    .addOperation(ctIOMOp.build())
    .addOperation(ctECOOp.build())
    .build();

// Sign the transaction.
transaction.sign(middlemanKeyPair);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Let the receiver trust ECO.
transaction = new TransactionBuilder(receiver, Network.TESTNET)
    .addOperation(ctECOOp.build())
    .build();

// Sign.
transaction.sign(receiverKeyPair);

// Submit.
await sdk.submitTransaction(transaction);

// Now send assets to the accounts from the issuer, so that we can start our case.
// Send 100 IOM to sender.
// Send 100 IOM and 100 ECO to middleman.
transaction = new TransactionBuilder(issuer, Network.TESTNET)
    .addOperation(
        PaymentOperationBuilder(senderAccountId, iomAsset, "100").build())
    .addOperation(
        PaymentOperationBuilder(middlemanAccountId, iomAsset, "100")
            .build())
    .addOperation(
        PaymentOperationBuilder(middlemanAccountId, ecoAsset, "100")
            .build())
    .build();

// Sign.
transaction.sign(issuerKeyPair);

// Submit.
await sdk.submitTransaction(transaction);

// Now let the middleman offer ECO for IOM: 1 IOM = 2 ECO. Offered Amount: 30 ECO.
ManageSellOfferOperation sellOfferOp =
    ManageSellOfferOperation(ecoAsset, iomAsset, "30", "0.5", 0);

// Build the transaction.
transaction = new TransactionBuilder(middleman, Network.TESTNET)
    .addOperation(sellOfferOp)
    .build();

// Sign.
transaction.sign(middlemanKeyPair);

// Submit.
await sdk.submitTransaction(transaction);

// Everything is prepared now. We can use path payment to send IOM but receive ECO.
// Stellar will find the path for us.
// First path payment strict send. Send exactly 10 IOM, receive minimum 18 ECO (it will be 20).
PathPaymentStrictSendOperation strictSend = PathPaymentStrictSendOperation(
    iomAsset, "10", receiverAccountId, ecoAsset, "18", null);

// Build the transaction.
transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(strictSend)
    .build();

//Sign.
transaction.sign(senderKeyPair);

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
// We want the receiver to receive exactly 3 ECO.
// The sender sends max 2 IOM (will be 1.5).
PathPaymentStrictReceiveOperation strictReceive =
    PathPaymentStrictReceiveOperation(
        iomAsset, "2", receiverAccountId, ecoAsset, "3", null);

// Build the transaction.
transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(strictReceive)
    .build();

// Sign.
transaction.sign(senderKeyPair);

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
