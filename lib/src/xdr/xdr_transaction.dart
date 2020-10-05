// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_signing.dart';
import 'xdr_operation.dart';
import 'xdr_ledger.dart';
import 'xdr_account.dart';
import 'xdr_memo.dart';
import "dart:convert";
import 'dart:typed_data';

class XdrTransaction {
  XdrTransaction();
  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrUint32 _fee;
  XdrUint32 get fee => this._fee;
  set fee(XdrUint32 value) => this._fee = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrTimeBounds _timeBounds;
  XdrTimeBounds get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds value) => this._timeBounds = value;

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
    if (encodedTransaction._timeBounds != null) {
      stream.writeInt(1);
      XdrTimeBounds.encode(stream, encodedTransaction._timeBounds);
    } else {
      stream.writeInt(0);
    }
    XdrMemo.encode(stream, encodedTransaction._memo);
    int operationsSize = encodedTransaction.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperation.encode(stream, encodedTransaction._operations[i]);
    }
    XdrTransactionExt.encode(stream, encodedTransaction._ext);
  }

  static XdrTransaction decode(XdrDataInputStream stream) {
    XdrTransaction decodedTransaction = XdrTransaction();
    decodedTransaction._sourceAccount = XdrMuxedAccount.decode(stream);
    decodedTransaction._fee = XdrUint32.decode(stream);
    decodedTransaction._seqNum = XdrSequenceNumber.decode(stream);
    int timeBoundsPresent = stream.readInt();
    if (timeBoundsPresent != 0) {
      decodedTransaction._timeBounds = XdrTimeBounds.decode(stream);
    }
    decodedTransaction._memo = XdrMemo.decode(stream);
    int operationssize = stream.readInt();
    decodedTransaction._operations = List<XdrOperation>(operationssize);
    for (int i = 0; i < operationssize; i++) {
      decodedTransaction._operations[i] = XdrOperation.decode(stream);
    }
    decodedTransaction._ext = XdrTransactionExt.decode(stream);
    return decodedTransaction;
  }
}

class XdrTransactionExt {
  XdrTransactionExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionExt encodedTransactionExt) {
    stream.writeInt(encodedTransactionExt.discriminant);
    switch (encodedTransactionExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionExt decode(XdrDataInputStream stream) {
    XdrTransactionExt decodedTransactionExt = XdrTransactionExt();
    int discriminant = stream.readInt();
    decodedTransactionExt.discriminant = discriminant;
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}

class XdrFeeBumpTransaction {
  XdrFeeBumpTransaction();
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
    XdrFeeBumpTransaction decodedTransaction = XdrFeeBumpTransaction();
    decodedTransaction._feeSource = XdrMuxedAccount.decode(stream);
    decodedTransaction._fee = XdrInt64.decode(stream);
    decodedTransaction._innerTx = XdrFeeBumpTransactionInnerTx.decode(stream);
    decodedTransaction._ext = XdrFeeBumpTransactionExt.decode(stream);

    return decodedTransaction;
  }
}

class XdrFeeBumpTransactionInnerTx {
  XdrFeeBumpTransactionInnerTx();

  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransactionV1Envelope _v1;
  XdrTransactionV1Envelope get v1 => this._v1;
  set v1(XdrTransactionV1Envelope value) => this._v1 = value;

  static void encode(XdrDataOutputStream stream,
      XdrFeeBumpTransactionInnerTx encodedTransaction) {
    stream.writeInt(encodedTransaction.discriminant.value);
    switch (encodedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransactionV1Envelope.encode(stream, encodedTransaction.v1);
        break;
    }
  }

  static XdrFeeBumpTransactionInnerTx decode(XdrDataInputStream stream) {
    XdrFeeBumpTransactionInnerTx decoded = XdrFeeBumpTransactionInnerTx();
    decoded.discriminant = XdrEnvelopeType.decode(stream);
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decoded.v1 = XdrTransactionV1Envelope.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrFeeBumpTransactionExt {
  XdrFeeBumpTransactionExt();
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
    XdrFeeBumpTransactionExt decodedTransactionExt = XdrFeeBumpTransactionExt();
    int discriminant = stream.readInt();
    decodedTransactionExt.discriminant = discriminant;
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}

/// Transaction used before protocol 13.
class XdrTransactionV0 {
  XdrTransactionV0();
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

  XdrTimeBounds _timeBounds;
  XdrTimeBounds get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds value) => this._timeBounds = value;

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
      XdrTimeBounds.encode(stream, encodedTransaction._timeBounds);
    } else {
      stream.writeInt(0);
    }
    XdrMemo.encode(stream, encodedTransaction._memo);
    int operationssize = encodedTransaction.operations.length;
    stream.writeInt(operationssize);
    for (int i = 0; i < operationssize; i++) {
      XdrOperation.encode(stream, encodedTransaction._operations[i]);
    }
    XdrTransactionV0Ext.encode(stream, encodedTransaction._ext);
  }

  static XdrTransactionV0 decode(XdrDataInputStream stream) {
    XdrTransactionV0 decodedTransaction = XdrTransactionV0();
    decodedTransaction._sourceAccountEd25519 = XdrUint256.decode(stream);
    decodedTransaction._fee = XdrUint32.decode(stream);
    decodedTransaction._seqNum = XdrSequenceNumber.decode(stream);
    int timeBoundsPresent = stream.readInt();
    if (timeBoundsPresent != 0) {
      decodedTransaction._timeBounds = XdrTimeBounds.decode(stream);
    }
    decodedTransaction._memo = XdrMemo.decode(stream);
    int operationssize = stream.readInt();
    decodedTransaction._operations = List<XdrOperation>(operationssize);
    for (int i = 0; i < operationssize; i++) {
      decodedTransaction._operations[i] = XdrOperation.decode(stream);
    }
    decodedTransaction._ext = XdrTransactionV0Ext.decode(stream);
    return decodedTransaction;
  }
}

