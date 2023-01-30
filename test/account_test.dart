import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:math';

import 'tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test meta', () async{
    String xdrStr = 'AAAAAgAAAAIAAAADAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXSHbi7AAL2HsAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAABAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXSHbi7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAADQAAAAAAAAADAAAAAwAL2H0AAAAAAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAF0h24uwAC9h7AAAAAQAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAMAAAAAAAvYfQAAAABj19OQAAAAAAAAAAEAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAAAAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAUAAAAAAAvYfQAAAAMAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAGc29uZXNvAAAAAAAIaXMgc3VwZXIAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAwAL2H0AAAAAAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAFwzcGOwAC9h7AAAAAQAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAMAAAAAAAvYfQAAAABj19OQAAAAAAAAAAEAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAwAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAADAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAC9h9AAAAAAAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAA7msoAAAvYfQAAAAAAAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAADAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAABQAAAAMAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAwAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAABAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXDNwY7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAQAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAAAAAL2H0AAAABAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAAVJJQ0gAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAAAAAOjUpRAAAAAAAQAAAAAAAAABAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAADAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAwAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAC9h9AAAAAAAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAA7msoAAAvYfQAAAAAAAAACAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAEAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAgAAAAMAC9h9AAAAAQAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAFSSUNIAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAAAAADo1KUQAAAAAAEAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAL2H0AAAABAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAAVJJQ0gAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAACVAvkAAAAAOjUpRAAAAAAAQAAAAAAAAABAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAAHAAAAAwAL2H0AAAAAAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAADuaygAAC9h9AAAAAAAAAAIAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAQAAAAAAAAAAAAAAAAAAAABAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAABAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAAAwAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAL68IAAAAAAAAAAAAAAAACAAAABQAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAMAC9h9AAAAAQAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAFSSUNIAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAlQL5AAAAADo1KUQAAAAAAEAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAL2H0AAAABAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAAVJJQ0gAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAACVAvkAAAAAOjUpRAAAAAAAQAAAAEAAAAAAAAAAAAAAAAF9eEAAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAMAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAABAAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAABAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXDNwY7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAUAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAAAAAL2H0AAAACAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAAAAC/bwAAAABUklDSAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAAABfXhAAAAAAIAAAABAAAAAAAAAAAAAAABAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAADAAAAAAAL2H0AAAAEAAAAAA6of4XEs0ISnN4RidaXj8MGVwRTzeH80CV0ZxZ0tFUNAAAAAQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAVJJQ0gAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAABfXhAAAAAAAAAAABAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAADAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXDNwY7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAUAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAAAQAL2H0AAAAAAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAFwzcGOwAC9h7AAAAAQAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAGAAAAAAAAAAMAAAAAAAvYfQAAAABj19OQAAAAAAAAAAQAAAADAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXDNwY7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAYAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAAAQAL2H0AAAAAAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAFwzcGOwAC9h7AAAAAQAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAHAAAAAAAAAAMAAAAAAAvYfQAAAABj19OQAAAAAAAAAAMAC9h9AAAAAAAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAA7msoAAAvYfQAAAAAAAAADAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAvrwgAAAAAAAAAAAAAAAAIAAAAFAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAL2H0AAAAAAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAADuaygAAC9h9AAAAAAAAAAQAAAAAAAAAAAAAAAABAAAAAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAEAAAABAAAAAAvrwgAAAAAAAAAAAAAAAAIAAAAGAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAAAAAAEAAAAAwAL2H0AAAAAAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAFwzcGOwAC9h7AAAAAQAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAHAAAAAAAAAAMAAAAAAAvYfQAAAABj19OQAAAAAAAAAAEAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAABQAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAADAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAABAAAAAAAAAAAAAAAAAEAAAAAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAQAAAAEAAAAAC+vCAAAAAAAAAAAAAAAAAgAAAAYAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAL2H0AAAAAAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAADuaygAAC9h9AAAAAAAAAAQAAAAAAAAAAAAAAAABAAAAAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAEAAAABAAAAAAvrwgAAAAAAAAAAAAAAAAIAAAAEAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAAAAAAAAAAAAAAAYAAAADAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAABAAAAAAAAAAAAAAAAAEAAAAAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAQAAAAEAAAAAC+vCAAAAAAAAAAAAAAAAAgAAAAQAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAAAAAAAAAAAAAAAQAL2H0AAAAAAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAADuaygAAC9h9AAAAAAAAAAQAAAAAAAAAAAAAAAABAAAAAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAEAAAABAAAAAAvrwgAAAAAAAAAAAAAAAAIAAAADAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAAAAAAAAAAAAAAAMAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAABQAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAABAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXDNwY7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAQAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAAAwAL2H0AAAADAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAABnNvbmVzbwAAAAAACGlzIHN1cGVyAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAC9h9AAAAAwAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAZzb25lc28AAAAAAAhpcyBzdXBlcgAAAAAAAAABAAAAAAAAAAAAAAAGAAAAAwAL2H0AAAAAAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAFwzcGOwAC9h7AAAAAQAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAEAAAAAAAAAAMAAAAAAAvYfQAAAABj19OQAAAAAAAAAAEAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAwAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAADAAvYfQAAAAAAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAAAO5rKAAAL2H0AAAAAAAAABAAAAAAAAAAAAAAAAAEAAAAAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAQAAAAEAAAAAC+vCAAAAAAAAAAAAAAAAAgAAAAMAAAAAAAAAAQAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAAAAAAAQAAAAAAAAAAAAAAAQAL2H0AAAAAAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAADuaygAAC9h9AAAAAAAAAAQAAAAAAAAAAAAAAAABAAAAAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAEAAAABAAAAAAvrwgAAAAAAAAAAAAAAAAIAAAACAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAAAAAAAAAAAAAAAMAC9h9AAAAAQAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAFSSUNIAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAlQL5AAAAADo1KUQAAAAAAEAAAABAAAAAAAAAAAAAAAABfXhAAAAAAAAAAABAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAAAAAABAAvYfQAAAAEAAAAAlhAbkDkJmUtfFT4lfaHRiLBo/BZEUUhVDAieqEyTqYsAAAABUklDSAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAJUC+QAAAAA6NSlEAAAAAABAAAAAQAAAAAAAAAAAAAAAAX14QAAAAAAAAAAAQAAAAAAAAAAAAAABAAAAAMAC9h9AAAAAAAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAABcM3BjsAAvYewAAAAEAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAwAAAAAAAAADAAAAAAAL2H0AAAAAY9fTkAAAAAAAAAABAAvYfQAAAAAAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAAXDNwY7AAL2HsAAAABAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAwAAAAAAC9h9AAAAAGPX05AAAAAAAAAAAwAL2H0AAAAAAAAAAJYQG5A5CZlLXxU+JX2h0YiwaPwWRFFIVQwInqhMk6mLAAAAADuaygAAC9h9AAAAAAAAAAQAAAAAAAAAAAAAAAABAAAAAAAAAQAAAACBv9zcICc6a093/IuO8n8fe2hIbg1FwIGPngeHaK+YnAAAAAEAAAABAAAAAAvrwgAAAAAAAAAAAAAAAAIAAAACAAAAAAAAAAEAAAABAAAAAIG/3NwgJzprT3f8i47yfx97aEhuDUXAgY+eB4dor5icAAAAAAAAAAEAAAAAAAAAAAAAAAEAC9h9AAAAAAAAAACWEBuQOQmZS18VPiV9odGIsGj8FkRRSFUMCJ6oTJOpiwAAAAA7msoAAAvYfQAAAAAAAAAEAAAAAAAAAAAAAAAAAQAAAAAAAAEAAAAAgb/c3CAnOmtPd/yLjvJ/H3toSG4NRcCBj54Hh2ivmJwAAAABAAAAAQAAAAAL68IAAAAAAAAAAAAAAAACAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAA';
    XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(xdrStr);
    print(meta.toBase64EncodedXdrString());
    assert(xdrStr == meta.toBase64EncodedXdrString());
  });

  test('test set account options', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);
    int seqNum = accountA.sequenceNumber;

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

    transaction.sign(keyPairA, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
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
    Page<AccountResponse> accounts = await sdk.accounts.forSigner(keyPairB.accountId).execute();
    aFound = false;
    for (AccountResponse? account in accounts.records!) {
      if (account!.accountId == keyPairA.accountId) {
        aFound = true;
        break;
      }
    }
    assert(aFound);
  });

  test('test find accounts for asset', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperation changeTrustOperation =
        ChangeTrustOperationBuilder(iomAsset, "200999").build();

    transaction = new TransactionBuilder(accountC).addOperation(changeTrustOperation).build();

    transaction.sign(keyPairC, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Find account for asset.
    AccountsRequestBuilder ab = sdk.accounts.forAsset(iomAsset);
    Page<AccountResponse> accounts = await ab.execute();
    bool cFound = false;
    for (AccountResponse? account in accounts.records!) {
      if (account!.accountId == keyPairC.accountId) {
        cFound = true;
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

    AccountMergeOperation accountMergeOperation = AccountMergeOperationBuilder(accountXId).build();

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction =
        TransactionBuilder(accountY).addOperation(accountMergeOperation).build();

    transaction.sign(keyPairY, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    await sdk.accounts.account(accountYId).then((response) {
      assert(false);
    }).catchError((error) {
      print(error.toString());
      assert(error is ErrorResponse && error.code == 404);
    });
  });

  test('test account merge muxed source and destination account', () async {
    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    await FriendBot.fundTestAccount(accountXId);
    await FriendBot.fundTestAccount(accountYId);

    MuxedAccount muxedDestinationAccount = MuxedAccount(accountXId, 10120291);
    MuxedAccount muxedSourceAccount = MuxedAccount(accountYId, 9999999999);

    AccountMergeOperation accountMergeOperation =
        AccountMergeOperationBuilder.forMuxedDestinationAccount(muxedDestinationAccount)
            .setMuxedSourceAccount(muxedSourceAccount)
            .build();

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction =
        TransactionBuilder(accountY).addOperation(accountMergeOperation).build();

    transaction.sign(keyPairY, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    //print(response.hash);

    await sdk.accounts.account(accountYId).then((response) {
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

    BumpSequenceOperation bumpSequenceOperation =
        BumpSequenceOperationBuilder(startSequence + 10).build();

    Transaction transaction =
        TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

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

    ManageDataOperation manageDataOperation = ManageDataOperationBuilder(key, valueBytes).build();

    Transaction transaction = TransactionBuilder(account).addOperation(manageDataOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);

    Uint8List resultBytes = account.data.getDecoded(key);
    String resultValue = String.fromCharCodes(resultBytes);

    assert(value == resultValue);

    manageDataOperation = ManageDataOperationBuilder(key, null).build();

    transaction = TransactionBuilder(account).addOperation(manageDataOperation).build();
    transaction.sign(keyPair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);
    assert(!account.data.keys.contains(key));
  });

  test('test muxed account ID (M..)', () {
    String med25519AccountId =
        'MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26';
    MuxedAccount? mux = MuxedAccount.fromAccountId(med25519AccountId);
    assert(mux!.ed25519AccountId == 'GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY');
    assert(mux!.id == 1234);
    assert(mux!.accountId == med25519AccountId);
  });
}
