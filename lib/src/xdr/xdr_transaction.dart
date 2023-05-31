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

class XdrOperationEvents {
  List<XdrContractEvent> _events;
  List<XdrContractEvent> get events => this._events;
  set events(List<XdrContractEvent> value) => this._events = value;

  /*List<XdrOperationDiagnosticEvents> _diagnosticEvents;
  List<XdrOperationDiagnosticEvents> get diagnosticEvents => this._diagnosticEvents;
  set diagnosticEvents(List<XdrOperationDiagnosticEvents> value) => this._diagnosticEvents = value;*/

  XdrOperationEvents(this._events); //, this._diagnosticEvents);

  static void encode(XdrDataOutputStream stream, XdrOperationEvents encoded) {
    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrContractEvent.encode(stream, encoded.events[i]);
    }

    /*eventsSize = encoded.diagnosticEvents.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrOperationDiagnosticEvents.encode(stream, encoded.diagnosticEvents[i]);
    }*/
  }

  static XdrOperationEvents decode(XdrDataInputStream stream) {
    int eventsSize = stream.readInt();
    List<XdrContractEvent> events =
        List<XdrContractEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrContractEvent.decode(stream));
    }

    /*eventsSize = stream.readInt();
    List<XdrOperationDiagnosticEvents> diagnosticEvents =
    List<XdrOperationDiagnosticEvents>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      diagnosticEvents.add(XdrOperationDiagnosticEvents.decode(stream));
    }*/

    return XdrOperationEvents(events); //, diagnosticEvents);
  }
}

class XdrTransactionMetaV3 {
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

  List<XdrOperationEvents> _events;
  List<XdrOperationEvents> get events => this._events;
  set events(List<XdrOperationEvents> value) => this._events = value;

  XdrTransactionResult _txResult;
  XdrTransactionResult get txResult => this._txResult;
  set txResult(XdrTransactionResult value) => this._txResult = value;

  List<XdrHash> _hashes;
  List<XdrHash> get hashes => this._hashes;
  set hashes(List<XdrHash> value) => this._hashes = value;

  List<XdrOperationDiagnosticEvents> _diagnosticEvents;
  List<XdrOperationDiagnosticEvents> get diagnosticEvents =>
      this._diagnosticEvents;
  set diagnosticEvents(List<XdrOperationDiagnosticEvents> value) =>
      this._diagnosticEvents = value;

  XdrTransactionMetaV3(
      this._txChangesBefore,
      this._operations,
      this._txChangesAfter,
      this._events,
      this._txResult,
      this._hashes,
      this._diagnosticEvents);

  static void encode(XdrDataOutputStream stream, XdrTransactionMetaV3 encoded) {
    XdrLedgerEntryChanges.encode(stream, encoded._txChangesBefore);
    int operationsSize = encoded.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encoded._operations[i]);
    }

    XdrLedgerEntryChanges.encode(stream, encoded._txChangesAfter);

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrOperationEvents.encode(stream, encoded._events[i]);
    }

    XdrTransactionResult.encode(stream, encoded._txResult);

    int hashesSize = encoded.hashes.length;
    //stream.writeInt(hashesSize);
    for (int i = 0; i < hashesSize; i++) {
      XdrHash.encode(stream, encoded._hashes[i]);
    }

    int diagnosticEventsSize = encoded.diagnosticEvents.length;
    stream.writeInt(diagnosticEventsSize);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      XdrOperationDiagnosticEvents.encode(stream, encoded.diagnosticEvents[i]);
    }
  }

  static XdrTransactionMetaV3 decode(XdrDataInputStream stream) {
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    int eventsSize = stream.readInt();
    List<XdrOperationEvents> events =
        List<XdrOperationEvents>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrOperationEvents.decode(stream));
    }

    XdrTransactionResult txResult = XdrTransactionResult.decode(stream);

    int hashesSize = 3; //stream.readInt();
    List<XdrHash> hashes = List<XdrHash>.empty(growable: true);
    for (int i = 0; i < hashesSize; i++) {
      hashes.add(XdrHash.decode(stream));
    }

    int diagnosticEventsSize = stream.readInt();
    List<XdrOperationDiagnosticEvents> diagnosticEvents =
        List<XdrOperationDiagnosticEvents>.empty(growable: true);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      diagnosticEvents.add(XdrOperationDiagnosticEvents.decode(stream));
    }

    return XdrTransactionMetaV3(txChangesBefore, operations, txChangesAfter,
        events, txResult, hashes, diagnosticEvents);
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

