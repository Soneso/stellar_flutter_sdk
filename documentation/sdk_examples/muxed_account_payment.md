
### Use muxed account for payment

In this example we will see how to use a muxed account in a payment. 

Muxed accounts can furthermore be used in:
- payment operation destination
- payment strict receive operation destination
- payment strict send operation destination
- any operation source account
- account merge operation destination
- transaction source account
- fee bump transaction fee source

```dart
// Create two random key pairs, we will need them later for signing.
KeyPair senderKeyPair = KeyPair.random();
KeyPair receiverKeyPair = KeyPair.random();

// AccountIds
String accountCId = receiverKeyPair.accountId;
String senderAccountId = senderKeyPair.accountId;

// Create the sender account.
await FriendBot.fundTestAccount(senderAccountId);

// Load the current account data of the sender account.
AccountResponse accountA = await sdk.accounts.account(senderAccountId);

// Create the receiver account.
Transaction transaction = new TransactionBuilder(accountA)
    .addOperation(
        new CreateAccountOperationBuilder(accountCId, "10").build())
    .build();

// Sign.
transaction.sign(senderKeyPair, Network.TESTNET);

// Submit.
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

// Now let's create the mxued accounts to be used in the payment transaction.
MuxedAccount muxedDestinationAccount = MuxedAccount(accountCId, 8298298319);
MuxedAccount muxedSourceAccount = MuxedAccount(senderAccountId, 2442424242);

// Build the payment operation.
// We use the muxed account objects for destination and for source here.
// This is not needed, you can also use only a muxed source account or muxed destination account.
PaymentOperation paymentOperation =
    PaymentOperationBuilder.forMuxedDestinationAccount(
            muxedDestinationAccount, Asset.NATIVE, "100")
        .setMuxedSourceAccount(muxedSourceAccount)
        .build();

// Build the transaction.
// If we want to use a Med25519 muxed account with id as a source of the transaction, we can just set the id in our account object.
accountA.muxedAccountMed25519Id = 44498494844;
transaction = new TransactionBuilder(accountA)
    .addOperation(paymentOperation)
    .build();

// Sign.
transaction.sign(senderKeyPair, Network.TESTNET);

// Submit.
response = await sdk.submitTransaction(transaction);

// Have a look to the transaction and the contents of the envelope in Stellar Laboratory
// https://laboratory.stellar.org/#explorer?resource=transactions&endpoint=single&network=test
print(response.hash);
```
