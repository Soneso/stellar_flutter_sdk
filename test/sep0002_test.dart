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
  // test('resolve transaction id', () async {
  //   FederationResponse response = await Federation.resolveStellarTransactionId(
  //       "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a",
  //       "https://stellarid.io/federation/");
  //   assert(response.stellarAddress == "bob*soneso.com");
  //   assert(response.accountId == "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
  //   assert(response.memoType == "text");
  //   assert(response.memo == "hello memo text");
  // });

  /// TODO : fix later, server code 400
  // test('resolve forward', () async {
  //   FederationResponse response = await Federation.resolveForward(
  //       {"forward_type": "bank_account", "swift": "BOPBPHMM", "acct": "2382376"},
  //       "https://stellarid.io/federation/");
  //   assert(response.stellarAddress == "bob*soneso.com");
  //   assert(response.accountId == "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI");
  //   assert(response.memoType == "text");
  //   assert(response.memo == "hello memo text");
  // });
}
