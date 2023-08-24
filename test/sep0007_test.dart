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

    await uriScheme.checkUIRSchemeIsValid(url).then((response) {
      assert(false);
    }).catchError((error) async {
      assert(error is URISchemeError &&
          error.type == URISchemeError.missingSignature);
    });
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

    await uriScheme.checkUIRSchemeIsValid(url).then((response) {
      assert(false);
    }).catchError((error) async {
      assert(error is URISchemeError &&
          error.type == URISchemeError.missingOriginDomain);
    });
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
    url = uriScheme.signURI(url, signerKeyPair);

    assert(uriScheme.getParameterValue(URIScheme.signatureParameterName, url) !=
        null);
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
    url = uriScheme.signURI(url, signerKeyPair);

    assert(uriScheme.getParameterValue(URIScheme.signatureParameterName, url) !=
        null);

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              "https://place.domain.com/.well-known/stellar.toml") &&
          request.method == "GET") {
        return http.Response(requestToml(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    bool isValid = await uriScheme.checkUIRSchemeIsValid(url);
    assert(isValid);
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
    url = uriScheme.signURI(url, signerKeyPair);

    assert(uriScheme.getParameterValue(URIScheme.signatureParameterName, url) !=
        null);

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
    url = uriScheme.signURI(url, signerKeyPair);

    assert(uriScheme.getParameterValue(URIScheme.signatureParameterName, url) !=
        null);

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

    url = uriScheme.signURI(url, signerKeyPair);

    assert(uriScheme.getParameterValue(URIScheme.signatureParameterName, url) !=
        null);

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              "https://place.domain.com/.well-known/stellar.toml") &&
          request.method == "GET") {
        return http.Response(requestTomlSignatureMissing(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    await uriScheme.checkUIRSchemeIsValid(url).then((response) {
      assert(false);
    }).catchError((error) async {
      assert(error is URISchemeError &&
          error.type == URISchemeError.tomlSignatureMissing);
    });
    uriScheme.httpClient = http.Client();
  });

  test('check Toml Signature Missmatch', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme
            .generateSignTransactionURI(transaction.toEnvelopeXdrBase64()) +
        originDomainParam;

    url = uriScheme.signURI(url, signerKeyPair);

    assert(uriScheme.getParameterValue(URIScheme.signatureParameterName, url) !=
        null);

    uriScheme.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(
              "https://place.domain.com/.well-known/stellar.toml") &&
          request.method == "GET") {
        return http.Response(requestTomlSignatureMissmatch(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    await uriScheme.checkUIRSchemeIsValid(url).then((response) {
      assert(false);
    }).catchError((error) async {
      assert(error is URISchemeError &&
          error.type == URISchemeError.invalidSignature);
    });
    uriScheme.httpClient = http.Client();
  });
}
