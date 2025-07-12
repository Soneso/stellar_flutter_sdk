import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:math';

import 'tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  test('test set account options', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountAId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountAId);
    }
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);
    BigInt seqNum = accountA.sequenceNumber;

    KeyPair keyPairB = KeyPair.random();

    // Signer account B.
    XdrSignerKey bKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
    bKey.ed25519 = keyPairB.xdrPublicKey.getEd25519();

    var rng = new Random();
    String newHomeDomain = "www." + rng.nextInt(10000).toString() + ".com";

    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();

    Transaction transaction = new TransactionBuilder(accountA)
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

    transaction.sign(keyPairA, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    assert(response.successfulTransaction != null);
    assert(response.successfulTransaction!.id == response.hash!);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    accountA = await sdk.accounts.account(keyPairA.accountId);

    assert(accountA.sequenceNumber > seqNum);
    assert(accountA.homeDomain == newHomeDomain);
    assert(accountA.thresholds.highThreshold == 5);
    assert(accountA.thresholds.medThreshold == 3);
    assert(accountA.thresholds.lowThreshold == 1);
    assert(accountA.signers.length > 1);
    bool bFound = false;
    bool aFound = false;
    for (Signer? signer in accountA.signers) {
      if (signer!.accountId == keyPairB.accountId) {
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
    Page<AccountResponse> accounts =
        await sdk.accounts.forSigner(keyPairB.accountId).execute();
    aFound = false;
    for (AccountResponse? account in accounts.records) {
      if (account!.accountId == keyPairA.accountId) {
        aFound = true;
        break;
      }
    }
    assert(aFound);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountAId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountAId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test find accounts for asset', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountAId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountAId);
    }
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperation changeTrustOperation =
        ChangeTrustOperationBuilder(iomAsset, "200999").build();

    transaction = new TransactionBuilder(accountC)
        .addOperation(changeTrustOperation)
        .build();

    transaction.sign(keyPairC, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Find account for asset.
    AccountsRequestBuilder ab = sdk.accounts.forAsset(iomAsset);
    Page<AccountResponse> accounts = await ab.execute();
    bool cFound = false;
    for (AccountResponse account in accounts.records) {
      if (account.accountId == keyPairC.accountId) {
        cFound = true;
      }
    }
    assert(cFound);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountAId).execute();
    assert(operationsPage.records.isNotEmpty);
    operationsPage = await sdk.operations.forAccount(accountCId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountAId).execute();
    assert(effectsPage.records.isNotEmpty);
    effectsPage = await sdk.effects.forAccount(accountCId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test account merge', () async {
    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountXId);
      await FriendBot.fundTestAccount(accountYId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountXId);
      await FuturenetFriendBot.fundTestAccount(accountYId);
    }

    AccountMergeOperation accountMergeOperation =
        AccountMergeOperationBuilder(accountXId).build();

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction = TransactionBuilder(accountY)
        .addOperation(accountMergeOperation)
        .build();

    transaction.sign(keyPairY, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    await sdk.accounts.account(accountYId).then((response) {
      assert(false);
    }).catchError((error) {
      print(error.toString());
      assert(error is ErrorResponse && error.code == 404);
    });

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountXId).execute();
    assert(operationsPage.records.isNotEmpty);
    operationsPage = await sdk.operations.forAccount(accountYId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountXId).execute();
    assert(effectsPage.records.isNotEmpty);
    effectsPage = await sdk.effects.forAccount(accountYId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test account merge muxed source and destination account', () async {
    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountXId);
      await FriendBot.fundTestAccount(accountYId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountXId);
      await FuturenetFriendBot.fundTestAccount(accountYId);
    }

    MuxedAccount muxedDestinationAccount = MuxedAccount(accountXId, 10120291);
    MuxedAccount muxedSourceAccount = MuxedAccount(accountYId, 9999999999);

    AccountMergeOperation accountMergeOperation =
        AccountMergeOperationBuilder.forMuxedDestinationAccount(
                muxedDestinationAccount)
            .setMuxedSourceAccount(muxedSourceAccount)
            .build();

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction = TransactionBuilder(accountY)
        .addOperation(accountMergeOperation)
        .build();

    transaction.sign(keyPairY, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    //print(response.hash);

    await sdk.accounts.account(accountYId).then((response) {
      assert(false);
    }).catchError((error) {
      print(error.toString());
      assert(error is ErrorResponse && error.code == 404);
    });

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountXId).execute();
    assert(operationsPage.records.isNotEmpty);
    operationsPage = await sdk.operations.forAccount(accountYId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountXId).execute();
    assert(effectsPage.records.isNotEmpty);
    effectsPage = await sdk.effects.forAccount(accountYId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test bump sequence', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountId);
    }

    AccountResponse account = await sdk.accounts.account(accountId);
    BigInt startSequence = account.sequenceNumber;

    BumpSequenceOperation bumpSequenceOperation =
        BumpSequenceOperationBuilder(startSequence + BigInt.from(10)).build();

    Transaction transaction =
        TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);

    assert(startSequence + BigInt.from(10) == account.sequenceNumber);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test manage data', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountId);
    }

    AccountResponse account = await sdk.accounts.account(accountId);

    String key = "Sommer";
    String value = "Die Möbel sind heiß!";

    List<int> list = value.codeUnits;
    Uint8List valueBytes = Uint8List.fromList(list);

    ManageDataOperation manageDataOperation =
        ManageDataOperationBuilder(key, valueBytes).build();

    Transaction transaction =
        TransactionBuilder(account).addOperation(manageDataOperation).build();

    transaction.sign(keyPair, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);

    Uint8List resultBytes = account.data.getDecoded(key);
    String resultValue = String.fromCharCodes(resultBytes);

    assert(value == resultValue);

    manageDataOperation = ManageDataOperationBuilder(key, null).build();

    transaction =
        TransactionBuilder(account).addOperation(manageDataOperation).build();
    transaction.sign(keyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);
    assert(!account.data.keys.contains(key));

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test muxed account ID (M..)', () {
    String med25519AccountId =
        'MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26';
    MuxedAccount? mux = MuxedAccount.fromAccountId(med25519AccountId);
    assert(mux!.ed25519AccountId ==
        'GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY');
    assert(mux!.id == 1234);
    assert(mux!.accountId == med25519AccountId);
  });

  test('stream transactions for an account', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(accountAId);
    } else {
      await FuturenetFriendBot.fundTestAccount(accountAId);
    }
    AccountResponse accountA = await sdk.accounts.account(accountAId);

    KeyPair keyPairB = KeyPair.random();
    String accountBId = keyPairB.accountId;

    // fund account B.
    Transaction transaction = TransactionBuilder(accountA)
        .addOperation(CreateAccountOperationBuilder(accountBId, "1000").build())
        .build();
    transaction.sign(keyPairA, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    String amount = "10";
    int count = 0;
    // Stream.
    var subscription = sdk.transactions
        .forAccount(accountAId)
        .cursor("now")
        .stream()
        .listen((response) async {
      count++;
      print("account transaction event received " + count.toString());
      assert(response.operationCount == 1);

      if (count < 3) {
        AccountResponse accountB = await sdk.accounts.account(accountBId);
        transaction = TransactionBuilder(accountB)
            .addOperation(
                PaymentOperationBuilder(accountAId, Asset.NATIVE, amount)
                    .build())
            .build();
        transaction.sign(keyPairB, network);
        SubmitTransactionResponse submitResponse =
            await sdk.submitTransaction(transaction);
        assert(submitResponse.success);
      }
    });

    AccountResponse accountB = await sdk.accounts.account(accountBId);
    transaction = TransactionBuilder(accountB)
        .addOperation(
            PaymentOperationBuilder(accountAId, Asset.NATIVE, amount).build())
        .build();
    transaction.sign(keyPairB, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    await Future.delayed(const Duration(seconds: 30), () {});

    subscription.cancel();
    assert(count == 3);
  });
}
