@Timeout(const Duration(seconds: 400))
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  final String accountId =
      "GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV";
  final String secretSeed =
      "SBA2XQ5SRUW5H3FUQARMC6QYEPUYNSVCMM4PGESGVB2UIFHLM73TPXXF";
  final String originDomainParam = "&origin_domain=place.domain.com";
  final String callbackParam = "&callback=url:https://examplepost.com";
  final KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);
  final URIScheme uriScheme = URIScheme();

  String requestToml() {
    return '''# Sample stellar.toml

    FEDERATION_SERVER="https://api.domain.com/federation"
    AUTH_SERVER="https://api.domain.com/auth"
    TRANSFER_SERVER="https://api.domain.com"
    URI_REQUEST_SIGNING_KEY="GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV"''';
  }

  String requestTomlSignatureMissing() {
    return '''# Sample stellar.toml

    FEDERATION_SERVER="https://api.domain.com/federation"
    AUTH_SERVER="https://api.domain.com/auth"
    TRANSFER_SERVER="https://api.domain.com"''';
  }

  String requestTomlSignatureMissmatch() {
    return '''# Sample stellar.toml

    FEDERATION_SERVER="https://api.domain.com/federation"
    AUTH_SERVER="https://api.domain.com/auth"
    TRANSFER_SERVER="https://api.domain.com"
    URI_REQUEST_SIGNING_KEY="GCCHBLJOZUFBVAUZP55N7ZU6ZB5VGEDHSXT23QC6UIVDQNGI6QDQTOOR"''';
  }

  setUp(() async {
    await sdk.accounts.account(accountId).then((response) {
      assert(true);
    }).catchError((error) async {
      assert(error is ErrorResponse && error.code == 404);
      await FriendBot.fundTestAccount(accountId);
    });
  });

  test('test generate sign transaction url', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url =
        uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());
    assert(url.startsWith(
        "web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9O"));
  });

  test('test generate pay operation url', () async {
    String url = uriScheme.generatePayOperationURI(accountId,
        amount: "123.21",
        assetCode: "ANA",
        assetIssuer:
            "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV");
    assert(
        "web+stellar:pay?destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV&amount=123.21&asset_code=ANA&asset_issuer=GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV" ==
            url);
  });

  test('check missing signature from URI scheme', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Missing parameter 'signature'");
  });

  test('check missing domain from URI scheme', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url =
        uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Missing parameter 'origin_domain'");
  });

  test('generate signed Tx Test Url', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;
    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));
  });

  test('validate Test Url', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;
    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              "https://place.domain.com/.well-known/stellar.toml") &&
          request.method == "GET") {
        return http.Response(requestToml(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(validationResult.result);

    uriScheme.httpClient = http.Client();
  });

  test('sign and submit transaction', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;
    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));

    SubmitUriSchemeTransactionResponse response = await uriScheme
        .signAndSubmitTransaction(url, signerKeyPair, network: Network.TESTNET);
    assert(response.submitTransactionResponse != null);
    assert(response.submitTransactionResponse!.success);
  });

  test('sign and submit transaction to callback', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam +
        callbackParam;
    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith("https://examplepost.com") &&
          request.method == "POST" &&
          request.body.startsWith(URIScheme.xdrParameterName)) {
        return http.Response("", 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SubmitUriSchemeTransactionResponse response = await uriScheme
        .signAndSubmitTransaction(url, signerKeyPair, network: Network.TESTNET);
    assert(response.submitTransactionResponse == null);
    assert(response.response != null);
    assert(response.response!.statusCode == 200);
    uriScheme.httpClient = http.Client();
  });

  test('check Toml Signature Missing', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;

    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              "https://place.domain.com/.well-known/stellar.toml") &&
          request.method == "GET") {
        return http.Response(requestTomlSignatureMissing(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "No signing key found in toml from 'place.domain.com'");
    uriScheme.httpClient = http.Client();
  });

  test('check Toml Signature Mismatch', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;

    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              "https://place.domain.com/.well-known/stellar.toml") &&
          request.method == "GET") {
        return http.Response(requestTomlSignatureMissmatch(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(!validationResult.result);
    assert(validationResult.reason != null);
    assert(validationResult.reason!
            .startsWith("Signature is not from the signing key") &&
        validationResult.reason!
            .endsWith("found in the toml data of 'place.domain.com"));

    uriScheme.httpClient = http.Client();
  });

  test('test invalid sep7 url', () {
    var url = "https://soneso.com/tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9O";

    var validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "It must start with web+stellar:");

    url = "web+stellar:tx/pay?destination=$accountId";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Invalid number of path segments. Must only have one path segment");

    url = "web+stellar:203842";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Operation type 203842 is not supported");

    url = "web+stellar:tx?destination=$accountId";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Operation type tx must have a 'xdr' parameter");

    url = "web+stellar:tx?xdr=12345673773";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "The provided 'xdr' parameter is not a valid transaction envelope");

    url = "web+stellar:pay?xdr=12345673773";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Operation type pay must have a 'destination' parameter");

    url = "web+stellar:pay?destination=12345673773";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "The provided 'destination' parameter is not a valid Stellar address");

    url = "web+stellar:pay?destination=$accountId&pubkey=123434938";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "The provided 'pubkey' parameter is not a valid Stellar public key");

    url = "web+stellar:pay?destination=$accountId&msg=lksjafhdalkjsfhkldjahsflkjhasfhasdkjfhasdlfkjhdlkfhjasdlkjhfdskljhflkdsajhfladskjhflasdkjhfklasdjhfadslkjhfdlksjhflasdkjhflsdakjhfkasdjlhfljkdshfkjdshaflkjdhsalfkhdskjflhsadlkjfhdlskjhfasdlkfhdlsakjfhdlkjfhlaskdjhfldsajhfsldjkahflkjsdahflksjafhdalkjsfhkldjahsflkjhasfhasdkjfhasdlfkjhdlkfhjasdlkjhfdskljhflkdsajhfladskjhflasdkjhfklasdjhfadslkjhfdlksjhflasdkjhflsdakjhfkasdjlhfljkdshfkjdshaflkjdhsalfkhdskjflhsadlkjfhdlskjhfasdlkfhdlsakjfhdlkjfhlaskdjhfldsajhfsldjkahflkjsdahf";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "The 'msg' parameter should be no longer than 300 characters");

    url = "web+stellar:pay?destination=$accountId&origin_domain=911";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "The 'origin_domain' parameter is not a fully qualified domain name");


    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
    TransactionBuilder(Account(accountId, BigInt.zero)).addOperation(setOp.build()).build();
    url = uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());
    for(var i=0;i<10;i++) {
      url = uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64(), chain: url);
    }
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Chaining more then 7 nested levels is not allowed");
  });
}