class XdrSorobanResources {
  XdrLedgerFootprint _footprint;
  XdrLedgerFootprint get footprint => this._footprint;
  set footprint(XdrLedgerFootprint value) => this._footprint = value;

  XdrUint32 _instructions;
  XdrUint32 get instructions => this._instructions;
  set instructions(XdrUint32 value) => this._instructions = value;

  XdrUint32 _readBytes;
  XdrUint32 get readBytes => this._readBytes;
  set readBytes(XdrUint32 value) => this._readBytes = value;

  XdrUint32 _writeBytes;
  XdrUint32 get writeBytes => this._writeBytes;
  set writeBytes(XdrUint32 value) => this._writeBytes = value;

  XdrUint32 _extendedMetaDataSizeBytes;
  XdrUint32 get extendedMetaDataSizeBytes => this._extendedMetaDataSizeBytes;
  set extendedMetaDataSizeBytes(XdrUint32 value) =>
      this._extendedMetaDataSizeBytes = value;

  XdrSorobanResources(this._footprint, this._instructions, this._readBytes,
      this._writeBytes, this._extendedMetaDataSizeBytes);

  static void encode(XdrDataOutputStream stream, XdrSorobanResources encoded) {
    XdrLedgerFootprint.encode(stream, encoded.footprint);
    XdrUint32.encode(stream, encoded.instructions);
    XdrUint32.encode(stream, encoded.readBytes);
    XdrUint32.encode(stream, encoded.writeBytes);
    XdrUint32.encode(stream, encoded.extendedMetaDataSizeBytes);
  }

  static XdrSorobanResources decode(XdrDataInputStream stream) {
    XdrLedgerFootprint footprint = XdrLedgerFootprint.decode(stream);
    XdrUint32 instructions = XdrUint32.decode(stream);
    XdrUint32 readBytes = XdrUint32.decode(stream);
    XdrUint32 writeBytes = XdrUint32.decode(stream);
    XdrUint32 extendedMetaDataSizeBytes = XdrUint32.decode(stream);
    return XdrSorobanResources(footprint, instructions, readBytes, writeBytes,
        extendedMetaDataSizeBytes);
  }
}

class XdrSorobanTransactionData {
  XdrSorobanResources _resources;
  XdrSorobanResources get resources => this._resources;
  set resources(XdrSorobanResources value) => this._resources = value;

  XdrInt64 _refundableFee;
  XdrInt64 get refundableFee => this._refundableFee;
  set refundableFee(XdrInt64 value) => this._refundableFee = value;

  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrSorobanTransactionData(this._resources, this._refundableFee, this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionData encoded) {
    XdrSorobanResources.encode(stream, encoded.resources);
    XdrInt64.encode(stream, encoded.refundableFee);
    XdrExtensionPoint.encode(stream, encoded.ext);
  }

  static XdrSorobanTransactionData decode(XdrDataInputStream stream) {
    XdrSorobanResources resources = XdrSorobanResources.decode(stream);
    XdrInt64 refundableFee = XdrInt64.decode(stream);
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    return XdrSorobanTransactionData(resources, refundableFee, ext);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSorobanTransactionData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrSorobanTransactionData fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSorobanTransactionData.decode(XdrDataInputStream(bytes));
  }
}

