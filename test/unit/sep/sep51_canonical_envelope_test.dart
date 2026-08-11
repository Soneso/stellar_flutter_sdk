import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// The worked `TransactionEnvelope` of SEP-0051 §Examples.
///
/// It is the specification's only end-to-end document, and it exercises the
/// whole rule set in one value: nested unions with and without arms, an integer
/// case, a hyper rendered as a string beside a 32-bit integer rendered as a
/// number, an account strkey, a contract strkey, empty arrays, an absent
/// optional, and hexadecimal opaque data.
///
/// It is asserted structurally in one direction and byte-for-byte in the other.
/// Structurally on the way out, because the specification prints the document
/// with whitespace this SDK does not emit, and reading it as a tree compares the
/// values rather than the layout. Byte-for-byte on the way back, because the
/// binary is the specification's own and any disagreement about a single field
/// changes it.
const String _specBase64 =
    'AAAAAgAAAADmmSZkwY3163TMouB2TY8MljqXw2IxVYTGyvDrR6YtAAAqmmQAABpuAAAAAQAA'
    'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAB'
    'AAAABgAAAAHXkotywnA8z+r365/0701QSlWouXn8m0UOoshCtNHOYQAAABQAAAABAAI9fQAA'
    'AAAAAAD4AAAAAAAqmgAAAAABR6YtAAAAAEArDtxbqUI+CsdkRmV0lFhVt0wyB7fyrmmkM6Fr'
    '35wpPcK8WKcXeKTl4BQ+akE14MZtpaea9LMdhXopaW3pJA0E';

/// The document exactly as SEP-0051 §Examples prints it.
const String _specJson = r'''
{
  "tx": {
    "tx": {
      "source_account": "GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA",
      "fee": 2792036,
      "seq_num": "29059748724737",
      "cond": "none",
      "memo": "none",
      "operations": [
        {
          "source_account": null,
          "body": {
            "invoke_host_function": {
              "host_function": {
                "create_contract": {
                  "contract_id_preimage": {
                    "asset": "native"
                  },
                  "executable": "stellar_asset"
                }
              },
              "auth": []
            }
          }
        }
      ],
      "ext": {
        "v1": {
          "ext": "v0",
          "resources": {
            "footprint": {
              "read_only": [],
              "read_write": [
                {
                  "contract_data": {
                    "contract": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
                    "key": "ledger_key_contract_instance",
                    "durability": "persistent"
                  }
                }
              ]
            },
            "instructions": 146813,
            "disk_read_bytes": 0,
            "write_bytes": 248
          },
          "resource_fee": "2791936"
        }
      }
    },
    "signatures": [
      {
        "hint": "47a62d00",
        "signature": "2b0edc5ba9423e0ac764466574945855b74c3207b7f2ae69a433a16bdf9c293dc2bc58a71778a4e5e0143e6a4135e0c66da5a79af4b31d857a29696de9240d04"
      }
    ]
  }
}
''';

/// The same document in the canonical compact form this SDK emits.
const String _canonicalJson =
    '{"tx":{"tx":{"source_account":'
    '"GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA",'
    '"fee":2792036,"seq_num":"29059748724737","cond":"none","memo":"none",'
    '"operations":[{"source_account":null,"body":{"invoke_host_function":'
    '{"host_function":{"create_contract":{"contract_id_preimage":'
    '{"asset":"native"},"executable":"stellar_asset"}},"auth":[]}}}],'
    '"ext":{"v1":{"ext":"v0","resources":{"footprint":{"read_only":[],'
    '"read_write":[{"contract_data":{"contract":'
    '"CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",'
    '"key":"ledger_key_contract_instance","durability":"persistent"}}]},'
    '"instructions":146813,"disk_read_bytes":0,"write_bytes":248},'
    '"resource_fee":"2791936"}}},"signatures":[{"hint":"47a62d00",'
    '"signature":"2b0edc5ba9423e0ac764466574945855b74c3207b7f2ae69a433a16bdf'
    '9c293dc2bc58a71778a4e5e0143e6a4135e0c66da5a79af4b31d857a29696de9240d04"'
    '}]}}';

void main() {
  group('the SEP-0051 TransactionEnvelope example', () {
    test('renders the published binary as the published document', () {
      expect(
        XdrTransactionEnvelope.fromBase64EncodedXdrString(
          _specBase64,
        ).toXdrJsonValue(),
        jsonDecode(_specJson),
      );
    });

    test('reads the published document back to the published binary', () {
      expect(
        XdrTransactionEnvelope.fromXdrJson(
          _specJson,
        ).toBase64EncodedXdrString(),
        _specBase64,
      );
    });

    test('emits it in the canonical compact form', () {
      expect(
        XdrTransactionEnvelope.fromBase64EncodedXdrString(
          _specBase64,
        ).toXdrJson(),
        _canonicalJson,
      );
    });

    test('reads the canonical form back to the published binary', () {
      expect(
        XdrTransactionEnvelope.fromXdrJson(
          _canonicalJson,
        ).toBase64EncodedXdrString(),
        _specBase64,
      );
    });

    test(
      'reaches the same document through the whitespace it is printed with',
      () {
        // The published document carries indentation and line breaks; the
        // canonical one carries neither. Both describe the same envelope, and
        // this is what says so rather than assuming it.
        expect(
          XdrTransactionEnvelope.fromXdrJson(_specJson).toXdrJson(),
          XdrTransactionEnvelope.fromXdrJson(_canonicalJson).toXdrJson(),
        );
      },
    );

    test('names the outer union arm by the discriminant, not by the field', () {
      // The envelope is a union over EnvelopeType whose ENVELOPE_TYPE_TX arm is
      // declared `TransactionV1Envelope v1`. The key is the discriminant's own
      // name, so the two `tx` keys are the envelope arm and the transaction
      // inside it, and neither is `v1`.
      final Map<String, Object?> document =
          jsonDecode(_canonicalJson) as Map<String, Object?>;
      expect(document.keys.toList(), <String>['tx']);
      expect((document['tx']! as Map<String, Object?>).keys.toList(), <String>[
        'tx',
        'signatures',
      ]);
    });

    test('keeps the key order the .x declares the components in', () {
      final Map<String, Object?> transaction =
          ((jsonDecode(_canonicalJson) as Map<String, Object?>)['tx']!
                  as Map<String, Object?>)['tx']!
              as Map<String, Object?>;
      expect(transaction.keys.toList(), <String>[
        'source_account',
        'fee',
        'seq_num',
        'cond',
        'memo',
        'operations',
        'ext',
      ]);
    });
  });
}
