// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_signing.dart';
import 'xdr_operation.dart';
import 'xdr_ledger.dart';
import 'xdr_account.dart';
import 'xdr_contract.dart';
import 'xdr_memo.dart';
import "dart:convert";
import 'dart:typed_data';
import 'xdr_asset.dart';

class XdrTransaction {
  XdrTransaction(this._sourceAccount, this._fee, this._seqNum, this._cond,
      this._memo, this._operations, this._ext);
  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrUint32 _fee;
  XdrUint32 get fee => this._fee;
  set fee(XdrUint32 value) => this._fee = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrPreconditions _cond;
  XdrPreconditions get preconditions => this._cond;
  set preconditions(XdrPreconditions value) => this._cond = value;

  XdrMemo _memo;
  XdrMemo get memo => this._memo;
  set memo(XdrMemo value) => this._memo = value;

  List<XdrOperation> _operations;
  List<XdrOperation> get operations => this._operations;
  set operations(List<XdrOperation> value) => this._operations = value;

  XdrTransactionExt _ext;
  XdrTransactionExt get ext => this._ext;
  set ext(XdrTransactionExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransaction encodedTransaction) {
    XdrMuxedAccount.encode(stream, encodedTransaction._sourceAccount);
    XdrUint32.encode(stream, encodedTransaction._fee);
    XdrSequenceNumber.encode(stream, encodedTransaction._seqNum);
    XdrPreconditions.encode(stream, encodedTransaction._cond);
    XdrMemo.encode(stream, encodedTransaction._memo);
    int operationsSize = encodedTransaction.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperation.encode(stream, encodedTransaction._operations[i]);
    }
    XdrTransactionExt.encode(stream, encodedTransaction._ext);
  }

  static XdrTransaction decode(XdrDataInputStream stream) {
    XdrMuxedAccount sourceAccount = XdrMuxedAccount.decode(stream);
    XdrUint32 fee = XdrUint32.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrPreconditions cond = XdrPreconditions.decode(stream);
    XdrMemo memo = XdrMemo.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperation> operations = List<XdrOperation>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperation.decode(stream));
    }
    XdrTransactionExt ext = XdrTransactionExt.decode(stream);
    return XdrTransaction(
        sourceAccount, fee, seqNum, cond, memo, operations, ext);
  }
}

class XdrTransactionExt {
  XdrTransactionExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanTransactionData? _sorobanTransactionData;
  XdrSorobanTransactionData? get sorobanTransactionData =>
      this._sorobanTransactionData;
  set sorobanTransactionData(XdrSorobanTransactionData? value) =>
      this._sorobanTransactionData = value;

  static void encode(XdrDataOutputStream stream, XdrTransactionExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanTransactionData.encode(
            stream, encoded.sorobanTransactionData!);
        break;
    }
  }

  static XdrTransactionExt decode(XdrDataInputStream stream) {
    XdrTransactionExt decodedTransactionExt =
        XdrTransactionExt(stream.readInt());
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedTransactionExt.sorobanTransactionData =
            XdrSorobanTransactionData.decode(stream);
        break;
    }
    return decodedTransactionExt;
  }
}

class XdrFeeBumpTransaction {
  XdrFeeBumpTransaction(this._feeSource, this._fee, this._innerTx, this._ext);
  XdrMuxedAccount _feeSource;
  XdrMuxedAccount get feeSource => this._feeSource;
  set feeSource(XdrMuxedAccount value) => this._feeSource = value;

  XdrInt64 _fee;
  XdrInt64 get fee => this._fee;
  set fee(XdrInt64 value) => this._fee = value;

  XdrFeeBumpTransactionInnerTx _innerTx;
  XdrFeeBumpTransactionInnerTx get innerTx => this._innerTx;
  set innerTx(XdrFeeBumpTransactionInnerTx value) => this._innerTx = value;

  XdrFeeBumpTransactionExt _ext;
  XdrFeeBumpTransactionExt get ext => this._ext;
  set ext(XdrFeeBumpTransactionExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrFeeBumpTransaction encodedTransaction) {
    XdrMuxedAccount.encode(stream, encodedTransaction._feeSource);
    XdrInt64.encode(stream, encodedTransaction._fee);
    XdrFeeBumpTransactionInnerTx.encode(stream, encodedTransaction._innerTx);
    XdrFeeBumpTransactionExt.encode(stream, encodedTransaction._ext);
  }

  static XdrFeeBumpTransaction decode(XdrDataInputStream stream) {
    XdrMuxedAccount feeSource = XdrMuxedAccount.decode(stream);
    XdrInt64 fee = XdrInt64.decode(stream);
    XdrFeeBumpTransactionInnerTx innerTx =
        XdrFeeBumpTransactionInnerTx.decode(stream);
    XdrFeeBumpTransactionExt ext = XdrFeeBumpTransactionExt.decode(stream);

    return XdrFeeBumpTransaction(feeSource, fee, innerTx, ext);
  }
}

class XdrFeeBumpTransactionInnerTx {
  XdrFeeBumpTransactionInnerTx(this._type);

  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransactionV1Envelope? _v1;
  XdrTransactionV1Envelope? get v1 => this._v1;
  set v1(XdrTransactionV1Envelope? value) => this._v1 = value;

  static void encode(XdrDataOutputStream stream,
      XdrFeeBumpTransactionInnerTx encodedTransaction) {
    stream.writeInt(encodedTransaction.discriminant.value);
    switch (encodedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransactionV1Envelope.encode(stream, encodedTransaction.v1!);
        break;
    }
  }

  static XdrFeeBumpTransactionInnerTx decode(XdrDataInputStream stream) {
    XdrFeeBumpTransactionInnerTx decoded =
        XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.decode(stream));
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decoded.v1 = XdrTransactionV1Envelope.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrFeeBumpTransactionExt {
  XdrFeeBumpTransactionExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrFeeBumpTransactionExt encodedTransactionExt) {
    stream.writeInt(encodedTransactionExt.discriminant);
    switch (encodedTransactionExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrFeeBumpTransactionExt decode(XdrDataInputStream stream) {
    XdrFeeBumpTransactionExt decodedTransactionExt =
        XdrFeeBumpTransactionExt(stream.readInt());
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}

/// Transaction used before protocol 13.
class XdrTransactionV0 {
  XdrTransactionV0(this._sourceAccountEd25519, this._fee, this._seqNum,
      this._timeBounds, this._memo, this._operations, this._ext);
  XdrUint256 _sourceAccountEd25519;
  XdrUint256 get sourceAccountEd25519 => this._sourceAccountEd25519;
  set sourceAccountEd25519(XdrUint256 value) =>
      this._sourceAccountEd25519 = value;

  XdrUint32 _fee;
  XdrUint32 get fee => this._fee;
  set fee(XdrUint32 value) => this._fee = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrTimeBounds? _timeBounds;
  XdrTimeBounds? get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds? value) => this._timeBounds = value;

  XdrMemo _memo;
  XdrMemo get memo => this._memo;
  set memo(XdrMemo value) => this._memo = value;

  List<XdrOperation> _operations;
  List<XdrOperation> get operations => this._operations;
  set operations(List<XdrOperation> value) => this._operations = value;

  XdrTransactionV0Ext _ext;
  XdrTransactionV0Ext get ext => this._ext;
  set ext(XdrTransactionV0Ext value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionV0 encodedTransaction) {
    XdrUint256.encode(stream, encodedTransaction._sourceAccountEd25519);
    XdrUint32.encode(stream, encodedTransaction._fee);
    XdrSequenceNumber.encode(stream, encodedTransaction._seqNum);
    if (encodedTransaction._timeBounds != null) {
      stream.writeInt(1);
      XdrTimeBounds.encode(stream, encodedTransaction._timeBounds!);
    } else {
      stream.writeInt(0);
    }
    XdrMemo.encode(stream, encodedTransaction._memo);
    int operationsSize = encodedTransaction.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperation.encode(stream, encodedTransaction._operations[i]);
    }
    XdrTransactionV0Ext.encode(stream, encodedTransaction._ext);
  }

  static XdrTransactionV0 decode(XdrDataInputStream stream) {
    XdrUint256 sourceAccountEd25519 = XdrUint256.decode(stream);
    XdrUint32 fee = XdrUint32.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrTimeBounds? timeBounds;
    int timeBoundsPresent = stream.readInt();
    if (timeBoundsPresent != 0) {
      timeBounds = XdrTimeBounds.decode(stream);
    }
    XdrMemo memo = XdrMemo.decode(stream);

    int operationsSize = stream.readInt();
    List<XdrOperation> operations = List<XdrOperation>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperation.decode(stream));
    }

    XdrTransactionV0Ext ext = XdrTransactionV0Ext.decode(stream);
    return XdrTransactionV0(
        sourceAccountEd25519, fee, seqNum, timeBounds, memo, operations, ext);
  }
}

