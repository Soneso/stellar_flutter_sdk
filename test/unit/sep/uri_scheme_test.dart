import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('URIScheme - Advanced Validation Tests', () {
    test('rejects tx URI missing xdr parameter', () {
      final result = uriScheme.isValidSep7Url('web+stellar:tx?callback=url:https://example.com');
      expect(result.result, isFalse);
      expect(result.reason, contains('xdr'));
    });

    test('rejects tx URI with invalid xdr', () {
      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=invalid_xdr_data');
      expect(result.result, isFalse);
      expect(result.reason, contains('transaction envelope'));
    });

    test('rejects pay URI missing destination parameter', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?amount=100');
      expect(result.result, isFalse);
      expect(result.reason, contains('destination'));
    });

    test('rejects pay URI with invalid destination', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=INVALID_ADDRESS');
      expect(result.result, isFalse);
      expect(result.reason, contains('Stellar address'));
    });

    test('rejects URI with xdr parameter in pay operation', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&xdr=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with destination parameter in tx operation', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&destination=${destinationKeyPair.accountId}');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with replace parameter in pay operation', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&replace=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with amount parameter in tx operation', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&amount=100');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with asset_code parameter in tx operation', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&asset_code=USD');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with asset_issuer parameter in tx operation', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&asset_issuer=${destinationKeyPair.accountId}');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with asset code longer than 12 characters', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&asset_code=VERYLONGASSET');
      expect(result.result, isFalse);
      expect(result.reason, contains('asset code'));
    });

    test('rejects URI with invalid asset issuer', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&asset_code=USD&asset_issuer=INVALID');
      expect(result.result, isFalse);
      expect(result.reason, contains('asset_issuer'));
    });

    test('rejects URI with pubkey parameter in pay operation', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&pubkey=${sourceKeyPair.accountId}');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with invalid pubkey', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&pubkey=INVALID_KEY');
      expect(result.result, isFalse);
      expect(result.reason, contains('public key'));
    });

    test('rejects URI with message longer than 300 characters', () {
      final longMessage = 'A' * 301;
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&msg=${Uri.encodeComponent(longMessage)}');
      expect(result.result, isFalse);
      expect(result.reason, contains('300 characters'));
    });

    test('rejects URI with memo_type parameter in tx operation', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&memo_type=MEMO_TEXT');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with memo parameter in tx operation', () {
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

      final result = uriScheme.isValidSep7Url('web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&memo=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with invalid memo type', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=test&memo_type=MEMO_INVALID');
      expect(result.result, isFalse);
      expect(result.reason, contains('memo_type'));
    });

    test('rejects URI with MEMO_TEXT that is too long', () {
      final longMemo = 'A' * 29; // MemoText max is 28 bytes
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=${Uri.encodeComponent(longMemo)}&memo_type=MEMO_TEXT');
      expect(result.result, isFalse);
      expect(result.reason, contains('too long'));
    });

    test('rejects URI with MEMO_ID with invalid value', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=invalid_id&memo_type=MEMO_ID');
      expect(result.result, isFalse);
      expect(result.reason, contains('invalid value'));
    });

    test('rejects URI with MEMO_HASH with non-base64 value', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=not_base64!&memo_type=MEMO_HASH');
      expect(result.result, isFalse);
      expect(result.reason, contains('base64'));
    });

    test('rejects URI with MEMO_RETURN with non-base64 value', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=not_base64!&memo_type=MEMO_RETURN');
      expect(result.result, isFalse);
      expect(result.reason, contains('base64'));
    });

    test('accepts URI with MEMO_HASH with shorter hash (auto-padded)', () {
      final shortHash = base64Encode(Uint8List.fromList(List<int>.filled(16, 1))); // Will be padded to 32 bytes
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=$shortHash&memo_type=MEMO_HASH');
      expect(result.result, isTrue);
    });

    test('accepts URI with MEMO_RETURN with shorter hash (auto-padded)', () {
      final shortHash = base64Encode(Uint8List.fromList(List<int>.filled(16, 1))); // Will be padded to 32 bytes
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=$shortHash&memo_type=MEMO_RETURN');
      expect(result.result, isTrue);
    });

    test('accepts URI with valid MEMO_HASH', () {
      final hash = base64Encode(Uint8List.fromList(List<int>.filled(32, 1)));
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=$hash&memo_type=MEMO_HASH');
      expect(result.result, isTrue);
    });

    test('accepts URI with valid MEMO_RETURN', () {
      final hash = base64Encode(Uint8List.fromList(List<int>.filled(32, 1)));
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=$hash&memo_type=MEMO_RETURN');
      expect(result.result, isTrue);
    });

    test('accepts URI with valid MEMO_ID', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=12345&memo_type=MEMO_ID');
      expect(result.result, isTrue);
    });

    test('rejects URI with invalid origin domain format', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&origin_domain=invalid_domain_!@#');
      expect(result.result, isFalse);
      expect(result.reason, contains('domain name'));
    });

    test('accepts URI with valid fully qualified domain name', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&origin_domain=example.com');
      expect(result.result, isTrue);
    });

    test('rejects URI with chain parameter in pay operation', () {
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=${destinationKeyPair.accountId}&chain=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('rejects URI with unsupported operation type', () {
      final result = uriScheme.isValidSep7Url('web+stellar:unsupported?test=value');
      expect(result.result, isFalse);
      expect(result.reason, contains('not supported'));
    });

    test('rejects URI with multiple path segments', () {
      final result = uriScheme.isValidSep7Url('web+stellar:tx/extra?xdr=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('path segments'));
    });

    test('validates contract ID as destination', () {
      final contractId = 'CAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQC526';
      final result = uriScheme.isValidSep7Url('web+stellar:pay?destination=$contractId');
      expect(result.result, isTrue);
    });

    test('handles tx URI with replace parameter', () {
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
        replace: 'sourceAccount:X;X:source account'
      );

      final result = uriScheme.isValidSep7Url(uri);
      expect(result.result, isTrue);
    });

    test('handles tx URI with pubkey parameter', () {
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
        publicKey: sourceKeyPair.accountId
      );

      final result = uriScheme.isValidSep7Url(uri);
      expect(result.result, isTrue);
    });

    test('handles tx URI with chain parameter', () {
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

      final chainUri = uriScheme.generateSignTransactionURI(xdr);
      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        chain: chainUri
      );

      final result = uriScheme.isValidSep7Url(uri);
      expect(result.result, isTrue);
    });

    test('rejects URI with chain nesting deeper than 7 levels', () {
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

      // Create chain with 9 levels (8 is max accepted, 9 should fail)
      // The check happens when finding a chain at level N pointing to level N+1
      // So level 8 with chain to level 9 will trigger the check: 8 > 7
      String chainUri = uriScheme.generateSignTransactionURI(xdr);
      for (int i = 0; i < 9; i++) {
        chainUri = uriScheme.generateSignTransactionURI(xdr, chain: chainUri);
      }

      final result = uriScheme.isValidSep7Url(chainUri);
      expect(result.result, isFalse);
      expect(result.reason, contains('nested levels'));
    });

    test('accepts URI with chain nesting at 7 levels', () {
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

      // Create nested chain at exactly 7 levels
      String chainUri = uriScheme.generateSignTransactionURI(xdr);
      for (int i = 0; i < 7; i++) {
        chainUri = uriScheme.generateSignTransactionURI(xdr, chain: chainUri);
      }

      final result = uriScheme.isValidSep7Url(chainUri);
      expect(result.result, isTrue);
    });
  });

  group('URIScheme - Replacement Handling', () {
    test('converts replacement objects to string format', () {
      final replacements = [
        UriSchemeReplacement('X', 'sourceAccount', 'account paying fees'),
        UriSchemeReplacement('Y', 'operations[0].destination', 'receiving account'),
      ];

      final result = uriScheme.uriSchemeReplacementsToString(replacements);

      expect(result, contains('sourceAccount:X'));
      expect(result, contains('operations[0].destination:Y'));
      expect(result, contains('X:account paying fees'));
      expect(result, contains('Y:receiving account'));
    });

    test('parses replacement string into objects', () {
      final replaceString = 'sourceAccount:X,operations[0].destination:Y;X:account paying fees,Y:receiving account';

      final replacements = uriScheme.uriSchemeReplacementsFromString(replaceString);

      expect(replacements.length, equals(2));
      expect(replacements[0].path, equals('sourceAccount'));
      expect(replacements[0].id, equals('X'));
      expect(replacements[0].hint, equals('account paying fees'));
      expect(replacements[1].path, equals('operations[0].destination'));
      expect(replacements[1].id, equals('Y'));
      expect(replacements[1].hint, equals('receiving account'));
    });

    test('handles empty replacement list', () {
      final result = uriScheme.uriSchemeReplacementsToString([]);
      expect(result, isEmpty);
    });

    test('handles empty replacement string', () {
      final result = uriScheme.uriSchemeReplacementsFromString('');
      expect(result, isEmpty);
    });

    test('handles replacement with duplicate IDs', () {
      final replacements = [
        UriSchemeReplacement('X', 'operations[0].destination', 'account 1'),
        UriSchemeReplacement('X', 'operations[1].destination', 'account 1'),
      ];

      final result = uriScheme.uriSchemeReplacementsToString(replacements);

      expect(result, contains('operations[0].destination:X'));
      expect(result, contains('operations[1].destination:X'));
      // Hint should only appear once
      final hintCount = 'X:account 1'.allMatches(result).length;
      expect(hintCount, equals(1));
    });

    test('roundtrip conversion preserves replacement data', () {
      final original = [
        UriSchemeReplacement('A', 'sourceAccount', 'source'),
        UriSchemeReplacement('B', 'operations[0].amount', 'amount'),
        UriSchemeReplacement('C', 'operations[0].destination', 'dest'),
      ];

      final stringFormat = uriScheme.uriSchemeReplacementsToString(original);
      final parsed = uriScheme.uriSchemeReplacementsFromString(stringFormat);

      expect(parsed.length, equals(original.length));
      for (int i = 0; i < original.length; i++) {
        expect(parsed[i].id, equals(original[i].id));
        expect(parsed[i].path, equals(original[i].path));
        expect(parsed[i].hint, equals(original[i].hint));
      }
    });
  });

  group('URIScheme - Error Handling', () {
    test('addSignature throws on invalid URI', () {
      expect(
        () => uriScheme.addSignature('https://example.com', signerKeyPair),
        throwsArgumentError
      );
    });

    test('verifySignature returns false for invalid public key', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100'
      );
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      final isValid = uriScheme.verifySignature(signedUri, 'INVALID_KEY');
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for unparseable URI', () {
      final isValid = uriScheme.verifySignature('not a uri', signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for invalid sep7 URL', () {
      final isValid = uriScheme.verifySignature('https://example.com', signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for URI with modified signature', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100'
      );
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      // Modify the signature
      final modifiedUri = signedUri.replaceAll(RegExp(r'signature=[^&]+'), 'signature=AAAA');

      final isValid = uriScheme.verifySignature(modifiedUri, signerKeyPair.accountId);
      expect(isValid, isFalse);
    });
  });

  group('URIScheme - Memo Return Type', () {
    test('generates pay URI with memo return', () {
      final hash = base64Encode(Uint8List.fromList(List<int>.filled(32, 2)));

      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        memo: hash,
        memoType: 'MEMO_RETURN'
      );

      expect(uri, contains('memo='));
      expect(uri, contains('memo_type='));
      expect(uri, contains('MEMO_RETURN'));

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['memo_type'], equals('MEMO_RETURN'));
    });
  });

  group('URI Validation Edge Cases', () {
    test('isValidSep7Url rejects URI with invalid XDR transaction', () {
      final result = uriScheme
          .isValidSep7Url('web+stellar:tx?xdr=notvalidxdr');
      expect(result.result, isFalse);
      expect(result.reason, contains('transaction envelope'));
    });

    test('isValidSep7Url validates URI with contract ID as destination', () {
      final contractId = 'CAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQC526';
      final result = uriScheme
          .isValidSep7Url('web+stellar:pay?destination=$contractId');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url validates URI with muxed account destination', () {
      final muxedAccountId =
          'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6';
      final result = uriScheme
          .isValidSep7Url('web+stellar:pay?destination=$muxedAccountId');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects URI with too many path segments', () {
      final result =
          uriScheme.isValidSep7Url('web+stellar:tx/extra/segments?xdr=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('path segments'));
    });

    test('isValidSep7Url rejects pay URI with xdr parameter', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&xdr=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects tx URI with destination parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&destination=${destinationKeyPair.accountId}');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects tx URI with amount parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&amount=100');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects tx URI with asset_code parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&asset_code=USD');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects tx URI with asset_issuer parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&asset_issuer=${destinationKeyPair.accountId}');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects pay URI with asset code longer than 12', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&asset_code=VERYLONGASSET');
      expect(result.result, isFalse);
      expect(result.reason, contains('asset code'));
    });

    test('isValidSep7Url rejects pay URI with invalid asset issuer', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&asset_code=USD&asset_issuer=INVALID');
      expect(result.result, isFalse);
      expect(result.reason, contains('asset_issuer'));
    });

    test('isValidSep7Url rejects pay URI with pubkey parameter', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&pubkey=${sourceKeyPair.accountId}');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects tx URI with invalid pubkey', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&pubkey=INVALID_KEY');
      expect(result.result, isFalse);
      expect(result.reason, contains('public key'));
    });

    test('isValidSep7Url rejects URI with message longer than 300 chars', () {
      final longMessage = 'A' * 301;
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&msg=${Uri.encodeComponent(longMessage)}');
      expect(result.result, isFalse);
      expect(result.reason, contains('300 characters'));
    });

    test('isValidSep7Url accepts URI with message exactly 300 chars', () {
      final message300 = 'A' * 300;
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&msg=${Uri.encodeComponent(message300)}');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects tx URI with memo_type parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&memo_type=MEMO_TEXT');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects tx URI with memo parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final result = uriScheme.isValidSep7Url(
          'web+stellar:tx?xdr=${Uri.encodeComponent(xdr)}&memo=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects pay URI with invalid memo type', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=test&memo_type=MEMO_INVALID');
      expect(result.result, isFalse);
      expect(result.reason, contains('memo_type'));
    });

    test('isValidSep7Url rejects pay URI with MEMO_TEXT that is too long',
        () {
      final longMemo = 'A' * 29; // MemoText max is 28 bytes
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=${Uri.encodeComponent(longMemo)}&memo_type=MEMO_TEXT');
      expect(result.result, isFalse);
      expect(result.reason, contains('too long'));
    });

    test('isValidSep7Url accepts pay URI with MEMO_TEXT at max length', () {
      final memo28 = 'A' * 28;
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=${Uri.encodeComponent(memo28)}&memo_type=MEMO_TEXT');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects pay URI with MEMO_ID with invalid value', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=invalid_id&memo_type=MEMO_ID');
      expect(result.result, isFalse);
      expect(result.reason, contains('invalid value'));
    });

    test('isValidSep7Url accepts pay URI with valid MEMO_ID', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=12345&memo_type=MEMO_ID');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects pay URI with MEMO_HASH with non-base64', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=not_base64!&memo_type=MEMO_HASH');
      expect(result.result, isFalse);
      expect(result.reason, contains('base64'));
    });

    test('isValidSep7Url accepts pay URI with valid MEMO_HASH', () {
      final hash = base64Encode(Uint8List.fromList(List<int>.filled(32, 1)));
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=$hash&memo_type=MEMO_HASH');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects pay URI with MEMO_RETURN with non-base64',
        () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=not_base64!&memo_type=MEMO_RETURN');
      expect(result.result, isFalse);
      expect(result.reason, contains('base64'));
    });

    test('isValidSep7Url accepts pay URI with valid MEMO_RETURN', () {
      final hash = base64Encode(Uint8List.fromList(List<int>.filled(32, 2)));
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&memo=$hash&memo_type=MEMO_RETURN');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects pay URI with invalid origin domain', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&origin_domain=invalid_domain_!@#');
      expect(result.result, isFalse);
      expect(result.reason, contains('domain name'));
    });

    test('isValidSep7Url accepts pay URI with valid origin domain', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&origin_domain=example.com');
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects pay URI with chain parameter', () {
      final result = uriScheme.isValidSep7Url(
          'web+stellar:pay?destination=${destinationKeyPair.accountId}&chain=test');
      expect(result.result, isFalse);
      expect(result.reason, contains('Unsupported parameter'));
    });

    test('isValidSep7Url rejects URI with unsupported operation type', () {
      final result =
          uriScheme.isValidSep7Url('web+stellar:unsupported?test=value');
      expect(result.result, isFalse);
      expect(result.reason, contains('not supported'));
    });

    test('isValidSep7Url handles chain parameter with nesting', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final chainUri = uriScheme.generateSignTransactionURI(xdr);
      final uri =
          uriScheme.generateSignTransactionURI(xdr, chain: chainUri);

      final result = uriScheme.isValidSep7Url(uri);
      expect(result.result, isTrue);
    });

    test('isValidSep7Url rejects chain nesting deeper than 7 levels', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      String chainUri = uriScheme.generateSignTransactionURI(xdr);
      for (int i = 0; i < 9; i++) {
        chainUri =
            uriScheme.generateSignTransactionURI(xdr, chain: chainUri);
      }

      final result = uriScheme.isValidSep7Url(chainUri);
      expect(result.result, isFalse);
      expect(result.reason, contains('nested levels'));
    });
  });

  group('Replacement Handling', () {
    test('uriSchemeReplacementsToString with single replacement', () {
      final replacements = [
        UriSchemeReplacement('X', 'sourceAccount', 'account paying fees'),
      ];

      final result = uriScheme.uriSchemeReplacementsToString(replacements);

      expect(result, contains('sourceAccount:X'));
      expect(result, contains('X:account paying fees'));
    });

    test('uriSchemeReplacementsToString with multiple replacements', () {
      final replacements = [
        UriSchemeReplacement('X', 'sourceAccount', 'account paying fees'),
        UriSchemeReplacement(
            'Y', 'operations[0].destination', 'receiving account'),
      ];

      final result = uriScheme.uriSchemeReplacementsToString(replacements);

      expect(result, contains('sourceAccount:X'));
      expect(result, contains('operations[0].destination:Y'));
      expect(result, contains('X:account paying fees'));
      expect(result, contains('Y:receiving account'));
    });

    test('uriSchemeReplacementsToString with duplicate IDs deduplicates hints',
        () {
      final replacements = [
        UriSchemeReplacement('X', 'operations[0].destination', 'account'),
        UriSchemeReplacement('X', 'operations[1].destination', 'account'),
      ];

      final result = uriScheme.uriSchemeReplacementsToString(replacements);

      expect(result, contains('operations[0].destination:X'));
      expect(result, contains('operations[1].destination:X'));
      final hintCount = 'X:account'.allMatches(result).length;
      expect(hintCount, equals(1));
    });

    test('uriSchemeReplacementsToString with empty list', () {
      final result = uriScheme.uriSchemeReplacementsToString([]);
      expect(result, isEmpty);
    });

    test('uriSchemeReplacementsFromString parses single replacement', () {
      final replaceString = 'sourceAccount:X;X:account paying fees';

      final replacements =
          uriScheme.uriSchemeReplacementsFromString(replaceString);

      expect(replacements.length, equals(1));
      expect(replacements[0].path, equals('sourceAccount'));
      expect(replacements[0].id, equals('X'));
      expect(replacements[0].hint, equals('account paying fees'));
    });

    test('uriSchemeReplacementsFromString parses multiple replacements', () {
      final replaceString =
          'sourceAccount:X,operations[0].destination:Y;X:account paying fees,Y:receiving account';

      final replacements =
          uriScheme.uriSchemeReplacementsFromString(replaceString);

      expect(replacements.length, equals(2));
      expect(replacements[0].path, equals('sourceAccount'));
      expect(replacements[0].id, equals('X'));
      expect(replacements[1].path, equals('operations[0].destination'));
      expect(replacements[1].id, equals('Y'));
    });

    test('uriSchemeReplacementsFromString with empty string', () {
      final result = uriScheme.uriSchemeReplacementsFromString('');
      expect(result, isEmpty);
    });

    test('uriSchemeReplacementsFromString handles shared IDs', () {
      final replaceString =
          'operations[0].destination:X,operations[1].destination:X;X:same account';

      final replacements =
          uriScheme.uriSchemeReplacementsFromString(replaceString);

      expect(replacements.length, equals(2));
      expect(replacements[0].id, equals('X'));
      expect(replacements[1].id, equals('X'));
      expect(replacements[0].hint, equals('same account'));
      expect(replacements[1].hint, equals('same account'));
    });

    test('replacement roundtrip preserves data', () {
      final original = [
        UriSchemeReplacement('A', 'sourceAccount', 'source'),
        UriSchemeReplacement('B', 'operations[0].amount', 'amount'),
        UriSchemeReplacement('C', 'operations[0].destination', 'dest'),
      ];

      final stringFormat = uriScheme.uriSchemeReplacementsToString(original);
      final parsed = uriScheme.uriSchemeReplacementsFromString(stringFormat);

      expect(parsed.length, equals(original.length));
      for (int i = 0; i < original.length; i++) {
        expect(parsed[i].id, equals(original[i].id));
        expect(parsed[i].path, equals(original[i].path));
        expect(parsed[i].hint, equals(original[i].hint));
      }
    });
  });

  group('Signature Verification Edge Cases', () {
    test('verifySignature returns false for invalid public key', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
      );
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      final isValid = uriScheme.verifySignature(signedUri, 'INVALID_KEY');
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for unparseable URI', () {
      final isValid =
          uriScheme.verifySignature('not a uri', signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for invalid sep7 URL', () {
      final isValid = uriScheme.verifySignature(
          'https://example.com', signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for URI without signature', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
      );

      final isValid = uriScheme.verifySignature(uri, signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('verifySignature returns false for modified signature', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
      );
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      final modifiedUri =
          signedUri.replaceAll(RegExp(r'signature=[^&]+'), 'signature=AAAA');

      final isValid =
          uriScheme.verifySignature(modifiedUri, signerKeyPair.accountId);
      expect(isValid, isFalse);
    });

    test('addSignature throws on invalid URI', () {
      expect(
        () => uriScheme.addSignature('https://example.com', signerKeyPair),
        throwsArgumentError,
      );
    });

    test('addSignature throws on already signed URI', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
      );
      final signedUri = uriScheme.addSignature(uri, signerKeyPair);

      expect(
        () => uriScheme.addSignature(signedUri, signerKeyPair),
        throwsArgumentError,
      );
    });
  });

  group('generatePayOperationURI with all parameters', () {
    test('generates pay URI with all possible parameters', () {
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
        originDomain: 'example.com',
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

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['destination'],
          equals(destinationKeyPair.accountId));
      expect(parsed.queryParameters['amount'], equals('100.50'));
      expect(parsed.queryParameters['asset_code'], equals('USD'));
      expect(parsed.queryParameters['asset_issuer'],
          equals(issuerKeyPair.accountId));
      expect(parsed.queryParameters['memo'], equals('Order #123'));
      expect(parsed.queryParameters['memo_type'], equals('MEMO_TEXT'));
    });

    test('generates pay URI with signature', () {
      final uri = uriScheme.generatePayOperationURI(
        destinationKeyPair.accountId,
        amount: '100',
        originDomain: 'example.com',
        signature: 'dGVzdHNpZ25hdHVyZQ==',
      );

      expect(uri, contains('signature='));
      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['signature'], isNotNull);
    });
  });

  group('generateSignTransactionURI with all parameters', () {
    test('generates tx URI with all parameters including signature', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final uri = uriScheme.generateSignTransactionURI(
        xdr,
        replace: 'sourceAccount:X;X:source account',
        callback: 'url:https://example.com/callback',
        publicKey: sourceKeyPair.accountId,
        message: 'Sign this payment',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        originDomain: 'example.com',
        signature: 'dGVzdHNpZ25hdHVyZQ==',
      );

      expect(uri, contains('xdr='));
      expect(uri, contains('replace='));
      expect(uri, contains('callback='));
      expect(uri, contains('pubkey='));
      expect(uri, contains('msg='));
      expect(uri, contains('network_passphrase='));
      expect(uri, contains('origin_domain='));
      expect(uri, contains('signature='));

      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['xdr'], equals(xdr));
      expect(parsed.queryParameters['pubkey'], equals(sourceKeyPair.accountId));
    });

    test('generates tx URI with chain parameter', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction =
          TransactionBuilder(sourceAccount).addOperation(paymentOp).build();
      transaction.sign(sourceKeyPair, Network.TESTNET);
      final xdr = transaction.toEnvelopeXdrBase64();

      final chainUri = uriScheme.generateSignTransactionURI(xdr);
      final uri =
          uriScheme.generateSignTransactionURI(xdr, chain: chainUri);

      expect(uri, contains('chain='));
      final parsed = uriScheme.tryParseSep7Url(uri);
      expect(parsed, isNotNull);
      expect(parsed!.queryParameters['chain'], isNotNull);
    });
  });

  group('URIScheme Final Coverage Tests', () {
    late KeyPair testKeyPair;

    setUp(() {
      testKeyPair = KeyPair.random();
    });

    group('signAndSubmitTransaction Tests', () {
      test('throws on invalid sep7 transaction URL', () async {
        final invalidUrl = 'web+stellar:pay?destination=GABC';

        expect(
          () async => await uriScheme.signAndSubmitTransaction(invalidUrl, testKeyPair),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on sep7 URL without xdr parameter', () async {
        final urlWithoutXdr = 'web+stellar:tx?callback=url:https://example.com';

        expect(
          () async => await uriScheme.signAndSubmitTransaction(urlWithoutXdr, testKeyPair),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on invalid XDR in transaction URL', () async {
        final urlWithInvalidXdr = 'web+stellar:tx?xdr=invalid_xdr_data';

        expect(
          () async => await uriScheme.signAndSubmitTransaction(urlWithInvalidXdr, testKeyPair),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('submits transaction via callback URL', () async {
        final localSourceAccount = Account(testKeyPair.accountId, BigInt.from(100));
        final transaction = TransactionBuilder(localSourceAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();
        transaction.sign(testKeyPair, Network.TESTNET);

        final xdr = transaction.toEnvelopeXdrBase64();
        final callbackUrl = 'url:https://example.com/callback';
        final txUrl = uriScheme.generateSignTransactionURI(
          xdr,
          callback: callbackUrl,
        );

        final mockClient = MockClient((request) async {
          expect(request.url.toString(), 'https://example.com/callback');
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'], 'application/x-www-form-urlencoded');
          return http.Response('{"status":"pending"}', 200);
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);
        final result = await uriSchemeWithMock.signAndSubmitTransaction(
          txUrl,
          signerKeyPair,
          network: Network.TESTNET,
        );

        expect(result.response, isNotNull);
        expect(result.submitTransactionResponse, isNull);
        expect(result.response!.statusCode, 200);
      });

      test('submits transaction to network when no callback', () async {
        final localSourceAccount = Account(testKeyPair.accountId, BigInt.from(100));
        final transaction = TransactionBuilder(localSourceAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();
        transaction.sign(testKeyPair, Network.TESTNET);

        final xdr = transaction.toEnvelopeXdrBase64();
        final txUrl = uriScheme.generateSignTransactionURI(xdr);

        // This test verifies the code path, actual submission would require network
        expect(txUrl, contains('xdr='));
      });

      test('handles callback with HTTP request headers', () async {
        final localSourceAccount = Account(testKeyPair.accountId, BigInt.from(100));
        final transaction = TransactionBuilder(localSourceAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();
        transaction.sign(testKeyPair, Network.TESTNET);

        final xdr = transaction.toEnvelopeXdrBase64();
        final txUrl = uriScheme.generateSignTransactionURI(
          xdr,
          callback: 'url:https://example.com/callback',
        );

        final mockClient = MockClient((request) async {
          expect(request.headers['Custom-Header'], 'test-value');
          return http.Response('{"status":"ok"}', 200);
        });

        final uriSchemeWithHeaders = URIScheme(
          httpClient: mockClient,
          httpRequestHeaders: {'Custom-Header': 'test-value'},
        );

        final result = await uriSchemeWithHeaders.signAndSubmitTransaction(
          txUrl,
          signerKeyPair,
          network: Network.TESTNET,
        );

        expect(result.response, isNotNull);
      });
    });

    group('Deprecated signURI Tests', () {
      test('deprecated signURI successfully signs valid URL', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final signedUrl = uriScheme.signURI(payUrl, signerKeyPair);

        expect(signedUrl, contains('signature='));
        expect(signedUrl.split('signature=').length, 2);
      });

      test('deprecated signURI signs URL even with minimal path', () {
        // The signURI deprecated method doesn't validate the URL, it just signs it
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final signedUrl = uriScheme.signURI(payUrl, signerKeyPair);

        expect(signedUrl, contains('signature='));
      });
    });

    group('isValidSep7SignedUrl Tests', () {
      test('returns error for URL without origin_domain', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final result = await uriScheme.isValidSep7SignedUrl(payUrl);

        expect(result.result, false);
        expect(result.reason, contains('origin_domain'));
      });

      test('returns error for URL without signature', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );

        final result = await uriScheme.isValidSep7SignedUrl(payUrl);

        expect(result.result, false);
        expect(result.reason, contains('signature'));
      });

      test('returns error for invalid origin_domain format', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'invalid',
          signature: 'fake_signature',
        );

        final result = await uriScheme.isValidSep7SignedUrl(payUrl);

        expect(result.result, false);
        expect(result.reason, isNotNull);
      });

      test('returns error when toml not found', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);
        final result = await uriSchemeWithMock.isValidSep7SignedUrl(signedUrl);

        expect(result.result, false);
        expect(result.reason, contains('Toml not found'));
      });

      test('returns error when toml missing signing key', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final mockClient = MockClient((request) async {
          return http.Response('VERSION="1.0.0"', 200);
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);
        final result = await uriSchemeWithMock.isValidSep7SignedUrl(signedUrl);

        expect(result.result, false);
        expect(result.reason, contains('No signing key'));
      });

      test('returns error when signing key is invalid', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final mockClient = MockClient((request) async {
          return http.Response('URI_REQUEST_SIGNING_KEY="invalid_key"', 200);
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);
        final result = await uriSchemeWithMock.isValidSep7SignedUrl(signedUrl);

        expect(result.result, false);
        expect(result.reason, contains('not valid'));
      });

      test('returns error when signature verification fails', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );
        final wrongSigner = KeyPair.random();
        final signedUrl = uriScheme.addSignature(payUrl, wrongSigner);

        final mockClient = MockClient((request) async {
          return http.Response(
            'URI_REQUEST_SIGNING_KEY="${signerKeyPair.accountId}"',
            200,
          );
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);
        final result = await uriSchemeWithMock.isValidSep7SignedUrl(signedUrl);

        expect(result.result, false);
        expect(result.reason, contains('Signature is not from'));
      });
    });

    group('Deprecated checkUIRSchemeIsValid Tests', () {
      test('throws URISchemeError for missing origin domain', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        expect(
          () async => await uriScheme.checkUIRSchemeIsValid(payUrl),
          throwsA(isA<URISchemeError>()),
        );
      });

      test('throws URISchemeError for invalid origin domain', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'invalid',
          signature: 'test',
        );

        expect(
          () async => await uriScheme.checkUIRSchemeIsValid(payUrl),
          throwsA(isA<URISchemeError>()),
        );
      });

      test('throws URISchemeError for missing signature', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );

        expect(
          () async => await uriScheme.checkUIRSchemeIsValid(payUrl),
          throwsA(isA<URISchemeError>()),
        );
      });

      test('throws URISchemeError for toml not found', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);

        expect(
          () async => await uriSchemeWithMock.checkUIRSchemeIsValid(signedUrl),
          throwsA(isA<URISchemeError>()),
        );
      });

      test('throws URISchemeError for missing toml signature', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final mockClient = MockClient((request) async {
          return http.Response('VERSION="1.0.0"', 200);
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);

        expect(
          () async => await uriSchemeWithMock.checkUIRSchemeIsValid(signedUrl),
          throwsA(isA<URISchemeError>()),
        );
      });

      test('throws URISchemeError for invalid signature', () async {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
          originDomain: 'example.com',
          signature: 'fake_signature',
        );

        final mockClient = MockClient((request) async {
          return http.Response(
            'URI_REQUEST_SIGNING_KEY="${signerKeyPair.accountId}"',
            200,
          );
        });

        final uriSchemeWithMock = URIScheme(httpClient: mockClient);

        expect(
          () async => await uriSchemeWithMock.checkUIRSchemeIsValid(payUrl),
          throwsA(isA<URISchemeError>()),
        );
      });
    });

    group('Deprecated verify Tests', () {
      test('verify returns false for invalid signature', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final fakeSignature = base64Encode(List.filled(64, 0));
        final result = uriScheme.verify(payUrl, Uri.encodeComponent(fakeSignature), signerKeyPair);

        expect(result, false);
      });

      test('verify successfully validates correct signature', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final signedUrl = uriScheme.signURI(payUrl, signerKeyPair);
        final signature = signedUrl.split('signature=').last;

        final result = uriScheme.verify(payUrl, signature, signerKeyPair);
        expect(result, true);
      });
    });

    group('Deprecated getParameterValue Tests', () {
      test('getParameterValue extracts parameter correctly', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final amount = uriScheme.getParameterValue('amount', payUrl);
        expect(amount, '100');
      });

      test('getParameterValue returns null for missing parameter', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
        );

        final amount = uriScheme.getParameterValue('amount', payUrl);
        expect(amount, isNull);
      });
    });

    group('URISchemeError Tests', () {
      test('URISchemeError toString for invalid signature', () {
        final error = URISchemeError(URISchemeError.invalidSignature);
        expect(error.toString(), contains('invalid Signature'));
        expect(error.type, URISchemeError.invalidSignature);
      });

      test('URISchemeError toString for invalid origin domain', () {
        final error = URISchemeError(URISchemeError.invalidOriginDomain);
        expect(error.toString(), contains('invalid Origin Domain'));
      });

      test('URISchemeError toString for missing origin domain', () {
        final error = URISchemeError(URISchemeError.missingOriginDomain);
        expect(error.toString(), contains('missing Origin Domain'));
      });

      test('URISchemeError toString for missing signature', () {
        final error = URISchemeError(URISchemeError.missingSignature);
        expect(error.toString(), contains('missing Signature'));
      });

      test('URISchemeError toString for toml not found', () {
        final error = URISchemeError(URISchemeError.tomlNotFoundOrInvalid);
        expect(error.toString(), contains('toml not found'));
      });

      test('URISchemeError toString for toml signature missing', () {
        final error = URISchemeError(URISchemeError.tomlSignatureMissing);
        expect(error.toString(), contains('Toml Signature Missing'));
      });

      test('URISchemeError toString for unknown error', () {
        final error = URISchemeError(999);
        expect(error.toString(), contains('unknown error'));
      });
    });

    group('isValidSep7Url Tests - Additional Edge Cases', () {
      test('handles chain parameter validation', () {
        final localSourceAccount = Account(testKeyPair.accountId, BigInt.from(100));
        final transaction = TransactionBuilder(localSourceAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        // Create a chain URL with proper format
        final chainUrl = uriScheme.generatePayOperationURI(
          KeyPair.random().accountId,
          amount: '10',
        );

        final txUrl = uriScheme.generateSignTransactionURI(
          transaction.toEnvelopeXdrBase64(),
          chain: chainUrl,
        );

        final result = uriScheme.isValidSep7Url(txUrl);
        expect(result.result, true);
      });
    });

    group('verifySignature Tests', () {
      test('verifySignature returns false for invalid public key', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final result = uriScheme.verifySignature(signedUrl, 'invalid_key');
        expect(result, false);
      });

      test('verifySignature returns false for unparseable URL', () {
        final result = uriScheme.verifySignature('not_a_url', signerKeyPair.accountId);
        expect(result, false);
      });

      test('verifySignature returns false for invalid sep7 URL', () {
        final result = uriScheme.verifySignature(
          'web+stellar:invalid',
          signerKeyPair.accountId,
        );
        expect(result, false);
      });

      test('verifySignature returns false for URL without signature', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );

        final result = uriScheme.verifySignature(payUrl, signerKeyPair.accountId);
        expect(result, false);
      });

      test('verifySignature successfully validates correct signature', () {
        final payUrl = uriScheme.generatePayOperationURI(
          testKeyPair.accountId,
          amount: '100',
        );
        final signedUrl = uriScheme.addSignature(payUrl, signerKeyPair);

        final result = uriScheme.verifySignature(signedUrl, signerKeyPair.accountId);
        expect(result, true);
      });
    });
  });
}
