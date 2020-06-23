import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

void main() {

  test('test first test', () async {
    KeyPair keypair = KeyPair.random();
    String accountId = keypair.accountId;
    Account account = new Account(keypair, 100);
    assert(account.keypair.accountId == accountId);
    assert(account.sequenceNumber == 100);

    var url = "https://friendbot.stellar.org/?addr=${accountId}";
    http.get(url).then((response) {
      switch (response.statusCode) {
        case 200:
          {
            print("new account created : \n${response.body}");
            getAccountDetails(accountId);
            break;
          }
        default:
          {
            print("err: \n${response.body}");
          }
      }
    });
    await Future.delayed(const Duration(seconds: 15), (){});
  });
}

void getAccountDetails(String accountId) {
  KeyPair pair = KeyPair.fromAccountId(accountId);
  
  StellarSDK.TESTNET.accounts.account(pair.accountId).then((account) {
    print("Balances for account: ${pair.accountId}");

    for (Balance balance in account.balances) {
      print(
          "Type: ${balance.assetType}, Code: ${balance.assetCode}, Balance: ${balance.balance}");

      switch (balance.assetType) {
        case "native":
          {
            print("balance: ${balance.balance} XLM");
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
}