class XdrTransactionV0Ext {
  XdrTransactionV0Ext(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionV0Ext encodedTransactionExt) {
    stream.writeInt(encodedTransactionExt.discriminant);
    switch (encodedTransactionExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionV0Ext decode(XdrDataInputStream stream) {
    XdrTransactionV0Ext decodedTransactionExt =
        XdrTransactionV0Ext(stream.readInt());
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}

class XdrTransactionEnvelope {
  XdrTransactionEnvelope(this._type);

  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransactionV1Envelope? _v1;
  XdrTransactionV1Envelope? get v1 => this._v1;
  set v1(XdrTransactionV1Envelope? value) => this._v1 = value;

  XdrFeeBumpTransactionEnvelope? _feeBump;
  XdrFeeBumpTransactionEnvelope? get feeBump => this._feeBump;
  set feeBump(XdrFeeBumpTransactionEnvelope? value) => this._feeBump = value;

  XdrTransactionV0Envelope? _v0;
  XdrTransactionV0Envelope? get v0 => this._v0;
  set v0(XdrTransactionV0Envelope? value) => this._v0 = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionEnvelope encodedEnvelope) {
    stream.writeInt(encodedEnvelope.discriminant.value);
    switch (encodedEnvelope.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        XdrTransactionV0Envelope.encode(stream, encodedEnvelope.v0!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransactionV1Envelope.encode(stream, encodedEnvelope.v1!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        XdrFeeBumpTransactionEnvelope.encode(stream, encodedEnvelope.feeBump!);
        break;
    }
  }

  static XdrTransactionEnvelope decode(XdrDataInputStream stream) {
    XdrTransactionEnvelope decoded =
        XdrTransactionEnvelope(XdrEnvelopeType.decode(stream));
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        decoded.v0 = XdrTransactionV0Envelope.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decoded.v1 = XdrTransactionV1Envelope.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        decoded.feeBump = XdrFeeBumpTransactionEnvelope.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrTransactionEnvelope fromEnvelopeXdrString(String envelope) {
    Uint8List bytes = base64Decode(envelope);
    return XdrTransactionEnvelope.decode(XdrDataInputStream(bytes));
  }

  String toEnvelopeXdrBase64() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionEnvelope.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}

class XdrTransactionV1Envelope {
  XdrTransactionV1Envelope(this._tx, this._signatures);

  XdrTransaction _tx;
  XdrTransaction get tx => this._tx;
  set tx(XdrTransaction value) => this._tx = value;

  List<XdrDecoratedSignature> _signatures;
  List<XdrDecoratedSignature> get signatures => this._signatures;
  set signatures(List<XdrDecoratedSignature> value) => this._signatures = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionV1Envelope encodedTransactionEnvelope) {
    XdrTransaction.encode(stream, encodedTransactionEnvelope._tx);
    int signaturesSize = encodedTransactionEnvelope.signatures.length;
    stream.writeInt(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      XdrDecoratedSignature.encode(
          stream, encodedTransactionEnvelope._signatures[i]);
    }
  }

  static XdrTransactionV1Envelope decode(XdrDataInputStream stream) {
    XdrTransaction tx = XdrTransaction.decode(stream);
    int signaturesSize = stream.readInt();
    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    for (int i = 0; i < signaturesSize; i++) {
      signatures.add(XdrDecoratedSignature.decode(stream));
    }
    return XdrTransactionV1Envelope(tx, signatures);
  }
}

class XdrFeeBumpTransactionEnvelope {
  XdrFeeBumpTransactionEnvelope(this._tx, this._signatures);

  XdrFeeBumpTransaction _tx;
  XdrFeeBumpTransaction get tx => this._tx;
  set tx(XdrFeeBumpTransaction value) => this._tx = value;

  List<XdrDecoratedSignature> _signatures;
  List<XdrDecoratedSignature> get signatures => this._signatures;
  set signatures(List<XdrDecoratedSignature> value) => this._signatures = value;

  static void encode(XdrDataOutputStream stream,
      XdrFeeBumpTransactionEnvelope encodedTransactionEnvelope) {
    XdrFeeBumpTransaction.encode(stream, encodedTransactionEnvelope._tx);
    int signaturesSize = encodedTransactionEnvelope.signatures.length;
    stream.writeInt(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      XdrDecoratedSignature.encode(
          stream, encodedTransactionEnvelope._signatures[i]);
    }
  }

  static XdrFeeBumpTransactionEnvelope decode(XdrDataInputStream stream) {
    XdrFeeBumpTransaction tx = XdrFeeBumpTransaction.decode(stream);
    int signaturesSize = stream.readInt();
    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    for (int i = 0; i < signaturesSize; i++) {
      signatures.add(XdrDecoratedSignature.decode(stream));
    }
    return XdrFeeBumpTransactionEnvelope(tx, signatures);
  }
}

/// Transaction envelope used before protocol 13.
class XdrTransactionV0Envelope {
  XdrTransactionV0Envelope(this._tx, this._signatures);

  XdrTransactionV0 _tx;
  XdrTransactionV0 get tx => this._tx;
  set tx(XdrTransactionV0 value) => this._tx = value;

  List<XdrDecoratedSignature> _signatures;
  List<XdrDecoratedSignature> get signatures => this._signatures;
  set signatures(List<XdrDecoratedSignature> value) => this._signatures = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionV0Envelope encodedTransactionEnvelope) {
    XdrTransactionV0.encode(stream, encodedTransactionEnvelope._tx);
    int signaturesSize = encodedTransactionEnvelope.signatures.length;
    stream.writeInt(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      XdrDecoratedSignature.encode(
          stream, encodedTransactionEnvelope._signatures[i]);
    }
  }

  static XdrTransactionV0Envelope decode(XdrDataInputStream stream) {
    XdrTransactionV0 tx = XdrTransactionV0.decode(stream);
    int signaturesSize = stream.readInt();
    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    for (int i = 0; i < signaturesSize; i++) {
      signatures.add(XdrDecoratedSignature.decode(stream));
    }

    return XdrTransactionV0Envelope(tx, signatures);
  }
}

class XdrTransactionMeta {
  XdrTransactionMeta(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  List<XdrOperationMeta>? _operations;
  List<XdrOperationMeta>? get operations => this._operations;
  set operations(List<XdrOperationMeta>? value) => this._operations = value;

  XdrTransactionMetaV1? _v1;
  XdrTransactionMetaV1? get v1 => this._v1;
  set v1(XdrTransactionMetaV1? value) => this._v1 = value;

  XdrTransactionMetaV2? _v2;
  XdrTransactionMetaV2? get v2 => this._v2;
  set v2(XdrTransactionMetaV2? value) => this._v2 = value;

  XdrTransactionMetaV3? _v3;
  XdrTransactionMetaV3? get v3 => this._v3;
  set v3(XdrTransactionMetaV3? value) => this._v3 = value;

  XdrTransactionMetaV4? _v4;
  XdrTransactionMetaV4? get v4 => this._v4;
  set v4(XdrTransactionMetaV4? value) => this._v4 = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionMeta encodedTransactionMeta) {
    stream.writeInt(encodedTransactionMeta.discriminant);
    switch (encodedTransactionMeta.discriminant) {
      case 0:
        int operationsSize = encodedTransactionMeta.operations!.length;
        stream.writeInt(operationsSize);
        for (int i = 0; i < operationsSize; i++) {
          XdrOperationMeta.encode(
              stream, encodedTransactionMeta._operations![i]);
        }
        break;
      case 1:
        XdrTransactionMetaV1.encode(stream, encodedTransactionMeta._v1!);
        break;
      case 2:
        XdrTransactionMetaV2.encode(stream, encodedTransactionMeta._v2!);
        break;
      case 3:
        XdrTransactionMetaV3.encode(stream, encodedTransactionMeta._v3!);
        break;
      case 4:
        XdrTransactionMetaV4.encode(stream, encodedTransactionMeta._v4!);
        break;
    }
  }

  static XdrTransactionMeta decode(XdrDataInputStream stream) {
    XdrTransactionMeta decodedTransactionMeta =
        XdrTransactionMeta(stream.readInt());
    switch (decodedTransactionMeta.discriminant) {
      case 0:
        int operationsSize = stream.readInt();
        List<XdrOperationMeta> operations =
            List<XdrOperationMeta>.empty(growable: true);
        for (int i = 0; i < operationsSize; i++) {
          operations.add(XdrOperationMeta.decode(stream));
        }
        decodedTransactionMeta._operations = operations;
        break;
      case 1:
        decodedTransactionMeta._v1 = XdrTransactionMetaV1.decode(stream);
        break;
      case 2:
        decodedTransactionMeta._v2 = XdrTransactionMetaV2.decode(stream);
        break;
      case 3:
        decodedTransactionMeta._v3 = XdrTransactionMetaV3.decode(stream);
        break;
      case 4:
        decodedTransactionMeta._v4 = XdrTransactionMetaV4.decode(stream);
        break;
    }
    return decodedTransactionMeta;
  }

  static XdrTransactionMeta fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionMeta.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionMeta.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}

class XdrSorobanTransactionMetaExtV1 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  // The following are the components of the overall Soroban resource fee
  // charged for the transaction.
  // The following relation holds:
  // `resourceFeeCharged = totalNonRefundableResourceFeeCharged + totalRefundableResourceFeeCharged`
  // where `resourceFeeCharged` is the overall fee charged for the
  // transaction. Also, `resourceFeeCharged` <= `sorobanData.resourceFee`
  // i.e.we never charge more than the declared resource fee.
  // The inclusion fee for charged the Soroban transaction can be found using
  // the following equation:
  // `result.feeCharged = resourceFeeCharged + inclusionFeeCharged`.
  // Total amount (in stroops) that has been charged for non-refundable
  // Soroban resources.
  // Non-refundable resources are charged based on the usage declared in
  // the transaction envelope (such as `instructions`, `readBytes` etc.) and
  // is charged regardless of the success of the transaction.
  XdrInt64 _totalNonRefundableResourceFeeCharged;
  XdrInt64 get totalNonRefundableResourceFeeCharged =>
      this._totalNonRefundableResourceFeeCharged;
  set totalNonRefundableResourceFeeCharged(XdrInt64 value) =>
      this._totalNonRefundableResourceFeeCharged = value;

  // Total amount (in stroops) that has been charged for refundable
  // Soroban resource fees.
  // Currently this comprises the rent fee (`rentFeeCharged`) and the
  // fee for the events and return value.
  // Refundable resources are charged based on the actual resources usage.
  // Since currently refundable resources are only used for the successful
  // transactions, this will be `0` for failed transactions.
  XdrInt64 _totalRefundableResourceFeeCharged;
  XdrInt64 get totalRefundableResourceFeeCharged =>
      this._totalRefundableResourceFeeCharged;
  set totalRefundableResourceFeeCharged(XdrInt64 value) =>
      this._totalRefundableResourceFeeCharged = value;

  // Amount (in stroops) that has been charged for rent.
  // This is a part of `totalNonRefundableResourceFeeCharged`.
  XdrInt64 _rentFeeCharged;
  XdrInt64 get rentFeeCharged => this._rentFeeCharged;
  set rentFeeCharged(XdrInt64 value) => this._rentFeeCharged = value;

  XdrSorobanTransactionMetaExtV1(
      this._ext,
      this._totalNonRefundableResourceFeeCharged,
      this._totalRefundableResourceFeeCharged,
      this._rentFeeCharged);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionMetaExtV1 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrInt64.encode(stream, encoded.totalNonRefundableResourceFeeCharged);
    XdrInt64.encode(stream, encoded.totalRefundableResourceFeeCharged);
    XdrInt64.encode(stream, encoded.rentFeeCharged);
  }

  static XdrSorobanTransactionMetaExtV1 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrInt64 totalNonRefundableResourceFeeCharged = XdrInt64.decode(stream);
    XdrInt64 totalRefundableResourceFeeCharged = XdrInt64.decode(stream);
    XdrInt64 rentFeeCharged = XdrInt64.decode(stream);
    return XdrSorobanTransactionMetaExtV1(
        ext,
        totalNonRefundableResourceFeeCharged,
        totalRefundableResourceFeeCharged,
        rentFeeCharged);
  }
}

