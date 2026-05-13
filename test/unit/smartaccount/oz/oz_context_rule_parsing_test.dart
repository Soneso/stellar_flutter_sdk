// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const String _validContractAddress =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _validContractAddress2 =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _validAccountAddress =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

/// Generates a unique valid C-address by encoding a deterministic 32-byte
/// payload via the in-SDK [StrKey.encodeContractId] helper.
String _generateContractAddress(int seed) {
  final bytes = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    bytes[i] = (i + seed) & 0xFF;
  }
  return StrKey.encodeContractId(bytes);
}

/// Builds a fresh [FakePipelineKit] without a connected wallet; the context
/// rule manager parser tests do not require a connected state.
FakePipelineKit _buildKit() => FakePipelineKit();

/// Builds a fresh [FakePipelineKit] pre-connected so [addContextRule]
/// validation paths past [requireConnected] can be reached.
FakePipelineKit _buildConnectedKit() => FakePipelineKit()
  ..setConnected(
    credentialId: 'test-credential-id',
    contractId: _validContractAddress,
  );

OZContextRuleManager _manager(FakePipelineKit kit) => OZContextRuleManager(kit);

/// Builds an `XdrSCVal` Map from a list of (Symbol-key, value) entries,
/// matching the on-chain encoding shape produced by Soroban for named
/// structs.
XdrSCVal _buildMapScVal(List<MapEntry<String, XdrSCVal>> entries) {
  return XdrSCVal.forMap(<XdrSCMapEntry>[
    for (final e in entries)
      XdrSCMapEntry(XdrSCVal.forSymbol(e.key), e.value),
  ]);
}

/// Builds an Address-typed `XdrSCVal` from a contract C-address.
XdrSCVal _addressScVal(String contractAddress) {
  return XdrSCVal.forAddress(Address.forContractId(contractAddress).toXdr());
}

/// Builds the `Vec([Symbol("Delegated"), Address])` shape used to encode a
/// delegated signer on-chain.
XdrSCVal _delegatedSignerScVal(String address) {
  final XdrSCAddress scAddress = StrKey.isValidContractId(address)
      ? Address.forContractId(address).toXdr()
      : Address.forAccountId(address).toXdr();
  return XdrSCVal.forVec(<XdrSCVal>[
    XdrSCVal.forSymbol('Delegated'),
    XdrSCVal.forAddress(scAddress),
  ]);
}

/// Builds the `Vec([Symbol("External"), Address, Bytes])` shape used to
/// encode an external signer on-chain.
XdrSCVal _externalSignerScVal(String verifierAddress, Uint8List keyData) {
  return XdrSCVal.forVec(<XdrSCVal>[
    XdrSCVal.forSymbol('External'),
    XdrSCVal.forAddress(Address.forContractId(verifierAddress).toXdr()),
    XdrSCVal.forBytes(keyData),
  ]);
}

XdrSCVal _defaultContextTypeScVal() =>
    XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('Default')]);

XdrSCVal _callContractContextTypeScVal(String contractAddress) {
  return XdrSCVal.forVec(<XdrSCVal>[
    XdrSCVal.forSymbol('CallContract'),
    XdrSCVal.forAddress(Address.forContractId(contractAddress).toXdr()),
  ]);
}

XdrSCVal _createContractContextTypeScVal(Uint8List wasmHash) {
  return XdrSCVal.forVec(<XdrSCVal>[
    XdrSCVal.forSymbol('CreateContract'),
    XdrSCVal.forBytes(wasmHash),
  ]);
}

/// Builds a complete, valid context-rule Map `XdrSCVal` with all eight
/// fields populated.
XdrSCVal _buildFullRuleMap({
  int id = 1,
  String name = 'TestRule',
  XdrSCVal? contextType,
  List<XdrSCVal>? signers,
  List<int>? signerIds,
  List<XdrSCVal>? policies,
  List<int>? policyIds,
  XdrSCVal? validUntil,
}) {
  return _buildMapScVal(<MapEntry<String, XdrSCVal>>[
    MapEntry('id', XdrSCVal.forU32(id)),
    MapEntry('name', XdrSCVal.forString(name)),
    MapEntry('context_type', contextType ?? _defaultContextTypeScVal()),
    MapEntry('signers', XdrSCVal.forVec(signers ?? const <XdrSCVal>[])),
    MapEntry(
      'signer_ids',
      XdrSCVal.forVec(<XdrSCVal>[
        for (final id in signerIds ?? const <int>[]) XdrSCVal.forU32(id),
      ]),
    ),
    MapEntry('policies', XdrSCVal.forVec(policies ?? const <XdrSCVal>[])),
    MapEntry(
      'policy_ids',
      XdrSCVal.forVec(<XdrSCVal>[
        for (final id in policyIds ?? const <int>[]) XdrSCVal.forU32(id),
      ]),
    ),
    MapEntry('valid_until', validUntil ?? XdrSCVal.forVoid()),
  ]);
}

