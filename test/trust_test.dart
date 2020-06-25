@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('change trust test', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    await FriendBot.fundTestAccount(trustorAccountId);

    AccountResponse trustorAccount = await sdk.accounts.account(trustorAccountId);
    CreateAccountOperationBuilder caob = CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    String limit = "10000";
    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    bool found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.limit) == double.parse(limit));
        break;
      }
    }
    assert(found);

    // update trustline, change limit.
    limit = "40000";
    ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.limit) == double.parse(limit));
        break;
      }
    }
    assert(found);

    // delete trustline.
    limit = "0";
    ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        break;
      }
    }
    assert(!found);
  });
}