class XdrTransactionV0Ext {
  XdrTransactionV0Ext();
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
    XdrTransactionV0Ext decodedTransactionExt = XdrTransactionV0Ext();
    int discriminant = stream.readInt();
    decodedTransactionExt.discriminant = discriminant;
    switch (decodedTransactionExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionExt;
  }
}

class XdrTransactionEnvelope {
  XdrTransactionEnvelope();

  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransactionV1Envelope _v1;
  XdrTransactionV1Envelope get v1 => this._v1;
  set v1(XdrTransactionV1Envelope value) => this._v1 = value;

  XdrFeeBumpTransactionEnvelope _feeBump;
  XdrFeeBumpTransactionEnvelope get feeBump => this._feeBump;
  set feeBump(XdrFeeBumpTransactionEnvelope value) => this._feeBump = value;

  XdrTransactionV0Envelope _v0;
  XdrTransactionV0Envelope get v0 => this._v0;
  set v0(XdrTransactionV0Envelope value) => this._v0 = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionEnvelope encodedEnvelope) {
    stream.writeInt(encodedEnvelope.discriminant.value);
    switch (encodedEnvelope.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        XdrTransactionV0Envelope.encode(stream, encodedEnvelope.v0);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransactionV1Envelope.encode(stream, encodedEnvelope.v1);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        XdrFeeBumpTransactionEnvelope.encode(stream, encodedEnvelope.feeBump);
        break;
    }
  }

  static XdrTransactionEnvelope decode(XdrDataInputStream stream) {
    XdrTransactionEnvelope decoded = XdrTransactionEnvelope();
    decoded.discriminant = XdrEnvelopeType.decode(stream);
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
  XdrTransactionV1Envelope();

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
    XdrTransactionV1Envelope decodedTransactionEnvelope =
        XdrTransactionV1Envelope();
    decodedTransactionEnvelope._tx = XdrTransaction.decode(stream);
    int signaturesSize = stream.readInt();
    decodedTransactionEnvelope._signatures =
        List<XdrDecoratedSignature>(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      decodedTransactionEnvelope._signatures[i] =
          XdrDecoratedSignature.decode(stream);
    }
    return decodedTransactionEnvelope;
  }
}

