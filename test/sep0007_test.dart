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
  final String originDomain = "place.domain.com";
  final String callbackUrl = "url:https://examplepost.com";
  final KeyPair signerKeyPair = KeyPair.fromSecretSeed(secretSeed);
  final URIScheme uriScheme = URIScheme();
  final txXdr = Uri.encodeComponent(
      "AAAAAgAAAACBv/Oc5CHGxiLZ4Xc4ehTB2jEB29pFIFnvyuLL6D0eQQAAAGQABE6rAAAAAQAAAAEAAAAAAAAAAAAAAABnAF3fAAAAAQAAAAtNZW1vIHN0cmluZwAAAAABAAAAAQAAAACBv/Oc5CHGxiLZ4Xc4ehTB2jEB29pFIFnvyuLL6D0eQQAAAAAAAAAAUsm2Z5rxXqY9/Fj7HVJq+jDt0ybXZ1AauYQyPzHrCqsAAAAAO6oMQAAAAAAAAAAA");

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

  Transaction getTestTransaction() {
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    return TransactionBuilder(Account(accountId, BigInt.zero))
        .addOperation(setOp.build())
        .build();
  }

  test('test generate tx url', () {
    final transaction = getTestTransaction();
    String url =
        uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());
    assert(url.startsWith(
        "web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9O"));
  });

  test('test generate pay url', () {
    String url = uriScheme.generatePayOperationURI(accountId,
        amount: "123.21",
        assetCode: "ANA",
        assetIssuer:
            "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV");
    assert(
        "web+stellar:pay?destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV&amount=123.21&asset_code=ANA&asset_issuer=GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV" ==
            url);
  });

  test('test missing signature', () async {
    final transaction = getTestTransaction();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain);

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Missing parameter 'signature'");
  });

  test('test missing origin domain', () async {
    final transaction = getTestTransaction();
    String url =
        uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());

    final validationResult = await uriScheme.isValidSep7SignedUrl(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Missing parameter 'origin_domain'");
  });

  test('test generate signed tx url', () {
    final transaction = getTestTransaction();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain);
    url = uriScheme.addSignature(url, signerKeyPair);

    final parsedResult = uriScheme.tryParseSep7Url(url);
    assert(parsedResult != null);
    assert(parsedResult!.queryParameters
        .containsKey(URIScheme.signatureParameterName));
  });

  test('test signed transaction ok', () async {
    Transaction transaction = getTestTransaction();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain);
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

  test('test sign and submit transaction to stellar', () async {
    AccountResponse sourceAccount = await sdk.accounts.account(accountId);
    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain);
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

  test('test sign and submit transaction to callback', () async {
    final transaction = getTestTransaction();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain,
        callback: callbackUrl);
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

  test('test toml signature missing', () async {
    final transaction = getTestTransaction();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain);

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

  test('test toml signature invalid', () async {
    final transaction = getTestTransaction();
    String url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
        originDomain: originDomain);

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

  test('test sep7 url validation', () {
    var url =
        "https://soneso.com/tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9O";

    var validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "It must start with web+stellar:");

    url = "web+stellar:tx/pay?destination=$accountId";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Invalid number of path segments. Must only have one path segment");

    url = "web+stellar:203842";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Operation type 203842 is not supported");

    url = "web+stellar:tx?destination=$accountId";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Operation type tx must have a 'xdr' parameter");

    url = "web+stellar:tx?xdr=12345673773";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The provided 'xdr' parameter is not a valid transaction envelope");

    url = "web+stellar:pay?xdr=$txXdr";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'xdr' for operation type 'pay'");

    url = "web+stellar:pay?amount=20";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Operation type pay must have a 'destination' parameter");

    url = "web+stellar:pay?destination=12345673773";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The provided 'destination' parameter is not a valid Stellar address");

    url = "web+stellar:tx?xdr=$txXdr&destination=$accountId";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'destination' for operation type 'tx'");

    url = "web+stellar:tx?xdr=$txXdr&asset_code=USDC";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'asset_code' for operation type 'tx'");

    url = "web+stellar:tx?xdr=$txXdr&asset_issuer=$accountId";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'asset_issuer' for operation type 'tx'");

    url = "web+stellar:tx?xdr=$txXdr&memo=123";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'memo' for operation type 'tx'");

    url = "web+stellar:tx?xdr=$txXdr&memo_type=id";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'memo_type' for operation type 'tx'");

    url = "web+stellar:tx?xdr=$txXdr&pubkey=123434938";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The provided 'pubkey' parameter is not a valid Stellar public key");

    url = "web+stellar:pay?destination=$accountId&replace=123";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'replace' for operation type 'pay'");

    url =
        "web+stellar:pay?destination=$accountId&msg=lksjafhdalkjsfhkldjahsflkjhasfhasdkjfhasdlfkjhdlkfhjasdlkjhfdskljhflkdsajhfladskjhflasdkjhfklasdjhfadslkjhfdlksjhflasdkjhflsdakjhfkasdjlhfljkdshfkjdshaflkjdhsalfkhdskjflhsadlkjfhdlskjhfasdlkfhdlsakjfhdlkjfhlaskdjhfldsajhfsldjkahflkjsdahflksjafhdalkjsfhkldjahsflkjhasfhasdkjfhasdlfkjhdlkfhjasdlkjhfdskljhflkdsajhfladskjhflasdkjhfklasdjhfadslkjhfdlksjhflasdkjhflsdakjhfkasdjlhfljkdshfkjdshaflkjdhsalfkhdskjflhsadlkjfhdlskjhfasdlkfhdlsakjfhdlkjfhlaskdjhfldsajhfsldjkahflkjsdahf";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The 'msg' parameter should be no longer than 300 characters");

    url = "web+stellar:pay?destination=$accountId&origin_domain=911";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The 'origin_domain' parameter is not a fully qualified domain name");

    url = "web+stellar:pay?destination=$accountId&chain=911";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Unsupported parameter 'chain' for operation type 'pay'");

    url =
        "web+stellar:pay?destination=$accountId&asset_code=19281209831092830912830917409238904231493827139871239847234";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The provided 'asset_code' parameter is not a valid Stellar asset code");

    url =
        "web+stellar:pay?destination=$accountId&asset_issuer=19281209831092830912830917409238904231493827139871239847234";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "The provided 'asset_issuer' parameter is not a valid Stellar address");

    url =
        "web+stellar:pay?destination=$accountId&memo=abracadabra&memo_type=zulu";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason == "Unsupported 'memo_type' value 'zulu'");

    url =
        "web+stellar:pay?destination=$accountId&memo=abracadabra&memo_type=MEMO_ID";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Parameter 'memo' of type 'MEMO_ID' has an invalid value");

    url =
        "web+stellar:pay?destination=$accountId&memo=abracadabra&memo_type=MEMO_HASH";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Parameter 'memo' or type 'MEMO_HASH' must be base64 encoded");

    url =
        "web+stellar:pay?destination=$accountId&memo=YWxrc2RmajA5MzIxOTA0dWtkbm1sc2EgeDJlb2pmZGxzd2tkajg5YXMgd3PDtmRhc0pEQVNVOVVESiBBU0Rhc0RBc2R3cWVxdw%3D%3D&memo_type=MEMO_HASH";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Parameter 'memo' of type 'MEMO_HASH' has an invalid value");

    url =
        "web+stellar:pay?destination=$accountId&memo=abracadabra&memo_type=MEMO_RETURN";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Parameter 'memo' or type 'MEMO_RETURN' must be base64 encoded");

    url =
        "web+stellar:pay?destination=$accountId&memo=YWxrc2RmajA5MzIxOTA0dWtkbm1sc2EgeDJlb2pmZGxzd2tkajg5YXMgd3PDtmRhc0pEQVNVOVVESiBBU0Rhc0RBc2R3cWVxdw%3D%3D&memo_type=MEMO_RETURN";
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Parameter 'memo' of type 'MEMO_RETURN' has an invalid value");

    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
    setOp.setSourceAccount(accountId);
    setOp.setHomeDomain("www.soneso.com");
    Transaction transaction =
        TransactionBuilder(Account(accountId, BigInt.zero))
            .addOperation(setOp.build())
            .build();
    url =
        uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());
    for (var i = 0; i < 10; i++) {
      url = uriScheme.generateSignTransactionURI(
          transaction.toEnvelopeXdrBase64(),
          chain: url);
    }
    validationResult = uriScheme.isValidSep7Url(url);
    assert(!validationResult.result);
    assert(validationResult.reason ==
        "Chaining more then 7 nested levels is not allowed");

    url =
        'web+stellar:pay?destination=GCALNQQBXAPZ2WIRSDDBMSTAKCUH5SG6U76YBFLQLIXJTF7FE5AX7AOO&amount=120.1234567&memo=skdjfasf&memo_type=MEMO_TEXT&msg=pay%20me%20with%20lumens';
    validationResult = uriScheme.isValidSep7Url(url);
    assert(validationResult.result);

    url =
        'web+stellar:pay?destination=GCALNQQBXAPZ2WIRSDDBMSTAKCUH5SG6U76YBFLQLIXJTF7FE5AX7AOO&amount=120.123&asset_code=USD&asset_issuer=GCRCUE2C5TBNIPYHMEP7NK5RWTT2WBSZ75CMARH7GDOHDDCQH3XANFOB&memo=hasysda987fs&memo_type=MEMO_TEXT&callback=url%3Ahttps%3A%2F%2FsomeSigningService.com%2Fhasysda987fs%3Fasset%3DUSD';
    validationResult = uriScheme.isValidSep7Url(url);
    assert(validationResult.result);

    url =
        'web+stellar:pay?destination=GCALNQQBXAPZ2WIRSDDBMSTAKCUH5SG6U76YBFLQLIXJTF7FE5AX7AOO&amount=120.1234567&memo=skdjfasf&memo_type=MEMO_TEXT&msg=pay%20me%20with%20lumens&origin_domain=someDomain.com&signature=tbsLtlK%2FfouvRWk2UWFP47yHYeI1g1NEC%2FfEQvuXG6V8P%2BbeLxplYbOVtTk1g94Wp97cHZ3pVJy%2FtZNYobl3Cw%3D%3D';
    validationResult = uriScheme.isValidSep7Url(url);
    assert(validationResult.result);

    url =
        'web+stellar:tx?xdr=AAAAAP%2Byw%2BZEuNg533pUmwlYxfrq6%2FBoMJqiJ8vuQhf6rHWmAAAAZAB8NHAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAYAAAABSFVHAAAAAABAH0wIyY3BJBS2qHdRPAV80M8hF7NBpxRjXyjuT9kEbH%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FAAAAAAAAAAA%3D&callback=url%3Ahttps%3A%2F%2FsomeSigningService.com%2Fa8f7asdfkjha&pubkey=GAU2ZSYYEYO5S5ZQSMMUENJ2TANY4FPXYGGIMU6GMGKTNVDG5QYFW6JS&msg=order%20number%2024';
    validationResult = uriScheme.isValidSep7Url(url);
    assert(validationResult.result);

    url =
        'web+stellar:tx?xdr=AAAAAP%2Byw%2BZEuNg533pUmwlYxfrq6%2FBoMJqiJ8vuQhf6rHWmAAAAZAB8NHAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAYAAAABSFVHAAAAAABAH0wIyY3BJBS2qHdRPAV80M8hF7NBpxRjXyjuT9kEbH%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FAAAAAAAAAAA%3D&replace=sourceAccount%3AX%3BX%3Aaccount%20on%20which%20to%20create%20the%20trustline';
    validationResult = uriScheme.isValidSep7Url(url);
    assert(validationResult.result);
  });

  test('test replace param composing and parsing', () {
    final first = UriSchemeReplacement(
        'X', 'sourceAccount', 'account from where you want to pay fees');
    final second = UriSchemeReplacement('Y', 'operations[0].sourceAccount',
        'account that needs the trustline and which will receive the new tokens');
    final third = UriSchemeReplacement('Y', 'operations[1].destination',
        'account that needs the trustline and which will receive the new tokens');

    var replace =
        uriScheme.uriSchemeReplacementsToString([first, second, third]);
    var expected =
        "sourceAccount:X,operations[0].sourceAccount:Y,operations[1].destination:Y;X:account from where you want to pay fees,Y:account that needs the trustline and which will receive the new tokens";
    assert(expected == replace);

    var url = "web+stellar:tx?xdr=$txXdr&replace=$replace";
    var validationResult = uriScheme.isValidSep7Url(url);
    assert(validationResult.result);

    var replacements = uriScheme.uriSchemeReplacementsFromString(replace);
    assert(replacements.length == 3);
    final firstParsed = replacements.first;
    assert(first.id == firstParsed.id);
    assert(first.path == firstParsed.path);
    assert(first.hint == firstParsed.hint);

    final secondParsed = replacements[1];
    assert(second.id == secondParsed.id);
    assert(second.path == secondParsed.path);
    assert(second.hint == secondParsed.hint);

    final thirdParsed = replacements[2];
    assert(third.id == thirdParsed.id);
    assert(third.path == thirdParsed.path);
    assert(third.hint == thirdParsed.hint);
  });
}
