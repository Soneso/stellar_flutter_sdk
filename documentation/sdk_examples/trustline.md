
### Create a trustline

In this example we will let one account, called trustor, trust another account that is the issuer of a custom token called "IOM".

```dart
// First we create the trustor key pair from the seed of the trustor so that we can use it to sign the transaction.
KeyPair trustorKeyPair = KeyPair.fromSecretSeed("SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");

// Account Id of the trustor account.
String trustorAccountId = trustorKeyPair.accountId;

// Load the trustor's account details including it's current sequence number.
AccountResponse trustor = await sdk.accounts.account(trustorAccountId);

// Account Id of the issuer of our custom token "IOM".
String issuerAccountId = "GBGAKKFVRQJCXDLYANAMK4H2D4UHY4FARMGJXPSLGVVW3DQLYODFIKZ2";

// Define our custom token/asset "IOM" issued by the upper issuer account.
Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccountId);

// Prepare the change trust operation to trust the IOM asset/token defined above.
// We limit the trusted/credit amount to 30.000.
ChangeTrustOperationBuilder changeTrustOperation =
    ChangeTrustOperationBuilder(iomAsset, "300000");

// Build the transaction.
Transaction transaction = new TransactionBuilder(trustor)
    .addOperation(changeTrustOperation.build())
    .build();

// The trustor signs the transaction.
transaction.sign(trustorKeyPair, Network.TESTNET);

// Submit the transaction.
SubmitTransactionResponse response =
    await sdk.submitTransaction(transaction);

if (!response.success) {
  print("something went wrong.");
}

// Now we can send 1000 IOM from the issuer to the trustor.

// First we create the issuer account key pair from it's seed so that we can use it to sign the transaction.
KeyPair issuerKeyPair = KeyPair.fromSecretSeed("SA75FA55DXG7EN22ZYT6E42ZQBY3TUFF6MHDGG7R6ZEDMNGQ3EVSO3VZ");

// Load the issuer's account details including its current sequence number.
AccountResponse issuer = await sdk.accounts.account(issuerAccountId);

// Send 1000 IOM non native payment from the issuer to the trustor.
transaction = new TransactionBuilder(issuer)
    .addOperation(PaymentOperationBuilder(trustorAccountId, iomAsset, "1000").build())
    .build();

// The issuer signs the transaction.
transaction.sign(issuerKeyPair, Network.TESTNET);

// Submit the transaction to the stellar network.
response = await sdk.submitTransaction(transaction);

if (!response.success) {
  print("something went wrong.");
}

// (info) check the trustor account data to see if the trustor received the payment.
trustor = await sdk.accounts.account(trustorAccountId);
for (Balance balance in trustor.balances) {
  if (balance.assetType != Asset.TYPE_NATIVE &&
      balance.assetCode == "IOM" &&
      double.parse(balance.balance) > 90) {
    print("trustor received IOM payment");
    break;
  }
}
```
