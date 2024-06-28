@Timeout(const Duration(seconds: 400))
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  Network network = Network.TESTNET;

  test('clawback and claimabale balance clawback', () async {
    KeyPair masterAccountKeyPair = KeyPair.random();
    String masterAccountId = masterAccountKeyPair.accountId;
    await FriendBot.fundTestAccount(masterAccountId);

    KeyPair destinationAccountKeyPair = KeyPair.random();
    String destinationAccountId = destinationAccountKeyPair.accountId;

    AccountResponse masterAccount = await sdk.accounts.account(masterAccountId);

    Transaction transaction = new TransactionBuilder(masterAccount)
        .addOperation(new CreateAccountOperationBuilder(destinationAccountId, "10").build())
        .build();

    transaction.sign(masterAccountKeyPair, network);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("destination account created:" + destinationAccountId);
    print("destination account created:" + destinationAccountKeyPair.secretSeed);

    KeyPair skyIssuerAccountKeyPair = KeyPair.random();
    String skyIssuerAccountId = skyIssuerAccountKeyPair.accountId;

    masterAccount = await sdk.accounts.account(masterAccountId);

    transaction = new TransactionBuilder(masterAccount)
        .addOperation(new CreateAccountOperationBuilder(skyIssuerAccountId, "10").build())
        .build();

    transaction.sign(masterAccountKeyPair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("sky issuer account created:" + skyIssuerAccountId);
    print("sky issuer account created:" + skyIssuerAccountKeyPair.secretSeed);

    AccountResponse skyIssuerAccount = await sdk.accounts.account(skyIssuerAccountId);

    // enable clawback
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();

    transaction = new TransactionBuilder(skyIssuerAccount)
        .addOperation(setOp
            .setSetFlags(AccountFlag.AUTH_CLAWBACK_ENABLED_FLAG.value |
                AccountFlag.AUTH_REVOCABLE_FLAG.value)
            .build())
        .addMemo(Memo.text("Test enable clawback"))
        .build();

    transaction.sign(skyIssuerAccountKeyPair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("clawback enabled");

    String assetCode = "SKY";
    Asset sky = AssetTypeCreditAlphaNum4(assetCode, skyIssuerAccount.accountId);

    String limit = "10000";

    AccountResponse destinationAccount = await sdk.accounts.account(destinationAccountId);
    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(sky, limit);
    transaction = TransactionBuilder(destinationAccount).addOperation(ctob.build()).build();
    transaction.sign(destinationAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("destination account is trusting");

    skyIssuerAccount = await sdk.accounts.account(skyIssuerAccountId);
    // send 100 SKY
    transaction = new TransactionBuilder(skyIssuerAccount)
        .addOperation(PaymentOperationBuilder(destinationAccountId, sky, "100").build())
        .build();
    transaction.sign(skyIssuerAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    bool found = false;
    destinationAccount = await sdk.accounts.account(destinationAccountId);
    for (Balance balance in destinationAccount.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == assetCode) {
        assert(double.parse(balance.balance) > 90);
        found = true;
        break;
      }
    }
    assert(found);

    print("destination account received sky");

    skyIssuerAccount = await sdk.accounts.account(skyIssuerAccountId);

    // clawback
    transaction = new TransactionBuilder(skyIssuerAccount)
        .addOperation(ClawbackOperationBuilder(sky, destinationAccountId, "80").build())
        .build();
    transaction.sign(skyIssuerAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    found = false;
    destinationAccount = await sdk.accounts.account(destinationAccountId);
    for (Balance balance in destinationAccount.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == assetCode) {
        assert(double.parse(balance.balance) < 30);
        found = true;
        break;
      }
    }
    assert(found);

    print("clawback success");

    KeyPair claimantAccountKeyPair = KeyPair.random();
    String claimantAccountId = claimantAccountKeyPair.accountId;

    masterAccount = await sdk.accounts.account(masterAccountId);

    transaction = new TransactionBuilder(masterAccount)
        .addOperation(new CreateAccountOperationBuilder(claimantAccountId, "10").build())
        .build();

    transaction.sign(masterAccountKeyPair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("claimant account created:" + claimantAccountId);
    print("claimant account created:" + claimantAccountKeyPair.secretSeed);

    AccountResponse claimantAccount = await sdk.accounts.account(claimantAccountId);
    transaction = TransactionBuilder(claimantAccount).addOperation(ctob.build()).build();
    transaction.sign(claimantAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("claimant account account is trusting");

    claimantAccount = await sdk.accounts.account(claimantAccountId);

    bool cenabled = false;
    for (Balance balance in claimantAccount.balances) {
      if (balance.assetCode == assetCode && balance.isClawbackEnabled!) {
        cenabled = true;
        break;
      }
    }
    assert(cenabled);

    destinationAccount = await sdk.accounts.account(destinationAccountId);
    Claimant claimant = Claimant(claimantAccountId, Claimant.predicateUnconditional());
    CreateClaimableBalanceOperationBuilder opb =
        CreateClaimableBalanceOperationBuilder([claimant], sky, "10.00");

    transaction = new TransactionBuilder(destinationAccount)
        .addOperation(opb.build())
        .addMemo(Memo.text("create claimable balance"))
        .build();

    transaction.sign(destinationAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    Page<ClaimableBalanceResponse> claimableBalances =
        await sdk.claimableBalances.forClaimant(claimantAccountId).execute();
    assert(claimableBalances.records.length == 1);
    ClaimableBalanceResponse cb = claimableBalances.records[0];

    String balanceId = cb.balanceId;
    print("claimable balance created: " + balanceId);

    // clawback claimable balance
    skyIssuerAccount = await sdk.accounts.account(skyIssuerAccountId);

    // clawback claimable balance
    transaction = new TransactionBuilder(skyIssuerAccount)
        .addOperation(ClawbackClaimableBalanceOperationBuilder(balanceId).build())
        .build();
    transaction.sign(skyIssuerAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    print("claimable balance clawed back");

    claimableBalances = await sdk.claimableBalances.forClaimant(claimantAccountId).execute();
    assert(claimableBalances.records.length == 0);
    print("clawback claimable balance success");

    var effectsPage = await sdk.effects
        .forAccount(skyIssuerAccountId)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    var effects = effectsPage.records;
    assert(effects.isNotEmpty);
    String? bid;
    for (EffectResponse res in effects) {
      if (res is ClaimableBalanceClawedBackEffectResponse) {
        ClaimableBalanceClawedBackEffectResponse effect = res;
        bid = effect.balanceId;
        break;
      }
    }
    assert(bid != null);
    print("clawed back bid: " + bid!);

    // clear trustline clawback enabled flag
    skyIssuerAccount = await sdk.accounts.account(skyIssuerAccountId);

    transaction = new TransactionBuilder(skyIssuerAccount)
        .addOperation(SetTrustLineFlagsOperationBuilder(
                claimantAccountId, sky, XdrTrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG.value, 0)
            .build())
        .build();
    transaction.sign(skyIssuerAccountKeyPair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    effectsPage = await sdk.effects
        .forAccount(skyIssuerAccountId)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    effects = effectsPage.records;
    assert(effects.length > 0);

    bool ok = false;
    for (EffectResponse res in effects) {
      if (res is TrustLineFlagsUpdatedEffectResponse) {
        TrustLineFlagsUpdatedEffectResponse effect = res;
        if (effect.clawbackEnabledFlag != null && !effect.clawbackEnabledFlag!) {
          ok = true;
        }
        break;
      }
    }
    assert(ok);

    claimantAccount = await sdk.accounts.account(claimantAccountId);

    ok = false;
    for (Balance balance in claimantAccount.balances) {
      if (balance.assetCode == assetCode && balance.isClawbackEnabled == null) {
        ok = true;
        break;
      }
    }
    assert(ok);
    print("cleared trustline flag");

    var operationsPage = await sdk.operations
        .forAccount(skyIssuerAccountKeyPair.accountId)
        .execute();
    assert(operationsPage.records.isNotEmpty);
  });
}