class XdrSorobanTransactionMetaExt {
  XdrSorobanTransactionMetaExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanTransactionMetaExtV1? _v1;
  XdrSorobanTransactionMetaExtV1? get v1 => this._v1;
  set v1(XdrSorobanTransactionMetaExtV1? value) => this._v1 = value;

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionMetaExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanTransactionMetaExtV1.encode(stream, encoded.v1!);
        break;
    }
  }

  static XdrSorobanTransactionMetaExt decode(XdrDataInputStream stream) {
    XdrSorobanTransactionMetaExt decoded =
        XdrSorobanTransactionMetaExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.v1 = XdrSorobanTransactionMetaExtV1.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrSorobanTransactionMeta {
  XdrSorobanTransactionMetaExt _ext;
  XdrSorobanTransactionMetaExt get ext => this._ext;
  set ext(XdrSorobanTransactionMetaExt value) => this._ext = value;

  List<XdrContractEvent> _events;
  List<XdrContractEvent> get events => this._events;
  set events(List<XdrContractEvent> value) => this._events = value;

  XdrSCVal _returnValue;
  XdrSCVal get returnValue => this._returnValue;
  set returnValue(XdrSCVal value) => this._returnValue = value;

  List<XdrDiagnosticEvent> _diagnosticEvents;
  List<XdrDiagnosticEvent> get diagnosticEvents => this._diagnosticEvents;
  set diagnosticEvents(List<XdrDiagnosticEvent> value) =>
      this._diagnosticEvents = value;

  XdrSorobanTransactionMeta(
      this._ext, this._events, this._returnValue, this._diagnosticEvents);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionMeta encoded) {
    XdrSorobanTransactionMetaExt.encode(stream, encoded.ext);

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrContractEvent.encode(stream, encoded._events[i]);
    }

    XdrSCVal.encode(stream, encoded.returnValue);

    int diagnosticEventsSize = encoded.diagnosticEvents.length;
    stream.writeInt(diagnosticEventsSize);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      XdrDiagnosticEvent.encode(stream, encoded.diagnosticEvents[i]);
    }
  }

  static XdrSorobanTransactionMeta decode(XdrDataInputStream stream) {
    XdrSorobanTransactionMetaExt ext =
        XdrSorobanTransactionMetaExt.decode(stream);

    int eventsSize = stream.readInt();
    List<XdrContractEvent> events =
        List<XdrContractEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrContractEvent.decode(stream));
    }

    XdrSCVal returnValue = XdrSCVal.decode(stream);

    int diagnosticEventsSize = stream.readInt();
    List<XdrDiagnosticEvent> diagnosticEvents =
        List<XdrDiagnosticEvent>.empty(growable: true);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      diagnosticEvents.add(XdrDiagnosticEvent.decode(stream));
    }

    return XdrSorobanTransactionMeta(
        ext, events, returnValue, diagnosticEvents);
  }
}

class XdrSorobanTransactionMetaV2 {
  XdrSorobanTransactionMetaExt _ext;
  XdrSorobanTransactionMetaExt get ext => this._ext;
  set ext(XdrSorobanTransactionMetaExt value) => this._ext = value;

  XdrSCVal? _returnValue;
  XdrSCVal? get returnValue => this._returnValue;
  set returnValue(XdrSCVal? value) => this._returnValue = value;

  XdrSorobanTransactionMetaV2(this._ext, this._returnValue);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionMetaV2 encoded) {
    XdrSorobanTransactionMetaExt.encode(stream, encoded.ext);
    if (encoded.returnValue != null) {
      stream.writeInt(1);
      XdrSCVal.encode(stream, encoded.returnValue!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrSorobanTransactionMetaV2 decode(XdrDataInputStream stream) {
    XdrSorobanTransactionMetaExt ext =
        XdrSorobanTransactionMetaExt.decode(stream);

    XdrSCVal? returnValue;
    int present = stream.readInt();
    if (present != 0) {
      returnValue = XdrSCVal.decode(stream);
    }
    return XdrSorobanTransactionMetaV2(ext, returnValue);
  }
}

class XdrTransactionMetaV3 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrLedgerEntryChanges _txChangesBefore;
  XdrLedgerEntryChanges get txChangesBefore => this._txChangesBefore;
  set txChangesBefore(XdrLedgerEntryChanges value) =>
      this._txChangesBefore = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  XdrLedgerEntryChanges _txChangesAfter;
  XdrLedgerEntryChanges get txChangesAfter => this._txChangesAfter;
  set txChangesAfter(XdrLedgerEntryChanges value) =>
      this._txChangesAfter = value;

  XdrSorobanTransactionMeta? _sorobanMeta;
  XdrSorobanTransactionMeta? get sorobanMeta => this._sorobanMeta;
  set sorobanMeta(XdrSorobanTransactionMeta? value) =>
      this._sorobanMeta = value;

  XdrTransactionMetaV3(this._ext, this._txChangesBefore, this._operations,
      this._txChangesAfter, this._sorobanMeta);

  static void encode(XdrDataOutputStream stream, XdrTransactionMetaV3 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrLedgerEntryChanges.encode(stream, encoded._txChangesBefore);
    int operationsSize = encoded.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encoded._operations[i]);
    }

    XdrLedgerEntryChanges.encode(stream, encoded._txChangesAfter);

    if (encoded.sorobanMeta != null) {
      stream.writeInt(1);
      XdrSorobanTransactionMeta.encode(stream, encoded.sorobanMeta!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrTransactionMetaV3 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    XdrSorobanTransactionMeta? sorobanMeta;
    int present = stream.readInt();
    if (present != 0) {
      sorobanMeta = XdrSorobanTransactionMeta.decode(stream);
    }

    return XdrTransactionMetaV3(
        ext, txChangesBefore, operations, txChangesAfter, sorobanMeta);
  }
}

// Transaction-level events happen at different stages of the ledger apply flow
// (as opposed to the operation events that all happen atomically after
// a transaction is applied).
// This enum represents the possible stages during which an event has been
// emitted.
class XdrTransactionEventStage {
  final _value;
  const XdrTransactionEventStage._internal(this._value);
  toString() => 'TransactionEventStage.$_value';
  XdrTransactionEventStage(this._value);
  get value => this._value;

  // The event has happened before any one of the transactions has its operations applied.
  static const TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS =
      const XdrTransactionEventStage._internal(0);

  // The event has happened immediately after operations of the transaction have been applied.
  static const TRANSACTION_EVENT_STAGE_AFTER_TX =
      const XdrTransactionEventStage._internal(1);

  // The event has happened after every transaction had its operations applied.
  static const TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS =
      const XdrTransactionEventStage._internal(2);

  static XdrTransactionEventStage decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS;
      case 1:
        return TRANSACTION_EVENT_STAGE_AFTER_TX;
      case 2:
        return TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrTransactionEventStage value) {
    stream.writeInt(value.value);
  }
}

// Represents a transaction-level event in metadata.
// Currently this is limited to the fee events (when fee is charged or
// refunded).
class XdrTransactionEvent {
  // Stage at which an event has occurred.
  XdrTransactionEventStage _stage;
  XdrTransactionEventStage get stage => this._stage;
  set ext(XdrTransactionEventStage value) => this._stage = value;

  // The contract event that has occurred.
  XdrContractEvent _event;
  XdrContractEvent get event => this._event;
  set event(XdrContractEvent value) => this._event = value;

  XdrTransactionEvent(this._stage, this._event);

  static void encode(XdrDataOutputStream stream, XdrTransactionEvent encoded) {
    XdrTransactionEventStage.encode(stream, encoded.stage);
    XdrContractEvent.encode(stream, encoded.event);
  }

  static XdrTransactionEvent decode(XdrDataInputStream stream) {
    final stage = XdrTransactionEventStage.decode(stream);
    final event = XdrContractEvent.decode(stream);

    return XdrTransactionEvent(stage, event);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrTransactionEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionEvent.decode(XdrDataInputStream(bytes));
  }
}

class XdrTransactionMetaV4 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  // tx level changes before operations are applied if any
  XdrLedgerEntryChanges _txChangesBefore;
  XdrLedgerEntryChanges get txChangesBefore => this._txChangesBefore;
  set txChangesBefore(XdrLedgerEntryChanges value) =>
      this._txChangesBefore = value;

  // meta for each operation
  List<XdrOperationMetaV2> _operations;
  List<XdrOperationMetaV2> get operations => this._operations;
  set operations(List<XdrOperationMetaV2> value) => this._operations = value;

  // tx level changes after operations are applied if any
  XdrLedgerEntryChanges _txChangesAfter;
  XdrLedgerEntryChanges get txChangesAfter => this._txChangesAfter;
  set txChangesAfter(XdrLedgerEntryChanges value) =>
      this._txChangesAfter = value;

  // Soroban-specific meta (only for Soroban transactions).
  XdrSorobanTransactionMetaV2? _sorobanMeta;
  XdrSorobanTransactionMetaV2? get sorobanMeta => this._sorobanMeta;
  set sorobanMeta(XdrSorobanTransactionMetaV2? value) =>
      this._sorobanMeta = value;

  // Used for transaction-level events (like fee payment)
  List<XdrTransactionEvent> _events;
  List<XdrTransactionEvent> get events => this._events;
  set events(List<XdrTransactionEvent> value) => this._events = value;

  // Used for all diagnostic information
  List<XdrDiagnosticEvent> _diagnosticEvents;
  List<XdrDiagnosticEvent> get diagnosticEvents => this._diagnosticEvents;
  set diagnosticEvents(List<XdrDiagnosticEvent> value) =>
      this._diagnosticEvents = value;

  XdrTransactionMetaV4(
      this._ext,
      this._txChangesBefore,
      this._operations,
      this._txChangesAfter,
      this._sorobanMeta,
      this._events,
      this._diagnosticEvents);

  static void encode(XdrDataOutputStream stream, XdrTransactionMetaV4 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrLedgerEntryChanges.encode(stream, encoded.txChangesBefore);
    int operationsSize = encoded.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMetaV2.encode(stream, encoded.operations[i]);
    }

    XdrLedgerEntryChanges.encode(stream, encoded.txChangesAfter);

    if (encoded.sorobanMeta != null) {
      stream.writeInt(1);
      XdrSorobanTransactionMetaV2.encode(stream, encoded.sorobanMeta!);
    } else {
      stream.writeInt(0);
    }

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrTransactionEvent.encode(stream, encoded.events[i]);
    }

    int diagnosticEventsSize = encoded.diagnosticEvents.length;
    stream.writeInt(diagnosticEventsSize);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      XdrDiagnosticEvent.encode(stream, encoded.diagnosticEvents[i]);
    }
  }

  static XdrTransactionMetaV4 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);

    int operationsSize = stream.readInt();
    List<XdrOperationMetaV2> operations =
        List<XdrOperationMetaV2>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMetaV2.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    XdrSorobanTransactionMetaV2? sorobanMeta;
    int present = stream.readInt();
    if (present != 0) {
      sorobanMeta = XdrSorobanTransactionMetaV2.decode(stream);
    }

    int eventsSize = stream.readInt();
    List<XdrTransactionEvent> events =
        List<XdrTransactionEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrTransactionEvent.decode(stream));
    }

    int diagnosticEventsSize = stream.readInt();
    List<XdrDiagnosticEvent> diagnosticEvents =
        List<XdrDiagnosticEvent>.empty(growable: true);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      diagnosticEvents.add(XdrDiagnosticEvent.decode(stream));
    }

    return XdrTransactionMetaV4(ext, txChangesBefore, operations,
        txChangesAfter, sorobanMeta, events, diagnosticEvents);
  }
}

