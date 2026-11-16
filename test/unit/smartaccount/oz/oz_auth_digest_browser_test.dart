// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_auth_digest_fixtures.dart';

// The digest assertions that run on the VM and in the browser, where an int
// is a JavaScript number: both schemes for ADDRESS and ADDRESS_V2
// credentials, a nonce above 2^53 built as a BigInt, and the u32 bounds of
// the signature expiration and the rule ids.

Future<void> _expectDigests(
  XdrSorobanAuthorizationEntry entry,
  AuthDigestVector expected,
) async {
  final preimage = await OZSmartAccountAuth.computeEntryAuthDigest(
    entry,
    expected.expirationLedger,
    vectorNetworkPassphrase,
    expected.contextRuleIds,
    OZAuthDigestScheme.preimageV1,
  );
  expect(
    Util.bytesToHex(preimage.signaturePayload),
    expected.signaturePayloadHex,
  );
  expect(Util.bytesToHex(preimage.authDigest), expected.preimageV1DigestHex);
  expect(preimage.delegatedAuthArgs.map(scValXdrBase64).toList(), <String>[
    expected.preimageV1ArgsXdrBase64,
  ], reason: 'The delegated __check_auth argument is the preimage');

  final legacy = await OZSmartAccountAuth.computeEntryAuthDigest(
    entry,
    expected.expirationLedger,
    vectorNetworkPassphrase,
    expected.contextRuleIds,
    OZAuthDigestScheme.legacyConcat,
  );
  expect(
    Util.bytesToHex(legacy.signaturePayload),
    expected.signaturePayloadHex,
  );
  expect(Util.bytesToHex(legacy.authDigest), expected.legacyDigestHex);
  expect(
    legacy.delegatedAuthArgs.map(scValXdrBase64).toList(),
    <String>[expected.legacyArgsXdrBase64],
    reason: 'The legacy delegated __check_auth argument is Bytes(auth_digest)',
  );
}

void main() {
  group('computeEntryAuthDigest', () {
    test('fixture entry: both schemes match the fixture values', () async {
      await _expectDigests(fixtureEntryVector.entry(), fixtureEntryVector);
    });

    test(
      'expiration 0 and no rule ids, the lower u32 ends, are encoded',
      () async {
        await _expectDigests(lowerBoundVector.entry(), lowerBoundVector);
      },
    );

    for (final vector in bigNonceVectors) {
      test('${vector.expected.name}: both schemes match the values computed '
          'outside the SDK', () async {
        final entry = vectorFromFixtureEntry(
          vector.arm,
          BigInt.parse(vector.nonce),
        );
        expect(
          entry.toBase64EncodedXdrString(),
          vector.expected.entryXdrBase64,
          reason: 'The BigInt nonce encodes as the int64 ${vector.nonce}',
        );
        await _expectDigests(entry, vector.expected);
      });
    }

    for (final value in <int>[-1, 4294967296]) {
      test('expiration ledger $value is refused', () async {
        for (final scheme in OZAuthDigestScheme.values) {
          await expectLater(
            OZSmartAccountAuth.computeEntryAuthDigest(
              fixtureEntryVector.entry(),
              value,
              vectorNetworkPassphrase,
              fixtureEntryVector.contextRuleIds,
              scheme,
            ),
            throwsA(
              isA<SmartAccountInvalidInput>().having(
                (e) => e.message,
                'message',
                'Invalid input for expirationLedger: must be a u32 value '
                    '(0 to 4294967295), got: $value',
              ),
            ),
          );
        }
      });

      test('context rule id $value is refused', () async {
        for (final scheme in OZAuthDigestScheme.values) {
          await expectLater(
            OZSmartAccountAuth.computeEntryAuthDigest(
              fixtureEntryVector.entry(),
              fixtureEntryVector.expirationLedger,
              vectorNetworkPassphrase,
              <int>[0, value],
              scheme,
            ),
            throwsA(
              isA<SmartAccountInvalidInput>().having(
                (e) => e.message,
                'message',
                'Invalid input for contextRuleIds: must be a u32 value '
                    '(0 to 4294967295), got: $value',
              ),
            ),
          );
        }
      });
    }
  });
}
