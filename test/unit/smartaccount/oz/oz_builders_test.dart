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

ParsedContextRule _ruleWith(
  int id,
  List<OZSmartAccountSigner> signers, {
  String name = 'rule',
  ContextRuleType? contextType,
}) {
  return ParsedContextRule(
    id: id,
    contextType: contextType ?? const ContextRuleTypeDefault(),
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
      expect(result, isA<ContextRuleTypeDefault>());
    });
  });

  group('createCallContractContext', () {
    test('testCreateCallContractContext_validAddress', () {
      final result = OZBuilders.createCallContractContext(_kValidContractId);
      expect(result, isA<ContextRuleTypeCallContract>());
      expect((result as ContextRuleTypeCallContract).contractAddress,
          _kValidContractId);
    });

    test('testCreateCallContractContext_invalidAddress_throws', () {
      expect(
        () => OZBuilders.createCallContractContext('GABC...'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('testCreateCallContractContext_emptyAddress_throws', () {
      expect(
        () => OZBuilders.createCallContractContext(''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('createCreateContractContext (hex)', () {
    test('testCreateCreateContractContext_validHex', () {
      final hex = 'a' * 64;
      final result = OZBuilders.createCreateContractContextFromHex(hex);
      expect(result, isA<ContextRuleTypeCreateContract>());
      expect((result as ContextRuleTypeCreateContract).wasmHash.length, 32);
    });

    test('testCreateCreateContractContext_validHexWith0xPrefix', () {
      final hex = '0x${'b' * 64}';
      final result = OZBuilders.createCreateContractContextFromHex(hex);
      expect(result, isA<ContextRuleTypeCreateContract>());
      expect((result as ContextRuleTypeCreateContract).wasmHash.length, 32);
    });

    test('testCreateCreateContractContext_shortHex_throws', () {
      expect(
        () => OZBuilders.createCreateContractContextFromHex('abc123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('testCreateCreateContractContext_longHex_throws', () {
      expect(
        () => OZBuilders.createCreateContractContextFromHex('a' * 66),
        throwsA(isA<ValidationException>()),
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
      expect(result, isA<ContextRuleTypeCreateContract>());
      final hash = (result as ContextRuleTypeCreateContract).wasmHash;
      expect(hash.length, 32);
      for (var i = 0; i < 32; i++) {
        expect(hash[i], i);
      }
    });

    test('testCreateCreateContractContext_wrongSizeBytes_throws', () {
      expect(
        () => OZBuilders.createCreateContractContextFromBytes(Uint8List(16)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('collectUniqueSignersFromRules', () {
    test('testCollectUniqueSignersFromRules_emptyRules', () {
      final result = OZBuilders.collectUniqueSignersFromRules(
          const <ParsedContextRule>[]);
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
        contextType: ContextRuleTypeCallContract(_kValidContractId),
      );
      final ruleC = _ruleWith(
        3,
        [_delegatedSigner(addressA), signerD],
        name: 'C',
        contextType: ContextRuleTypeCallContract(_kValidContractIdAlt),
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
}