class XdrOperationDiagnosticEvents {
  List<XdrDiagnosticEvent> _events;
  List<XdrDiagnosticEvent> get events => this._events;
  set events(List<XdrDiagnosticEvent> value) => this._events = value;

  XdrOperationDiagnosticEvents(this._events);

  static void encode(
      XdrDataOutputStream stream, XdrOperationDiagnosticEvents encoded) {
    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrDiagnosticEvent.encode(stream, encoded.events[i]);
    }
  }

  static XdrOperationDiagnosticEvents decode(XdrDataInputStream stream) {
    int eventsSize = stream.readInt();
    List<XdrDiagnosticEvent> events =
        List<XdrDiagnosticEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrDiagnosticEvent.decode(stream));
    }
    return XdrOperationDiagnosticEvents(events);
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

  static const txSOROBAN_RESOURCE_LIMIT_EXCEEDED = const XdrTransactionResultCode._internal(-17);

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
        return txBAD_MIN_SEQ_AGE_OR_GAP;
      case -16:
        return txBAD_MIN_SEQ_AGE_OR_GAP;
      case -17:
        return txSOROBAN_RESOURCE_LIMIT_EXCEEDED;
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
  static const ENVELOPE_TYPE_CONTRACT_ID_FROM_ED25519 =
      const XdrEnvelopeType._internal(8);
  static const ENVELOPE_TYPE_CONTRACT_ID_FROM_CONTRACT =
      const XdrEnvelopeType._internal(9);
  static const ENVELOPE_TYPE_CONTRACT_ID_FROM_ASSET =
      const XdrEnvelopeType._internal(10);
  static const ENVELOPE_TYPE_CONTRACT_ID_FROM_SOURCE_ACCOUNT =
      const XdrEnvelopeType._internal(11);
  static const ENVELOPE_TYPE_CREATE_CONTRACT_ARGS =
      const XdrEnvelopeType._internal(12);
  static const ENVELOPE_TYPE_CONTRACT_AUTH =
      const XdrEnvelopeType._internal(13);

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
        return ENVELOPE_TYPE_CONTRACT_ID_FROM_ED25519;
      case 9:
        return ENVELOPE_TYPE_CONTRACT_ID_FROM_CONTRACT;
      case 10:
        return ENVELOPE_TYPE_CONTRACT_ID_FROM_ASSET;
      case 11:
        return ENVELOPE_TYPE_CONTRACT_ID_FROM_SOURCE_ACCOUNT;
      case 12:
        return ENVELOPE_TYPE_CREATE_CONTRACT_ARGS;
      case 13:
        return ENVELOPE_TYPE_CONTRACT_AUTH;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrEnvelopeType value) {
    stream.writeInt(value.value);
  }
}

class XdrAuthorizedInvocation {
  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  String _functionName;
  String get functionName => this._functionName;
  set functionName(String value) => this._functionName = value;

  List<XdrSCVal> _args;
  List<XdrSCVal> get args => this._args;
  set args(List<XdrSCVal> value) => this._args = value;

  List<XdrAuthorizedInvocation> _subInvocations;
  List<XdrAuthorizedInvocation> get subInvocations => this._subInvocations;
  set subInvocations(List<XdrAuthorizedInvocation> value) =>
      this._subInvocations = value;

  XdrAuthorizedInvocation(
      this._contractID, this._functionName, this._args, this._subInvocations);

  static void encode(
      XdrDataOutputStream stream, XdrAuthorizedInvocation encoded) {
    XdrHash.encode(stream, encoded.contractID);
    stream.writeString(encoded.functionName);

    int argsSize = encoded.args.length;
    stream.writeInt(argsSize);
    for (int i = 0; i < argsSize; i++) {
      XdrSCVal.encode(stream, encoded.args[i]);
    }
    int subInvocationsSize = encoded.subInvocations.length;
    stream.writeInt(subInvocationsSize);
    for (int i = 0; i < subInvocationsSize; i++) {
      XdrAuthorizedInvocation.encode(stream, encoded.subInvocations[i]);
    }
  }