class XdrFeeBumpTransactionEnvelope {
  XdrFeeBumpTransactionEnvelope();

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
    XdrFeeBumpTransactionEnvelope decodedTransactionEnvelope =
        XdrFeeBumpTransactionEnvelope();
    decodedTransactionEnvelope._tx = XdrFeeBumpTransaction.decode(stream);
    int signaturesSize = stream.readInt();
    decodedTransactionEnvelope._signatures =
        List<XdrDecoratedSignature>(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      decodedTransactionEnvelope._signatures[i] =
          XdrDecoratedSignature.decode(stream);
    }
    return decodedTransactionEnvelope;
  }
}

/// Transaction envelope used before protocol 13.
class XdrTransactionV0Envelope {
  XdrTransactionV0Envelope();

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
    XdrTransactionV0Envelope decodedTransactionEnvelope =
        XdrTransactionV0Envelope();
    decodedTransactionEnvelope._tx = XdrTransactionV0.decode(stream);
    int signaturesSize = stream.readInt();
    decodedTransactionEnvelope._signatures =
        List<XdrDecoratedSignature>(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      decodedTransactionEnvelope._signatures[i] =
          XdrDecoratedSignature.decode(stream);
    }
    return decodedTransactionEnvelope;
  }
}

class XdrTransactionMeta {
  XdrTransactionMeta();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  XdrTransactionMetaV1 _v1;
  XdrTransactionMetaV1 get v1 => this._v1;
  set v1(XdrTransactionMetaV1 value) => this._v1 = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionMeta encodedTransactionMeta) {
    stream.writeInt(encodedTransactionMeta.discriminant);
    switch (encodedTransactionMeta.discriminant) {
      case 0:
        int operationssize = encodedTransactionMeta.operations.length;
        stream.writeInt(operationssize);
        for (int i = 0; i < operationssize; i++) {
          XdrOperationMeta.encode(
              stream, encodedTransactionMeta._operations[i]);
        }
        break;
      case 1:
        XdrTransactionMetaV1.encode(stream, encodedTransactionMeta._v1);
        break;
    }
  }

  static XdrTransactionMeta decode(XdrDataInputStream stream) {
    XdrTransactionMeta decodedTransactionMeta = XdrTransactionMeta();
    int discriminant = stream.readInt();
    decodedTransactionMeta.discriminant = discriminant;
    switch (decodedTransactionMeta.discriminant) {
      case 0:
        int operationssize = stream.readInt();
        decodedTransactionMeta._operations =
            List<XdrOperationMeta>(operationssize);
        for (int i = 0; i < operationssize; i++) {
          decodedTransactionMeta._operations[i] =
              XdrOperationMeta.decode(stream);
        }
        break;
      case 1:
        decodedTransactionMeta._v1 = XdrTransactionMetaV1.decode(stream);
        break;
    }
    return decodedTransactionMeta;
  }
}

class XdrTransactionMetaV1 {
  XdrTransactionMetaV1();
  XdrLedgerEntryChanges _txChanges;
  XdrLedgerEntryChanges get txChanges => this._txChanges;
  set txChanges(XdrLedgerEntryChanges value) => this._txChanges = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionMetaV1 encodedTransactionMetaV1) {
    XdrLedgerEntryChanges.encode(stream, encodedTransactionMetaV1._txChanges);
    int operationssize = encodedTransactionMetaV1.operations.length;
    stream.writeInt(operationssize);
    for (int i = 0; i < operationssize; i++) {
      XdrOperationMeta.encode(stream, encodedTransactionMetaV1._operations[i]);
    }
  }

  static XdrTransactionMetaV1 decode(XdrDataInputStream stream) {
    XdrTransactionMetaV1 decodedTransactionMetaV1 = XdrTransactionMetaV1();
    decodedTransactionMetaV1._txChanges = XdrLedgerEntryChanges.decode(stream);
    int operationssize = stream.readInt();
    decodedTransactionMetaV1._operations =
        List<XdrOperationMeta>(operationssize);
    for (int i = 0; i < operationssize; i++) {
      decodedTransactionMetaV1._operations[i] = XdrOperationMeta.decode(stream);
    }
    return decodedTransactionMetaV1;
  }
}

class XdrTransactionResult {
  XdrTransactionResult();
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
    XdrTransactionResult decodedTransactionResult = XdrTransactionResult();
    decodedTransactionResult._feeCharged = XdrInt64.decode(stream);
    decodedTransactionResult._result =
        XdrTransactionResultResult.decode(stream);
    decodedTransactionResult._ext = XdrTransactionResultExt.decode(stream);
    return decodedTransactionResult;
  }
}

