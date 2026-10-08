import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'generated/xdr_test_helpers.dart';

void main() {
  // SEP-0023 vector: contract CA3D5KRY...GAXE paired with the id 123456. The
  // XDR places the id ahead of the contract hash; the strkey payload places
  // the hash first.
  const contractHex =
      '363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103';
  const muxedContractId =
      'WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG';
  const idHex = '000000000001e240';

  group('XdrMuxedContract', () {
    test('round trips through XDR with the id ahead of the hash', () {
      final muxed = XdrMuxedContract.forMuxedContractId(muxedContractId);
      expect(muxed.id.uint64, BigInt.from(123456));
      expect(Util.bytesToHex(muxed.contractId.hash), contractHex);

      final base64 = muxed.toBase64EncodedXdrString();
      expect(Util.bytesToHex(base64Decode(base64)), '$idHex$contractHex');
      final decoded = XdrMuxedContract.fromBase64EncodedXdrString(base64);
      expect(decoded.id.uint64, BigInt.from(123456));
      expect(Util.bytesToHex(decoded.contractId.hash), contractHex);
      expect(decoded.muxedContractId, muxedContractId);
    });

    test('renders as the W strkey in XDR-JSON', () {
      final muxed = XdrMuxedContract(
          XdrUint64(BigInt.from(123456)), XdrHash(Util.hexToBytes(contractHex)));
      expect(muxed.toXdrJson(), '"$muxedContractId"');

      final parsed = XdrMuxedContract.fromXdrJson('"$muxedContractId"');
      expect(parsed.id.uint64, BigInt.from(123456));
      expect(Util.bytesToHex(parsed.contractId.hash), contractHex);
    });

    test('refuses a strkey of another kind', () {
      expect(
          () => XdrMuxedContract.forMuxedContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE'),
          throwsFormatException);
    });
  });

  group('XdrSCAddress muxed contract arm', () {
    test('round trips through XDR, TxRep and XDR-JSON', () {
      final address = XdrSCAddress.forMuxedContractId(muxedContractId);
      expect(address.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_CONTRACT);
      expect(address.toStrKey(), muxedContractId);

      final base64 = address.toBase64EncodedXdrString();
      expect(Util.bytesToHex(base64Decode(base64)),
          '00000005$idHex$contractHex');
      final decoded =
          XdrSCAddress.decode(XdrDataInputStream(base64Decode(base64)));
      expect(decoded.toStrKey(), muxedContractId);

      final lines = <String>[];
      address.toTxRep('address', lines);
      final fromTxRep =
          XdrSCAddress.fromTxRep(parseTxRepLines(lines), 'address');
      expect(fromTxRep.toStrKey(), muxedContractId);

      expect(address.toXdrJson(), '"$muxedContractId"');
      final fromJson = XdrSCAddress.fromXdrJson('"$muxedContractId"');
      expect(fromJson.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_CONTRACT);
      expect(fromJson.toBase64EncodedXdrString(), base64);
    });
  });

  test('XdrContractCostType names the ML-DSA cost types', () {
    expect(XdrContractCostType.VerifyMlDsa87Sig.value, 94);
    expect(XdrContractCostType.VerifyMlDsa87Sig.toXdrJson(),
        '"verify_ml_dsa87_sig"');
    expect(XdrContractCostType.fromXdrJson('"verify_ml_dsa87_sig"').value, 94);
  });
}
