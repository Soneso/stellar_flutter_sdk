@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  String successResponse() {
    return "{ \"stellar_address\": \"bob*soneso.com\", \"account_id\": \"GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI\",\"memo_type\": \"text\", \"memo\": \"hello memo text\"}";
  }

  test('resolve stellar address', () async {
    FederationResponse response =
        await Federation.resolveStellarAddress("bob*soneso.com");
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId ==
        "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });

  // unfortunately this are not supported by stellarid.io.
  // but one can test by debugging and checking the federation request url.

  test('resolve stellar account id', () async {
    FederationResponse response = await Federation.resolveStellarAccountId(
        "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI",
        "https://stellarid.io/federation");
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId ==
        "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });

  test('resolve transaction id', () async {
    final httpClient = MockClient((request) async {
      if (request.url.toString().startsWith("https://fedtest.io/federation") &&
          request.method == "GET") {
        if (request.url.queryParameters.keys.contains("type") &&
            request.url.queryParameters["type"] == "txid" &&
            request.url.queryParameters.keys.contains("q") &&
            request.url.queryParameters["q"] ==
                "ae05181b239bd4a64ba2fb8086901479a0bde86f8e912150e74241fe4f5f0948") {
          return http.Response(successResponse(), 200);
        }
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    FederationResponse response = await Federation.resolveStellarTransactionId(
        "ae05181b239bd4a64ba2fb8086901479a0bde86f8e912150e74241fe4f5f0948",
        "https://fedtest.io/federation",
        httpClient: httpClient);
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId ==
        "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });

  test('resolve forward', () async {
    final httpClient = MockClient((request) async {
      if (request.url.toString().startsWith("https://fedtest.io/federation") &&
          request.method == "GET") {
        if (request.url.queryParameters.keys.contains("type") &&
            request.url.queryParameters["type"] == "forward" &&
            request.url.queryParameters.keys.contains("forward_type") &&
            request.url.queryParameters["forward_type"] == "bank_account" &&
            request.url.queryParameters.keys.contains("swift") &&
            request.url.queryParameters["swift"] == "BOPBPHMM" &&
            request.url.queryParameters.keys.contains("acct") &&
            request.url.queryParameters["acct"] == "2382376") {
          return http.Response(successResponse(), 200);
        }
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    FederationResponse response = await Federation.resolveForward({
      "forward_type": "bank_account",
      "swift": "BOPBPHMM",
      "acct": "2382376"
    }, "https://fedtest.io/federation", httpClient: httpClient);
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId ==
        "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });
}
