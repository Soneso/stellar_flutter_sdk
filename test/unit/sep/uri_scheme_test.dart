import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  late KeyPair sourceKeyPair;
  late Account sourceAccount;
  late KeyPair destinationKeyPair;
  late KeyPair signerKeyPair;
  late Network testNetwork;
  late URIScheme uriScheme;

  setUp(() {
    sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
    sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(2908908335136768));
    destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
    signerKeyPair = KeyPair.random();
    testNetwork = Network.TESTNET;
    uriScheme = URIScheme();
  });

  group('URIScheme - Transaction URI Generation', () {
    test('generates basic tx URI without optional parameters', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(xdr);

      expect(uri, startsWith('web+stellar:tx?'));
      expect(uri, contains('xdr='));
      expect(uri, isNot(contains('callback=')));
      expect(uri, isNot(contains('msg=')));
    });

    test('generates tx URI with callback parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        callback: 'url:https://example.com/callback'
      );

      expect(uri, contains('callback='));
      expect(uri, contains('example.com'));
    });

    test('generates tx URI with message parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        message: 'Please sign this transaction'
      );

      expect(uri, contains('msg='));
    });

    test('generates tx URI with network passphrase', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        networkPassphrase: Network.TESTNET.networkPassphrase
      );

      expect(uri, contains('network_passphrase='));
    });

    test('generates tx URI with origin domain', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        originDomain: 'example.com'
      );

      expect(uri, contains('origin_domain='));
      expect(uri, contains('example.com'));
    });

    test('generates tx URI with all optional parameters', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        callback: 'url:https://example.com/callback',
        message: 'Sign this payment',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        originDomain: 'example.com'
      );

      expect(uri, contains('xdr='));
      expect(uri, contains('callback='));
      expect(uri, contains('msg='));
      expect(uri, contains('network_passphrase='));
      expect(uri, contains('origin_domain='));
    });

    test('properly URL-encodes XDR parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(xdr);

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['xdr'], equals(xdr));
    });
  });

  group('URIScheme - Payment URI Generation', () {
    test('generates basic pay URI with destination only', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId
      );

      expect(uri, startsWith('web+stellar:pay?'));
      expect(uri, contains('destination='));
      expect(uri, contains(destinationKeyPair.accountId));
    });

    test('generates pay URI with amount', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100.50'
      );

      expect(uri, contains('amount='));
      expect(uri, contains('100.50'));
    });

    test('generates pay URI with custom asset', () {
      final issuerKeyPair = KeyPair.random();

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        assetCode: 'USD',
        assetIssuer: issuerKeyPair.accountId
      );

      expect(uri, contains('asset_code='));
      expect(uri, contains('USD'));
      expect(uri, contains('asset_issuer='));
      expect(uri, contains(issuerKeyPair.accountId));
    });

    test('generates pay URI with memo text', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: 'Invoice #12345',
        memoType: 'MEMO_TEXT'
      );

      expect(uri, contains('memo='));
      expect(uri, contains('memo_type='));
      expect(uri, contains('MEMO_TEXT'));
    });

    test('generates pay URI with memo ID', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: '9876543210',
        memoType: 'MEMO_ID'
      );

      expect(uri, contains('memo='));
      expect(uri, contains('9876543210'));
      expect(uri, contains('memo_type='));
      expect(uri, contains('MEMO_ID'));
    });

    test('generates pay URI with memo hash', () {
      final hash = base64Encode(Uint8List.fromList(List<int>.filled(32, 1)));

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: hash,
        memoType: 'MEMO_HASH'
      );

      expect(uri, contains('memo='));
      expect(uri, contains('memo_type='));
      expect(uri, contains('MEMO_HASH'));
    });

    test('generates pay URI with callback', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        callback: 'url:https://example.com/payment-callback'
      );

      expect(uri, contains('callback='));
      expect(uri, contains('example.com'));
    });

    test('generates pay URI with message', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        message: 'Payment for premium subscription'
      );

      expect(uri, contains('msg='));
    });

    test('generates pay URI with all parameters', () {
      final issuerKeyPair = KeyPair.random();

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100.50',
        assetCode: 'USD',
        assetIssuer: issuerKeyPair.accountId,
        memo: 'Order #123',
        memoType: 'MEMO_TEXT',
        callback: 'url:https://example.com/callback',
        message: 'Complete your order',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        originDomain: 'example.com'
      );

      expect(uri, contains('destination='));
      expect(uri, contains('amount='));
      expect(uri, contains('asset_code='));
      expect(uri, contains('asset_issuer='));
      expect(uri, contains('memo='));
      expect(uri, contains('memo_type='));
      expect(uri, contains('callback='));
      expect(uri, contains('msg='));
      expect(uri, contains('network_passphrase='));
      expect(uri, contains('origin_domain='));
    });

    test('properly URL-encodes pay URI parameters', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100.50',
        memo: 'Test memo with spaces',
        memoType: 'MEMO_TEXT'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['memo'], equals('Test memo with spaces'));
    });
  });

  group('URIScheme - URI Parsing', () {
    test('parses valid tx URI', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);

      final parsed = uriScheme.tryParseSep7Url(uri);

      expect(parsed, isNotNull);
      expect(parsed!.operationType, equals('tx'));
      expect(parsed.queryParameters['xdr'], equals(xdr));
    });

    test('parses valid pay URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);

      expect(parsed, isNotNull);
      expect(parsed!.operationType, equals('pay'));
      expect(parsed.queryParameters['destination'], equals(destinationKeyPair.accountId));
      expect(parsed.queryParameters['amount'], equals('100'));
    });

    test('parses URI with multiple parameters', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: 'Test memo',
        memoType: 'MEMO_TEXT',
        message: 'Payment request'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);

      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['destination'], isNotNull);
      expect(parsed.queryParameters['amount'], equals('100'));
      expect(parsed.queryParameters['memo'], equals('Test memo'));
      expect(parsed.queryParameters['memo_type'], equals('MEMO_TEXT'));
      expect(parsed.queryParameters['msg'], equals('Payment request'));
    });

    test('returns null for invalid URI scheme', () {
      final parsed = uriScheme.tryParseSep7Url('https://example.com');
      expect(parsed, isNull);
    });

    test('returns null for malformed URI', () {
      final parsed = uriScheme.tryParseSep7Url('web+stellar:invalid');
      expect(parsed, isNull);
    });
  });

  group('URIScheme - URI Validation', () {
    test('validates correct tx URI', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);

      final result = uriScheme.isValidSep7Url(uri);
      expect(result.result, isTrue);
    });

    test('validates correct pay URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100'
      );

      final result = uriScheme.isValidSep7Url(uri);
      expect(result.result, isTrue);
    });

    test('rejects URI with invalid scheme', () {
      final result = uriScheme.isValidSep7Url('https://stellar.org');
      expect(result.result, isFalse);
    });

    test('rejects malformed URI', () {
      final result = uriScheme.isValidSep7Url('web+stellar:');
      expect(result.result, isFalse);
    });

    test('rejects empty URI', () {
      final result = uriScheme.isValidSep7Url('');
      expect(result.result, isFalse);
    });
  });

  group('URIScheme - Signature Handling', () {
    test('adds signature to URI', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);

      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      expect(signedUri, contains('signature='));
      expect(signedUri.length, greaterThan(uri.length));
    });

    test('verifies valid signature', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      final isValid = uriScheme.verifySignature(signedUri, signerKeyPair.accountId);
      expect(isValid, isTrue);
    });

    test('rejects invalid signature', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      final differentKeyPair = KeyPair.random();
      final isValid = uriScheme.verifySignature(signedUri, differentKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('rejects URI without signature when verification attempted', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);

      final isValid = uriScheme.verifySignature(uri, signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('throws error when adding signature to already signed URI', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      expect(
        () => uriScheme.addSignature(signedUri, signerKeyPair),
        throwsArgumentError
      );
    });

    test('signature remains valid after adding to pay URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        originDomain: 'example.com'
      );

      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      expect(signedUri, contains('signature='));

      final isValid = uriScheme.verifySignature(signedUri, signerKeyPair.accountId);
      expect(isValid, isTrue);
    });
  });

  group('URIScheme - Edge Cases', () {
    test('handles URI with special characters in memo', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: 'Test: special @#\$% chars',
        memoType: 'MEMO_TEXT'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['memo'], equals('Test: special @#\$% chars'));
    });

    test('handles URI with very large amount', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '922337203685.4775807'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['amount'], equals('922337203685.4775807'));
    });

    test('handles URI with zero amount', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '0'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['amount'], equals('0'));
    });

    test('handles pay URI without amount', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['destination'], isNotNull);
      expect(parsed.queryParameters['amount'], isNull);
    });

    test('handles URI with long message', () {
      final longMessage = 'A' * 300;

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        message: longMessage
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
    });

    test('handles URI with callback containing query parameters', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        callback: 'url:https://example.com/callback?session=abc123&user=test'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['callback'], contains('session'));
    });

    test('handles muxed account as destination', () {
      final muxedAccountId = 'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6';

      final uri = uriScheme.generatePayOperationURI(
        muxedAccountId,
        amount: '100'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['destination'], equals(muxedAccountId));
    });

    test('handles AlphaNum12 asset in pay URI', () {
      final issuerKeyPair = KeyPair.random();

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        assetCode: 'LONGASSET123',
        assetIssuer: issuerKeyPair.accountId
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['asset_code'], equals('LONGASSET123'));
    });

    test('handles URI with network passphrase for public network', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        networkPassphrase: Network.PUBLIC.networkPassphrase
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['network_passphrase'], isNotNull);
    });
  });

  group('URIScheme - Parameter Extraction', () {
    test('extracts destination from pay URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed!.queryParameters['destination'], equals(destinationKeyPair.accountId));
    });

    test('extracts XDR from tx URI', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      final xdr = transaction.toEnvelopeXdrBase64();
      final uri = uriScheme.generateSignTransactionURI(xdr);

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed!.queryParameters['xdr'], equals(xdr));

      final reconstructedTx = AbstractTransaction.fromEnvelopeXdrString(
        parsed.queryParameters['xdr']!
      );
      expect(reconstructedTx, isNotNull);
    });

    test('extracts asset parameters from pay URI', () {
      final issuerKeyPair = KeyPair.random();

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        assetCode: 'USD',
        assetIssuer: issuerKeyPair.accountId
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed!.queryParameters['asset_code'], equals('USD'));
      expect(parsed.queryParameters['asset_issuer'], equals(issuerKeyPair.accountId));
    });

    test('extracts memo parameters from pay URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: 'Invoice #12345',
        memoType: 'MEMO_TEXT'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed!.queryParameters['memo'], equals('Invoice #12345'));
      expect(parsed.queryParameters['memo_type'], equals('MEMO_TEXT'));
    });

    test('extracts origin domain from URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        originDomain: 'example.com'
      );

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed!.queryParameters['origin_domain'], equals('example.com'));
    });

    test('extracts signature from signed URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100'
      );

      final signedUri = uriScheme.addSignature(uri, signerKeyPair);
      final parsed = uriScheme.tryParseSep7Url(signedUri);

      expect(parsed!.queryParameters['signature'], isNotNull);
      expect(parsed.queryParameters['signature']!.isNotEmpty, isTrue);
    });
  });
}