class XdrContractEventType {
  final _value;
  const XdrContractEventType._internal(this._value);
  toString() => 'ContractEventType.$_value';
  XdrContractEventType(this._value);
  get value => this._value;

  static const CONTRACT_EVENT_TYPE_SYSTEM =
      const XdrContractEventType._internal(0);
  static const CONTRACT_EVENT_TYPE_CONTRACT =
      const XdrContractEventType._internal(1);
  static const CONTRACT_EVENT_TYPE_DIAGNOSTIC =
      const XdrContractEventType._internal(2);

  static XdrContractEventType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONTRACT_EVENT_TYPE_SYSTEM;
      case 1:
        return CONTRACT_EVENT_TYPE_CONTRACT;
      case 2:
        return CONTRACT_EVENT_TYPE_DIAGNOSTIC;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrContractEventType value) {
    stream.writeInt(value.value);
  }
}

class XdrDiagnosticEvent {
  bool _inSuccessfulContractCall;
  bool get inSuccessfulContractCall => this._inSuccessfulContractCall;
  set ext(bool value) => this._inSuccessfulContractCall = value;

  XdrContractEvent _event;
  XdrContractEvent get event => this._event;
  set hash(XdrContractEvent value) => this._event = value;

  XdrDiagnosticEvent(this._inSuccessfulContractCall, this._event);

  static void encode(XdrDataOutputStream stream, XdrDiagnosticEvent encoded) {
    stream.writeBoolean(encoded.inSuccessfulContractCall);
    XdrContractEvent.encode(stream, encoded.event);
  }

  static XdrDiagnosticEvent decode(XdrDataInputStream stream) {
    return XdrDiagnosticEvent(
        stream.readBoolean(), XdrContractEvent.decode(stream));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrDiagnosticEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrDiagnosticEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrDiagnosticEvent.decode(XdrDataInputStream(bytes));
  }
}

// Resource limits for a Soroban transaction.
// The transaction will fail if it exceeds any of these limits.
class XdrSorobanResources {
  // The ledger footprint of the transaction.
  XdrLedgerFootprint _footprint;
  XdrLedgerFootprint get footprint => this._footprint;
  set footprint(XdrLedgerFootprint value) => this._footprint = value;

  // The maximum number of instructions this transaction can use
  XdrUint32 _instructions;
  XdrUint32 get instructions => this._instructions;
  set instructions(XdrUint32 value) => this._instructions = value;

  // The maximum number of bytes this transaction can read from disk backed entries
  XdrUint32 _diskReadBytes;
  XdrUint32 get diskReadBytes => this._diskReadBytes;
  set diskReadBytes(XdrUint32 value) => this._diskReadBytes = value;

  // The maximum number of bytes this transaction can write to ledger
  XdrUint32 _writeBytes;
  XdrUint32 get writeBytes => this._writeBytes;
  set writeBytes(XdrUint32 value) => this._writeBytes = value;

  XdrSorobanResources(this._footprint, this._instructions, this._diskReadBytes,
      this._writeBytes);

  static void encode(XdrDataOutputStream stream, XdrSorobanResources encoded) {
    XdrLedgerFootprint.encode(stream, encoded.footprint);
    XdrUint32.encode(stream, encoded.instructions);
    XdrUint32.encode(stream, encoded.diskReadBytes);
    XdrUint32.encode(stream, encoded.writeBytes);
  }

  static XdrSorobanResources decode(XdrDataInputStream stream) {
    final footprint = XdrLedgerFootprint.decode(stream);
    final instructions = XdrUint32.decode(stream);
    final diskReadBytes = XdrUint32.decode(stream);
    final writeBytes = XdrUint32.decode(stream);
    return XdrSorobanResources(
        footprint, instructions, diskReadBytes, writeBytes);
  }
}

class XdrSorobanResourcesExtV0 {
  // Vector of indices representing what Soroban
  // entries in the footprint are archived, based on the
  // order of keys provided in the readWrite footprint.
  List<XdrUint32> _archivedSorobanEntries;
  List<XdrUint32> get archivedSorobanEntries => this._archivedSorobanEntries;
  set archivedSorobanEntries(List<XdrUint32> value) =>
      this._archivedSorobanEntries = value;

  XdrSorobanResourcesExtV0(this._archivedSorobanEntries);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanResourcesExtV0 encoded) {
    int entriesSize = encoded.archivedSorobanEntries.length;
    stream.writeInt(entriesSize);
    for (int i = 0; i < entriesSize; i++) {
      XdrUint32.encode(stream, encoded.archivedSorobanEntries[i]);
    }
  }

  static XdrSorobanResourcesExtV0 decode(XdrDataInputStream stream) {
    int entriesSize = stream.readInt();
    List<XdrUint32> entries = List<XdrUint32>.empty(growable: true);
    for (int i = 0; i < entriesSize; i++) {
      entries.add(XdrUint32.decode(stream));
    }

    return XdrSorobanResourcesExtV0(entries);
  }
}

class XdrSorobanTransactionDataExt {
  XdrSorobanTransactionDataExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSorobanResourcesExtV0? _resourceExt;
  XdrSorobanResourcesExtV0? get resourceExt => this._resourceExt;
  set resourceExt(XdrSorobanResourcesExtV0? value) => this._resourceExt = value;

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionDataExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrSorobanResourcesExtV0.encode(stream, encoded.resourceExt!);
        break;
    }
  }

  static XdrSorobanTransactionDataExt decode(XdrDataInputStream stream) {
    XdrSorobanTransactionDataExt decoded =
        XdrSorobanTransactionDataExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.resourceExt = XdrSorobanResourcesExtV0.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrSorobanTransactionData {
  XdrSorobanTransactionDataExt _ext;
  XdrSorobanTransactionDataExt get ext => this._ext;
  set ext(XdrSorobanTransactionDataExt value) => this._ext = value;

  XdrSorobanResources _resources;
  XdrSorobanResources get resources => this._resources;
  set resources(XdrSorobanResources value) => this._resources = value;

  // Amount of the transaction `fee` allocated to the Soroban resource fees.
  // The fraction of `resourceFee` corresponding to `resources` specified
  // above is *not* refundable (i.e. fees for instructions, ledger I/O), as
  // well as fees for the transaction size.
  // The remaining part of the fee is refundable and the charged value is
  // based on the actual consumption of refundable resources (events, ledger
  // rent bumps).
  // The `inclusionFee` used for prioritization of the transaction is defined
  // as `tx.fee - resourceFee`.
  XdrInt64 _resourceFee;
  XdrInt64 get resourceFee => this._resourceFee;
  set resourceFee(XdrInt64 value) => this._resourceFee = value;

  XdrSorobanTransactionData(this._ext, this._resources, this._resourceFee);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionData encoded) {
    XdrSorobanTransactionDataExt.encode(stream, encoded.ext);
    XdrSorobanResources.encode(stream, encoded.resources);
    XdrInt64.encode(stream, encoded.resourceFee);
  }

  static XdrSorobanTransactionData decode(XdrDataInputStream stream) {
    final ext = XdrSorobanTransactionDataExt.decode(stream);
    final resources = XdrSorobanResources.decode(stream);
    final resourceFee = XdrInt64.decode(stream);
    return XdrSorobanTransactionData(ext, resources, resourceFee);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSorobanTransactionData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrSorobanTransactionData fromBase64EncodedXdrString(
      String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSorobanTransactionData.decode(XdrDataInputStream(bytes));
  }
}

class XdrContractEvent {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrHash? _hash;
  XdrHash? get hash => this._hash;
  set hash(XdrHash? value) => this._hash = value;

  XdrContractEventType _type;
  XdrContractEventType get type => this._type;
  set type(XdrContractEventType value) => this._type = value;

  XdrContractEventBody _body;
  XdrContractEventBody get body => this._body;
  set body(XdrContractEventBody value) => this._body = value;

  XdrContractEvent(this._ext, this._hash, this._type, this._body);

  static void encode(XdrDataOutputStream stream, XdrContractEvent encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    if (encoded.hash != null) {
      stream.writeInt(1);
      XdrHash.encode(stream, encoded.hash!);
    } else {
      stream.writeInt(0);
    }
    XdrContractEventType.encode(stream, encoded.type);
    XdrContractEventBody.encode(stream, encoded.body);
  }

  static XdrContractEvent decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrHash? hash;
    int hashPresent = stream.readInt();
    if (hashPresent != 0) {
      hash = XdrHash.decode(stream);
    }

    XdrContractEventType type = XdrContractEventType.decode(stream);
    XdrContractEventBody body = XdrContractEventBody.decode(stream);
    return XdrContractEvent(ext, hash, type, body);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrContractEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrContractEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrContractEvent.decode(XdrDataInputStream(bytes));
  }
}

class XdrContractEventBody {
  XdrContractEventBody(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrContractEventBodyV0? _v0;
  XdrContractEventBodyV0? get v0 => this._v0;
  set v0(XdrContractEventBodyV0? value) => this._v0 = value;

  static void encode(XdrDataOutputStream stream, XdrContractEventBody encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        XdrContractEventBodyV0.encode(stream, encoded.v0!);
        break;
    }
  }

