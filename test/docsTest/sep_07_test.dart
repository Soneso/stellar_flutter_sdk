@Timeout(const Duration(seconds: 300))

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final String accountId =
      'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV';
  final String secretSeed =
      'SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF';

  Transaction getTestTransaction() {
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain('www.example.com');
    return TransactionBuilder(Account(accountId, BigInt.zero))
        .addOperation(setOp.build())
        .build();
  }

  test('sep-07: Quick example - generate pay URI', () {
    // Snippet from sep-07.md "Quick example"
    final uriScheme = URIScheme();

    String uri = uriScheme.generatePayOperationURI(
      'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
      amount: '100',
      assetCode: 'USDC',
      assetIssuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
    );

    expect(uri, startsWith('web+stellar:pay?destination='));
    expect(uri, contains('amount=100'));
    expect(uri, contains('asset_code=USDC'));
    expect(uri, contains('asset_issuer=GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'));
  });

  test('sep-07: Transaction signing (tx operation)', () {
    // Snippet from sep-07.md "Transaction signing (tx operation)"
    final transaction = getTestTransaction();

    final uriScheme = URIScheme();
    String uri = uriScheme.generateSignTransactionURI(
      transaction.toEnvelopeXdrBase64(),
    );

    expect(uri, startsWith('web+stellar:tx?xdr='));

    // Validate the generated URI
    IsValidSep7UrlResult validation = uriScheme.isValidSep7Url(uri);
    expect(validation.result, true);
  });

  test('sep-07: Transaction URI with all options', () {
    // Snippet from sep-07.md "Transaction URI with all options"
    final uriScheme = URIScheme();
    final transaction = getTestTransaction();
    String xdrBase64 = transaction.toEnvelopeXdrBase64();

    String uri = uriScheme.generateSignTransactionURI(
      xdrBase64,
      replace: null,
      callback: 'url:https://example.com/callback',
      publicKey: 'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
      chain: null,
      message: 'Please sign to update your account settings',
      networkPassphrase: Network.TESTNET.networkPassphrase,
      originDomain: 'example.com',
    );

    expect(uri, startsWith('web+stellar:tx?xdr='));
    expect(uri, contains('callback='));
    expect(uri, contains('pubkey='));
    expect(uri, contains('msg='));
    expect(uri, contains('network_passphrase='));
    expect(uri, contains('origin_domain='));
  });

  test('sep-07: Field replacement with Txrep', () {
    // Snippet from sep-07.md "Field replacement with Txrep"
    final uriScheme = URIScheme();
    final transaction = getTestTransaction();
    String xdrBase64 = transaction.toEnvelopeXdrBase64();

    final replacements = [
      UriSchemeReplacement('X', 'sourceAccount', 'Account to pay fees from'),
      UriSchemeReplacement(
          'Y', 'operations[0].destination', 'Account to receive tokens'),
    ];

    String replaceString =
        uriScheme.uriSchemeReplacementsToString(replacements);
    expect(replaceString, contains('sourceAccount:X'));
    expect(replaceString, contains('operations[0].destination:Y'));

    String uri = uriScheme.generateSignTransactionURI(
      xdrBase64,
      replace: replaceString,
    );

    expect(uri, contains('replace='));

    // Parse the replacements back
    List<UriSchemeReplacement> parsed =
        uriScheme.uriSchemeReplacementsFromString(replaceString);
    expect(parsed.length, 2);
    expect(parsed[0].id, 'X');
    expect(parsed[0].path, 'sourceAccount');
    expect(parsed[0].hint, 'Account to pay fees from');
    expect(parsed[1].id, 'Y');
    expect(parsed[1].path, 'operations[0].destination');
    expect(parsed[1].hint, 'Account to receive tokens');
  });

  test('sep-07: Payment request (pay operation)', () {
    // Snippet from sep-07.md "Payment request (pay operation)"
    final uriScheme = URIScheme();

    String uri = uriScheme.generatePayOperationURI(
      'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
      amount: '50.5',
    );

    expect(uri, startsWith('web+stellar:pay?destination='));
    expect(uri, contains('amount=50.5'));
  });

  test('sep-07: Payment with asset and memo', () {
    // Snippet from sep-07.md "Payment with asset and memo"
    final uriScheme = URIScheme();

    String uri = uriScheme.generatePayOperationURI(
      'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
      amount: '100',
      assetCode: 'USDC',
      assetIssuer: 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
      memo: 'order-12345',
      memoType: 'MEMO_TEXT',
    );

    expect(uri, contains('amount=100'));
    expect(uri, contains('asset_code=USDC'));
    expect(uri, contains('memo=order-12345'));
    expect(uri, contains('memo_type=MEMO_TEXT'));

    IsValidSep7UrlResult validation = uriScheme.isValidSep7Url(uri);
    expect(validation.result, true);
  });

  test('sep-07: Donation request (no amount)', () {
    // Snippet from sep-07.md "Donation request (no amount)"
    final uriScheme = URIScheme();

    String uri = uriScheme.generatePayOperationURI(
      'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
      message: 'Support our open source project!',
    );

    expect(uri, startsWith('web+stellar:pay?destination='));
    expect(uri, contains('msg='));
    // Should not contain amount
    expect(uri, isNot(contains('amount=')));
  });

  test('sep-07: Signing URIs for origin verification', () {
    // Snippet from sep-07.md "Signing URIs for origin verification"
    final uriScheme = URIScheme();

    KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      originDomain: 'example.com',
    );

    String signedUri = uriScheme.addSignature(uri, signerKeyPair);

    expect(signedUri, contains('origin_domain='));
    expect(signedUri, contains('signature='));

    // Verify signature with the known public key
    expect(uriScheme.verifySignature(signedUri, signerKeyPair.accountId), true);
  });

  test('sep-07: Structure validation (isValidSep7Url)', () {
    // Snippet from sep-07.md "Structure validation"
    final uriScheme = URIScheme();

    // Valid pay URI
    String validUri =
        'web+stellar:pay?destination=$accountId&amount=100';
    IsValidSep7UrlResult result = uriScheme.isValidSep7Url(validUri);
    expect(result.result, true);

    // Invalid URI - wrong scheme
    String invalidUri = 'https://example.com/pay?destination=$accountId';
    result = uriScheme.isValidSep7Url(invalidUri);
    expect(result.result, false);
    expect(result.reason, isNotNull);
  });

  test('sep-07: Full validation with mock HTTP (isValidSep7SignedUrl)',
      () async {
    // Snippet from sep-07.md "Full validation including signature"
    final uriScheme = URIScheme();
    KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      originDomain: 'place.domain.com',
    );
    String signedUri = uriScheme.addSignature(uri, signerKeyPair);

    // Mock stellar.toml returning our signing key
    String tomlContent =
        'URI_REQUEST_SIGNING_KEY="$accountId"';

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              'https://place.domain.com/.well-known/stellar.toml') &&
          request.method == 'GET') {
        return http.Response(tomlContent, 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    IsValidSep7UrlResult result =
        await uriScheme.isValidSep7SignedUrl(signedUri);
    expect(result.result, true);

    uriScheme.httpClient = http.Client();
  });

  test('sep-07: Missing origin_domain validation', () async {
    // Snippet from sep-07.md validation failure reasons
    final uriScheme = URIScheme();

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
    );

    IsValidSep7UrlResult result = await uriScheme.isValidSep7SignedUrl(uri);
    expect(result.result, false);
    expect(result.reason, "Missing parameter 'origin_domain'");
  });

  test('sep-07: Missing signature validation', () async {
    final uriScheme = URIScheme();

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      originDomain: 'place.domain.com',
    );

    IsValidSep7UrlResult result = await uriScheme.isValidSep7SignedUrl(uri);
    expect(result.result, false);
    expect(result.reason, "Missing parameter 'signature'");
  });

  test('sep-07: Toml signing key missing validation', () async {
    final uriScheme = URIScheme();
    KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      originDomain: 'place.domain.com',
    );
    String signedUri = uriScheme.addSignature(uri, signerKeyPair);

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              'https://place.domain.com/.well-known/stellar.toml') &&
          request.method == 'GET') {
        return http.Response(
            'FEDERATION_SERVER="https://api.domain.com/federation"', 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    IsValidSep7UrlResult result =
        await uriScheme.isValidSep7SignedUrl(signedUri);
    expect(result.result, false);
    expect(result.reason,
        "No signing key found in toml from 'place.domain.com'");

    uriScheme.httpClient = http.Client();
  });

  test('sep-07: Signature mismatch validation', () async {
    final uriScheme = URIScheme();
    KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      originDomain: 'place.domain.com',
    );
    String signedUri = uriScheme.addSignature(uri, signerKeyPair);

    // Toml returns a different signing key
    String wrongKey =
        'URI_REQUEST_SIGNING_KEY="GCCHBLJOZUFBVAUZP55N7ZU6ZB5VGEDHSXT23QC6UIVDQNGI6QDQTOOR"';
    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              'https://place.domain.com/.well-known/stellar.toml') &&
          request.method == 'GET') {
        return http.Response(wrongKey, 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    IsValidSep7UrlResult result =
        await uriScheme.isValidSep7SignedUrl(signedUri);
    expect(result.result, false);
    expect(result.reason, isNotNull);
    expect(result.reason!, startsWith('Signature is not from the signing key'));

    uriScheme.httpClient = http.Client();
  });

  test('sep-07: Signing and submitting to callback', () async {
    // Snippet from sep-07.md "Signing and submitting transactions" (callback path)
    final uriScheme = URIScheme();
    KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      callback: 'url:https://examplepost.com',
    );

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith('https://examplepost.com') &&
          request.method == 'POST' &&
          request.body.startsWith(URIScheme.xdrParameterName)) {
        return http.Response('', 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SubmitUriSchemeTransactionResponse response =
        await uriScheme.signAndSubmitTransaction(
      uri,
      signerKeyPair,
      network: Network.TESTNET,
    );

    expect(response.submitTransactionResponse, isNull);
    expect(response.response, isNotNull);
    expect(response.response!.statusCode, 200);

    uriScheme.httpClient = http.Client();
  });

  test('sep-07: Parsing URI parameters', () {
    // Snippet from sep-07.md "Parsing URI parameters"
    final uriScheme = URIScheme();
    String uri =
        'web+stellar:pay?destination=$accountId&amount=100&memo=order-123&memo_type=MEMO_TEXT&msg=Payment%20for%20order';

    ParsedSep7UrlResult? parsed = uriScheme.tryParseSep7Url(uri);
    expect(parsed, isNotNull);
    expect(parsed!.operationType, 'pay');

    String? destination =
        parsed.queryParameters[URIScheme.destinationParameterName];
    String? amount = parsed.queryParameters[URIScheme.amountParameterName];
    String? memo = parsed.queryParameters[URIScheme.memoParameterName];
    String? message = parsed.queryParameters[URIScheme.messageParameterName];

    expect(destination, accountId);
    expect(amount, '100');
    expect(memo, 'order-123');
    expect(message, 'Payment for order');
  });

  test('sep-07: Verify signature with known public key', () {
    // Snippet from sep-07.md "Signature verification with known public key"
    final uriScheme = URIScheme();
    KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);

    String uri = uriScheme.generateSignTransactionURI(
      getTestTransaction().toEnvelopeXdrBase64(),
      originDomain: 'example.com',
    );
    String signedUri = uriScheme.addSignature(uri, signerKeyPair);

    // Verify using the known public key
    expect(uriScheme.verifySignature(signedUri, accountId), true);

    // Wrong key should fail
    expect(
        uriScheme.verifySignature(signedUri,
            'GCCHBLJOZUFBVAUZP55N7ZU6ZB5VGEDHSXT23QC6UIVDQNGI6QDQTOOR'),
        false);
  });

  test('sep-07: QR code URI generation', () {
    // Snippet from sep-07.md "QR codes"
    final uriScheme = URIScheme();

    String uri = uriScheme.generatePayOperationURI(
      'GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV',
      amount: '25',
      memo: 'coffee',
      memoType: 'MEMO_TEXT',
    );

    expect(uri, startsWith('web+stellar:pay?'));
    expect(uri, contains('amount=25'));
    expect(uri, contains('memo=coffee'));
    expect(uri, contains('memo_type=MEMO_TEXT'));

    IsValidSep7UrlResult validation = uriScheme.isValidSep7Url(uri);
    expect(validation.result, true);
  });
}
