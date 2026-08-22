import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  const deployer = 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
  final ownerHex = 'ab' * 32;
  final salt = XdrUint256(Uint8List.fromList(List.filled(32, 0x11)));

  String envelopeFor(HostFunction hostFunction) {
    final account = Account(deployer, BigInt.one);
    final op = InvokeHostFuncOpBuilder(hostFunction).build();
    return TransactionBuilder(account).addOperation(op).build().toEnvelopeXdrBase64();
  }

  group('external-ref create operations in TxRep envelopes', () {
    test('a CREATE_CONTRACT envelope round-trips and names the reference', () {
      final envelope = envelopeFor(CreateContractFromExternalRefHostFunction.forTagString(
          Address.forAccountId(deployer), Address.forContractId(ownerHex), 'token-v1',
          salt: salt));

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
      expect(
          txRep,
          contains('hostFunction.createContract.executable.type: '
              'CONTRACT_EXECUTABLE_EXTERNAL_REF'));
      expect(
          txRep,
          contains('hostFunction.createContract.executable.external_ref'
              '.executable_owner.contractId: $ownerHex'));
      expect(
          txRep,
          contains(
              'hostFunction.createContract.executable.external_ref.tag: "token-v1"'));

      expect(TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep), equals(envelope));
    });

    test('a CREATE_CONTRACT_V2 envelope round-trips with a binary tag and args', () {
      final binaryTag = Uint8List.fromList([0xC0, 0x00, 0xFF, 0xFE]);
      final envelope = envelopeFor(CreateContractFromExternalRefWithConstructorHostFunction(
          Address.forAccountId(deployer), Address.forContractId(ownerHex), binaryTag,
          [XdrSCVal.forU32(7)],
          salt: salt));

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
      expect(
          txRep,
          contains('hostFunction.createContractV2.executable.type: '
              'CONTRACT_EXECUTABLE_EXTERNAL_REF'));
      expect(
          txRep,
          contains(
              r'hostFunction.createContractV2.executable.external_ref.tag: "\xc0\x00\xff\xfe"'));
      expect(txRep, contains('createContractV2.constructorArgs.len: 1'));
      expect(txRep, contains('createContractV2.constructorArgs[0].u32: 7'));

      expect(TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep), equals(envelope));
    });
  });
}