  static XdrContractEventBody decode(XdrDataInputStream stream) {
    XdrContractEventBody decoded = XdrContractEventBody(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        decoded.v0 = XdrContractEventBodyV0.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrContractEventBodyV0 {
  List<XdrSCVal> _topics;
  List<XdrSCVal> get topics => this._topics;
  set topics(List<XdrSCVal> value) => this._topics = value;

  XdrSCVal _data;
  XdrSCVal get data => this._data;
  set data(XdrSCVal value) => this._data = value;

  XdrContractEventBodyV0(this._topics, this._data);

  static void encode(
      XdrDataOutputStream stream, XdrContractEventBodyV0 encoded) {
    int topicsSize = encoded.topics.length;
    stream.writeInt(topicsSize);
    for (int i = 0; i < topicsSize; i++) {
      XdrSCVal.encode(stream, encoded.topics[i]);
    }
    XdrSCVal.encode(stream, encoded.data);
  }

  static XdrContractEventBodyV0 decode(XdrDataInputStream stream) {
    int topicsSize = stream.readInt();
    List<XdrSCVal> topics = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < topicsSize; i++) {
      topics.add(XdrSCVal.decode(stream));
    }
    XdrSCVal data = XdrSCVal.decode(stream);

    return XdrContractEventBodyV0(topics, data);
  }
}

class XdrTransactionMetaV2 {
  XdrTransactionMetaV2(
      this._txChangesBefore, this._operations, this._txChangesAfter);
  XdrLedgerEntryChanges _txChangesBefore;
  XdrLedgerEntryChanges get txChangesBefore => this._txChangesBefore;
  set txChangesBefore(XdrLedgerEntryChanges value) =>
      this._txChangesBefore = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  XdrLedgerEntryChanges _txChangesAfter;
  XdrLedgerEntryChanges get txChangesAfter => this._txChangesAfter;
  set txChangesAfter(XdrLedgerEntryChanges value) =>
      this._txChangesAfter = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionMetaV2 encodedTransactionMetaV2) {
    XdrLedgerEntryChanges.encode(
        stream, encodedTransactionMetaV2._txChangesBefore);
    int operationsSize = encodedTransactionMetaV2.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encodedTransactionMetaV2._operations[i]);
    }
    XdrLedgerEntryChanges.encode(
        stream, encodedTransactionMetaV2._txChangesAfter);
  }

  static XdrTransactionMetaV2 decode(XdrDataInputStream stream) {
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    return XdrTransactionMetaV2(txChangesBefore, operations, txChangesAfter);
  }
}

class XdrTransactionMetaV1 {
  XdrTransactionMetaV1(this._txChanges, this._operations);
  XdrLedgerEntryChanges _txChanges;
  XdrLedgerEntryChanges get txChanges => this._txChanges;
  set txChanges(XdrLedgerEntryChanges value) => this._txChanges = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionMetaV1 encodedTransactionMetaV1) {
    XdrLedgerEntryChanges.encode(stream, encodedTransactionMetaV1._txChanges);
    int operationsSize = encodedTransactionMetaV1.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encodedTransactionMetaV1._operations[i]);
    }
  }

  static XdrTransactionMetaV1 decode(XdrDataInputStream stream) {
    XdrLedgerEntryChanges txChanges = XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    return XdrTransactionMetaV1(txChanges, operations);
  }
}

class XdrTransactionResult {
  XdrTransactionResult(this._feeCharged, this._result, this._ext);
  XdrInt64 _feeCharged;
  XdrInt64 get feeCharged => this._feeCharged;
  set feeCharged(XdrInt64 value) => this._feeCharged = value;

  XdrTransactionResultResult _result;
  XdrTransactionResultResult get result => this._result;
  set result(XdrTransactionResultResult value) => this._result = value;

  XdrTransactionResultExt _ext;
  XdrTransactionResultExt get ext => this._ext;
  set ext(XdrTransactionResultExt value) => this._ext = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResult encodedTransactionResult) {
    XdrInt64.encode(stream, encodedTransactionResult._feeCharged);
    XdrTransactionResultResult.encode(stream, encodedTransactionResult._result);
    XdrTransactionResultExt.encode(stream, encodedTransactionResult._ext);
  }

  static XdrTransactionResult decode(XdrDataInputStream stream) {
    XdrInt64 feeCharged = XdrInt64.decode(stream);
    XdrTransactionResultResult result =
        XdrTransactionResultResult.decode(stream);
    XdrTransactionResultExt ext = XdrTransactionResultExt.decode(stream);
    return XdrTransactionResult(feeCharged, result, ext);
  }

  static XdrTransactionResult fromBase64EncodedXdrString(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return XdrTransactionResult.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionResult.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}

class XdrTransactionResultResult {
  XdrTransactionResultResult(this._code, this._results, this._innerResultPair);
  XdrTransactionResultCode _code;
  XdrTransactionResultCode get discriminant => this._code;
  set discriminant(XdrTransactionResultCode value) => this._code = value;

  List<XdrOperationResult>? _results;
  get results => this._results;
  set results(value) => this._results = value;

  XdrInnerTransactionResultPair? _innerResultPair;
  get innerResultPair => this._innerResultPair;
  set innerResultPair(value) => this._innerResultPair = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionResultResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultsSize = encoded.results.length;
        stream.writeInt(resultsSize);
        for (int i = 0; i < resultsSize; i++) {
          XdrOperationResult.encode(stream, encoded._results![i]);
        }
        break;
      case XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS:
      case XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED:
        XdrInnerTransactionResultPair.encode(stream, encoded._innerResultPair!);
        break;
      default:
        break;
    }
  }

  static XdrTransactionResultResult decode(XdrDataInputStream stream) {
    List<XdrOperationResult>? results;
    XdrInnerTransactionResultPair? innerResultPair;
    XdrTransactionResultCode discriminant =
        XdrTransactionResultCode.decode(stream);
    switch (discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultsSize = stream.readInt();
        results = List<XdrOperationResult>.empty(growable: true);
        for (int i = 0; i < resultsSize; i++) {
          results.add(XdrOperationResult.decode(stream));
        }
        break;
      case XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS:
      case XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED:
        innerResultPair = XdrInnerTransactionResultPair.decode(stream);
        break;
      default:
        break;
    }
    return XdrTransactionResultResult(discriminant, results, innerResultPair);
  }
}

class XdrTransactionResultExt {
  XdrTransactionResultExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResultExt encodedTransactionResultExt) {
    stream.writeInt(encodedTransactionResultExt.discriminant);
    switch (encodedTransactionResultExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionResultExt decode(XdrDataInputStream stream) {
    XdrTransactionResultExt decodedTransactionResultExt =
        XdrTransactionResultExt(stream.readInt());
    switch (decodedTransactionResultExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionResultExt;
  }
}

class XdrInnerTransactionResult {
  XdrInnerTransactionResult(this._feeCharged, this._result, this._ext);
  XdrInt64 _feeCharged;
  XdrInt64 get feeCharged => this._feeCharged;
  set feeCharged(XdrInt64 value) => this._feeCharged = value;

  XdrInnerTransactionResultResult _result;
  XdrInnerTransactionResultResult get result => this._result;
  set result(XdrInnerTransactionResultResult value) => this._result = value;

  XdrTransactionResultExt _ext;
  XdrTransactionResultExt get ext => this._ext;
  set ext(XdrTransactionResultExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrInnerTransactionResult encoded) {
    XdrInt64.encode(stream, encoded._feeCharged);
    XdrInnerTransactionResultResult.encode(stream, encoded._result);
    XdrTransactionResultExt.encode(stream, encoded._ext);
  }

  static XdrInnerTransactionResult decode(XdrDataInputStream stream) {
    XdrInt64 feeCharged = XdrInt64.decode(stream);
    XdrInnerTransactionResultResult result =
        XdrInnerTransactionResultResult.decode(stream);
    XdrTransactionResultExt ext = XdrTransactionResultExt.decode(stream);
    return XdrInnerTransactionResult(feeCharged, result, ext);
  }
}

class XdrInnerTransactionResultResult {
  XdrInnerTransactionResultResult(this._code, this._results);

  XdrTransactionResultCode _code;

  XdrTransactionResultCode get discriminant => this._code;

  set discriminant(XdrTransactionResultCode value) => this._code = value;

  List<XdrOperationResult>? _results;

  get results => this._results;

  set results(value) => this._results = value;

  static void encode(
      XdrDataOutputStream stream, XdrInnerTransactionResultResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultsSize = encoded.results.length;
        stream.writeInt(resultsSize);
        for (int i = 0; i < resultsSize; i++) {
          XdrOperationResult.encode(stream, encoded._results![i]);
        }
        break;
      default:
        break;
    }
  }

  static XdrInnerTransactionResultResult decode(XdrDataInputStream stream) {
    List<XdrOperationResult>? results;
    XdrTransactionResultCode discriminant =
        XdrTransactionResultCode.decode(stream);
    switch (discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultsSize = stream.readInt();
        results = List<XdrOperationResult>.empty(growable: true);
        for (int i = 0; i < resultsSize; i++) {
          results.add(XdrOperationResult.decode(stream));
        }
        break;
      default:
        break;
    }
    return XdrInnerTransactionResultResult(discriminant, results);
  }
}

class XdrInnerTransactionResultPair {
  XdrInnerTransactionResultPair(this._transactionHash, this._result);
  XdrHash _transactionHash;
  XdrHash get transactionHash => this._transactionHash;
  set transactionHash(XdrHash value) => this._transactionHash = value;

  XdrInnerTransactionResult _result;
  XdrInnerTransactionResult get result => this._result;
  set result(XdrInnerTransactionResult value) => this._result = value;

  static void encode(
      XdrDataOutputStream stream, XdrInnerTransactionResultPair encoded) {
    XdrHash.encode(stream, encoded._transactionHash);
    XdrInnerTransactionResult.encode(stream, encoded._result);
  }

  static XdrInnerTransactionResultPair decode(XdrDataInputStream stream) {
    XdrHash transactionHash = XdrHash.decode(stream);
    XdrInnerTransactionResult result = XdrInnerTransactionResult.decode(stream);
    return XdrInnerTransactionResultPair(transactionHash, result);
  }
}

class XdrTransactionResultPair {
  XdrTransactionResultPair(this._transactionHash, this._result);
  XdrHash _transactionHash;
  XdrHash get transactionHash => this._transactionHash;
  set transactionHash(XdrHash value) => this._transactionHash = value;

  XdrTransactionResult _result;
  XdrTransactionResult get result => this._result;
  set result(XdrTransactionResult value) => this._result = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResultPair encodedTransactionResultPair) {
    XdrHash.encode(stream, encodedTransactionResultPair._transactionHash);
    XdrTransactionResult.encode(stream, encodedTransactionResultPair._result);
  }

  static XdrTransactionResultPair decode(XdrDataInputStream stream) {
    XdrHash transactionHash = XdrHash.decode(stream);
    XdrTransactionResult result = XdrTransactionResult.decode(stream);
    return XdrTransactionResultPair(transactionHash, result);
  }
}