class XdrTransactionResultResult {
  XdrTransactionResultResult();
  XdrTransactionResultCode _code;
  XdrTransactionResultCode get discriminant => this._code;
  set discriminant(XdrTransactionResultCode value) => this._code = value;

  List<XdrOperationResult> _results;
  get results => this._results;
  set results(value) => this._results = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResultResult encodedTransactionResultResult) {
    stream.writeInt(encodedTransactionResultResult.discriminant.value);
    switch (encodedTransactionResultResult.discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultssize = encodedTransactionResultResult.results.length;
        stream.writeInt(resultssize);
        for (int i = 0; i < resultssize; i++) {
          XdrOperationResult.encode(
              stream, encodedTransactionResultResult._results[i]);
        }
        break;
      default:
        break;
    }
  }

  static XdrTransactionResultResult decode(XdrDataInputStream stream) {
    XdrTransactionResultResult decodedTransactionResultResult =
        XdrTransactionResultResult();
    XdrTransactionResultCode discriminant =
        XdrTransactionResultCode.decode(stream);
    decodedTransactionResultResult.discriminant = discriminant;
    switch (decodedTransactionResultResult.discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultssize = stream.readInt();
        decodedTransactionResultResult._results =
            List<XdrOperationResult>(resultssize);
        for (int i = 0; i < resultssize; i++) {
          decodedTransactionResultResult._results[i] =
              XdrOperationResult.decode(stream);
        }
        break;
      default:
        break;
    }
    return decodedTransactionResultResult;
  }
}

class XdrTransactionResultExt {
  XdrTransactionResultExt();
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
        XdrTransactionResultExt();
    int discriminant = stream.readInt();
    decodedTransactionResultExt.discriminant = discriminant;
    switch (decodedTransactionResultExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionResultExt;
  }
}

class XdrTransactionResultPair {
  XdrTransactionResultPair();
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
    XdrTransactionResultPair decodedTransactionResultPair =
        XdrTransactionResultPair();
    decodedTransactionResultPair._transactionHash = XdrHash.decode(stream);
    decodedTransactionResultPair._result = XdrTransactionResult.decode(stream);
    return decodedTransactionResultPair;
  }
}

class XdrTransactionResultSet {
  XdrTransactionResultSet();
  List<XdrTransactionResultPair> _results;
  List<XdrTransactionResultPair> get results => this._results;
  set results(List<XdrTransactionResultPair> value) => this._results = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionResultSet encodedTransactionResultSet) {
    int resultssize = encodedTransactionResultSet.results.length;
    stream.writeInt(resultssize);
    for (int i = 0; i < resultssize; i++) {
      XdrTransactionResultPair.encode(
          stream, encodedTransactionResultSet._results[i]);
    }
  }

  static XdrTransactionResultSet decode(XdrDataInputStream stream) {
    XdrTransactionResultSet decodedTransactionResultSet =
        XdrTransactionResultSet();
    int resultssize = stream.readInt();
    decodedTransactionResultSet._results =
        List<XdrTransactionResultPair>(resultssize);
    for (int i = 0; i < resultssize; i++) {
      decodedTransactionResultSet._results[i] =
          XdrTransactionResultPair.decode(stream);
    }
    return decodedTransactionResultSet;
  }
}

class XdrTransactionSet {
  XdrTransactionSet();
  XdrHash _previousLedgerHash;
  XdrHash get previousLedgerHash => this._previousLedgerHash;
  set previousLedgerHash(XdrHash value) => this._previousLedgerHash = value;

