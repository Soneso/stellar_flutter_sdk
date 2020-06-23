import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {

  StellarSDK sdk = StellarSDK.TESTNET;
  String testSeed = "SDZMX7UQHIEX7KITGU4PBBI26U5NVZVRIVIJ53L7B7P52RTIVCO7YOKL";
  KeyPair keyPairA;
  KeyPair keyPairB = KeyPair.random();
  AccountResponse accountA;

  setUp(() async {

    print("B accountID: ${keyPairB.accountId}");

    keyPairA = KeyPair.fromSecretSeed(testSeed); // KeyPair.random();

    if (testSeed != keyPairA.secretSeed) {
      await FriendBot.fundTestAccount(keyPairA.accountId).then((funded) async {
        if (funded) {
          print(
              "Funded account A: ${keyPairA.accountId} : ${keyPairA.secretSeed}");
        }
      });
    } else {
      print(
          "Account A is ready: ${keyPairA.accountId} : ${keyPairA.secretSeed}");
    }
  });

  test('test account details and fund new account', () async {
    String accountAId = keyPairA.accountId;
    await sdk.accounts.account(keyPairA.accountId).then((account) async {
      accountA = account;
      assert(accountA.keypair.accountId == accountAId);

      for (Balance balance in accountA.balances) {
        print(
            "Type: ${balance.assetType}, Code: ${balance.assetCode}, Balance: ${balance.balance}");

        switch (balance.assetType) {
          case Asset.TYPE_NATIVE:
            {
              print("balance: ${balance.balance} XLM");
              assert(double.parse(balance.balance) > 1.0);
              break;
            }
          default:
            {
              print(
                  "balance: ${balance.balance} ${balance.assetCode} issuer: ${balance.assetIssuer}");
            }
        }

        print("sequence number: ${accountA.sequenceNumber}");
        assert(accountA.sequenceNumber > 0);

        for (Signer signer in accountA.signers) {
          print("signer public key: ${signer.accountId}");

        }

        print("auth required: ${account.flags.authRequired}");
        assert(accountA.flags.authRequired == false);
        print("auth revocable: ${account.flags.authRevocable}");
        assert(accountA.flags.authRevocable == false);
        print("auth revocable: ${account.flags.authImmutable}");
        assert(accountA.flags.authImmutable == false);

        for (String key in accountA.data.keys) {
          print("data key: ${key} value: ${accountA.data[key]}");
        }
      }

      // fund account B.
      Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
          .addOperation(new CreateAccountOperationBuilder(
          keyPairB.accountId, "10")
          .build())
          .addMemo(Memo.text("Test create account"))
          .build();

      transaction.sign(keyPairA);

      await sdk.submitTransaction(transaction).then((response) {
        print("Success!");
        print(response.envelopeXdr);
        assert(true);
      }).catchError((error) {
        print("Something went wrong!");
        assert(false);
      });
    });
  });
}
