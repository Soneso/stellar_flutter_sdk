@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('quick-start: Your First KeyPair', () {
    // Snippet from quick-start.md "Your First KeyPair"
    KeyPair keyPair = KeyPair.random();

    expect(keyPair.accountId, startsWith('G'));
    expect(keyPair.accountId.length, 56);
    expect(keyPair.secretSeed, startsWith('S'));
    expect(keyPair.secretSeed.length, 56);
  });

  test('quick-start: Creating Accounts', () async {
    // Snippet from quick-start.md "Creating Accounts"
    KeyPair keyPair = KeyPair.random();

    bool funded = await FriendBot.fundTestAccount(keyPair.accountId);

    expect(funded, true);
  });

  test('quick-start: Your First Transaction', () async {
    // Snippet from quick-start.md "Your First Transaction"
    // Setup: create and fund sender + destination
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(senderKeyPair.accountId);
    await FriendBot.fundTestAccount(destinationKeyPair.accountId);
    String destinationId = destinationKeyPair.accountId;

    // Code from the snippet (with real keys instead of placeholders)
    AccountResponse senderAccount =
        await sdk.accounts.account(senderKeyPair.accountId);

    PaymentOperation paymentOp = PaymentOperationBuilder(
      destinationId,
      Asset.NATIVE,
      "10",
    ).build();

    Transaction transaction = TransactionBuilder(senderAccount)
        .addOperation(paymentOp)
        .build();

    transaction.sign(senderKeyPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, true);
    expect(response.hash, isNotNull);
  });

  test('quick-start: Complete Example', () async {
    // Snippet from quick-start.md "Complete Example"
    // 1. Generate two keypairs
    KeyPair alice = KeyPair.random();
    KeyPair bob = KeyPair.random();

    expect(alice.accountId, startsWith('G'));
    expect(bob.accountId, startsWith('G'));

    // 2. Fund both accounts on testnet
    await FriendBot.fundTestAccount(alice.accountId);
    await FriendBot.fundTestAccount(bob.accountId);

    // 3. Connect to testnet
    StellarSDK sdk = StellarSDK.TESTNET;

    // 4. Load Alice's account
    AccountResponse aliceAccount =
        await sdk.accounts.account(alice.accountId);

    // 5. Build payment: Alice sends 100 XLM to Bob
    PaymentOperation paymentOp = PaymentOperationBuilder(
      bob.accountId,
      Asset.NATIVE,
      "100",
    ).build();

    Transaction transaction = TransactionBuilder(aliceAccount)
        .addOperation(paymentOp)
        .build();

    // 6. Sign with Alice's key
    transaction.sign(alice, Network.TESTNET);

    // 7. Submit to network
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, true);
    expect(response.hash, isNotNull);

    // 8. Check Bob's new balance
    AccountResponse bobAccount =
        await sdk.accounts.account(bob.accountId);
    bool foundNativeBalance = false;
    for (Balance balance in bobAccount.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        foundNativeBalance = true;
        // Bob started with 10000 from FriendBot + 100 from Alice
        expect(double.parse(balance.balance), greaterThanOrEqualTo(10100.0));
      }
    }
    expect(foundNativeBalance, true);
  });
}