  List<XdrTransactionEnvelope> _txs;
  List<XdrTransactionEnvelope> get txs => this._txs;
  set txs(List<XdrTransactionEnvelope> value) => this._txs = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionSet encodedTransactionSet) {
    XdrHash.encode(stream, encodedTransactionSet._previousLedgerHash);
    int txssize = encodedTransactionSet.txs.length;
    stream.writeInt(txssize);
    for (int i = 0; i < txssize; i++) {
      XdrTransactionEnvelope.encode(stream, encodedTransactionSet._txs[i]);
    }
  }

  static XdrTransactionSet decode(XdrDataInputStream stream) {
    XdrTransactionSet decodedTransactionSet = XdrTransactionSet();
    decodedTransactionSet._previousLedgerHash = XdrHash.decode(stream);
    int txssize = stream.readInt();
    decodedTransactionSet._txs = List<XdrTransactionEnvelope>(txssize);
    for (int i = 0; i < txssize; i++) {
      decodedTransactionSet._txs[i] = XdrTransactionEnvelope.decode(stream);
    }
    return decodedTransactionSet;
  }
}

class XdrTransactionSignaturePayload {
  XdrTransactionSignaturePayload();
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
    XdrTransactionSignaturePayload decodedTransactionSignaturePayload =
        XdrTransactionSignaturePayload();
    decodedTransactionSignaturePayload._networkId = XdrHash.decode(stream);
    decodedTransactionSignaturePayload._taggedTransaction =
        XdrTransactionSignaturePayloadTaggedTransaction.decode(stream);
    return decodedTransactionSignaturePayload;
  }
}

class XdrTransactionSignaturePayloadTaggedTransaction {
  XdrTransactionSignaturePayloadTaggedTransaction();
  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransaction _tx;
  XdrTransaction get tx => this._tx;
  set tx(XdrTransaction value) => this._tx = value;

  static void encode(
      XdrDataOutputStream stream,
      XdrTransactionSignaturePayloadTaggedTransaction
          encodedTransactionSignaturePayloadTaggedTransaction) {
    stream.writeInt(
        encodedTransactionSignaturePayloadTaggedTransaction.discriminant.value);
    switch (encodedTransactionSignaturePayloadTaggedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransaction.encode(
            stream, encodedTransactionSignaturePayloadTaggedTransaction._tx);
        break;
    }
  }

  static XdrTransactionSignaturePayloadTaggedTransaction decode(
      XdrDataInputStream stream) {
    XdrTransactionSignaturePayloadTaggedTransaction
        decodedTransactionSignaturePayloadTaggedTransaction =
        XdrTransactionSignaturePayloadTaggedTransaction();
    XdrEnvelopeType discriminant = XdrEnvelopeType.decode(stream);
    decodedTransactionSignaturePayloadTaggedTransaction.discriminant =
        discriminant;
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
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrEnvelopeType value) {
    stream.writeInt(value.value);
  }
}

class XdrOperationID {
  XdrOperationID();
  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrOperationIDId _id;
  XdrOperationIDId get id => this._id;
  set id(XdrOperationIDId value) => this.id = value;

  static void encode(XdrDataOutputStream stream, XdrOperationID encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        XdrOperationIDId.encode(stream, encoded.id);
        break;
    }
  }

  static XdrOperationID decode(XdrDataInputStream stream) {
    XdrOperationID decoded = XdrOperationID();
    XdrEnvelopeType discriminant = XdrEnvelopeType.decode(stream);
    decoded.discriminant = discriminant;
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        decoded.id = XdrOperationIDId.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrOperationIDId {
  XdrOperationIDId();

  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _opNum;
  XdrUint32 get opNum => this._opNum;
  set opNum(XdrUint32 value) => this._opNum = value;

  static void encode(XdrDataOutputStream stream, XdrOperationIDId encoded) {
    XdrMuxedAccount.encode(stream, encoded.sourceAccount);
    XdrSequenceNumber.encode(stream, encoded.seqNum);
    XdrUint32.encode(stream, encoded.opNum);
  }

  static XdrOperationIDId decode(XdrDataInputStream stream) {
    XdrOperationIDId decoded = XdrOperationIDId();
    decoded.sourceAccount = XdrMuxedAccount.decode(stream);
    decoded.seqNum = XdrSequenceNumber.decode(stream);
    decoded.opNum = XdrUint32.decode(stream);
    return decoded;
  }
}

class XdrTimeBounds {
  XdrTimeBounds();
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
    XdrTimeBounds decodedTimeBounds = XdrTimeBounds();
    decodedTimeBounds.minTime = XdrUint64.decode(stream);
    decodedTimeBounds.maxTime = XdrUint64.decode(stream);
    return decodedTimeBounds;
  }
}