  static XdrAuthorizedInvocation decode(XdrDataInputStream stream) {
    XdrHash contractID = XdrHash.decode(stream);
    String functionName = stream.readString();

    int argsSize = stream.readInt();
    List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < argsSize; i++) {
      args.add(XdrSCVal.decode(stream));
    }

    int subInvocationsSize = stream.readInt();
    List<XdrAuthorizedInvocation> subInvocations =
        List<XdrAuthorizedInvocation>.empty(growable: true);
    for (int i = 0; i < subInvocationsSize; i++) {
      subInvocations.add(XdrAuthorizedInvocation.decode(stream));
    }

    return XdrAuthorizedInvocation(
        contractID, functionName, args, subInvocations);
  }
}

class XdrAddressWithNonce {
  XdrSCAddress _address;
  XdrSCAddress get address => this._address;
  set address(XdrSCAddress value) => this._address = value;

  XdrUint64 _nonce;
  XdrUint64 get nonce => this._nonce;
  set nonce(XdrUint64 value) => this._nonce = value;

  XdrAddressWithNonce(this._address, this._nonce);

  static void encode(XdrDataOutputStream stream, XdrAddressWithNonce encoded) {
    XdrSCAddress.encode(stream, encoded.address);
    XdrUint64.encode(stream, encoded.nonce);
  }

  static XdrAddressWithNonce decode(XdrDataInputStream stream) {
    XdrSCAddress address = XdrSCAddress.decode(stream);
    XdrUint64 nonce = XdrUint64.decode(stream);

    return XdrAddressWithNonce(address, nonce);
  }
}

class XdrContractAuth {
  XdrAddressWithNonce? _addressWithNonce;
  XdrAddressWithNonce? get addressWithNonce => this._addressWithNonce;
  set addressWithNonce(XdrAddressWithNonce? value) =>
      this._addressWithNonce = value;

  XdrAuthorizedInvocation _rootInvocation;
  XdrAuthorizedInvocation get rootInvocation => this._rootInvocation;
  set rootInvocation(XdrAuthorizedInvocation value) =>
      this._rootInvocation = value;

  List<XdrSCVal> _signatureArgs;
  List<XdrSCVal> get signatureArgs => this._signatureArgs;
  set signatureArgs(List<XdrSCVal> value) => this._signatureArgs = value;

  XdrContractAuth(
      this._addressWithNonce, this._rootInvocation, this._signatureArgs);

  static void encode(XdrDataOutputStream stream, XdrContractAuth encoded) {
    if (encoded._addressWithNonce != null) {
      stream.writeInt(1);
      XdrAddressWithNonce.encode(stream, encoded._addressWithNonce!);
    } else {
      stream.writeInt(0);
    }

    XdrAuthorizedInvocation.encode(stream, encoded.rootInvocation);
    int signatureArgsSize = encoded.signatureArgs.length;
    stream.writeInt(signatureArgsSize);
    for (int i = 0; i < signatureArgsSize; i++) {
      XdrSCVal.encode(stream, encoded.signatureArgs[i]);
    }
  }

  static XdrContractAuth decode(XdrDataInputStream stream) {
    XdrAddressWithNonce? addressWithNonce;
    int addressWithNoncePresent = stream.readInt();
    if (addressWithNoncePresent != 0) {
      addressWithNonce = XdrAddressWithNonce.decode(stream);
    }

    XdrAuthorizedInvocation rootInvocation =
        XdrAuthorizedInvocation.decode(stream);

    int signatureArgsSize = stream.readInt();
    List<XdrSCVal> signatureArgs = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < signatureArgsSize; i++) {
      signatureArgs.add(XdrSCVal.decode(stream));
    }