class XdrTransactionResultSet {
  XdrTransactionResultSet(this._results);
  List<XdrTransactionResultPair> _results;
  List<XdrTransactionResultPair> get results => this._results;
  set results(List<XdrTransactionResultPair> value) => this._results = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResultSet encodedTransactionResultSet) {
    int resultsSize = encodedTransactionResultSet.results.length;
    stream.writeInt(resultsSize);
    for (int i = 0; i < resultsSize; i++) {
      XdrTransactionResultPair.encode(
          stream, encodedTransactionResultSet._results[i]);
    }
  }

  static XdrTransactionResultSet decode(XdrDataInputStream stream) {
    int resultsSize = stream.readInt();
    List<XdrTransactionResultPair> results =
        List<XdrTransactionResultPair>.empty(growable: true);
    for (int i = 0; i < resultsSize; i++) {
      results.add(XdrTransactionResultPair.decode(stream));
    }
    return XdrTransactionResultSet(results);
  }
}

class XdrTransactionSet {
  XdrTransactionSet(this._previousLedgerHash, this._txEnvelopes);
  XdrHash _previousLedgerHash;
  XdrHash get previousLedgerHash => this._previousLedgerHash;
  set previousLedgerHash(XdrHash value) => this._previousLedgerHash = value;

  List<XdrTransactionEnvelope> _txEnvelopes;
  List<XdrTransactionEnvelope> get txEnvelopes => this._txEnvelopes;
  set txs(List<XdrTransactionEnvelope> value) => this._txEnvelopes = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionSet encodedTransactionSet) {
    XdrHash.encode(stream, encodedTransactionSet._previousLedgerHash);
    int txEnvelopesSize = encodedTransactionSet.txEnvelopes.length;
    stream.writeInt(txEnvelopesSize);
    for (int i = 0; i < txEnvelopesSize; i++) {
      XdrTransactionEnvelope.encode(
          stream, encodedTransactionSet._txEnvelopes[i]);
    }
  }

  static XdrTransactionSet decode(XdrDataInputStream stream) {
    XdrHash previousLedgerHash = XdrHash.decode(stream);

    int txEnvelopesSize = stream.readInt();
    List<XdrTransactionEnvelope> envelopes =
        List<XdrTransactionEnvelope>.empty(growable: true);
    for (int i = 0; i < txEnvelopesSize; i++) {
      envelopes.add(XdrTransactionEnvelope.decode(stream));
    }

    return XdrTransactionSet(previousLedgerHash, envelopes);
  }
}

class XdrTransactionSignaturePayload {
  XdrTransactionSignaturePayload(this._networkId, this._taggedTransaction);
  XdrHash _networkId;
  XdrHash get networkId => this._networkId;
  set networkId(XdrHash value) => this._networkId = value;

  XdrTransactionSignaturePayloadTaggedTransaction _taggedTransaction;
  XdrTransactionSignaturePayloadTaggedTransaction get taggedTransaction =>
      this._taggedTransaction;
  set taggedTransaction(
          XdrTransactionSignaturePayloadTaggedTransaction value) =>
      this._taggedTransaction = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionSignaturePayload encodedTransactionSignaturePayload) {
    XdrHash.encode(stream, encodedTransactionSignaturePayload._networkId);
    XdrTransactionSignaturePayloadTaggedTransaction.encode(
        stream, encodedTransactionSignaturePayload._taggedTransaction);
  }

  static XdrTransactionSignaturePayload decode(XdrDataInputStream stream) {
    XdrHash networkId = XdrHash.decode(stream);
    XdrTransactionSignaturePayloadTaggedTransaction taggedTransaction =
        XdrTransactionSignaturePayloadTaggedTransaction.decode(stream);
    return XdrTransactionSignaturePayload(networkId, taggedTransaction);
  }
}

class XdrTransactionSignaturePayloadTaggedTransaction {
  XdrTransactionSignaturePayloadTaggedTransaction(this._type);
  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransaction? _tx;
  XdrTransaction? get tx => this._tx;
  set tx(XdrTransaction? value) => this._tx = value;

  static void encode(
      XdrDataOutputStream stream,
      XdrTransactionSignaturePayloadTaggedTransaction
          encodedTransactionSignaturePayloadTaggedTransaction) {
    stream.writeInt(
        encodedTransactionSignaturePayloadTaggedTransaction.discriminant.value);
    switch (encodedTransactionSignaturePayloadTaggedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransaction.encode(
            stream, encodedTransactionSignaturePayloadTaggedTransaction._tx!);
        break;
    }
  }

  static XdrTransactionSignaturePayloadTaggedTransaction decode(
      XdrDataInputStream stream) {
    XdrTransactionSignaturePayloadTaggedTransaction
        decodedTransactionSignaturePayloadTaggedTransaction =
        XdrTransactionSignaturePayloadTaggedTransaction(
            XdrEnvelopeType.decode(stream));
    switch (decodedTransactionSignaturePayloadTaggedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decodedTransactionSignaturePayloadTaggedTransaction._tx =
            XdrTransaction.decode(stream);
        break;
    }
    return decodedTransactionSignaturePayloadTaggedTransaction;
  }
}

class XdrTransactionResultCode {
  final _value;
  const XdrTransactionResultCode._internal(this._value);
  toString() => 'TransactionResultCode.$_value';
  XdrTransactionResultCode(this._value);
  get value => this._value;

  /// Fee bump inner transaction succeeded.
  static const txFEE_BUMP_INNER_SUCCESS =
      const XdrTransactionResultCode._internal(1);

  /// All operations succeeded.
  static const txSUCCESS = const XdrTransactionResultCode._internal(0);

  /// One of the operations failed (none were applied).
  static const txFAILED = const XdrTransactionResultCode._internal(-1);

  /// Ledger closeTime before minTime.
  static const txTOO_EARLY = const XdrTransactionResultCode._internal(-2);

  /// Ledger closeTime after maxTime.
  static const txTOO_LATE = const XdrTransactionResultCode._internal(-3);

  /// No operation was specified.
  static const txMISSING_OPERATION =
      const XdrTransactionResultCode._internal(-4);

  /// Sequence number does not match source account.
  static const txBAD_SEQ = const XdrTransactionResultCode._internal(-5);

  /// Too few valid signatures / wrong network.
  static const txBAD_AUTH = const XdrTransactionResultCode._internal(-6);

  /// Fee would bring account below reserve.
  static const txINSUFFICIENT_BALANCE =
      const XdrTransactionResultCode._internal(-7);

  /// Source account not found.
  static const txNO_ACCOUNT = const XdrTransactionResultCode._internal(-8);

  /// Fee is too small.
  static const txINSUFFICIENT_FEE =
      const XdrTransactionResultCode._internal(-9);

  /// Unused signatures attached to transaction.
  static const txBAD_AUTH_EXTRA = const XdrTransactionResultCode._internal(-10);

  /// An unknown error occured.
  static const txINTERNAL_ERROR = const XdrTransactionResultCode._internal(-11);

  /// Transaction type not supported.
  static const txNOT_SUPPORTED = const XdrTransactionResultCode._internal(-12);

  /// Fee bump inner transaction failed.
  static const txFEE_BUMP_INNER_FAILED =
      const XdrTransactionResultCode._internal(-13);

  /// Sponsorship not ended.
  static const txBAD_SPONSORSHIP =
      const XdrTransactionResultCode._internal(-14);

  static const txBAD_MIN_SEQ_AGE_OR_GAP =
      const XdrTransactionResultCode._internal(-15);

  static const txMALFORMED = const XdrTransactionResultCode._internal(-16);

  static const txSOROBAN_INVALID =
      const XdrTransactionResultCode._internal(-17);

  static XdrTransactionResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return txSUCCESS;
      case 1:
        return txFEE_BUMP_INNER_SUCCESS;
      case -1:
        return txFAILED;
      case -2:
        return txTOO_EARLY;
      case -3:
        return txTOO_LATE;
      case -4:
        return txMISSING_OPERATION;
      case -5:
        return txBAD_SEQ;
      case -6:
        return txBAD_AUTH;
      case -7:
        return txINSUFFICIENT_BALANCE;
      case -8:
        return txNO_ACCOUNT;
      case -9:
        return txINSUFFICIENT_FEE;
      case -10:
        return txBAD_AUTH_EXTRA;
      case -11:
        return txINTERNAL_ERROR;
      case -12:
        return txNOT_SUPPORTED;
      case -13:
        return txFEE_BUMP_INNER_FAILED;
      case -14:
        return txBAD_SPONSORSHIP;
      case -15:
        return txMALFORMED;
      case -16:
        return txBAD_MIN_SEQ_AGE_OR_GAP;
      case -17:
        return txSOROBAN_INVALID;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrTransactionResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrEnvelopeType {
  final _value;
  const XdrEnvelopeType._internal(this._value);
  toString() => 'EnvelopeType.$_value';
  XdrEnvelopeType(this._value);
  get value => this._value;

  static const ENVELOPE_TYPE_TX_V0 = const XdrEnvelopeType._internal(0);
  static const ENVELOPE_TYPE_SCP = const XdrEnvelopeType._internal(1);
  static const ENVELOPE_TYPE_TX = const XdrEnvelopeType._internal(2);
  static const ENVELOPE_TYPE_AUTH = const XdrEnvelopeType._internal(3);
  static const ENVELOPE_TYPE_SCPVALUE = const XdrEnvelopeType._internal(4);
  static const ENVELOPE_TYPE_TX_FEE_BUMP = const XdrEnvelopeType._internal(5);
  static const ENVELOPE_TYPE_OP_ID = const XdrEnvelopeType._internal(6);
  static const ENVELOPE_TYPE_POOL_REVOKE_OP_ID =
      const XdrEnvelopeType._internal(7);
  static const ENVELOPE_TYPE_CONTRACT_ID = const XdrEnvelopeType._internal(8);
  static const ENVELOPE_TYPE_SOROBAN_AUTHORIZATION =
      const XdrEnvelopeType._internal(9);

  static XdrEnvelopeType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ENVELOPE_TYPE_TX_V0;
      case 1:
        return ENVELOPE_TYPE_SCP;
      case 2:
        return ENVELOPE_TYPE_TX;
      case 3:
        return ENVELOPE_TYPE_AUTH;
      case 4:
        return ENVELOPE_TYPE_SCPVALUE;
      case 5:
        return ENVELOPE_TYPE_TX_FEE_BUMP;
      case 6:
        return ENVELOPE_TYPE_OP_ID;
      case 7:
        return ENVELOPE_TYPE_POOL_REVOKE_OP_ID;
      case 8:
        return ENVELOPE_TYPE_CONTRACT_ID;
      case 9:
        return ENVELOPE_TYPE_SOROBAN_AUTHORIZATION;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrEnvelopeType value) {
    stream.writeInt(value.value);
  }
}

