
### Send a non native ("IOM") payment

In this example we will send a non native payment (IOM - a custom token) from a sender stellar account to a receiver stellar account.

To be able to send the funds, both accounts must trust the issuer and token. For this we will create the corresponding trustlines first.

Then we need to send some IOM from the issuer to the sender so that the sender can send IOM to the receiver in the next step.

At the end, the sender sends 200 IOM (non native payment) to the receiver.

```dart
// Create the key pairs of issuer, sender and receiver from their secret seeds. We will need them for signing.
KeyPair issuerKeyPair = KeyPair.fromSecretSeed(
    "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");
KeyPair senderKeyPair = KeyPair.fromSecretSeed(
    "SCYKGVCVPKMNIG3DKLW42WR3Q6BAU2PTOEEFYNMSHDPWS2Z4LB6HDCXR");
KeyPair receiverKeyPair = KeyPair.fromSecretSeed(
    "SB2VYVJSBKXV6YUPMP2627EJP3FZIQQSX3XZIKD5ZUJX5ZDKCRVKXC5N");

// Account Ids.
String issuerAccountId = issuerKeyPair.accountId;
String senderAccountId = senderKeyPair.accountId;
String receiverAccountId = receiverKeyPair.accountId;

// Define the custom asset/token issued by the issuer account.
Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccountId);

// Prepare a change trust operation so that we can create trustlines for both, the sender and receiver.
// Both need to trust the IOM asset issued by the issuer account so that they can hold the token/asset.
// Trust limit is 10000.
ChangeTrustOperationBuilder chOp = ChangeTrustOperationBuilder(
    iomAsset, "10000");

// Load the sender account data from the stellar network so that we have it's current sequence number.
AccountResponse sender = await sdk.accounts.account(senderAccountId);

// Build the transaction for the trustline (sender trusts custom asset).
Transaction transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(chOp.build())
    .build();

// The sender signs the transaction.
transaction.sign(senderKeyPair);

// Submit the transaction to stellar.
await sdk.submitTransaction(transaction);

// Load the receiver account so that we have it's current sequence number.
AccountResponse receiver = await sdk.accounts.account(receiverAccountId);

// Build the transactuion for the trustline (receiver trusts custom asset).
transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(chOp.build())
    .build();

// The receiver signs the transaction.
transaction.sign(receiverKeyPair);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// Load the issuer account so that we have it's current sequence number.
AccountResponse issuer = await sdk.accounts.account(issuerAccountId);

// Send 500 IOM non native payment from issuer to sender.
transaction = new TransactionBuilder(issuer, Network.TESTNET)
    .addOperation(
    PaymentOperationBuilder(receiverAccountId, iomAsset, "500").build())
    .build();

// The issuer signs the transaction.
transaction.sign(issuerKeyPair);

// Submit the transaction.
await sdk.submitTransaction(transaction);

// The sender now has 500 IOM and can send to the receiver.
// Send 200 IOM (non native payment) from sender to receiver.
transaction = new TransactionBuilder(sender, Network.TESTNET)
    .addOperation(
    PaymentOperationBuilder(receiverAccountId, iomAsset, "200").build())
    .build();

// The sender signs the transaction.
transaction.sign(senderKeyPair);

// Submit the transaction to stellar.
await sdk.submitTransaction(transaction);

// Check that the receiver obtained the 200 IOM.
receiver = await sdk.accounts.account(receiverAccountId);
for (Balance balance in receiver.balances) {
  if (balance.assetType != Asset.TYPE_NATIVE
      && balance.assetCode == "IOM"
      && double.parse(balance.balance) > 199) {
    print("received IOM payment");
    break;
  }
}
```