    return XdrContractAuth(addressWithNonce, rootInvocation, signatureArgs);
  }

  static XdrContractAuth fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrContractAuth.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrContractAuth.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
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

  XdrHashIDPreimageEd25519ContractID? _ed25519ContractID;
  XdrHashIDPreimageEd25519ContractID? get ed25519ContractID =>
      this._ed25519ContractID;
  set ed25519ContractID(XdrHashIDPreimageEd25519ContractID? value) =>
      this.ed25519ContractID = value;

  XdrHashIDPreimageContractID? _contractID;
  XdrHashIDPreimageContractID? get contractID => this._contractID;
  set contractID(XdrHashIDPreimageContractID? value) => this.contractID = value;

  XdrHashIDPreimageFromAsset? _fromAsset;
  XdrHashIDPreimageFromAsset? get fromAsset => this._fromAsset;
  set fromAsset(XdrHashIDPreimageFromAsset? value) => this.fromAsset = value;

  XdrHashIDPreimageSourceAccountContractID? _sourceAccountContractID;
  XdrHashIDPreimageSourceAccountContractID? get sourceAccountContractID =>
      this._sourceAccountContractID;
  set sourceAccountContractID(
          XdrHashIDPreimageSourceAccountContractID? value) =>
      this.sourceAccountContractID = value;

  XdrHashIDPreimageCreateContractArgs? _createContractArgs;
  XdrHashIDPreimageCreateContractArgs? get createContractArgs =>
      this._createContractArgs;
  set createContractArgs(XdrHashIDPreimageCreateContractArgs? value) =>
      this.createContractArgs = value;

  XdrHashIDPreimageContractAuth? _contractAuth;
  XdrHashIDPreimageContractAuth? get contractAuth => this._contractAuth;
  set contractAuth(XdrHashIDPreimageContractAuth? value) =>
      this._contractAuth = value;

  static void encode(XdrDataOutputStream stream, XdrHashIDPreimage encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        XdrHashIDPreimageOperationID.encode(stream, encoded.operationID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
        XdrHashIDPreimageRevokeID.encode(stream, encoded.revokeID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ED25519:
        XdrHashIDPreimageEd25519ContractID.encode(
            stream, encoded.ed25519ContractID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_CONTRACT:
        XdrHashIDPreimageContractID.encode(stream, encoded.contractID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ASSET:
        XdrHashIDPreimageFromAsset.encode(stream, encoded.fromAsset!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_SOURCE_ACCOUNT:
        XdrHashIDPreimageSourceAccountContractID.encode(
            stream, encoded.sourceAccountContractID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CREATE_CONTRACT_ARGS:
        XdrHashIDPreimageCreateContractArgs.encode(
            stream, encoded.createContractArgs!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_AUTH:
        XdrHashIDPreimageContractAuth.encode(stream, encoded.contractAuth!);
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
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ED25519:
        decoded.ed25519ContractID =
            XdrHashIDPreimageEd25519ContractID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_CONTRACT:
        decoded.contractID = XdrHashIDPreimageContractID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ASSET:
        decoded.fromAsset = XdrHashIDPreimageFromAsset.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_SOURCE_ACCOUNT:
        decoded.sourceAccountContractID =
            XdrHashIDPreimageSourceAccountContractID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CREATE_CONTRACT_ARGS:
        decoded.createContractArgs =
            XdrHashIDPreimageCreateContractArgs.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_AUTH:
        decoded.contractAuth = XdrHashIDPreimageContractAuth.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrHashIDPreimageCreateContractArgs {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrSCContractExecutable _executable;
  XdrSCContractExecutable get executable => this._executable;
  set executable(XdrSCContractExecutable value) => this._executable = value;

  XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  XdrHashIDPreimageCreateContractArgs(
      this._networkID, this._executable, this._salt);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageCreateContractArgs encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrSCContractExecutable.encode(stream, encoded.executable);
    XdrUint256.encode(stream, encoded.salt);
  }

  static XdrHashIDPreimageCreateContractArgs decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrSCContractExecutable executable = XdrSCContractExecutable.decode(stream);
    XdrUint256 salt = XdrUint256.decode(stream);
    return XdrHashIDPreimageCreateContractArgs(networkID, executable, salt);
  }
}

class XdrHashIDPreimageSourceAccountContractID {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrAccountID _sourceAccount;
  XdrAccountID get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrAccountID value) => this._sourceAccount = value;

  XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  XdrHashIDPreimageSourceAccountContractID(
      this._networkID, this._sourceAccount, this._salt);

  static void encode(XdrDataOutputStream stream,
      XdrHashIDPreimageSourceAccountContractID encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrAccountID.encode(stream, encoded.sourceAccount);
    XdrUint256.encode(stream, encoded.salt);
  }

  static XdrHashIDPreimageSourceAccountContractID decode(
      XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrAccountID sourceAccount = XdrAccountID.decode(stream);
    XdrUint256 salt = XdrUint256.decode(stream);
    return XdrHashIDPreimageSourceAccountContractID(
        networkID, sourceAccount, salt);
  }
}

class XdrHashIDPreimageFromAsset {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrHashIDPreimageFromAsset(this._networkID, this._asset);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageFromAsset encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrAsset.encode(stream, encoded.asset);
  }

  static XdrHashIDPreimageFromAsset decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    return XdrHashIDPreimageFromAsset(networkID, asset);
  }
}

class XdrHashIDPreimageContractID {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  XdrHashIDPreimageContractID(this._networkID, this._contractID, this._salt);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageContractID encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrHash.encode(stream, encoded.contractID);
    XdrUint256.encode(stream, encoded.salt);
  }

  static XdrHashIDPreimageContractID decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrHash contractID = XdrHash.decode(stream);
    XdrUint256 salt = XdrUint256.decode(stream);
    return XdrHashIDPreimageContractID(networkID, contractID, salt);
  }
}

class XdrHashIDPreimageEd25519ContractID {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrUint256 _ed25519;
  XdrUint256 get ed25519 => this._ed25519;
  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  XdrHashIDPreimageEd25519ContractID(
      this._networkID, this._ed25519, this._salt);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageEd25519ContractID encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrUint256.encode(stream, encoded.ed25519);
    XdrUint256.encode(stream, encoded.salt);
  }

  static XdrHashIDPreimageEd25519ContractID decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrUint256 ed25519 = XdrUint256.decode(stream);
    XdrUint256 salt = XdrUint256.decode(stream);
    return XdrHashIDPreimageEd25519ContractID(networkID, ed25519, salt);
  }
}