class XdrSorobanAuthorizedFunctionType {
  final _value;
  const XdrSorobanAuthorizedFunctionType._internal(this._value);
  toString() => 'XdrSorobanAuthorizedFunctionType.$_value';
  XdrSorobanAuthorizedFunctionType(this._value);
  get value => this._value;

  static const SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN =
      const XdrSorobanAuthorizedFunctionType._internal(0);
  static const SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN =
      const XdrSorobanAuthorizedFunctionType._internal(1);
  static const SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN =
      const XdrSorobanAuthorizedFunctionType._internal(2);

  static XdrSorobanAuthorizedFunctionType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN;
      case 1:
        return SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN;
      case 2:
        return SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAuthorizedFunctionType value) {
    stream.writeInt(value.value);
  }
}

class XdrSorobanAuthorizedFunction {
  XdrSorobanAuthorizedFunction(this._type);
  XdrSorobanAuthorizedFunctionType _type;
  XdrSorobanAuthorizedFunctionType get type => this._type;
  set type(XdrSorobanAuthorizedFunctionType value) => this._type = value;

  XdrInvokeContractArgs? _contractFn;
  XdrInvokeContractArgs? get contractFn => this._contractFn;
  set contractFn(XdrInvokeContractArgs? value) => this._contractFn = value;

  XdrCreateContractArgs? _createContractHostFn;
  XdrCreateContractArgs? get createContractHostFn => this._createContractHostFn;
  set createContractHostFn(XdrCreateContractArgs? value) =>
      this._createContractHostFn = value;

  XdrCreateContractArgsV2? _createContractV2HostFn;
  XdrCreateContractArgsV2? get createContractV2HostFn =>
      this._createContractV2HostFn;
  set createContractV2HostFn(XdrCreateContractArgsV2? value) =>
      this._createContractV2HostFn = value;

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAuthorizedFunction encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN:
        XdrInvokeContractArgs.encode(stream, encoded.contractFn!);
        break;
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN:
        XdrCreateContractArgs.encode(stream, encoded.createContractHostFn!);
        break;
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN:
        XdrCreateContractArgsV2.encode(stream, encoded.createContractV2HostFn!);
        break;
    }
  }

  static XdrSorobanAuthorizedFunction decode(XdrDataInputStream stream) {
    XdrSorobanAuthorizedFunction decoded = XdrSorobanAuthorizedFunction(
        XdrSorobanAuthorizedFunctionType.decode(stream));
    switch (decoded.type) {
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN:
        decoded.contractFn = XdrInvokeContractArgs.decode(stream);
        break;
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN:
        decoded.createContractHostFn = XdrCreateContractArgs.decode(stream);
        break;
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN:
        decoded.createContractV2HostFn = XdrCreateContractArgsV2.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrSorobanAuthorizedFunction forInvokeContractArgs(
      XdrInvokeContractArgs args) {
    var result = XdrSorobanAuthorizedFunction(XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
    result.contractFn = args;
    return result;
  }

  static XdrSorobanAuthorizedFunction forCreateContractArgs(
      XdrCreateContractArgs args) {
    var result = XdrSorobanAuthorizedFunction(XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN);
    result.createContractHostFn = args;
    return result;
  }

  static XdrSorobanAuthorizedFunction forCreateContractArgsV2(
      XdrCreateContractArgsV2 args) {
    var result = XdrSorobanAuthorizedFunction(XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN);
    result.createContractV2HostFn = args;
    return result;
  }
}

class XdrSorobanAuthorizedInvocation {
  XdrSorobanAuthorizedFunction _function;
  XdrSorobanAuthorizedFunction get function => this._function;
  set function(XdrSorobanAuthorizedFunction value) => this._function = value;

  List<XdrSorobanAuthorizedInvocation> _subInvocations;
  List<XdrSorobanAuthorizedInvocation> get subInvocations =>
      this._subInvocations;
  set subInvocations(List<XdrSorobanAuthorizedInvocation> value) =>
      this._subInvocations = value;

  XdrSorobanAuthorizedInvocation(this._function, this._subInvocations);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAuthorizedInvocation encoded) {
    XdrSorobanAuthorizedFunction.encode(stream, encoded.function);
    int subSize = encoded.subInvocations.length;
    stream.writeInt(subSize);
    for (int i = 0; i < subSize; i++) {
      XdrSorobanAuthorizedInvocation.encode(stream, encoded.subInvocations[i]);
    }
  }

  static XdrSorobanAuthorizedInvocation decode(XdrDataInputStream stream) {
    XdrSorobanAuthorizedFunction function =
        XdrSorobanAuthorizedFunction.decode(stream);

    int subSize = stream.readInt();
    List<XdrSorobanAuthorizedInvocation> subs =
        List<XdrSorobanAuthorizedInvocation>.empty(growable: true);
    for (int i = 0; i < subSize; i++) {
      subs.add(XdrSorobanAuthorizedInvocation.decode(stream));
    }
    return XdrSorobanAuthorizedInvocation(function, subs);
  }
}

class XdrSorobanAddressCredentials {
  XdrSCAddress _address;
  XdrSCAddress get address => this._address;
  set address(XdrSCAddress value) => this._address = value;

  XdrInt64 _nonce;
  XdrInt64 get nonce => this._nonce;
  set nonce(XdrInt64 value) => this._nonce = value;

  XdrUint32 _signatureExpirationLedger;
  XdrUint32 get signatureExpirationLedger => this._signatureExpirationLedger;
  set signatureExpirationLedger(XdrUint32 value) =>
      this._signatureExpirationLedger = value;

  XdrSCVal _signature;
  XdrSCVal get signature => this._signature;
  set signature(XdrSCVal value) => this._signature = value;

  XdrSorobanAddressCredentials(this._address, this._nonce,
      this._signatureExpirationLedger, this._signature);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAddressCredentials encoded) {
    XdrSCAddress.encode(stream, encoded.address);
    XdrInt64.encode(stream, encoded.nonce);
    XdrUint32.encode(stream, encoded.signatureExpirationLedger);
    XdrSCVal.encode(stream, encoded.signature);
  }

  static XdrSorobanAddressCredentials decode(XdrDataInputStream stream) {
    XdrSCAddress address = XdrSCAddress.decode(stream);
    XdrInt64 nonce = XdrInt64.decode(stream);
    XdrUint32 signatureExpirationLedger = XdrUint32.decode(stream);

    XdrSCVal signature = XdrSCVal.decode(stream);

    return XdrSorobanAddressCredentials(
        address, nonce, signatureExpirationLedger, signature);
  }
}

class XdrSorobanAuthorizationEntry {
  XdrSorobanCredentials _credentials;
  XdrSorobanCredentials get credentials => this._credentials;
  set credentials(XdrSorobanCredentials value) => this._credentials = value;

  XdrSorobanAuthorizedInvocation _rootInvocation;
  XdrSorobanAuthorizedInvocation get rootInvocation => this._rootInvocation;
  set rootInvocation(XdrSorobanAuthorizedInvocation value) =>
      this._rootInvocation = value;

  XdrSorobanAuthorizationEntry(this._credentials, this._rootInvocation);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAuthorizationEntry encoded) {
    XdrSorobanCredentials.encode(stream, encoded.credentials);
    XdrSorobanAuthorizedInvocation.encode(stream, encoded.rootInvocation);
  }

  static XdrSorobanAuthorizationEntry decode(XdrDataInputStream stream) {
    XdrSorobanCredentials credentials = XdrSorobanCredentials.decode(stream);
    XdrSorobanAuthorizedInvocation rootInvocation =
        XdrSorobanAuthorizedInvocation.decode(stream);

    return XdrSorobanAuthorizationEntry(credentials, rootInvocation);
  }
}

class XdrHashIDPreimage {
  XdrHashIDPreimage(this._type);
  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrHashIDPreimageOperationID? _operationID;
  XdrHashIDPreimageOperationID? get operationID => this._operationID;
  set operationID(XdrHashIDPreimageOperationID? value) =>
      this._operationID = value;

  XdrHashIDPreimageRevokeID? _revokeID;
  XdrHashIDPreimageRevokeID? get revokeID => this._revokeID;
  set revokeID(XdrHashIDPreimageRevokeID? value) => this._revokeID = value;

  XdrHashIDPreimageContractID? _contractID;
  XdrHashIDPreimageContractID? get contractID => this._contractID;
  set contractID(XdrHashIDPreimageContractID? value) =>
      this._contractID = value;

  XdrHashIDPreimageSorobanAuthorization? _sorobanAuthorization;
  XdrHashIDPreimageSorobanAuthorization? get sorobanAuthorization =>
      this._sorobanAuthorization;
  set sorobanAuthorization(XdrHashIDPreimageSorobanAuthorization? value) =>
      this._sorobanAuthorization = value;

