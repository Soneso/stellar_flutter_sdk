import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:math';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  String testSeed = "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF";
  KeyPair keyPairA;
  KeyPair keyPairB = KeyPair.random();
  AccountResponse accountA;
  AccountResponse accountB;

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
      print("Account A: ${keyPairA.accountId} : ${keyPairA.secretSeed}");
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

        assert(accountA.flags.authRequired == false);
        assert(accountA.flags.authImmutable == false);

        for (String key in accountA.data.keys) {
          print("data key: ${key} value: ${accountA.data[key]}");
        }
      }

      // fund account B.
      Transaction transaction =
          new TransactionBuilder(accountA, Network.TESTNET)
              .addOperation(
                  new CreateAccountOperationBuilder(keyPairB.accountId, "10")
                      .build())
              .addMemo(Memo.text("Test create account"))
              .build();

      transaction.sign(keyPairA);

      await sdk.submitTransaction(transaction).then((response) {
        assert(response.success);
      }).catchError((error) {
        print(error);
        assert(false);
      });
    });
  });

  test('test set account options', () async {
    String accountAId = keyPairA.accountId;
    accountA = await sdk.accounts.account(keyPairA.accountId);
    int seqNum = accountA.sequenceNumber;

    // Signer account B.
    XdrSignerKey bKey = XdrSignerKey();
    bKey.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
    bKey.ed25519 = keyPairB.xdrPublicKey.getEd25519();

    var rng = new Random();
    String newHomeDomain = "www." + rng.nextInt(10000).toString() + ".com";

    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();

    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(setOp
            .setHomeDomain(newHomeDomain)
            .setSigner(bKey, 1)
            .setHighThreshold(5)
            .setMasterKeyWeight(5)
            .setMediumThreshold(3)
            .setLowThreshold(1)
            .setSetFlags(2)
            .build())
        .addMemo(Memo.text("Test create account"))
        .build();

    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
    }).catchError((error) {
      print(error);
      assert(false);
    });

    accountA = await sdk.accounts.account(keyPairA.accountId);
    assert(accountA.sequenceNumber > seqNum);
    assert(accountA.homeDomain == newHomeDomain);
    assert(accountA.thresholds.highThreshold == 5);
    assert(accountA.thresholds.medThreshold == 3);
    assert(accountA.thresholds.lowThreshold == 1);
    assert(accountA.signers.length > 1);
    bool bFound = false;
    bool aFound = false;
    for (Signer signer in accountA.signers) {
      if (signer.accountId == keyPairB.accountId) {
        bFound = true;
      }
      if (signer.accountId == keyPairA.accountId) {
        aFound = true;
        assert(signer.weight == 5);
      }
    }
    assert(aFound);
    assert(bFound);
    assert(accountA.flags.authRequired == false);
    assert(accountA.flags.authRevocable == true);
    assert(accountA.flags.authImmutable == false);

    // Find account for signer.
    AccountsRequestBuilder ab = sdk.accounts.forSigner(keyPairB.accountId);
    Page<AccountResponse> accounts = await ab.execute();
    aFound = false;
    for (AccountResponse account in accounts.records) {
      if (account.accountId == keyPairA.accountId) {
        aFound = true;
      }
    }
    assert(aFound);
  });

  test('test find accounts for asset', () async {
    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;
    accountA = await sdk.accounts.account(keyPairA.accountId);
    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("C created: " + accountCId);
    }).catchError((error) {
      print(error);
      assert(false);
    });

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperationBuilder chOp =
        ChangeTrustOperationBuilder(iomAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairC);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("C trusts IOM:A");
    }).catchError((error) {
      print(error);
      assert(false);
    });

    // Find account for signer.
    AccountsRequestBuilder ab = sdk.accounts.forAsset(iomAsset);
    Page<AccountResponse> accounts = await ab.execute();
    bool cFound = false;
    for (AccountResponse account in accounts.records) {
      if (account.accountId == keyPairC.accountId) {
        cFound = true;
        print("C found for asset");
      }
    }
    assert(cFound);
  });
}