class XdrHashIDPreimageContractAuth {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrUint64 _nonce;
  XdrUint64 get nonce => this._nonce;
  set nonce(XdrUint64 value) => this._nonce = value;

  XdrAuthorizedInvocation _invocation;
  XdrAuthorizedInvocation get invocation => this._invocation;
  set invocation(XdrAuthorizedInvocation value) => this._invocation = value;

  XdrHashIDPreimageContractAuth(this._networkID, this._nonce, this._invocation);

  static void encode(
      XdrDataOutputStream stream, XdrHashIDPreimageContractAuth encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrUint64.encode(stream, encoded.nonce);
    XdrAuthorizedInvocation.encode(stream, encoded.invocation);
  }

  static XdrHashIDPreimageContractAuth decode(XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrUint64 nonce = XdrUint64.decode(stream);
    XdrAuthorizedInvocation invocation = XdrAuthorizedInvocation.decode(stream);
    return XdrHashIDPreimageContractAuth(networkID, nonce, invocation);
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

  XdrUint64? _sequenceNumber;
  XdrUint64? get sequenceNumber => this._sequenceNumber;
  set sequenceNumber(XdrUint64? value) => this._sequenceNumber = value;

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
      XdrUint64.encode(stream, encoded.sequenceNumber!);
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
    XdrUint64? sqN;

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
      sqN = XdrUint64.decode(stream);
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
