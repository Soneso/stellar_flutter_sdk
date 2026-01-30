import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('PaymentOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;
    late KeyPair issuerKeyPair;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      issuerKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
    });

    test('create payment with native asset', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      expect(payment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(payment.asset, isA<AssetTypeNative>());
      expect(payment.amount, equals("100.0"));
      expect(payment.sourceAccount, isNull);
    });

    test('create payment with credit asset AlphaNum4', () {
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        usd,
        "50.75"
      ).build();

      expect(payment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(payment.asset, isA<AssetTypeCreditAlphaNum4>());
      final creditAsset = payment.asset as AssetTypeCreditAlphaNum4;
      expect(creditAsset.code, equals("USD"));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
      expect(payment.amount, equals("50.75"));
    });

    test('create payment with credit asset AlphaNum12', () {
      final longAsset = AssetTypeCreditAlphaNum12("LONGASSET", issuerKeyPair.accountId);
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        longAsset,
        "25.5"
      ).build();

      expect(payment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(payment.asset, isA<AssetTypeCreditAlphaNum12>());
      final creditAsset = payment.asset as AssetTypeCreditAlphaNum12;
      expect(creditAsset.code, equals("LONGASSET"));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
      expect(payment.amount, equals("25.5"));
    });

    test('create payment with source account', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).setSourceAccount(sourceKeyPair.accountId).build();

      expect(payment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(payment.amount, equals("100.0"));
      expect(payment.sourceAccount, isNotNull);
      expect(payment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('create payment with muxed source account', () {
      final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(12345));
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).setMuxedSourceAccount(muxedSource).build();

      expect(payment.sourceAccount, isNotNull);
      expect(payment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      expect(payment.sourceAccount!.id, equals(BigInt.from(12345)));
    });

    test('create payment with muxed destination account', () {
      final muxedDest = MuxedAccount(destinationKeyPair.accountId, BigInt.from(67890));
      final payment = PaymentOperationBuilder.forMuxedDestinationAccount(
        muxedDest,
        Asset.NATIVE,
        "100.0"
      ).build();

      expect(payment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(payment.destination.id, equals(BigInt.from(67890)));
      expect(payment.amount, equals("100.0"));
    });

    test('payment XDR round-trip with native asset', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final xdrBody = payment.toOperationBody();
      expect(xdrBody.discriminant, equals(XdrOperationType.PAYMENT));
      expect(xdrBody.paymentOp, isNotNull);

      final restoredBuilder = PaymentOperation.builder(xdrBody.paymentOp!);
      final restored = restoredBuilder.build();

      expect(restored.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(restored.asset, isA<AssetTypeNative>());
      expect(restored.amount, equals("100"));
    });

    test('payment XDR round-trip with credit asset', () {
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        usd,
        "50.75"
      ).setSourceAccount(sourceKeyPair.accountId).build();

      final xdrBody = payment.toOperationBody();
      final restoredBuilder = PaymentOperation.builder(xdrBody.paymentOp!);
      final restored = restoredBuilder.build();

      expect(restored.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(restored.asset, isA<AssetTypeCreditAlphaNum4>());
      final creditAsset = restored.asset as AssetTypeCreditAlphaNum4;
      expect(creditAsset.code, equals("USD"));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
      expect(restored.amount, equals("50.75"));
    });

    test('payment with decimal amount precision', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "0.0000001"
      ).build();

      expect(payment.amount, equals("0.0000001"));

      final xdrBody = payment.toOperationBody();
      final restoredBuilder = PaymentOperation.builder(xdrBody.paymentOp!);
      final restored = restoredBuilder.build();

      expect(restored.amount, equals("0.0000001"));
    });

    test('payment with large amount', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "922337203685.4775807"
      ).build();

      expect(payment.amount, equals("922337203685.4775807"));

      final xdrBody = payment.toOperationBody();
      final restoredBuilder = PaymentOperation.builder(xdrBody.paymentOp!);
      final restored = restoredBuilder.build();

      expect(restored.amount, equals("922337203685.4775807"));
    });

    test('payment builder pattern', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      )
        .setSourceAccount(sourceKeyPair.accountId)
        .build();

      expect(payment, isNotNull);
      expect(payment, isA<PaymentOperation>());
      expect(payment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(payment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('payment asset getter returns correct asset', () {
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        usd,
        "100.0"
      ).build();

      final asset = payment.asset;
      expect(asset, isA<AssetTypeCreditAlphaNum4>());
      expect((asset as AssetTypeCreditAlphaNum4).code, equals("USD"));
    });
  });

  group('CreateAccountOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair newAccountKeyPair;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      newAccountKeyPair = KeyPair.random();
    });

    test('create account with starting balance', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.0"
      ).build();

      expect(createAccount.destination, equals(newAccountKeyPair.accountId));
      expect(createAccount.startingBalance, equals("10.0"));
      expect(createAccount.sourceAccount, isNull);
    });

    test('create account with source account', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.0"
      ).setSourceAccount(sourceKeyPair.accountId).build();

      expect(createAccount.destination, equals(newAccountKeyPair.accountId));
      expect(createAccount.startingBalance, equals("10.0"));
      expect(createAccount.sourceAccount, isNotNull);
      expect(createAccount.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('create account with muxed source account', () {
      final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(99999));
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.0"
      ).setMuxedSourceAccount(muxedSource).build();

      expect(createAccount.sourceAccount, isNotNull);
      expect(createAccount.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      expect(createAccount.sourceAccount!.id, equals(BigInt.from(99999)));
    });

    test('create account XDR round-trip', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.0"
      ).build();

      final xdrBody = createAccount.toOperationBody();
      expect(xdrBody.discriminant, equals(XdrOperationType.CREATE_ACCOUNT));
      expect(xdrBody.createAccountOp, isNotNull);

      final restoredBuilder = CreateAccountOperation.builder(xdrBody.createAccountOp!);
      final restored = restoredBuilder.build();

      expect(restored.destination, equals(newAccountKeyPair.accountId));
      expect(restored.startingBalance, equals("10"));
    });

    test('create account with minimum starting balance', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "1.0"
      ).build();

      expect(createAccount.startingBalance, equals("1.0"));

      final xdrBody = createAccount.toOperationBody();
      final restoredBuilder = CreateAccountOperation.builder(xdrBody.createAccountOp!);
      final restored = restoredBuilder.build();

      expect(restored.startingBalance, equals("1"));
    });

    test('create account with large starting balance', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "1000000.0"
      ).build();

      expect(createAccount.startingBalance, equals("1000000.0"));
    });

    test('create account with decimal precision', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.5"
      ).build();

      expect(createAccount.startingBalance, equals("10.5"));

      final xdrBody = createAccount.toOperationBody();
      final restoredBuilder = CreateAccountOperation.builder(xdrBody.createAccountOp!);
      final restored = restoredBuilder.build();

      expect(restored.startingBalance, equals("10.5"));
    });

    test('create account builder pattern', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.0"
      )
        .setSourceAccount(sourceKeyPair.accountId)
        .build();

      expect(createAccount, isNotNull);
      expect(createAccount, isA<CreateAccountOperation>());
      expect(createAccount.destination, equals(newAccountKeyPair.accountId));
      expect(createAccount.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('create account destination getter returns correct value', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "10.0"
      ).build();

      expect(createAccount.destination, equals(newAccountKeyPair.accountId));
    });

    test('create account starting balance getter returns correct value', () {
      final createAccount = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "25.5"
      ).build();

      expect(createAccount.startingBalance, equals("25.5"));
    });
  });

  group('AccountMergeOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
    });

    test('merge account to destination', () {
      final merge = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      ).build();

      expect(merge.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(merge.sourceAccount, isNull);
    });

    test('merge account with source account', () {
      final merge = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      ).setSourceAccount(sourceKeyPair.accountId).build();

      expect(merge.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(merge.sourceAccount, isNotNull);
      expect(merge.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('merge account with muxed source account', () {
      final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(11111));
      final merge = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      ).setMuxedSourceAccount(muxedSource).build();

      expect(merge.sourceAccount, isNotNull);
      expect(merge.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      expect(merge.sourceAccount!.id, equals(BigInt.from(11111)));
    });

    test('merge account with muxed destination account', () {
      final muxedDest = MuxedAccount(destinationKeyPair.accountId, BigInt.from(22222));
      final merge = AccountMergeOperationBuilder.forMuxedDestinationAccount(
        muxedDest
      ).build();

      expect(merge.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(merge.destination.id, equals(BigInt.from(22222)));
    });

    test('account merge XDR round-trip', () {
      final merge = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      ).build();

      final xdrBody = merge.toOperationBody();
      expect(xdrBody.discriminant, equals(XdrOperationType.ACCOUNT_MERGE));
      expect(xdrBody.destination, isNotNull);

      final restoredBuilder = AccountMergeOperation.builder(xdrBody);
      final restored = restoredBuilder.build();

      expect(restored.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
    });

    test('account merge XDR round-trip with muxed accounts', () {
      final muxedDest = MuxedAccount(destinationKeyPair.accountId, BigInt.from(33333));
      final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(44444));

      final merge = AccountMergeOperationBuilder.forMuxedDestinationAccount(
        muxedDest
      ).setMuxedSourceAccount(muxedSource).build();

      final xdrBody = merge.toOperationBody();
      final restoredBuilder = AccountMergeOperation.builder(xdrBody);
      final restored = restoredBuilder.build();

      expect(restored.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(restored.destination.id, equals(BigInt.from(33333)));
    });

    test('account merge builder pattern', () {
      final merge = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      )
        .setSourceAccount(sourceKeyPair.accountId)
        .build();

      expect(merge, isNotNull);
      expect(merge, isA<AccountMergeOperation>());
      expect(merge.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(merge.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('account merge destination getter returns correct value', () {
      final merge = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      ).build();

      expect(merge.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
    });
  });

  group('PathPaymentStrictReceiveOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usd;
    late Asset eur;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      issuerKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
      usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
    });

    test('path payment with no intermediary assets', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).build();

      expect(pathPayment.sendAsset, equals(usd));
      expect(pathPayment.sendMax, equals("150.0"));
      expect(pathPayment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(pathPayment.destAsset, equals(eur));
      expect(pathPayment.destAmount, equals("100.0"));
      expect(pathPayment.path.length, equals(0));
    });

    test('path payment with single path asset', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).setPath([Asset.NATIVE]).build();

      expect(pathPayment.path.length, equals(1));
      expect(pathPayment.path[0], isA<AssetTypeNative>());
    });

    test('path payment with multiple path assets', () {
      final btc = AssetTypeCreditAlphaNum4("BTC", issuerKeyPair.accountId);
      final eth = AssetTypeCreditAlphaNum4("ETH", issuerKeyPair.accountId);

      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).setPath([Asset.NATIVE, btc, eth]).build();

      expect(pathPayment.path.length, equals(3));
      expect(pathPayment.path[0], isA<AssetTypeNative>());
      expect((pathPayment.path[1] as AssetTypeCreditAlphaNum4).code, equals("BTC"));
      expect((pathPayment.path[2] as AssetTypeCreditAlphaNum4).code, equals("ETH"));
    });

    test('path payment with maximum path assets', () {
      final asset1 = AssetTypeCreditAlphaNum4("AS1", issuerKeyPair.accountId);
      final asset2 = AssetTypeCreditAlphaNum4("AS2", issuerKeyPair.accountId);
      final asset3 = AssetTypeCreditAlphaNum4("AS3", issuerKeyPair.accountId);
      final asset4 = AssetTypeCreditAlphaNum4("AS4", issuerKeyPair.accountId);
      final asset5 = AssetTypeCreditAlphaNum4("AS5", issuerKeyPair.accountId);

      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).setPath([asset1, asset2, asset3, asset4, asset5]).build();

      expect(pathPayment.path.length, equals(5));
    });

    test('path payment with source account', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).setSourceAccount(sourceKeyPair.accountId).build();

      expect(pathPayment.sourceAccount, isNotNull);
      expect(pathPayment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('path payment with muxed source account', () {
      final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(55555));
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).setMuxedSourceAccount(muxedSource).build();

      expect(pathPayment.sourceAccount!.id, equals(BigInt.from(55555)));
    });

    test('path payment with muxed destination account', () {
      final muxedDest = MuxedAccount(destinationKeyPair.accountId, BigInt.from(66666));
      final pathPayment = PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
        usd,
        "150.0",
        muxedDest,
        eur,
        "100.0"
      ).build();

      expect(pathPayment.destination.id, equals(BigInt.from(66666)));
    });

    test('path payment XDR round-trip without path', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).build();

      final xdrBody = pathPayment.toOperationBody();
      expect(xdrBody.discriminant, equals(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE));
      expect(xdrBody.pathPaymentStrictReceiveOp, isNotNull);

      final restoredBuilder = PathPaymentStrictReceiveOperation.builder(xdrBody.pathPaymentStrictReceiveOp!);
      final restored = restoredBuilder.build();

      expect((restored.sendAsset as AssetTypeCreditAlphaNum4).code, equals("USD"));
      expect(restored.sendMax, equals("150"));
      expect(restored.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect((restored.destAsset as AssetTypeCreditAlphaNum4).code, equals("EUR"));
      expect(restored.destAmount, equals("100"));
      expect(restored.path.length, equals(0));
    });

    test('path payment XDR round-trip with path', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).setPath([Asset.NATIVE]).build();

      final xdrBody = pathPayment.toOperationBody();
      final restoredBuilder = PathPaymentStrictReceiveOperation.builder(xdrBody.pathPaymentStrictReceiveOp!);
      final restored = restoredBuilder.build();

      expect(restored.path.length, equals(1));
      expect(restored.path[0], isA<AssetTypeNative>());
    });

    test('path payment sendMax validation with decimal precision', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0000001",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      ).build();

      expect(pathPayment.sendMax, equals("150.0000001"));

      final xdrBody = pathPayment.toOperationBody();
      final restoredBuilder = PathPaymentStrictReceiveOperation.builder(xdrBody.pathPaymentStrictReceiveOp!);
      final restored = restoredBuilder.build();

      expect(restored.sendMax, equals("150.0000001"));
    });

    test('path payment destAmount validation with decimal precision', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0000001"
      ).build();

      expect(pathPayment.destAmount, equals("100.0000001"));

      final xdrBody = pathPayment.toOperationBody();
      final restoredBuilder = PathPaymentStrictReceiveOperation.builder(xdrBody.pathPaymentStrictReceiveOp!);
      final restored = restoredBuilder.build();

      expect(restored.destAmount, equals("100.0000001"));
    });

    test('path payment builder pattern', () {
      final pathPayment = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "150.0",
        destinationKeyPair.accountId,
        eur,
        "100.0"
      )
        .setPath([Asset.NATIVE])
        .setSourceAccount(sourceKeyPair.accountId)
        .build();

      expect(pathPayment, isNotNull);
      expect(pathPayment, isA<PathPaymentStrictReceiveOperation>());
      expect(pathPayment.path.length, equals(1));
      expect(pathPayment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });
  });

  group('PathPaymentStrictSendOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usd;
    late Asset eur;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      issuerKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
      usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
    });

    test('path payment strict send with no intermediary assets', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).build();

      expect(pathPayment.sendAsset, equals(usd));
      expect(pathPayment.sendAmount, equals("100.0"));
      expect(pathPayment.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect(pathPayment.destAsset, equals(eur));
      expect(pathPayment.destMin, equals("90.0"));
      expect(pathPayment.path.length, equals(0));
    });

    test('path payment strict send with single path asset', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).setPath([Asset.NATIVE]).build();

      expect(pathPayment.path.length, equals(1));
      expect(pathPayment.path[0], isA<AssetTypeNative>());
    });

    test('path payment strict send with multiple path assets', () {
      final btc = AssetTypeCreditAlphaNum4("BTC", issuerKeyPair.accountId);
      final eth = AssetTypeCreditAlphaNum4("ETH", issuerKeyPair.accountId);

      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).setPath([Asset.NATIVE, btc, eth]).build();

      expect(pathPayment.path.length, equals(3));
      expect(pathPayment.path[0], isA<AssetTypeNative>());
      expect((pathPayment.path[1] as AssetTypeCreditAlphaNum4).code, equals("BTC"));
      expect((pathPayment.path[2] as AssetTypeCreditAlphaNum4).code, equals("ETH"));
    });

    test('path payment strict send with maximum path assets', () {
      final asset1 = AssetTypeCreditAlphaNum4("AS1", issuerKeyPair.accountId);
      final asset2 = AssetTypeCreditAlphaNum4("AS2", issuerKeyPair.accountId);
      final asset3 = AssetTypeCreditAlphaNum4("AS3", issuerKeyPair.accountId);
      final asset4 = AssetTypeCreditAlphaNum4("AS4", issuerKeyPair.accountId);
      final asset5 = AssetTypeCreditAlphaNum4("AS5", issuerKeyPair.accountId);

      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).setPath([asset1, asset2, asset3, asset4, asset5]).build();

      expect(pathPayment.path.length, equals(5));
    });

    test('path payment strict send with source account', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).setSourceAccount(sourceKeyPair.accountId).build();

      expect(pathPayment.sourceAccount, isNotNull);
      expect(pathPayment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('path payment strict send with muxed source account', () {
      final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(77777));
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).setMuxedSourceAccount(muxedSource).build();

      expect(pathPayment.sourceAccount!.id, equals(BigInt.from(77777)));
    });

    test('path payment strict send with muxed destination account', () {
      final muxedDest = MuxedAccount(destinationKeyPair.accountId, BigInt.from(88888));
      final pathPayment = PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
        usd,
        "100.0",
        muxedDest,
        eur,
        "90.0"
      ).build();

      expect(pathPayment.destination.id, equals(BigInt.from(88888)));
    });

    test('path payment strict send XDR round-trip without path', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).build();

      final xdrBody = pathPayment.toOperationBody();
      expect(xdrBody.discriminant, equals(XdrOperationType.PATH_PAYMENT_STRICT_SEND));
      expect(xdrBody.pathPaymentStrictSendOp, isNotNull);

      final restoredBuilder = PathPaymentStrictSendOperation.builder(xdrBody.pathPaymentStrictSendOp!);
      final restored = restoredBuilder.build();

      expect((restored.sendAsset as AssetTypeCreditAlphaNum4).code, equals("USD"));
      expect(restored.sendAmount, equals("100"));
      expect(restored.destination.ed25519AccountId, equals(destinationKeyPair.accountId));
      expect((restored.destAsset as AssetTypeCreditAlphaNum4).code, equals("EUR"));
      expect(restored.destMin, equals("90"));
      expect(restored.path.length, equals(0));
    });

    test('path payment strict send XDR round-trip with path', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).setPath([Asset.NATIVE]).build();

      final xdrBody = pathPayment.toOperationBody();
      final restoredBuilder = PathPaymentStrictSendOperation.builder(xdrBody.pathPaymentStrictSendOp!);
      final restored = restoredBuilder.build();

      expect(restored.path.length, equals(1));
      expect(restored.path[0], isA<AssetTypeNative>());
    });

    test('path payment strict send sendAmount validation with decimal precision', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0000001",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      ).build();

      expect(pathPayment.sendAmount, equals("100.0000001"));

      final xdrBody = pathPayment.toOperationBody();
      final restoredBuilder = PathPaymentStrictSendOperation.builder(xdrBody.pathPaymentStrictSendOp!);
      final restored = restoredBuilder.build();

      expect(restored.sendAmount, equals("100.0000001"));
    });

    test('path payment strict send destMin validation with decimal precision', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0000001"
      ).build();

      expect(pathPayment.destMin, equals("90.0000001"));

      final xdrBody = pathPayment.toOperationBody();
      final restoredBuilder = PathPaymentStrictSendOperation.builder(xdrBody.pathPaymentStrictSendOp!);
      final restored = restoredBuilder.build();

      expect(restored.destMin, equals("90.0000001"));
    });

    test('path payment strict send builder pattern', () {
      final pathPayment = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.0",
        destinationKeyPair.accountId,
        eur,
        "90.0"
      )
        .setPath([Asset.NATIVE])
        .setSourceAccount(sourceKeyPair.accountId)
        .build();

      expect(pathPayment, isNotNull);
      expect(pathPayment, isA<PathPaymentStrictSendOperation>());
      expect(pathPayment.path.length, equals(1));
      expect(pathPayment.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });
  });

  group('Edge Cases and Validation', () {
    late KeyPair destinationKeyPair;
    late KeyPair issuerKeyPair;

    setUp(() {
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      issuerKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
    });

    test('payment operation with zero amount', () {
      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "0.0"
      ).build();

      expect(payment.amount, equals("0.0"));
    });

    test('create account operation with zero starting balance', () {
      final createAccount = CreateAccountOperationBuilder(
        destinationKeyPair.accountId,
        "0.0"
      ).build();

      expect(createAccount.startingBalance, equals("0.0"));
    });

    test('path payment strict receive with more than 5 path assets throws', () {
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
      final asset1 = AssetTypeCreditAlphaNum4("AS1", issuerKeyPair.accountId);
      final asset2 = AssetTypeCreditAlphaNum4("AS2", issuerKeyPair.accountId);
      final asset3 = AssetTypeCreditAlphaNum4("AS3", issuerKeyPair.accountId);
      final asset4 = AssetTypeCreditAlphaNum4("AS4", issuerKeyPair.accountId);
      final asset5 = AssetTypeCreditAlphaNum4("AS5", issuerKeyPair.accountId);
      final asset6 = AssetTypeCreditAlphaNum4("AS6", issuerKeyPair.accountId);

      expect(
        () => PathPaymentStrictReceiveOperationBuilder(
          usd,
          "150.0",
          destinationKeyPair.accountId,
          eur,
          "100.0"
        ).setPath([asset1, asset2, asset3, asset4, asset5, asset6]).build(),
        throwsA(isA<Exception>())
      );
    });

    test('path payment strict send with more than 5 path assets throws', () {
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
      final asset1 = AssetTypeCreditAlphaNum4("AS1", issuerKeyPair.accountId);
      final asset2 = AssetTypeCreditAlphaNum4("AS2", issuerKeyPair.accountId);
      final asset3 = AssetTypeCreditAlphaNum4("AS3", issuerKeyPair.accountId);
      final asset4 = AssetTypeCreditAlphaNum4("AS4", issuerKeyPair.accountId);
      final asset5 = AssetTypeCreditAlphaNum4("AS5", issuerKeyPair.accountId);
      final asset6 = AssetTypeCreditAlphaNum4("AS6", issuerKeyPair.accountId);

      expect(
        () => PathPaymentStrictSendOperationBuilder(
          usd,
          "100.0",
          destinationKeyPair.accountId,
          eur,
          "90.0"
        ).setPath([asset1, asset2, asset3, asset4, asset5, asset6]).build(),
        throwsA(isA<Exception>())
      );
    });

    test('payment with native asset type equals Asset.NATIVE', () {
      final payment1 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final payment2 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        AssetTypeNative(),
        "100.0"
      ).build();

      expect(payment1.asset.type, equals(payment2.asset.type));
    });

    test('operations can be added to transaction', () {
      final sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      final sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(2908908335136768));

      final payment = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final createAccount = CreateAccountOperationBuilder(
        KeyPair.random().accountId,
        "10.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(payment)
        .addOperation(createAccount)
        .build();

      expect(transaction.operations.length, equals(2));
      expect(transaction.operations[0], isA<PaymentOperation>());
      expect(transaction.operations[1], isA<CreateAccountOperation>());
    });
  });
}
