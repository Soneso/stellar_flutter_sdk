// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_auth_digest_fixtures.dart';
import 'oz_pipeline_fixtures.dart';
import 'oz_signing_harness.dart';

// The CreateContractExternalRef context rule kind of stellar-accounts 0.8:
// its on-chain encoding, parsing, the builder, the extraction from both
// create-contract invocation arms and rule matching.

const String _owner =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _otherOwner =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _account =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

/// One address of each kind an `ScAddress` carries.
const List<String> _ownersOfEveryKind = <String>[
  _account,
  _owner,
  'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK',
  'BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU',
  'LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN',
  'WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC',
];

OZContextRuleManager _manager() => OZContextRuleManager(FakePipelineKit());

XdrSCVal _ruleScVal(int id, XdrSCVal contextType) {
  XdrSCMapEntry field(String key, XdrSCVal value) =>
      XdrSCMapEntry(XdrSCVal.forSymbol(key), value);
  return XdrSCVal.forMap(<XdrSCMapEntry>[
    field('context_type', contextType),
    field('id', XdrSCVal.forU32(id)),
    field('name', XdrSCVal.forString('rule $id')),
    field('policies', XdrSCVal.forVec(<XdrSCVal>[])),
    field('policy_ids', XdrSCVal.forVec(<XdrSCVal>[])),
    field('signer_ids', XdrSCVal.forVec(<XdrSCVal>[])),
    field('signers', XdrSCVal.forVec(<XdrSCVal>[])),
    field('valid_until', XdrSCVal.forVoid()),
  ]);
}

XdrSCVal _externalRefScVal(String owner, String tag) =>
    XdrSCVal.forVec(<XdrSCVal>[
      XdrSCVal.forSymbol('CreateContractExternalRef'),
      XdrSCVal.forAddressStrKey(owner),
      XdrSCVal.forString(tag),
    ]);

XdrContractExecutable _externalRef(String owner, String tag) =>
    XdrContractExecutable.forExternalRef(
      XdrSCVal.forAddressStrKey(owner).address!,
      tag,
    );

XdrContractIDPreimage _idPreimage() =>
    XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
      )
      ..address = XdrSCAddress.forContractId(_otherOwner)
      ..salt = XdrUint256(Uint8List(32));

XdrSorobanAuthorizedFunction _createV1(XdrContractExecutable executable) =>
    XdrSorobanAuthorizedFunction.forCreateContractArgs(
      XdrCreateContractArgs(_idPreimage(), executable),
    );

XdrSorobanAuthorizedFunction _createV2(XdrContractExecutable executable) =>
    XdrSorobanAuthorizedFunction.forCreateContractArgsV2(
      XdrCreateContractArgsV2(_idPreimage(), executable, <XdrSCVal>[
        XdrSCVal.forU32(1),
      ]),
    );

XdrSorobanAuthorizationEntry _entry(
  XdrSorobanAuthorizedFunction function, [
  List<XdrSorobanAuthorizedInvocation> subInvocations =
      const <XdrSorobanAuthorizedInvocation>[],
]) => XdrSorobanAuthorizationEntry(
  XdrSorobanCredentials.forSourceAccount(),
  XdrSorobanAuthorizedInvocation(function, subInvocations),
);

OZParsedContextRule _rule(int id, OZContextRuleType type) =>
    OZParsedContextRule(
      id: id,
      contextType: type,
      name: 'rule $id',
      signers: const <OZSmartAccountSigner>[],
      signerIds: const <int>[],
      policies: const <String>[],
      policyIds: const <int>[],
    );

List<int> _resolve(
  XdrSorobanAuthorizationEntry entry,
  List<OZParsedContextRule> rules,
) => _manager().resolveContextRuleIdsForEntryWithRules(
  entry,
  const <OZSmartAccountSigner>[],
  rules,
);

Matcher _invalidInput(String message) => throwsA(
  isA<SmartAccountInvalidInput>().having((e) => e.message, 'message', message),
);

