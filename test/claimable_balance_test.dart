import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test claimable balance', () async {
    KeyPair sourceAccountKeyxPair = KeyPair.random();
    String sourceAccountId = sourceAccountKeyxPair.accountId;
    await FriendBot.fundTestAccount(sourceAccountId);
    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);

    KeyPair firstClaimantKp = KeyPair.random();
    print("fist claimant public key: " + firstClaimantKp.accountId);
    print("fist claimant seed: " + firstClaimantKp.secretSeed);

    String fistClaimantId = firstClaimantKp.accountId;
    KeyPair secondClaimantKp = KeyPair.random();
    Claimant firstClaimant =
        Claimant(fistClaimantId, Claimant.predicateUnconditional());
    XdrClaimPredicate predicateA = Claimant.predicateBeforeRelativeTime(100);
    XdrClaimPredicate predicateB =
        Claimant.predicateBeforeAbsoluteTime(1634000400);
    XdrClaimPredicate predicateC = Claimant.predicateNot(predicateA);
    XdrClaimPredicate predicateD =
        Claimant.predicateAnd(predicateC, predicateB);
    XdrClaimPredicate predicateE =
        Claimant.predicateBeforeAbsoluteTime(1601671345);
    XdrClaimPredicate predicateF = Claimant.predicateOr(predicateD, predicateE);
    Claimant secondClaimant = Claimant(secondClaimantKp.accountId, predicateF);
    List<Claimant> claimants = [];
    claimants.add(firstClaimant);
    claimants.add(secondClaimant);
    CreateClaimableBalanceOperationBuilder opb =
        CreateClaimableBalanceOperationBuilder(
            claimants, Asset.NATIVE, "12.33");

    Transaction transaction = new TransactionBuilder(sourceAccount)
        .addOperation(opb.build())
        .addMemo(Memo.text("createclaimablebalance"))
        .build();

    transaction.sign(sourceAccountKeyxPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    Page<EffectResponse> effectsPage = await sdk.effects
        .forAccount(sourceAccountId)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();

    var effects = effectsPage.records;
    assert(effects.isNotEmpty);

    String? bid;
    for (EffectResponse res in effects) {
      if (res is ClaimableBalanceCreatedEffectResponse) {
        ClaimableBalanceCreatedEffectResponse effect = res;
        bid = effect.balanceId;
        print('Claimable Balance ID: $bid');
        if (!bid.startsWith("B")) {
          final strKeyCid = StrKey.encodeClaimableBalanceIdHex(bid);
          print('Claimable Balance ID StrKey: $strKeyCid');
        }
        break;
      }
    }
    assert(bid != null);

    var operationsPage =
        await sdk.operations.forAccount(sourceAccountId).execute();
    assert(operationsPage.records.isNotEmpty);

    Page<ClaimableBalanceResponse> claimableBalances = await sdk
        .claimableBalances
        .forClaimant(firstClaimantKp.accountId)
        .execute();
    assert(claimableBalances.records.length == 1);
    ClaimableBalanceResponse cb = claimableBalances.records[0];
    await FriendBot.fundTestAccount(fistClaimantId);

    ClaimClaimableBalanceOperationBuilder opc =
        ClaimClaimableBalanceOperationBuilder(cb.balanceId);

    AccountResponse claimant =
        await sdk.accounts.account(firstClaimantKp.accountId);
    transaction = new TransactionBuilder(claimant)
        .addOperation(opc.build())
        .addMemo(Memo.text("claimclaimablebalance"))
        .build();

    transaction.sign(firstClaimantKp, Network.TESTNET);

    print(transaction.toEnvelopeXdrBase64());

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    operationsPage =
        await sdk.operations.forAccount(firstClaimantKp.accountId).execute();
    assert(operationsPage.records.isNotEmpty);
    effectsPage =
        await sdk.effects.forAccount(firstClaimantKp.accountId).execute();
    assert(effectsPage.records.isNotEmpty);
  });
}
