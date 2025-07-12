import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

import 'tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  StellarSDK sdk =
  testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  test('test sponsorship', () async {
    KeyPair masterAccountKeyPair = KeyPair.random();
    String masterAccountId = masterAccountKeyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(masterAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(masterAccountId);
    }

    AccountResponse masterAccount = await sdk.accounts.account(masterAccountId);

    KeyPair accountAKeyPair = KeyPair.random();
    String accountAId = accountAKeyPair.accountId;
    print("ACC: " + accountAId);

    BeginSponsoringFutureReservesOperationBuilder beginSponsoringBuilder =
        BeginSponsoringFutureReservesOperationBuilder(accountAId)
            .setSourceAccount(masterAccountId);
    CreateAccountOperationBuilder createAccountBuilder =
        CreateAccountOperationBuilder(accountAId, "100");
    String dataName = "soneso";
    String dataValue = "is super";

    List<int> list = dataValue.codeUnits;
    Uint8List valueBytes = Uint8List.fromList(list);
    ManageDataOperationBuilder manageDataBuilder =
        ManageDataOperationBuilder(dataName, valueBytes)
            .setSourceAccount(accountAId);

    Asset? richAsset = Asset.createFromCanonicalForm("RICH:" + masterAccountId);
    ChangeTrustOperationBuilder changeTrustBuilder =
        ChangeTrustOperationBuilder(richAsset!, "100000")
            .setSourceAccount(accountAId);
    PaymentOperationBuilder paymentBuilder =
        PaymentOperationBuilder(accountAId, richAsset, "1000");
    ManageSellOfferOperationBuilder manageSellOfferBuilder =
        ManageSellOfferOperationBuilder(richAsset, Asset.NATIVE, "10", "2")
            .setSourceAccount(accountAId);

    Claimant claimant =
        Claimant(masterAccountId, Claimant.predicateUnconditional());
    List<Claimant> claimants = [];
    claimants.add(claimant);

    CreateClaimableBalanceOperationBuilder createClaimBuilder =
        CreateClaimableBalanceOperationBuilder(claimants, richAsset, "10");

    SetOptionsOperationBuilder setOptionsBuilder =
        SetOptionsOperationBuilder().setSourceAccount(accountAId);
    XdrSignerKey signer =
        XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
    signer.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(masterAccountId));
    setOptionsBuilder.setSigner(signer, 1);

    EndSponsoringFutureReservesOperationBuilder endSponsorshipBuilder =
        EndSponsoringFutureReservesOperationBuilder()
            .setSourceAccount(accountAId);

    RevokeSponsorshipOperationBuilder revokeAccountSpBuilder =
        RevokeSponsorshipOperationBuilder()
            .revokeAccountSponsorship(accountAId);
    RevokeSponsorshipOperationBuilder revokeDataSpBuilder =
        RevokeSponsorshipOperationBuilder()
            .revokeDataSponsorship(accountAId, dataName);
    RevokeSponsorshipOperationBuilder revokeTrustlineSpBuilder =
        RevokeSponsorshipOperationBuilder()
            .revokeTrustlineSponsorship(accountAId, richAsset);
    RevokeSponsorshipOperationBuilder revokeSignerSpBuilder =
        RevokeSponsorshipOperationBuilder()
            .revokeEd25519Signer(accountAId, masterAccountId);

    Transaction transaction = new TransactionBuilder(masterAccount)
        .addOperation(beginSponsoringBuilder.build())
        .addOperation(createAccountBuilder.build())
        .addOperation(manageDataBuilder.build())
        .addOperation(changeTrustBuilder.build())
        .addOperation(paymentBuilder.build())
        .addOperation(manageSellOfferBuilder.build())
        .addOperation(createClaimBuilder.build())
        .addOperation(setOptionsBuilder.build())
        .addOperation(endSponsorshipBuilder.build())
        .addOperation(revokeAccountSpBuilder.build())
        .addOperation(revokeDataSpBuilder.build())
        .addOperation(revokeTrustlineSpBuilder.build())
        .addOperation(revokeSignerSpBuilder.build())
        .addMemo(Memo.text("sponsor"))
        .build();

    transaction.sign(masterAccountKeyPair, network);
    transaction.sign(accountAKeyPair, network);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations
        .forTransaction(response.hash!)
        .execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects
        .forTransaction(response.hash!)
        .execute();
    assert(effectsPage.records.isNotEmpty);
  });
}
