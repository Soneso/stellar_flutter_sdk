// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String _kValidContractId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _kValidContractIdAlt =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

OZDelegatedSigner _delegatedSigner(String address) {
  return OZDelegatedSigner(address);
}

OZParsedContextRule _ruleWith(
  int id,
  List<OZSmartAccountSigner> signers, {
  String name = 'rule',
  OZContextRuleType? contextType,
}) {
  return OZParsedContextRule(
    id: id,
    contextType: contextType ?? const OZContextRuleTypeDefault(),
    name: name,
    signers: signers,
    signerIds: List<int>.generate(signers.length, (i) => i),
    policies: const <String>[],
    policyIds: const <int>[],
  );
}

void main() {
  group('createDefaultContext', () {
    test('testCreateDefaultContext_returnsDefault', () {
      final result = OZBuilders.createDefaultContext();
      expect(result, isA<OZContextRuleTypeDefault>());
    });
  });

  group('createCallContractContext', () {
    test('testCreateCallContractContext_validAddress', () {
      final result = OZBuilders.createCallContractContext(_kValidContractId);
      expect(result, isA<OZContextRuleTypeCallContract>());
      expect((result as OZContextRuleTypeCallContract).contractAddress,
          _kValidContractId);
    });

    test('testCreateCallContractContext_invalidAddress_throws', () {
      expect(
        () => OZBuilders.createCallContractContext('GABC...'),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });

    test('testCreateCallContractContext_emptyAddress_throws', () {
      expect(
        () => OZBuilders.createCallContractContext(''),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });
  });

  group('createCreateContractContext (hex)', () {
    test('testCreateCreateContractContext_validHex', () {
      final hex = 'a' * 64;
      final result = OZBuilders.createCreateContractContextFromHex(hex);
      expect(result, isA<OZContextRuleTypeCreateContract>());
      expect((result as OZContextRuleTypeCreateContract).wasmHash.length, 32);
    });

    test('testCreateCreateContractContext_validHexWith0xPrefix', () {
      final hex = '0x${'b' * 64}';
      final result = OZBuilders.createCreateContractContextFromHex(hex);
      expect(result, isA<OZContextRuleTypeCreateContract>());
      expect((result as OZContextRuleTypeCreateContract).wasmHash.length, 32);
    });

    test('testCreateCreateContractContext_shortHex_throws', () {
      expect(
        () => OZBuilders.createCreateContractContextFromHex('abc123'),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });

    test('testCreateCreateContractContext_longHex_throws', () {
      expect(
        () => OZBuilders.createCreateContractContextFromHex('a' * 66),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });
  });

  group('createCreateContractContext (bytes)', () {
    test('testCreateCreateContractContext_validBytes', () {
      final bytes = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        bytes[i] = i;
      }
      final result = OZBuilders.createCreateContractContextFromBytes(bytes);
      expect(result, isA<OZContextRuleTypeCreateContract>());
      final hash = (result as OZContextRuleTypeCreateContract).wasmHash;
      expect(hash.length, 32);
      for (var i = 0; i < 32; i++) {
        expect(hash[i], i);
      }
    });

    test('testCreateCreateContractContext_wrongSizeBytes_throws', () {
      expect(
        () => OZBuilders.createCreateContractContextFromBytes(Uint8List(16)),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });
  });

  group('collectUniqueSignersFromRules', () {
    test('testCollectUniqueSignersFromRules_emptyRules', () {
      final result = OZBuilders.collectUniqueSignersFromRules(
          const <OZParsedContextRule>[]);
      expect(result, isEmpty);
    });

    test(
        'test_collectUniqueSignersFromRules_overlappingSignersDeduplicatedAcrossRules',
        () {
      final addressA = KeyPair.random().accountId;
      final addressB = KeyPair.random().accountId;
      final addressC = KeyPair.random().accountId;
      final addressD = KeyPair.random().accountId;

      final signerA = _delegatedSigner(addressA);
      final signerB = _delegatedSigner(addressB);
      final signerC = _delegatedSigner(addressC);
      final signerD = _delegatedSigner(addressD);

      final ruleA = _ruleWith(1, [signerA, signerB], name: 'A');
      final ruleB = _ruleWith(
        2,
        [_delegatedSigner(addressB), signerC],
        name: 'B',
        contextType: OZContextRuleTypeCallContract(_kValidContractId),
      );
      final ruleC = _ruleWith(
        3,
        [_delegatedSigner(addressA), signerD],
        name: 'C',
        contextType: OZContextRuleTypeCallContract(_kValidContractIdAlt),
      );

      final result =
          OZBuilders.collectUniqueSignersFromRules([ruleA, ruleB, ruleC]);

      expect(result, hasLength(4),
          reason: 'duplicate signers across rules must be collapsed');
      final keys = result.map((s) => s.uniqueKey).toList();
      expect(keys, contains('delegated:$addressA'));
      expect(keys, contains('delegated:$addressB'));
      expect(keys, contains('delegated:$addressC'));
      expect(keys, contains('delegated:$addressD'));
    });
  });

  group('OZContextRuleType equality', () {
    test('ContextRuleTypeDefault_equalityWithNonConstInstances', () {
      // Non-const to avoid identical() short-circuit, exercising line 76.
      final a = const OZContextRuleTypeDefault();
      final b = OZContextRuleTypeDefault();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ContextRuleTypeDefault_notEqualToOtherType', () {
      const a = OZContextRuleTypeDefault();
      const b = OZContextRuleTypeCallContract(_kValidContractId);
      expect(a == b, isFalse);
    });

    test('ContextRuleTypeCallContract_equalityWithNonConstInstances', () {
      final a = OZContextRuleTypeCallContract(_kValidContractId);
      final b = OZContextRuleTypeCallContract(_kValidContractId);
      final c = OZContextRuleTypeCallContract(_kValidContractIdAlt);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('ContextRuleTypeCreateContract_equalityWithNonConstInstances', () {
      final wasm = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final a = OZContextRuleTypeCreateContract(wasm);
      final b = OZContextRuleTypeCreateContract(Uint8List.fromList(List<int>.generate(32, (i) => i)));
      final c = OZContextRuleTypeCreateContract(Uint8List.fromList(List<int>.generate(32, (i) => i + 1)));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });
  });

  group('OZParsedContextRule equality', () {
    // These tests exercise OZParsedContextRule.operator== including the
    // _listEquals helper (lines 202-208 of oz_builders.dart).

    test('ParsedContextRule_differentSignerCount_notEqual', () {
      // Exercises _listEquals length mismatch (line 204).
      final signer = _delegatedSigner(_kValidContractIdAlt);
      final a = OZParsedContextRule(
        id: 1,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[signer],
        signerIds: const <int>[0],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      final b = OZParsedContextRule(
        id: 1,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: const <OZSmartAccountSigner>[],
        signerIds: const <int>[],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      expect(a == b, isFalse,
          reason: 'Different signer-list lengths must produce inequality');
    });

    test('ParsedContextRule_sameLengthDifferentContent_notEqual', () {
      // Exercises the per-element comparison in _listEquals (line 206).
      final s1 = _delegatedSigner(_kValidContractId);
      final s2 = _delegatedSigner(_kValidContractIdAlt);
      final a = OZParsedContextRule(
        id: 1,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[s1],
        signerIds: const <int>[0],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      final b = OZParsedContextRule(
        id: 1,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[s2],
        signerIds: const <int>[0],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      expect(a == b, isFalse,
          reason: 'Different signer instances must produce inequality');
    });

    test('ParsedContextRule_equal_instances', () {
      final s1 = _delegatedSigner(_kValidContractId);
      final s2 = _delegatedSigner(_kValidContractId);
      final a = OZParsedContextRule(
        id: 1,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[s1],
        signerIds: const <int>[0],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      final b = OZParsedContextRule(
        id: 1,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[s2],
        signerIds: const <int>[0],
        policies: const <String>[],
        policyIds: const <int>[],
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });
}
