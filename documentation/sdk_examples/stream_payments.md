
### Stream for payments

In this example we will listen for received payments for an account.

```dart
 // Create two accounts, so that we can send a payment.
KeyPair keyPairA = KeyPair.random();
KeyPair keyPairB = KeyPair.random();
String accountBId = keyPairB.accountId;
String accountAId = keyPairA.accountId;
await FriendBot.fundTestAccount(accountAId);
await FriendBot.fundTestAccount(accountBId);

// Load current data of account B.
AccountResponse accountB = await sdk.accounts.account(accountBId);

// Subscribe to listen for payments for account A.
// If we set the cursor to "now" it will not receive old events such as the create account operation.
StreamSubscription subscription = sdk.payments.forAccount(accountAId).cursor("now").stream().listen((response) {
  if (response is PaymentOperationResponse) {
    switch (response.assetType) {
      case Asset.TYPE_NATIVE:
        print("Payment of ${response.amount} XLM from ${response.sourceAccount} received.");
        break;
      default:
        print("Payment of ${response.amount} ${response.assetCode} from ${response.sourceAccount} received.");
    }
  }
});

// Send 10 XLM from account B to account A.
Transaction transaction = new TransactionBuilder(accountB, Network.TESTNET)
    .addOperation(PaymentOperationBuilder(accountAId, Asset.NATIVE, "10").build())
    .build();
transaction.sign(keyPairB);
await sdk.submitTransaction(transaction);

// When you are done listening to that stream, for any reason, you may close/cancel the subscription.
// In this example we wait 5 seconds for the payment event.
await Future.delayed(const Duration(seconds: 5), () {});
// Now cancel the subscription.
subscription.cancel();
```
