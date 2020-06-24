
### Send a native (XLM) payment

In this example we will let one account, called truster, trust another account that is the issuer of a custom token called "IOM".

```dart
// First create the sender key pair from the secret seed of the sender so we can use it later for signing.
KeyPair senderKeyPair = KeyPair.fromSecretSeed("SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");

// Next, we need the account id of the receiver so that we can use to as a destination of our payment. 
String destination = "GDXPJR65A6EXW7ZIWWIQPO6RKTPG3T2VWFBS3EAHJZNFW6ZXG3VWTTSK";

// Load sender's account data from the stellar network. It contains the current sequence number.
AccountResponse sender = await sdk.accounts.account(senderKeyPair.accountId);

// Build the transaction to send 100 XLM native payment from sender to destination
Transaction transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(PaymentOperationBuilder(destination,Asset.NATIVE, "100").build())
    .build();

// Sign the transaction with the sender's key pair.
transaction.sign(senderKeyPair);

// Submit the transaction to the stellar network.
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (response.success) {
  print("Payment sent");
}
```
