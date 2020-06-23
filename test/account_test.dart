import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {

  StellarSDK sdk = StellarSDK.TESTNET;
  String testSeed = "SDZMX7UQHIEX7KITGU4PBBI26U5NVZVRIVIJ53L7B7P52RTIVCO7YOKL";
  KeyPair keyPairA;
  KeyPair keyPairB = KeyPair.random();

  setUp(() async {
    keyPairA = KeyPair.fromSecretSeed(testSeed); // KeyPair.random();
    print(
        "Account A is ready: ${keyPairA.accountId} : ${keyPairA.secretSeed}");

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

  test('test get account details', () async {
    String accountAId = keyPairA.accountId;
    await sdk.accounts.account(keyPairA.accountId).then((account) {
      assert(account.keypair.accountId == accountAId);

      print("Balances for account: ${keyPairA.accountId}");

      for (Balance balance in account.balances) {
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

        print("sequence number: ${account.sequenceNumber}");

        for (Signer signer in account.signers) {
          print("signer public key: ${signer.accountId}");
        }

        print("auth required: ${account.flags.authRequired}");
        print("auth revocable: ${account.flags.authRevocable}");

        for (String key in account.data.keys) {
          print("data key: ${key} value: ${account.data[key]}");
        }
      }
    });
  });
}
