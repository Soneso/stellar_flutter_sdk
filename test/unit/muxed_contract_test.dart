import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // The muxed contract strkeys SEP-0023 lists as valid: the contract, the id
  // and the W strkey pairing them.
  final vectors = <(String, BigInt, String)>[
    (
      'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA',
      BigInt.zero,
      'WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC'
    ),
    (
      'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA',
      BigInt.parse('9223372036854775808'),
      'WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAACWJY'
    ),
    (
      'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
      BigInt.from(123456),
      'WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG'
    ),
  ];

  test('decomposes and rebuilds the SEP-0023 vectors', () {
    for (final (contractId, id, muxedContractId) in vectors) {
      final muxed = MuxedContract.fromMuxedContractId(muxedContractId);
      expect(muxed.contractId, contractId, reason: muxedContractId);
      expect(muxed.id, id, reason: muxedContractId);
      expect(MuxedContract(contractId, id).muxedContractId, muxedContractId);

      final fromXdr = MuxedContract.fromXdr(muxed.toXdr());
      expect(fromXdr.contractId, contractId);
      expect(fromXdr.id, id);

      final address = muxed.toAddress();
      expect(address.type, Address.TYPE_MUXED_CONTRACT);
      expect(address.toXdr().toStrKey(), muxedContractId);
    }
  });

  test('stores a hex contract id as its contract strkey', () {
    final muxed = MuxedContract(
        '363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103',
        BigInt.from(123456));
    expect(muxed.contractId,
        'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE');
    expect(muxed.muxedContractId, vectors.last.$3);
  });

  test('refuses an id outside the unsigned 64-bit range', () {
    for (final id in [BigInt.from(-1), BigInt.one << 64]) {
      expect(
          () => MuxedContract(vectors.first.$1, id),
          throwsA(isA<ArgumentError>()
              .having((ArgumentError e) => e.name, 'name', 'id')
              .having((ArgumentError e) => e.invalidValue, 'value', id)));
    }
  });

  test('fromXdr refuses an id outside the unsigned 64-bit range', () {
    final contractHash = XdrHash(StrKey.decodeContractId(vectors.first.$1));
    for (final id in [BigInt.from(-1), BigInt.one << 64]) {
      expect(
          () => MuxedContract.fromXdr(
              XdrMuxedContract(XdrUint64(id), contractHash)),
          throwsA(isA<ArgumentError>()
              .having((ArgumentError e) => e.name, 'name', 'id')
              .having((ArgumentError e) => e.invalidValue, 'value', id)));
    }
  });

  test('refuses a contract id in neither accepted form', () {
    for (final contractId in [
      'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXF',
      '363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b1',
      vectors.last.$3,
    ]) {
      expect(
          () => MuxedContract(contractId, BigInt.one),
          throwsA(isA<ArgumentError>()
              .having((ArgumentError e) => e.name, 'name', 'contractId')
              .having(
                  (ArgumentError e) => e.invalidValue, 'value', contractId)));
    }
  });

  test('refuses a strkey that is not a muxed contract address', () {
    expect(() => MuxedContract.fromMuxedContractId(vectors.first.$1),
        throwsFormatException);
  });
}
