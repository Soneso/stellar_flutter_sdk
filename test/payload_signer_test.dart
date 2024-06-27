import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:convert/convert.dart';

void main() {
  String seed =
      "1123740522f11bfef6b3671f51e159ccf589ccf8965262dd5f97d1721d383dd4";

  test('test sign payload signer', () async {
    KeyPair keyPair =
        KeyPair.fromSecretSeedList(Uint8List.fromList(hex.decode(seed)));
    Uint8List payload = Uint8List.fromList([1, 2, 3, 4, 5]);
    XdrDecoratedSignature sig = keyPair.signPayloadDecorated(payload);
    assert(listEquals(sig.hint.signatureHint,
        Uint8List.fromList([(0xFF & 252), 65, 0, 50])));
  });

  test('test sign payload signer less than hint', () async {
    KeyPair keyPair =
        KeyPair.fromSecretSeedList(Uint8List.fromList(hex.decode(seed)));
    Uint8List payload = Uint8List.fromList([1, 2, 3]);
    XdrDecoratedSignature sig = keyPair.signPayloadDecorated(payload);
    assert(listEquals(
        sig.hint.signatureHint, Uint8List.fromList([255, 64, 7, 55])));
  });

  test('it creates signed payload signer', () async {
    String accountStrKey =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ";
    String payloadStr =
        "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
    Uint8List payload = Uint8List.fromList(base16decode(payloadStr));
    SignedPayloadSigner signedPayloadSigner =
        SignedPayloadSigner.fromAccountId(accountStrKey, payload);
    XdrSignerKey signerKey = SignerKey.signedPayload(signedPayloadSigner);
    Uint8List cPayload = signerKey.signedPayload!.payload.dataValue;
    assert(listEquals(payload, cPayload));
    Uint8List a = signerKey.signedPayload!.ed25519.uint256;
    Uint8List b =
        signedPayloadSigner.signerAccountID.accountID.getEd25519()!.uint256;
    assert(listEquals(a, b));
  });

  test('test valid signed payload encode', () async {
    String accountStrKey =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ";

    // Valid signed payload with an ed25519 public key and a 32-byte payload.
    String payloadStr =
        "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
    Uint8List payload = Uint8List.fromList(base16decode(payloadStr));
    SignedPayloadSigner signedPayloadSigner =
        SignedPayloadSigner.fromAccountId(accountStrKey, payload);
    String encoded = StrKey.encodeSignedPayload(signedPayloadSigner);
    String pEncoded =
        "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM";
    assert(encoded == pEncoded);

    // Valid signed payload with an ed25519 public key and a 29-byte payload.
    payloadStr = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d";
    payload = Uint8List.fromList(base16decode(payloadStr));
    signedPayloadSigner =
        SignedPayloadSigner.fromAccountId(accountStrKey, payload);
    encoded = StrKey.encodeSignedPayload(signedPayloadSigner);
    pEncoded =
        "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU";
    assert(encoded == pEncoded);
  });

  test('test tx preconditions convert to xdr', () async {
    TransactionPreconditions cond = TransactionPreconditions();
    cond.minSeqNumber = 91891891;
    cond.minSeqAge = 181811;
    cond.minSeqLedgerGap = 1991;
    LedgerBounds lb = LedgerBounds(100, 100000);
    cond.ledgerBounds = lb;
    TimeBounds tb = TimeBounds(1651767858, 1651967858);
    cond.timeBounds = tb;
    String accountStrKey =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ";
    String payloadStr =
        "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
    Uint8List payload = Uint8List.fromList(base16decode(payloadStr));
    SignedPayloadSigner signedPayloadSigner =
        SignedPayloadSigner.fromAccountId(accountStrKey, payload);
    XdrSignerKey signerKey = SignerKey.signedPayload(signedPayloadSigner);
    cond.extraSigners = [signerKey];

    XdrDataOutputStream xdrOutputStream = new XdrDataOutputStream();
    XdrPreconditions.encode(xdrOutputStream, cond.toXdr());

    Uint8List bytes = Uint8List.fromList(xdrOutputStream.bytes);
    XdrDataInputStream xdrInputStream = new XdrDataInputStream(bytes);
    XdrPreconditions resultXdr = XdrPreconditions.decode(xdrInputStream);
    TransactionPreconditions cond2 =
        TransactionPreconditions.fromXdr(resultXdr);
    assert(cond.minSeqNumber == cond2.minSeqNumber);
    assert(cond.minSeqAge == cond2.minSeqAge);
    assert(cond.minSeqLedgerGap == cond2.minSeqLedgerGap);
    assert(cond.ledgerBounds!.minLedger == cond2.ledgerBounds!.minLedger);
    assert(cond.ledgerBounds!.maxLedger == cond2.ledgerBounds!.maxLedger);
    assert(cond.timeBounds!.minTime == cond2.timeBounds!.minTime);
    assert(cond.timeBounds!.maxTime == cond2.timeBounds!.maxTime);
    assert(cond.extraSigners!.length == cond2.extraSigners!.length);
    XdrSignerKey a = cond.extraSigners![0];
    XdrSignerKey b = cond2.extraSigners![0];
    assert(a.discriminant == b.discriminant);
    Uint8List aPayload = a.signedPayload!.payload.dataValue;
    Uint8List bPayload = b.signedPayload!.payload.dataValue;
    assert(listEquals(bPayload, aPayload));
    Uint8List aacc = a.signedPayload!.ed25519.uint256;
    Uint8List bacc = b.signedPayload!.ed25519.uint256;
    assert(listEquals(aacc, bacc));
  });

  test('test tx envelope from xdr', () async {
    String xdr =
        "AAAAAgAAAQAAAAAAABODof/acuzxAA9pILE4Qo4ywluEu8QPmzZdt9lqLwuIhryTAAAAZAALmqcAAAAUAAAAAgAAAAEAAAAAYnk1lQAAAABobxaVAAAAAQANnJQAHN7UAAAAAQALmqcAAAAIAAAAAAAAAAEAAAABAAAAAAAAAAAAAAABAAAAAQAAAQAAAAAAABODof/acuzxAA9pILE4Qo4ywluEu8QPmzZdt9lqLwuIhryTAAAAAQAAAQAAAAACTzrbb3aC2IBy/P5SR+6HUM0IKF3u4XY6AiFDhxsJI3NF3+ibAAAAAAAAAAAA5OHAAAAAAAAAAAGIhryTAAAAQCu6e+o3o+skZSo1H8mEjZ0Aw0seyrGjjk+vXmx/PD7RTC2b8RxXF5X/IdCEDiYe/kR8pUBzL1IPsgaVcs0RjQw=";

    AbstractTransaction transaction =
        AbstractTransaction.fromEnvelopeXdrString(xdr);
    Transaction t = transaction as Transaction;
    TransactionPreconditions? tp = t.preconditions;
    assert(tp != null);
    assert(tp!.ledgerBounds!.minLedger == 892052);
    assert(tp!.ledgerBounds!.maxLedger == 1892052);
    assert(tp!.timeBounds!.minTime == 1652110741);
    assert(tp!.timeBounds!.maxTime == 1752110741);
    assert(tp!.minSeqAge == 1);
    assert(tp!.minSeqLedgerGap == 1);
    assert(tp!.extraSigners!.length == 0);
  });
}
