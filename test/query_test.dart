@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test query accounts', () async {
    KeyPair accountKeyPair = KeyPair.random();
    String accountId = accountKeyPair.accountId;
    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);
    Page<AccountResponse> accountsForSigner =
        await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records.first.accountId == accountId);

    List<KeyPair> testKeyPairs = List<KeyPair>();
    for (int i = 0; i < 3; i++) {
      testKeyPairs.add(KeyPair.random());
    }
    // Create an issuer account and a custom asset to test "accounts.forAsset()"
    KeyPair issuerkp = KeyPair.random();
    String issuerAccountId = issuerkp.accountId;

    TransactionBuilder tb = TransactionBuilder(account, Network.TESTNET);

    CreateAccountOperation createAccount =
        CreateAccountOperationBuilder(issuerAccountId, "5").build();
    tb.addOperation(createAccount);

    for (KeyPair keyp in testKeyPairs) {
      createAccount =
          CreateAccountOperationBuilder(keyp.accountId, "5").build();
      tb.addOperation(createAccount);
    }

    Transaction transaction = tb.build();
    transaction.sign(accountKeyPair);
    SubmitTransactionResponse respone =
        await sdk.submitTransaction(transaction);
    assert(respone.success);

    tb = TransactionBuilder(account, Network.TESTNET);
    for (KeyPair keyp in testKeyPairs) {
      tb.addOperation(SetOptionsOperationBuilder()
          .setSourceAccount(keyp.accountId)
          .setSigner(accountKeyPair.xdrSignerKey, 1)
          .build());
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair);
    for (KeyPair keyp in testKeyPairs) {
      transaction.sign(keyp);
    }

    respone = await sdk.submitTransaction(transaction);
    assert(respone.success);
    accountsForSigner = await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records.length == 4);
    accountsForSigner = await sdk.accounts
        .forSigner(accountId)
        .limit(2)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(accountsForSigner.records.length == 2);

    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);
    tb = TransactionBuilder(account, Network.TESTNET);
    ChangeTrustOperation ct = ChangeTrustOperationBuilder(astroDollar, "20000")
        .setSourceAccount(accountId)
        .build();
    tb.addOperation(ct);
    for (KeyPair keyp in testKeyPairs) {
      ct = ChangeTrustOperationBuilder(astroDollar, "20000")
          .setSourceAccount(keyp.accountId)
          .build();
      tb.addOperation(ct);
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair);
    respone = await sdk.submitTransaction(transaction);
    assert(respone.success);
    Page<AccountResponse> accountsForAsset =
        await sdk.accounts.forAsset(astroDollar).execute();
    assert(accountsForAsset.records.length == 4);
    accountsForAsset = await sdk.accounts
        .forAsset(astroDollar)
        .limit(2)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(accountsForAsset.records.length == 2);
  });
}