void main() {
  group('encoding and parsing', () {
    test('toScVal encodes the symbol, the owner and the tag', () {
      expect(
        const OZContextRuleTypeCreateContractExternalRef(
          _owner,
          'account-v1',
        ).toScVal().toBase64EncodedXdrString(),
        _externalRefScVal(_owner, 'account-v1').toBase64EncodedXdrString(),
      );
    });

    test('toScVal refuses an owner that is no address, naming it', () {
      expect(
        () => const OZContextRuleTypeCreateContractExternalRef(
          'not-an-address',
          'tag',
        ).toScVal(),
        throwsA(
          isA<SmartAccountInvalidAddress>().having(
            (e) => e.message,
            'message',
            'Invalid address: not-an-address',
          ),
        ),
      );
    });

    test('the owner of every address kind round-trips', () {
      for (final owner in _ownersOfEveryKind) {
        final type = OZContextRuleTypeCreateContractExternalRef(
          owner,
          'account-v1',
        );
        final parsed = _manager().parseContextRule(
          _ruleScVal(3, type.toScVal()),
        );
        expect(parsed.id, 3);
        expect(parsed.contextType, type, reason: owner);
      }
    });

    test('a rule without its tag is refused, naming the element count', () {
      final truncated = XdrSCVal.forVec(<XdrSCVal>[
        XdrSCVal.forSymbol('CreateContractExternalRef'),
        XdrSCVal.forContractAddress(_owner),
      ]);
      expect(
        () => _manager().parseContextRule(_ruleScVal(1, truncated)),
        _invalidInput(
          'Invalid input for context_type: CreateContractExternalRef '
          'context_type needs an owner and a tag element, got 1 element(s)',
        ),
      );
    });

    test('an owner that is no Address is refused', () {
      final malformed = XdrSCVal.forVec(<XdrSCVal>[
        XdrSCVal.forSymbol('CreateContractExternalRef'),
        XdrSCVal.forString(_owner),
        XdrSCVal.forString('tag'),
      ]);
      expect(
        () => _manager().parseContextRule(_ruleScVal(1, malformed)),
        _invalidInput(
          'Invalid input for context_type: Expected Address for '
          'CreateContractExternalRef owner',
        ),
      );
    });

    test('a tag that is no String is refused', () {
      final malformed = XdrSCVal.forVec(<XdrSCVal>[
        XdrSCVal.forSymbol('CreateContractExternalRef'),
        XdrSCVal.forContractAddress(_owner),
        XdrSCVal.forU32(1),
      ]);
      expect(
        () => _manager().parseContextRule(_ruleScVal(1, malformed)),
        _invalidInput(
          'Invalid input for context_type: Expected String for '
          'CreateContractExternalRef tag',
        ),
      );
    });

    test('an unknown discriminant is still refused', () {
      final unknown = XdrSCVal.forVec(<XdrSCVal>[
        XdrSCVal.forSymbol('CreateContractFromRegistry'),
        XdrSCVal.forString('x'),
      ]);
      expect(
        () => _manager().parseContextRule(_ruleScVal(1, unknown)),
        _invalidInput(
          'Invalid input for context_type: Unknown context_type '
          'discriminant: CreateContractFromRegistry',
        ),
      );
    });
  });

  group('builder and equality', () {
    test('a contract owner builds the rule type', () {
      expect(
        OZBuilders.createCreateContractExternalRefContextType(
          _owner,
          'account-v1',
        ),
        const OZContextRuleTypeCreateContractExternalRef(_owner, 'account-v1'),
      );
    });

    test('an account owner is refused, naming it', () {
      expect(
        () => OZBuilders.createCreateContractExternalRefContextType(
          _account,
          'account-v1',
        ),
        throwsA(
          isA<SmartAccountInvalidAddress>().having(
            (e) => e.message,
            'message',
            'owner must be a valid contract address (C...), got: $_account',
          ),
        ),
      );
    });

    test('owner and tag both count', () {
      const type = OZContextRuleTypeCreateContractExternalRef(_owner, 'a');
      expect(
        type,
        const OZContextRuleTypeCreateContractExternalRef(_owner, 'a'),
      );
      expect(
        type.hashCode,
        const OZContextRuleTypeCreateContractExternalRef(_owner, 'a').hashCode,
      );
      expect(
        type,
        isNot(
          const OZContextRuleTypeCreateContractExternalRef(_otherOwner, 'a'),
        ),
      );
      expect(
        type,
        isNot(const OZContextRuleTypeCreateContractExternalRef(_owner, 'b')),
      );
      expect(type, isNot(const OZContextRuleTypeDefault()));
      expect(type, isNot(const OZContextRuleTypeCallContract(_owner)));
    });
  });

  group('extraction and matching', () {
    test('a V1 create from a reference matches the equal rule', () {
      final rules = <OZParsedContextRule>[
        _rule(
          1,
          const OZContextRuleTypeCreateContractExternalRef(
            _otherOwner,
            'account-v1',
          ),
        ),
        _rule(
          2,
          const OZContextRuleTypeCreateContractExternalRef(
            _owner,
            'account-v2',
          ),
        ),
        _rule(
          3,
          const OZContextRuleTypeCreateContractExternalRef(
            _owner,
            'account-v1',
          ),
        ),
      ];
      expect(
        _resolve(_entry(_createV1(_externalRef(_owner, 'account-v1'))), rules),
        <int>[3],
      );
    });

    test('a V2 create from a reference matches the equal rule', () {
      final rules = <OZParsedContextRule>[
        _rule(
          4,
          const OZContextRuleTypeCreateContractExternalRef(
            _owner,
            'account-v1',
          ),
        ),
        _rule(5, const OZContextRuleTypeCallContract(_owner)),
      ];
      expect(
        _resolve(_entry(_createV2(_externalRef(_owner, 'account-v1'))), rules),
        <int>[4],
      );
    });

    test('a reference in a sub-invocation is extracted', () {
      final call = XdrSorobanAuthorizedFunction.forInvokeContractArgs(
        XdrInvokeContractArgs(
          XdrSCAddress.forContractId(_owner),
          'deploy',
          const <XdrSCVal>[],
        ),
      );
      final rules = <OZParsedContextRule>[
        _rule(6, const OZContextRuleTypeCallContract(_owner)),
        _rule(
          7,
          const OZContextRuleTypeCreateContractExternalRef(
            _owner,
            'account-v1',
          ),
        ),
      ];
      final entry = _entry(call, <XdrSorobanAuthorizedInvocation>[
        XdrSorobanAuthorizedInvocation(
          _createV2(_externalRef(_owner, 'account-v1')),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      ]);
      expect(_resolve(entry, rules), <int>[6, 7]);
    });

    test('the owner of every address kind is kept and matched', () {
      for (final owner in _ownersOfEveryKind) {
        final rules = <OZParsedContextRule>[
          _rule(
            8,
            OZContextRuleTypeCreateContractExternalRef(owner, 'account-v1'),
          ),
        ];
        expect(
          _resolve(_entry(_createV1(_externalRef(owner, 'account-v1'))), rules),
          <int>[8],
          reason: owner,
        );
      }
    });

    test('an other owner or tag alone matches no rule', () {
      final rules = <OZParsedContextRule>[
        _rule(
          1,
          const OZContextRuleTypeCreateContractExternalRef(
            _otherOwner,
            'account-v1',
          ),
        ),
        _rule(
          2,
          const OZContextRuleTypeCreateContractExternalRef(
            _owner,
            'account-v2',
          ),
        ),
        _rule(3, OZContextRuleTypeCreateContract(Uint8List(32))),
      ];
      expect(
        () => _resolve(
          _entry(_createV1(_externalRef(_owner, 'account-v1'))),
          rules,
        ),
        throwsA(
          isA<SmartAccountInvalidInput>().having(
            (e) => e.message,
            'message',
            startsWith(
              'Invalid input for contextRuleIds: No context rule '
              'matches',
            ),
          ),
        ),
      );
    });

    test('with only a Default rule the Default rule is used', () {
      expect(
        _resolve(
          _entry(_createV1(_externalRef(_owner, 'account-v1'))),
          <OZParsedContextRule>[_rule(9, const OZContextRuleTypeDefault())],
        ),
        <int>[9],
      );
    });

    test('a create from a WASM hash does not match a reference rule', () {
      final hash = Uint8List.fromList(List<int>.filled(32, 7));
      final rules = <OZParsedContextRule>[
        _rule(
          1,
          const OZContextRuleTypeCreateContractExternalRef(
            _owner,
            'account-v1',
          ),
        ),
        _rule(2, OZContextRuleTypeCreateContract(hash)),
      ];
      expect(
        _resolve(_entry(_createV1(XdrContractExecutable.forWasm(hash))), rules),
        <int>[2],
      );
    });

    test('a create of a Stellar Asset Contract is still refused', () {
      expect(
        () => _resolve(
          _entry(_createV1(XdrContractExecutable.forAsset())),
          <OZParsedContextRule>[_rule(1, const OZContextRuleTypeDefault())],
        ),
        _invalidInput(
          'Invalid input for executable: CreateContract invocation '
          'references a Stellar Asset Contract, not a WASM contract',
        ),
      );
    });

    test('a reference executable without its reference is refused', () {
      final executable = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_EXTERNAL_REF,
      );
      expect(
        () => _resolve(_entry(_createV1(executable)), <OZParsedContextRule>[
          _rule(1, const OZContextRuleTypeDefault()),
        ]),
        _invalidInput(
          'Invalid input for executable: External reference contract '
          'executable is missing its reference',
        ),
      );
    });
  });

  test('a wallet holding a reference rule lists it and signs with the rule '
      'its call matches', () async {
    final entry = harnessEntry();
    final run = await runSingleSignerSubmit(
      <XdrSorobanAuthorizationEntry>[entry],
      harnessInstanceRead(v080Executable()),
      onChainRules: <XdrSCVal>[
        _ruleScVal(0, _externalRefScVal(_owner, 'account-v1')),
        _ruleScVal(1, const OZContextRuleTypeDefault().toScVal()),
      ],
    );

    expect(run.error, isNull);
    expect(run.result!.success, isTrue);
    expect(run.challenges, <Uint8List>[
      IndependentAuthDigest.preimageDigest(
        harnessWallet,
        await harnessPayload(entry),
        <int>[1],
      ),
    ], reason: 'The call matches the Default rule 1, not the reference rule 0');
  });
}
