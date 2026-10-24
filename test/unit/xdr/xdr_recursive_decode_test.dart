import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const _cap = 500;

Uint8List _payload(String kind, int depth) {
  final words = <int>[];
  if (kind == 'not') {
    for (var i = 1; i < depth; i++) {
      words.addAll([XdrClaimPredicateType.CLAIM_PREDICATE_NOT.value, 1]);
    }
    words.add(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL.value);
  } else {
    if (kind == 'map') {
      while (depth > 2) {
        words.addAll([
          XdrSCValType.SCV_MAP.value,
          1,
          1,
          XdrSCValType.SCV_VOID.value,
        ]); // Map, present, one entry, void key.
        depth -= 2; // SCVal and SCMapEntry each consume one guarded level.
      }
    }
    for (var i = 1; i < depth; i++) {
      words.addAll([XdrSCValType.SCV_VEC.value, 1, 1]);
    }
    words.addAll([XdrSCValType.SCV_VEC.value, 1, 0]); // Empty innermost vector.
  }
  final bytes = ByteData(words.length * 4);
  for (var i = 0; i < words.length; i++) {
    bytes.setInt32(i * 4, words[i]);
  }
  return bytes.buffer.asUint8List();
}

Object _decode(String kind, XdrDataInputStream stream) =>
    kind == 'not' ? XdrClaimPredicate.decode(stream) : XdrSCVal.decode(stream);

List<int> _delegateNode(int children, {int signatureDepth = 1}) {
  final out = XdrDataOutputStream();
  XdrSCAddress.encode(out, XdrSCAddress.forContractId('00' * 32));
  out.write(_payload('vec', signatureDepth));
  out.writeInt(children);
  return out.bytes;
}

Uint8List _delegateChain(int depth, {int signatureDepth = 1}) =>
    Uint8List.fromList([
      for (var i = 1; i < depth; i++) ..._delegateNode(1),
      ..._delegateNode(0, signatureDepth: signatureDepth),
    ]);

void _assertDelegateNode(
  XdrSorobanDelegateSignature node,
  int children, {
  int signatureDepth = 1,
}) {
  expect(node.address.discriminant, XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
  expect(node.address.contractId!.hash, Uint8List(32));
  _assertStructure('vec', node.signature, signatureDepth);
  expect(node.nestedDelegates, hasLength(children));
}

void _assertDelegateChain(
  XdrSorobanDelegateSignature node,
  int depth, {
  int signatureDepth = 1,
}) {
  for (var i = 1; i <= depth; i++) {
    _assertDelegateNode(
      node,
      i == depth ? 0 : 1,
      signatureDepth: i == depth ? signatureDepth : 1,
    );
    if (i < depth) node = node.nestedDelegates.single;
  }
}

void _assertStructure(String kind, Object value, int depth) {
  if (kind == 'not') {
    var predicate = value as XdrClaimPredicate;
    for (var i = 1; i < depth; i++) {
      expect(predicate.discriminant, XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
      predicate = predicate.notPredicate!;
    }
    expect(
      predicate.discriminant,
      XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL,
    );
    expect(predicate.notPredicate, isNull);
  } else {
    var val = value as XdrSCVal;
    if (kind == 'map') {
      while (depth > 2) {
        expect(val.discriminant, XdrSCValType.SCV_MAP);
        expect(val.map, hasLength(1));
        expect(val.map!.single.key.discriminant, XdrSCValType.SCV_VOID);
        val = val.map!.single.val;
        depth -= 2;
      }
    }
    for (var i = 1; i < depth; i++) {
      expect(val.discriminant, XdrSCValType.SCV_VEC);
      expect(val.vec, hasLength(1));
      val = val.vec!.single;
    }
    expect(val.discriminant, XdrSCValType.SCV_VEC);
    expect(val.vec, isEmpty);
  }
}

Matcher get _depthFailure => throwsA(
  isA<Exception>().having(
    (e) => e.toString(),
    'message',
    contains('XDR decode depth limit exceeded ($_cap)'),
  ),
);

void main() {
  test('binary and delegate caps have independent constants', () {
    expect(XdrDataInputStream.maxXdrDecodeDepth, _cap);
    expect(XdrDataInputStream.maxRecursiveDecodeDepth, 128);
    expect(XdrJsonHelper.maxDepth, 128);
  });

  for (final kind in ['vec', 'not', 'map']) {
    test('$kind decodes exactly $_cap guarded levels', () {
      final bytes = _payload(kind, _cap);
      final stream = XdrDataInputStream(bytes);
      _assertStructure(kind, _decode(kind, stream), _cap);
      expect(stream.offset, bytes.length);
    });

    for (final depth in [_cap + 1, 10000]) {
      test('$kind rejects $depth levels with the depth exception', () {
        expect(
          () => _decode(kind, XdrDataInputStream(_payload(kind, depth))),
          _depthFailure,
        );
      });
    }

    for (final throwsFirst in [false, true]) {
      test('$kind restores the counter after throws=$throwsFirst', () {
        final first = _payload(kind, _cap + (throwsFirst ? 1 : 0));
        final second = _payload(kind, _cap);
        final stream = XdrDataInputStream(
          Uint8List.fromList([...first, ...second]),
        );
        if (throwsFirst) {
          expect(() => _decode(kind, stream), _depthFailure);
          stream.readBytes(first.length - stream.offset!);
        } else {
          _assertStructure(kind, _decode(kind, stream), _cap);
        }
        _assertStructure(kind, _decode(kind, stream), _cap);
        expect(stream.offset, first.length + second.length);
      });
    }
  }

  test('100 SCVal levels decode at the host value depth', () {
    _assertStructure(
      'vec',
      XdrSCVal.decode(XdrDataInputStream(_payload('vec', 100))),
      100,
    );
  });

  test('two 128-level delegate chains decode from one stream', () {
    final chain = _delegateChain(128);
    final stream = XdrDataInputStream(Uint8List.fromList([...chain, ...chain]));
    for (var i = 1; i <= 2; i++) {
      _assertDelegateChain(XdrSorobanDelegateSignature.decode(stream), 128);
      expect(stream.offset, chain.length * i);
    }
  });

  test('a delegate with 200 sibling nested delegates decodes', () {
    final bytes = Uint8List.fromList([
      ..._delegateNode(200),
      for (var i = 0; i < 200; i++) ..._delegateNode(0),
    ]);
    final stream = XdrDataInputStream(bytes);
    final root = XdrSorobanDelegateSignature.decode(stream);
    _assertDelegateNode(root, 200);
    for (final child in root.nestedDelegates) {
      _assertDelegateNode(child, 0);
    }
    expect(stream.offset, bytes.length);
  });

  test(
    '128 delegate levels share the $_cap cap with their SCVal signature',
    () {
      final bytes = _delegateChain(128, signatureDepth: _cap - 128);
      final stream = XdrDataInputStream(bytes);
      _assertDelegateChain(
        XdrSorobanDelegateSignature.decode(stream),
        128,
        signatureDepth: _cap - 128,
      );
      expect(stream.offset, bytes.length);
      expect(
        () => XdrSorobanDelegateSignature.decode(
          XdrDataInputStream(_delegateChain(128, signatureDepth: _cap - 127)),
        ),
        _depthFailure,
      );
    },
  );
}
