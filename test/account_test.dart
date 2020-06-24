import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:math';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  String testSeed = "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF";
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
          print("data key: $key value: ${accountA.data[key]}");
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
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
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

  test('test account merge', () async {

    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    await FriendBot.fundTestAccount(accountXId);
    await FriendBot.fundTestAccount(accountYId);

    AccountMergeOperationBuilder accMergeOp =
        AccountMergeOperationBuilder(accountXId);

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction = TransactionBuilder(accountY, Network.TESTNET)
        .addOperation(accMergeOp.build())
        .build();

    transaction.sign(keyPairY);

    await sdk.submitTransaction(transaction);

    await sdk.accounts.account(accountYId).then((response) {
      print("account still exists: ${accountYId}");
      assert(false);
    }).catchError((error) {
      print(error.toString());
      assert(error is ErrorResponse && error.code == 404);
    });

  });

  test('test bump sequence', () async {

    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);
    int startSequence = account.sequenceNumber;

    BumpSequenceOperationBuilder bumpSequenceOpB =
    BumpSequenceOperationBuilder(startSequence + 10);

    Transaction transaction = TransactionBuilder(account, Network.TESTNET)
        .addOperation(bumpSequenceOpB.build())
        .build();

    transaction.sign(keyPair);

    await sdk.submitTransaction(transaction);

    account = await sdk.accounts.account(accountId);

    assert(startSequence + 10 == account.sequenceNumber);

  });

  test('test manage data', () async {

    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);

    String key = "Sommer";
    String value = "Die Möbel sind heiß!";

    List<int> list = value.codeUnits;
    Uint8List valueBytes = Uint8List.fromList(list);

    ManageDataOperationBuilder
    manageDataOperationBuilder =
    ManageDataOperationBuilder(key, valueBytes);

    Transaction transaction = TransactionBuilder(account, Network.TESTNET)
        .addOperation(manageDataOperationBuilder.build())
        .build();

    transaction.sign(keyPair);

    await sdk.submitTransaction(transaction);

    account = await sdk.accounts.account(accountId);

    Uint8List resultBytes = account.data.getDecoded(key);
    String restltValue = String.fromCharCodes(resultBytes);

    assert(value == restltValue);

    manageDataOperationBuilder =
        ManageDataOperationBuilder(key, null);

    transaction = TransactionBuilder(account, Network.TESTNET)
        .addOperation(manageDataOperationBuilder.build())
        .build();

    transaction.sign(keyPair);

    await sdk.submitTransaction(transaction);

    account = await sdk.accounts.account(accountId);

    assert(!account.data.keys.contains(key));

  });
}