  static void encode(XdrDataOutputStream stream, XdrHashIDPreimage encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        XdrHashIDPreimageOperationID.encode(stream, encoded.operationID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
        XdrHashIDPreimageRevokeID.encode(stream, encoded.revokeID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID:
        XdrHashIDPreimageContractID.encode(stream, encoded.contractID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION:
        XdrHashIDPreimageSorobanAuthorization.encode(
            stream, encoded.sorobanAuthorization!);
        break;
    }
  }

  static XdrHashIDPreimage decode(XdrDataInputStream stream) {
    XdrHashIDPreimage decoded =
        XdrHashIDPreimage(XdrEnvelopeType.decode(stream));
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        decoded.operationID = XdrHashIDPreimageOperationID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
        decoded.revokeID = XdrHashIDPreimageRevokeID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID:
        decoded.contractID = XdrHashIDPreimageContractID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION:
        decoded.sorobanAuthorization =
            XdrHashIDPreimageSorobanAuthorization.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrHashIDPreimageContractID {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrContractIDPreimage _contractIDPreimage;
  XdrContractIDPreimage get contractIDPreimage => this._contractIDPreimage;
  set contractIDPreimage(XdrContractIDPreimage value) =>
      this._contractIDPreimage = value;

  XdrHashIDPreimageContractID(this._networkID, this._contractIDPreimage);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageContractID encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrContractIDPreimage.encode(stream, encoded.contractIDPreimage);
  }

  static XdrHashIDPreimageContractID decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrContractIDPreimage contractIDPreimage =
        XdrContractIDPreimage.decode(stream);
    return XdrHashIDPreimageContractID(networkID, contractIDPreimage);
  }
}

class XdrHashIDPreimageSorobanAuthorization {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrInt64 _nonce;
  XdrInt64 get nonce => this._nonce;
  set nonce(XdrInt64 value) => this._nonce = value;

  XdrUint32 _signatureExpirationLedger;
  XdrUint32 get signatureExpirationLedger => this._signatureExpirationLedger;
  set signatureExpirationLedger(XdrUint32 value) =>
      this._signatureExpirationLedger = value;

  XdrSorobanAuthorizedInvocation _invocation;
  XdrSorobanAuthorizedInvocation get invocation => this._invocation;
  set invocation(XdrSorobanAuthorizedInvocation value) =>
      this._invocation = value;

  XdrHashIDPreimageSorobanAuthorization(this._networkID, this._nonce,
      this._signatureExpirationLedger, this._invocation);

  static void encode(XdrDataOutputStream stream,
      XdrHashIDPreimageSorobanAuthorization encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrInt64.encode(stream, encoded.nonce);
    XdrUint32.encode(stream, encoded.signatureExpirationLedger);
    XdrSorobanAuthorizedInvocation.encode(stream, encoded.invocation);
  }

  static XdrHashIDPreimageSorobanAuthorization decode(
      XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrInt64 nonce = XdrInt64.decode(stream);
    XdrUint32 signatureExpirationLedger = XdrUint32.decode(stream);
    XdrSorobanAuthorizedInvocation invocation =
        XdrSorobanAuthorizedInvocation.decode(stream);
    return XdrHashIDPreimageSorobanAuthorization(
        networkID, nonce, signatureExpirationLedger, invocation);
  }
}

class XdrHashIDPreimageRevokeID {
  XdrHashIDPreimageRevokeID(this._accountID, this._seqNum, this._opNum,
      this._liquidityPoolID, this._asset);

  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _opNum;
  XdrUint32 get opNum => this._opNum;
  set opNum(XdrUint32 value) => this._opNum = value;

  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageRevokeID encoded) {
    XdrAccountID.encode(stream, encoded.accountID);
    XdrSequenceNumber.encode(stream, encoded.seqNum);
    XdrUint32.encode(stream, encoded.opNum);
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrAsset.encode(stream, encoded.asset);
  }

  static XdrHashIDPreimageRevokeID decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrUint32 opNum = XdrUint32.decode(stream);
    XdrHash liquidityPoolID = XdrHash.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    return XdrHashIDPreimageRevokeID(
        accountID, seqNum, opNum, liquidityPoolID, asset);
  }
}

class XdrHashIDPreimageOperationID {
  XdrHashIDPreimageOperationID(this._sourceAccount, this._seqNum, this._opNum);

  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _opNum;
  XdrUint32 get opNum => this._opNum;
  set opNum(XdrUint32 value) => this._opNum = value;

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageOperationID encoded) {
    XdrMuxedAccount.encode(stream, encoded.sourceAccount);
    XdrSequenceNumber.encode(stream, encoded.seqNum);
    XdrUint32.encode(stream, encoded.opNum);
  }

  static XdrHashIDPreimageOperationID decode(XdrDataInputStream stream) {
    XdrMuxedAccount sourceAccount = XdrMuxedAccount.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrUint32 opNum = XdrUint32.decode(stream);
    return XdrHashIDPreimageOperationID(sourceAccount, seqNum, opNum);
  }
}

class XdrTimeBounds {
  XdrTimeBounds(this._minTime, this._maxTime);
  XdrUint64 _minTime;
  XdrUint64 get minTime => this._minTime;
  set minTime(XdrUint64 value) => this._minTime = value;

  XdrUint64 _maxTime;
  XdrUint64 get maxTime => this._maxTime;
  set maxTime(XdrUint64 value) => this._maxTime = value;

  static void encode(
      XdrDataOutputStream stream, XdrTimeBounds encodedTimeBounds) {
    XdrUint64.encode(stream, encodedTimeBounds.minTime);
    XdrUint64.encode(stream, encodedTimeBounds.maxTime);
  }

  static XdrTimeBounds decode(XdrDataInputStream stream) {
    XdrTimeBounds decodedTimeBounds =
        XdrTimeBounds(XdrUint64.decode(stream), XdrUint64.decode(stream));
    return decodedTimeBounds;
  }
}

class XdrLedgerBounds {
  XdrLedgerBounds(this._minLedger, this._maxLedger);
  XdrUint32 _minLedger;
  XdrUint32 get minLedger => this._minLedger;
  set minLedger(XdrUint32 value) => this._minLedger = value;

  XdrUint32 _maxLedger;
  XdrUint32 get maxLedger => this._maxLedger;
  set maxLedger(XdrUint32 value) => this._maxLedger = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerBounds encoded) {
    XdrUint32.encode(stream, encoded.minLedger);
    XdrUint32.encode(stream, encoded.maxLedger);
  }

  static XdrLedgerBounds decode(XdrDataInputStream stream) {
    XdrLedgerBounds decoded =
        XdrLedgerBounds(XdrUint32.decode(stream), XdrUint32.decode(stream));
    return decoded;
  }
}

class XdrPreconditionType {
  final _value;

  const XdrPreconditionType._internal(this._value);

  toString() => 'PreconditionType.$_value';

  XdrPreconditionType(this._value);

  get value => this._value;

  static const NONE = const XdrPreconditionType._internal(0);
  static const TIME = const XdrPreconditionType._internal(1);
  static const V2 = const XdrPreconditionType._internal(2);

  static XdrPreconditionType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return NONE;
      case 1:
        return TIME;
      case 2:
        return V2;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrPreconditionType value) {
    stream.writeInt(value.value);
  }
}

class XdrPreconditionsV2 {
  XdrPreconditionsV2(
      this._minSeqAge, this._minSeqLedgerGap, this._extraSigners);

  XdrTimeBounds? _timeBounds;
  XdrTimeBounds? get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds? value) => this._timeBounds = value;

  XdrLedgerBounds? _ledgerBounds;
  XdrLedgerBounds? get ledgerBounds => this._ledgerBounds;
  set ledgerBounds(XdrLedgerBounds? value) => this._ledgerBounds = value;

  XdrBigInt64? _sequenceNumber;
  XdrBigInt64? get sequenceNumber => this._sequenceNumber;
  set sequenceNumber(XdrBigInt64? value) => this._sequenceNumber = value;

  XdrUint64 _minSeqAge;
  XdrUint64 get minSeqAge => this._minSeqAge;
  set minSeqAge(XdrUint64 value) => this._minSeqAge = value;

  XdrUint32 _minSeqLedgerGap;
  XdrUint32 get minSeqLedgerGap => this._minSeqLedgerGap;
  set minSeqLedgerGap(XdrUint32 value) => this._minSeqLedgerGap = value;

  List<XdrSignerKey> _extraSigners;
  List<XdrSignerKey> get extraSigners => this._extraSigners;
  set extraSigners(List<XdrSignerKey> value) => this._extraSigners = value;

  static void encode(XdrDataOutputStream stream, XdrPreconditionsV2 encoded) {
    if (encoded._timeBounds != null) {
      stream.writeInt(1);
      XdrTimeBounds.encode(stream, encoded._timeBounds!);
    } else {
      stream.writeInt(0);
    }
    if (encoded._ledgerBounds != null) {
      stream.writeInt(1);
      XdrLedgerBounds.encode(stream, encoded._ledgerBounds!);
    } else {
      stream.writeInt(0);
    }

    if (encoded.sequenceNumber != null) {
      stream.writeInt(1);
      XdrBigInt64.encode(stream, encoded.sequenceNumber!);
    } else {
      stream.writeInt(0);
    }

    XdrUint64.encode(stream, encoded.minSeqAge);
    XdrUint32.encode(stream, encoded.minSeqLedgerGap);
    int signersSize = encoded.extraSigners.length;
    stream.writeInt(signersSize);
    for (int i = 0; i < signersSize; i++) {
      XdrSignerKey.encode(stream, encoded.extraSigners[i]);
    }
  }

  static XdrPreconditionsV2 decode(XdrDataInputStream stream) {
    XdrTimeBounds? tb;
    XdrLedgerBounds? lb;
    XdrBigInt64? sqN;

    int timeBoundsPresent = stream.readInt();
    if (timeBoundsPresent != 0) {
      tb = XdrTimeBounds.decode(stream);
    }

    int ledgerBoundsPresent = stream.readInt();
    if (ledgerBoundsPresent != 0) {
      lb = XdrLedgerBounds.decode(stream);
    }

    int sequenceNumberPresent = stream.readInt();
    if (sequenceNumberPresent != 0) {
      sqN = XdrBigInt64.decode(stream);
    }

    XdrUint64 minSA = XdrUint64.decode(stream);
    XdrUint32 minSLG = XdrUint32.decode(stream);

    int signersSize = stream.readInt();
    List<XdrSignerKey> keys = List<XdrSignerKey>.empty(growable: true);
    for (int i = 0; i < signersSize; i++) {
      keys.add(XdrSignerKey.decode(stream));
    }

    XdrPreconditionsV2 decoded = XdrPreconditionsV2(minSA, minSLG, keys);

    if (tb != null) {
      decoded.timeBounds = tb;
    }
    if (lb != null) {
      decoded.ledgerBounds = lb;
    }
    if (sqN != null) {
      decoded.sequenceNumber = sqN;
    }
    return decoded;
  }
}

class XdrPreconditions {
  XdrPreconditions(this._type);

  XdrPreconditionType _type;
  XdrPreconditionType get discriminant => this._type;
  set discriminant(XdrPreconditionType value) => this._type = value;

  XdrTimeBounds? _timeBounds;
  XdrTimeBounds? get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds? value) => this._timeBounds = value;

  XdrPreconditionsV2? _v2;
  XdrPreconditionsV2? get v2 => this._v2;
  set v2(XdrPreconditionsV2? value) => this._v2 = value;

  static void encode(XdrDataOutputStream stream, XdrPreconditions encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrPreconditionType.NONE:
        break;
      case XdrPreconditionType.TIME:
        XdrTimeBounds.encode(stream, encoded.timeBounds!);
        break;
      case XdrPreconditionType.V2:
        XdrPreconditionsV2.encode(stream, encoded.v2!);
        break;
    }
  }

  static XdrPreconditions decode(XdrDataInputStream stream) {
    XdrPreconditions decoded =
        XdrPreconditions(XdrPreconditionType.decode(stream));
    switch (decoded.discriminant) {
      case XdrPreconditionType.NONE:
        break;
      case XdrPreconditionType.TIME:
        decoded.timeBounds = XdrTimeBounds.decode(stream);
        break;
      case XdrPreconditionType.V2:
        decoded.v2 = XdrPreconditionsV2.decode(stream);
        break;
    }
    return decoded;
  }
}
