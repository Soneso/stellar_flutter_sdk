@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('resolve stellar address', () async {
    FederationResponse response = await Federation.resolveStellarAddress("bob*soneso.com");
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId == "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });

  // unfortunately this are not supported by stellarid.io.
  // but one can test by debugging and checking the federation request url.

  test('resolve stellar account id', () async {
    FederationResponse response = await Federation.resolveStellarAccountId(
        "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI",
        "https://stellarid.io/federation/");
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId == "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });

  /// TODO : fix later, server code 400
  /// ! Body: {"error": "Request type 'txid' not supported."}
  test('resolve transaction id', () async {
    FederationResponse response = await Federation.resolveStellarTransactionId(
        "ae05181b239bd4a64ba2fb8086901479a0bde86f8e912150e74241fe4f5f0948",
        "https://stellarid.io/federation/");
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId == "GDD7WGDAIYQBPGQ5WE3VWOXH42YPB5H2VZNMZ3OHE45VJNP4Q6Z4ZNSZ");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });

  /// TODO : fix later, server code 400
  /// ! Body: {"error": "Malformed query, parameters \"q\" and \"type\" are required."}
  test('resolve forward', () async {
    FederationResponse response = await Federation.resolveForward(
        {"forward_type": "bank_account", "swift": "BOPBPHMM", "acct": "2382376"},
        "https://stellarid.io/federation/");
    assert(response.stellarAddress == "bob*soneso.com");
    assert(response.accountId == "GDD7WGDAIYQBPGQ5WE3VWOXH42YPB5H2VZNMZ3OHE45VJNP4Q6Z4ZNSZ");
    assert(response.memoType == "text");
    assert(response.memo == "hello memo text");
  });
}