/// Returns a 65-byte uncompressed secp256r1-shaped public key suitable for
/// External signer fixtures. The byte content is deterministic.
Uint8List _secp256r1Key() {
  final key = Uint8List(65);
  key[0] = 0x04; // uncompressed prefix
  for (var i = 1; i < key.length; i++) {
    key[i] = i & 0xFF;
  }
  return key;
}

void main() {
  // ==========================================================================
  // parseContextRule — Valid rules
  // ==========================================================================

  group('parseContextRule valid rules', () {
    test('validRuleWithAllFields', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildFullRuleMap(
        id: 42,
        name: 'MyRule',
        contextType: _defaultContextTypeScVal(),
        signers: <XdrSCVal>[_delegatedSignerScVal(_validAccountAddress)],
        signerIds: <int>[10],
        policies: <XdrSCVal>[_addressScVal(_validContractAddress2)],
        policyIds: <int>[20],
        validUntil: XdrSCVal.forU32(999999),
      );

      final result = manager.parseContextRule(ruleMap);

      expect(result.id, 42);
      expect(result.name, 'MyRule');
      expect(result.contextType, isA<ContextRuleTypeDefault>());
      expect(result.signers.length, 1);
      expect(result.signers[0], isA<OZDelegatedSigner>());
      expect(
        (result.signers[0] as OZDelegatedSigner).address,
        _validAccountAddress,
      );
      expect(result.signerIds, <int>[10]);
      expect(result.policies.length, 1);
      expect(result.policyIds, <int>[20]);
      expect(result.validUntil, 999999);
    });

    test('defaultContextType', () {
      final manager = _manager(_buildKit());
      final result = manager.parseContextRule(
        _buildFullRuleMap(contextType: _defaultContextTypeScVal()),
      );
      expect(result.contextType, isA<ContextRuleTypeDefault>());
    });

    test('callContractContextType', () {
      final manager = _manager(_buildKit());
      final result = manager.parseContextRule(
        _buildFullRuleMap(
          contextType: _callContractContextTypeScVal(_validContractAddress2),
        ),
      );

      expect(result.contextType, isA<ContextRuleTypeCallContract>());
      expect(
        (result.contextType as ContextRuleTypeCallContract).contractAddress,
        _validContractAddress2,
      );
    });

    test('createContractContextType', () {
      final manager = _manager(_buildKit());
      final wasmHash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        wasmHash[i] = (i + 5) & 0xFF;
      }
      final result = manager.parseContextRule(
        _buildFullRuleMap(
          contextType: _createContractContextTypeScVal(wasmHash),
        ),
      );

      expect(result.contextType, isA<ContextRuleTypeCreateContract>());
      expect(
        (result.contextType as ContextRuleTypeCreateContract).wasmHash,
        orderedEquals(wasmHash),
      );
    });

    test('emptySignersAndPolicies', () {
      final manager = _manager(_buildKit());
      final result = manager.parseContextRule(
        _buildFullRuleMap(
          signers: const <XdrSCVal>[],
          signerIds: const <int>[],
          policies: const <XdrSCVal>[],
          policyIds: const <int>[],
        ),
      );

      expect(result.signers, isEmpty);
      expect(result.signerIds, isEmpty);
      expect(result.policies, isEmpty);
      expect(result.policyIds, isEmpty);
    });

    test('multipleSigners_delegatedAndExternal', () {
      final manager = _manager(_buildKit());
      final keyData = _secp256r1Key();
      final result = manager.parseContextRule(
        _buildFullRuleMap(
          signers: <XdrSCVal>[
            _delegatedSignerScVal(_validAccountAddress),
            _externalSignerScVal(_validContractAddress2, keyData),
          ],
          signerIds: <int>[1, 2],
        ),
      );

      expect(result.signers.length, 2);
      expect(result.signers[0], isA<OZDelegatedSigner>());
      expect(result.signers[1], isA<OZExternalSigner>());
      expect(
        (result.signers[0] as OZDelegatedSigner).address,
        _validAccountAddress,
      );
      expect(
        (result.signers[1] as OZExternalSigner).verifierAddress,
        _validContractAddress2,
      );
      expect(
        (result.signers[1] as OZExternalSigner).keyData,
        orderedEquals(keyData),
      );
    });

    test('validUntilVoid_noExpiration', () {
      final manager = _manager(_buildKit());
      final result = manager.parseContextRule(
        _buildFullRuleMap(validUntil: XdrSCVal.forVoid()),
      );
      expect(result.validUntil, isNull);
    });

    test('validUntilU32_hasExpiration', () {
      final manager = _manager(_buildKit());
      final result = manager.parseContextRule(
        _buildFullRuleMap(validUntil: XdrSCVal.forU32(12345678)),
      );
      expect(result.validUntil, 12345678);
    });

    test('validUntilFieldMissing_returnsNull', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('NoExpiry')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry('signers', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('signer_ids', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('policies', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('policy_ids', XdrSCVal.forVec(const <XdrSCVal>[])),
      ]);
      final result = manager.parseContextRule(ruleMap);
      expect(result.validUntil, isNull);
    });
  });

  // ==========================================================================
  // parseContextRule — Missing required fields
  // ==========================================================================

  group('parseContextRule missing required fields', () {
    test('missingId_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('name', XdrSCVal.forString('TestRule')),
        MapEntry('context_type', _defaultContextTypeScVal()),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('id'),
          isTrue,
          reason: "Exception message should mention 'id', got: ${e.message}",
        );
      }
    });

    test('missingName_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('context_type', _defaultContextTypeScVal()),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('name'),
          isTrue,
          reason:
              "Exception message should mention 'name', got: ${e.message}",
        );
      }
    });

    test('missingContextType_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('TestRule')),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('context_type'),
          isTrue,
          reason:
              "Exception message should mention 'context_type', "
              'got: ${e.message}',
        );
      }
    });
  });

  // ==========================================================================
  // parseContextRule — Invalid field types
  // ==========================================================================

  group('parseContextRule invalid field types', () {
    test('idNotU32_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forString('not-a-number')),
        MapEntry('name', XdrSCVal.forString('TestRule')),
        MapEntry('context_type', _defaultContextTypeScVal()),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('id'), isTrue);
      }
    });

    test('nameNotString_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forU32(42)),
        MapEntry('context_type', _defaultContextTypeScVal()),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('name'), isTrue);
      }
    });

    test('contextTypeNotVec_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('TestRule')),
        MapEntry('context_type', XdrSCVal.forString('Default')),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('context_type'), isTrue);
      }
    });

    test('signersNotVec_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('TestRule')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry('signers', XdrSCVal.forString('not-a-vec')),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('signers'), isTrue);
      }
    });

    test('signerIdsEntryNotU32_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('TestRule')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry(
          'signer_ids',
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forString('not-a-u32')]),
        ),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('signer_ids'), isTrue);
      }
    });

    test('validUntilInvalidType_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildFullRuleMap(
        validUntil: XdrSCVal.forString('not-a-u32'),
      );

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('valid_until'), isTrue);
      }
    });
  });

  // ==========================================================================
  // parseContextRule — Non-Map input
  // ==========================================================================

  group('parseContextRule non-Map input', () {
    test('nonMapInput_throwsValidationException', () {
      final manager = _manager(_buildKit());
      try {
        manager.parseContextRule(XdrSCVal.forVec(const <XdrSCVal>[]));
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('Map'),
          isTrue,
          reason: "Exception message should mention 'Map', got: ${e.message}",
        );
      }
    });

    test('voidInput_throwsValidationException', () {
      final manager = _manager(_buildKit());
      expect(
        () => manager.parseContextRule(XdrSCVal.forVoid()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('stringInput_throwsValidationException', () {
      final manager = _manager(_buildKit());
      expect(
        () => manager.parseContextRule(XdrSCVal.forString('not-a-map')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ==========================================================================
  // parseContextRule — Context-type edge cases
  // ==========================================================================

  group('parseContextRule context-type edge cases', () {
    test('emptyContextTypeVec_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap =
          _buildFullRuleMap(contextType: XdrSCVal.forVec(const <XdrSCVal>[]));

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('context_type'), isTrue);
      }
    });

    test('unknownContextTypeDiscriminant_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final unknown =
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('Unknown')]);
      final ruleMap = _buildFullRuleMap(contextType: unknown);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('Unknown'),
          isTrue,
          reason:
              'Exception message should contain the unknown discriminant, '
              'got: ${e.message}',
        );
      }
    });

    test('callContractMissingAddress_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final bad =
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('CallContract')]);
      final ruleMap = _buildFullRuleMap(contextType: bad);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('CallContract'), isTrue);
      }
    });

    test('createContractMissingHash_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final bad =
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('CreateContract')]);
      final ruleMap = _buildFullRuleMap(contextType: bad);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('CreateContract'), isTrue);
      }
    });
  });

  // ==========================================================================
  // parseContextRule — Signer parsing edge cases
  // ==========================================================================

  group('parseContextRule signer parsing edge cases', () {
    test('unknownSignerDiscriminant_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final unknown =
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('UnknownType')]);
      final ruleMap = _buildFullRuleMap(
        signers: <XdrSCVal>[unknown],
        signerIds: <int>[1],
      );

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('UnknownType'), isTrue);
      }
    });

    test('emptySignerVec_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final empty = XdrSCVal.forVec(const <XdrSCVal>[]);
      final ruleMap = _buildFullRuleMap(
        signers: <XdrSCVal>[empty],
        signerIds: <int>[1],
      );

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('signer'), isTrue);
      }
    });

    test('delegatedSignerMissingAddress_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final bad =
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('Delegated')]);
      final ruleMap = _buildFullRuleMap(
        signers: <XdrSCVal>[bad],
        signerIds: <int>[1],
      );

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('Delegated'), isTrue);
      }
    });

    test('externalSignerMissingKeyData_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final bad = XdrSCVal.forVec(<XdrSCVal>[
        XdrSCVal.forSymbol('External'),
        XdrSCVal.forAddress(Address.forContractId(_validContractAddress).toXdr()),
      ]);
      final ruleMap = _buildFullRuleMap(
        signers: <XdrSCVal>[bad],
        signerIds: <int>[1],
      );

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('External'), isTrue);
      }
    });
  });

  // ==========================================================================
  // ContextRuleType.toScVal
  // ==========================================================================

  group('ContextRuleType toScVal', () {
    test('defaultToScVal', () {
      final scVal = const ContextRuleTypeDefault().toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final elements = scVal.vec!;
      expect(elements.length, 1);
      expect(elements[0].sym, 'Default');
    });

    test('callContractToScVal', () {
      final scVal =
          const ContextRuleTypeCallContract(_validContractAddress2).toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final elements = scVal.vec!;
      expect(elements.length, 2);
      expect(elements[0].sym, 'CallContract');
      expect(elements[1].discriminant, XdrSCValType.SCV_ADDRESS);

      // Round-trip the address.
      final parsedAddress = Address.fromXdr(elements[1].address!);
      final hex = parsedAddress.contractId;
      expect(hex, isNotNull);
      final encoded = hex!.startsWith('C')
          ? hex
          : StrKey.encodeContractId(Util.hexToBytes(hex.toUpperCase()));
      expect(encoded, _validContractAddress2);
    });

    test('createContractToScVal', () {
      final wasmHash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        wasmHash[i] = (i * 3) & 0xFF;
      }
      final scVal = ContextRuleTypeCreateContract(wasmHash).toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final elements = scVal.vec!;
      expect(elements.length, 2);
      expect(elements[0].sym, 'CreateContract');
      expect(elements[1].discriminant, XdrSCValType.SCV_BYTES);
      expect(elements[1].bytes!.sCBytes, orderedEquals(wasmHash));
    });

    test('callContractInvalidAddress_throwsValidationException', () {
      expect(
        () =>
            const ContextRuleTypeCallContract('INVALID_ADDRESS').toScVal(),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ==========================================================================
  // ContextRuleType equality and hashCode
  // ==========================================================================

  group('ContextRuleType equality', () {
    test('defaultEquality', () {
      const a = ContextRuleTypeDefault();
      const b = ContextRuleTypeDefault();
      expect(a, b);
    });

    test('callContractEquality', () {
      const a = ContextRuleTypeCallContract(_validContractAddress);
      const b = ContextRuleTypeCallContract(_validContractAddress);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('createContractEquality', () {
      final hash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        hash[i] = i & 0xFF;
      }
      final a = ContextRuleTypeCreateContract(Uint8List.fromList(hash));
      final b = ContextRuleTypeCreateContract(Uint8List.fromList(hash));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  // ==========================================================================
  // ParsedContextRule data class
  // ==========================================================================

  group('ParsedContextRule data class', () {
    test('constructionAndFieldAccess', () {
      final signer = OZDelegatedSigner(_validAccountAddress);
      final rule = ParsedContextRule(
        id: 5,
        contextType: const ContextRuleTypeDefault(),
        name: 'TestRule',
        signers: <OZSmartAccountSigner>[signer],
        signerIds: const <int>[10],
        policies: <String>[_validContractAddress2],
        policyIds: const <int>[20],
        validUntil: 100,
      );

      expect(rule.id, 5);
      expect(rule.contextType, isA<ContextRuleTypeDefault>());
      expect(rule.name, 'TestRule');
      expect(rule.signers.length, 1);
      expect(rule.signerIds, <int>[10]);
      expect(rule.policies, <String>[_validContractAddress2]);
      expect(rule.policyIds, <int>[20]);
      expect(rule.validUntil, 100);
    });

    test('nullValidUntil', () {
      final rule = ParsedContextRule(
        id: 0,
        contextType: const ContextRuleTypeDefault(),
        name: 'NoExpiry',
        signers: const <OZSmartAccountSigner>[],
        signerIds: const <int>[],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      expect(rule.validUntil, isNull);
    });

    test('valueClassEquality', () {
      final a = ParsedContextRule(
        id: 1,
        contextType: const ContextRuleTypeDefault(),
        name: 'Rule',
        signers: const <OZSmartAccountSigner>[],
        signerIds: const <int>[],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      final b = ParsedContextRule(
        id: 1,
        contextType: const ContextRuleTypeDefault(),
        name: 'Rule',
        signers: const <OZSmartAccountSigner>[],
        signerIds: const <int>[],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  // ==========================================================================
  // addContextRule — Input validation (without network)
  // ==========================================================================

  group('addContextRule input validation', () {
    test('notConnected_throwsWalletNotConnected', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'Rule',
          signers: <OZSmartAccountSigner>[
            OZDelegatedSigner(_validAccountAddress),
          ],
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('emptyName_throwsValidationException', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: '',
          signers: <OZSmartAccountSigner>[
            OZDelegatedSigner(_validAccountAddress),
          ],
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('name'), isTrue);
      }
    });

    test('emptySignersAndPolicies_throwsValidationException', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'EmptyRule',
          signers: const <OZSmartAccountSigner>[],
          policies: const <String, XdrSCVal>{},
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('signer') || e.message.contains('policy'),
          isTrue,
          reason:
              'Exception message should mention signers or policies, '
              'got: ${e.message}',
        );
      }
    });

    test('tooManySigners_throwsValidationException', () async {
      final manager = _manager(_buildConnectedKit());
      // OZConstants.maxSigners is 15; passing 16 must reject.
      final signers = <OZSmartAccountSigner>[
        for (var i = 0; i < 16; i++) OZDelegatedSigner(_validAccountAddress),
      ];

      try {
        await manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'TooManySigners',
          signers: signers,
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('15') || e.message.contains('signers'),
          isTrue,
          reason: 'Exception message should mention signer limit, '
              'got: ${e.message}',
        );
      }
    });

    test('tooManyPolicies_throwsValidationException', () async {
      final manager = _manager(_buildConnectedKit());
      // OZConstants.maxPolicies is 5; supply 6 unique valid C-addresses.
      final policies = <String, XdrSCVal>{
        for (var i = 0; i < 6; i++)
          _generateContractAddress(i * 10): XdrSCVal.forVoid(),
      };
      expect(policies.length, 6,
          reason: 'Precondition: must have 6 unique policy addresses');

      try {
        await manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'TooManyPolicies',
          signers: <OZSmartAccountSigner>[
            OZDelegatedSigner(_validAccountAddress),
          ],
          policies: policies,
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.contains('5') || e.message.contains('policies'),
          isTrue,
          reason: 'Exception message should mention policy limit, '
              'got: ${e.message}',
        );
      }
    });

    test('invalidPolicyAddress_throwsValidationException', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'BadPolicy',
          signers: <OZSmartAccountSigner>[
            OZDelegatedSigner(_validAccountAddress),
          ],
          policies: <String, XdrSCVal>{
            'INVALID_ADDRESS': XdrSCVal.forVoid(),
          },
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(
          e.message.toLowerCase().contains('address'),
          isTrue,
          reason:
              'Exception message should mention address validation, '
              'got: ${e.message}',
        );
      }
    });

    test('gAddressAsPolicy_throwsValidationException', () async {
      final manager = _manager(_buildConnectedKit());
      // Policy addresses must be C-addresses (contracts), not G-addresses.
      try {
        await manager.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'GAddressPolicy',
          signers: <OZSmartAccountSigner>[
            OZDelegatedSigner(_validAccountAddress),
          ],
          policies: <String, XdrSCVal>{
            _validAccountAddress: XdrSCVal.forVoid(),
          },
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message, isNotEmpty);
      }
    });
  });

  // ==========================================================================
  // parseContextRule — Round-trip: toScVal then parse back
  // ==========================================================================

  group('parseContextRule round-trip', () {
    test('defaultContextType', () {
      final manager = _manager(_buildKit());
      final scVal = const ContextRuleTypeDefault().toScVal();
      final ruleMap = _buildFullRuleMap(contextType: scVal);
      final parsed = manager.parseContextRule(ruleMap);
      expect(parsed.contextType, isA<ContextRuleTypeDefault>());
    });

    test('callContractContextType', () {
      final manager = _manager(_buildKit());
      final scVal =
          const ContextRuleTypeCallContract(_validContractAddress2).toScVal();
      final ruleMap = _buildFullRuleMap(contextType: scVal);
      final parsed = manager.parseContextRule(ruleMap);
      expect(parsed.contextType, isA<ContextRuleTypeCallContract>());
      expect(
        (parsed.contextType as ContextRuleTypeCallContract).contractAddress,
        _validContractAddress2,
      );
    });

    test('createContractContextType', () {
      final manager = _manager(_buildKit());
      final wasmHash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        wasmHash[i] = (i * 7) & 0xFF;
      }
      final scVal = ContextRuleTypeCreateContract(wasmHash).toScVal();
      final ruleMap = _buildFullRuleMap(contextType: scVal);
      final parsed = manager.parseContextRule(ruleMap);
      expect(parsed.contextType, isA<ContextRuleTypeCreateContract>());
      expect(
        (parsed.contextType as ContextRuleTypeCreateContract).wasmHash,
        orderedEquals(wasmHash),
      );
    });
  });

  // ==========================================================================
  // parseContextRule — Multiple policies parsing
  // ==========================================================================

  group('parseContextRule multiple policies', () {
    test('multiplePolicies', () {
      final manager = _manager(_buildKit());
      final result = manager.parseContextRule(
        _buildFullRuleMap(
          policies: <XdrSCVal>[
            _addressScVal(_validContractAddress),
            _addressScVal(_validContractAddress2),
          ],
          policyIds: <int>[10, 20],
        ),
      );

      expect(result.policies.length, 2);
      expect(result.policyIds.length, 2);
      expect(result.policyIds[0], 10);
      expect(result.policyIds[1], 20);
    });
  });

  // ==========================================================================
  // parseContextRule — Fields looked up by key name, not position
  // ==========================================================================

  group('parseContextRule field-name lookup', () {
    test('fieldsInNonAlphabeticalOrder', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('valid_until', XdrSCVal.forVoid()),
        MapEntry('signers', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('signer_ids', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('policies', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('policy_ids', XdrSCVal.forVec(const <XdrSCVal>[])),
        MapEntry('name', XdrSCVal.forString('ReversedFields')),
        MapEntry('id', XdrSCVal.forU32(99)),
        MapEntry('context_type', _defaultContextTypeScVal()),
      ]);

      final result = manager.parseContextRule(ruleMap);
      expect(result.id, 99);
      expect(result.name, 'ReversedFields');
      expect(result.contextType, isA<ContextRuleTypeDefault>());
    });
  });

  // ==========================================================================
  // parseContextRule — Non-Symbol keys silently skipped
  // ==========================================================================

  group('parseContextRule non-symbol keys skipped', () {
    test('nonSymbolKeysIgnored', () {
      final manager = _manager(_buildKit());
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forU32(0), XdrSCVal.forString('ignored')),
        XdrSCMapEntry(XdrSCVal.forSymbol('id'), XdrSCVal.forU32(7)),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('name'),
          XdrSCVal.forString('WithExtra'),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_type'),
          _defaultContextTypeScVal(),
        ),
        XdrSCMapEntry(XdrSCVal.forBytes(Uint8List(4)), XdrSCVal.forVoid()),
      ];
      final ruleMap = XdrSCVal.forMap(entries);

      final result = manager.parseContextRule(ruleMap);
      expect(result.id, 7);
      expect(result.name, 'WithExtra');
    });
  });

  // ==========================================================================
  // parseContextRule — Policy parsing errors
  // ==========================================================================

  group('parseContextRule policy parsing errors', () {
    test('policiesEntryNotAddress_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('BadPolicies')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry(
          'policies',
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forString('not-an-address')]),
        ),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('policies'), isTrue);
      }
    });

    test('policyIdsNotVec_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('BadPolicyIds')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry('policy_ids', XdrSCVal.forString('not-a-vec')),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('policy_ids'), isTrue);
      }
    });

    test('policyIdsEntryNotU32_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('BadPolicyIdEntry')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry(
          'policy_ids',
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forString('not-a-u32')]),
        ),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('policy_ids'), isTrue);
      }
    });
  });

  // ==========================================================================
  // parseContextRule — Signer entry not a Vec
  // ==========================================================================

  group('parseContextRule signer not a Vec', () {
    test('signerEntryNotVec_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final ruleMap = _buildMapScVal(<MapEntry<String, XdrSCVal>>[
        MapEntry('id', XdrSCVal.forU32(1)),
        MapEntry('name', XdrSCVal.forString('BadSigner')),
        MapEntry('context_type', _defaultContextTypeScVal()),
        MapEntry(
          'signers',
          XdrSCVal.forVec(
            <XdrSCVal>[XdrSCVal.forString('not-a-signer-vec')],
          ),
        ),
      ]);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('signer'), isTrue);
      }
    });
  });

  // ==========================================================================
  // parseContextRule — Context-type discriminant not a Symbol
  // ==========================================================================

  group('parseContextRule discriminant not a Symbol', () {
    test('contextTypeDiscriminantNotSymbol_throwsValidationException', () {
      final manager = _manager(_buildKit());
      final bad = XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forU32(42)]);
      final ruleMap = _buildFullRuleMap(contextType: bad);

      try {
        manager.parseContextRule(ruleMap);
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('context_type'), isTrue);
      }
    });
  });

  // ==========================================================================
  // resolveContextRuleIdsForEntry — 3-tier algorithm
  //
  // The Flutter implementation exposes the 3-tier algorithm via the
  // synchronous `resolveContextRuleIdsForEntryWithRules(entry, signers,
  // rules)` accessor on the concrete `OZContextRuleManager` class. The
  // tests below construct synthetic CallContract auth entries paired with
  // pre-built `ParsedContextRule` lists to exercise each tier directly.
  //
  // - Tier 1: exact bidirectional signer-set match (per D-135).
  // - Tier 2: rule signers subset of selected, no policies (per D-136).
  // - Tier 3: selected signers subset of rule (threshold scenarios,
  //   per D-137).
  // - Empty-candidates throws with the "Add a Default rule" hint
  //   (per D-138).
  // - Ambiguous matches throw with the rule-id list (per D-138).
  // ==========================================================================

  /// Builds a synthetic auth entry whose root invocation is a contract call
  /// to [targetContract].`noop()`. Used to exercise the resolver against
  /// CallContract context-type rules.
  XdrSorobanAuthorizationEntry buildCallContractEntry({
    String targetContract = _validContractAddress2,
    String fn = 'noop',
  }) {
    final invokeArgs = XdrInvokeContractArgs(
      Address.forContractId(targetContract).toXdr(),
      fn,
      const <XdrSCVal>[],
    );
    final invocation = XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
      <XdrSorobanAuthorizedInvocation>[],
    );
    final addressCreds = XdrSorobanAddressCredentials(
      Address.forContractId(_validContractAddress).toXdr(),
      XdrInt64(BigInt.zero),
      XdrUint32(0),
      XdrSCVal.forVoid(),
    );
    return XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forAddressCredentials(addressCreds),
      invocation,
    );
  }

  ParsedContextRule buildRule({
    required int id,
    required ContextRuleType contextType,
    List<OZSmartAccountSigner> signers = const <OZSmartAccountSigner>[],
    List<String> policies = const <String>[],
    List<int> signerIds = const <int>[],
    List<int> policyIds = const <int>[],
  }) {
    return ParsedContextRule(
      id: id,
      contextType: contextType,
      name: 'rule-$id',
      signers: signers,
      signerIds: signerIds,
      policies: policies,
      policyIds: policyIds,
    );
  }

  group('resolveContextRuleIdsForEntry tier 1 (exact match)', () {
    test('singleSignerExactMatch_returnsRuleId', () {
      final manager = _manager(_buildKit());
      final signer = OZDelegatedSigner(_validAccountAddress);
      final rule = buildRule(
        id: 11,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[signer],
      );
      // Add a second matching candidate so single-candidate fast-path
      // is bypassed and Tier 1 is the resolver branch under test.
      final decoy = buildRule(
        id: 12,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[
          OZDelegatedSigner(
              'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS'),
        ],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[signer],
        <ParsedContextRule>[rule, decoy],
      );
      expect(ids, <int>[11]);
    });

    test('multiSignerExactMatch_returnsRuleId', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      final rule = buildRule(
        id: 21,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s2],
      );
      final decoy = buildRule(
        id: 22,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[s1, s2],
        <ParsedContextRule>[rule, decoy],
      );
      expect(ids, <int>[21]);
    });

    test('bidirectionalContainmentEnforced', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      // Rule has [s1, s2]; selected has [s1]. Sizes differ — Tier 1 must
      // not fire. With two candidates the resolver falls through to Tier 3.
      final rule1 = buildRule(
        id: 31,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s2],
      );
      final rule2 = buildRule(
        id: 32,
        contextType: const ContextRuleTypeDefault(),
        // Different signer set so subset and exact tiers do not pick it.
        signers: <OZSmartAccountSigner>[s2],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[s1],
        <ParsedContextRule>[rule1, rule2],
      );
      // Selected signer s1 only fits inside rule 31 (Tier 3).
      expect(ids, <int>[31]);
    });

    test('sizeMismatchSkipsTier1', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      // One rule per candidate so Tier 1 is the would-be branch but
      // sizes differ; Tier 2 (no policies) accepts the rule that contains
      // every selected signer.
      final rule = buildRule(
        id: 41,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s2],
      );
      final decoy = buildRule(
        id: 42,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[
          OZDelegatedSigner(
            'GADQQCIKBMGA2DQPCAIREEYUCULBOGAZDINRYHI6D4QCCIRDEQSSMYVS',
          ),
        ],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[s1],
        <ParsedContextRule>[rule, decoy],
      );
      expect(ids, <int>[41]);
    });
  });

  group('resolveContextRuleIdsForEntry tier 2 (subset, no policies)', () {
    test('ruleSignersSubsetSelected_noPolicies_matches', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      // Tier 2 rule: subset of selected, no policies.
      final tier2 = buildRule(
        id: 51,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1],
      );
      // Decoy: doesn't qualify for Tier 1 (size mismatch) and has policies.
      final decoy = buildRule(
        id: 52,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s2],
        policies: <String>[_validContractAddress2],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[s1, s2],
        <ParsedContextRule>[tier2, decoy],
      );
      expect(ids, <int>[51]);
    });

    test('ruleSignersSubsetSelected_withPolicies_skipsTier2', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      // Both candidates have policies; Tier 2 must skip them. Tier 3
      // (selected subset of rule) accepts only rule 62.
      final ruleA = buildRule(
        id: 61,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1],
        policies: <String>[_validContractAddress2],
      );
      final ruleB = buildRule(
        id: 62,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s2],
        policies: <String>[_validContractAddress2],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[s1],
        <ParsedContextRule>[ruleA, ruleB],
      );
      // Selected [s1] is subset of rule 62; rule 61 also contains s1 but
      // signers.length == selected.length so Tier 1 picks rule 61.
      expect(ids, <int>[61]);
    });
  });

  group('resolveContextRuleIdsForEntry tier 3 (selected subset of rule)', () {
    test('selectedSubsetOfRule_thresholdScenario_picksRule', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      final s3 = OZDelegatedSigner(
        'GADQQCIKBMGA2DQPCAIREEYUCULBOGAZDINRYHI6D4QCCIRDEQSSMYVS',
      );
      // 2-of-3 threshold scenario: rule has 3 signers, user picks 2.
      final rule = buildRule(
        id: 71,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s2, s3],
        policies: <String>[_validContractAddress2],
      );
      // Decoy candidate so single-candidate fast-path is bypassed.
      final decoy = buildRule(
        id: 72,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[
          OZDelegatedSigner(
            'GAHA6EARCIJRIFIWC4MBSGQ3DQOR4HZAEERCGJBFEYTSQKJKFMWC34NB',
          ),
        ],
      );
      final entry = buildCallContractEntry();
      final ids = manager.resolveContextRuleIdsForEntryWithRules(
        entry,
        <OZSmartAccountSigner>[s1, s2],
        <ParsedContextRule>[rule, decoy],
      );
      expect(ids, <int>[71]);
    });

    test('selectedSubsetOfMultipleRules_throwsAmbiguous', () {
      final manager = _manager(_buildKit());
      final s1 = OZDelegatedSigner(_validAccountAddress);
      final s2 = OZDelegatedSigner(
        'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
      );
      final s3 = OZDelegatedSigner(
        'GADQQCIKBMGA2DQPCAIREEYUCULBOGAZDINRYHI6D4QCCIRDEQSSMYVS',
      );
      // Two rules where selected [s1] is a subset of both.
      final ruleA = buildRule(
        id: 81,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s2],
        policies: <String>[_validContractAddress2],
      );
      final ruleB = buildRule(
        id: 82,
        contextType: const ContextRuleTypeDefault(),
        signers: <OZSmartAccountSigner>[s1, s3],
        policies: <String>[_validContractAddress2],
      );
      final entry = buildCallContractEntry();
      try {
        manager.resolveContextRuleIdsForEntryWithRules(
          entry,
          <OZSmartAccountSigner>[s1],
          <ParsedContextRule>[ruleA, ruleB],
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('multiple'), isTrue,
            reason: 'Should hint at ambiguity, got: ${e.message}');
        expect(e.message.contains('81'), isTrue);
        expect(e.message.contains('82'), isTrue);
      }
    });
  });

  group('resolveContextRuleIdsForEntry empty candidates', () {
    test('noMatchingRule_throwsWithDefaultRuleHint', () {
      final manager = _manager(_buildKit());
      // Provide a rule that does not match the CallContract context type
      // and is also not a Default rule, so candidates is empty.
      final unrelated = buildRule(
        id: 91,
        contextType: ContextRuleTypeCallContract(_validContractAddress),
        signers: <OZSmartAccountSigner>[
          OZDelegatedSigner(_validAccountAddress),
        ],
      );
      final unrelated2 = buildRule(
        id: 92,
        contextType: ContextRuleTypeCallContract(_validContractAddress),
        signers: <OZSmartAccountSigner>[
          OZDelegatedSigner(_validAccountAddress),
        ],
      );
      // Entry targets _validContractAddress2; neither rule matches.
      final entry = buildCallContractEntry(
        targetContract: _validContractAddress2,
      );
      try {
        manager.resolveContextRuleIdsForEntryWithRules(
          entry,
          <OZSmartAccountSigner>[
            OZDelegatedSigner(_validAccountAddress),
          ],
          <ParsedContextRule>[unrelated, unrelated2],
        );
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message.contains('Default'), isTrue,
            reason: 'Should mention Default-rule hint, got: ${e.message}');
      }
    });
  });
}
