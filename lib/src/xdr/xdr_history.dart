// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger.dart';
import 'xdr_scp.dart';
import 'xdr_transaction.dart';

class XdrSCPHistoryEntry {
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSCPHistoryEntryV0? _v0;
  XdrSCPHistoryEntryV0? get v0 => this._v0;
  set v0(XdrSCPHistoryEntryV0? value) => this._v0 = value;

  XdrSCPHistoryEntry(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPHistoryEntry encodedSCPHistoryEntry,
  ) {
    stream.writeInt(encodedSCPHistoryEntry.discriminant);
    switch (encodedSCPHistoryEntry.discriminant) {
      case 0:
        XdrSCPHistoryEntryV0.encode(stream, encodedSCPHistoryEntry.v0!);
        break;
    }
  }

  static XdrSCPHistoryEntry decode(XdrDataInputStream stream) {
    XdrSCPHistoryEntry decodedSCPHistoryEntry = XdrSCPHistoryEntry(
      stream.readInt(),
    );
    switch (decodedSCPHistoryEntry.discriminant) {
      case 0:
        decodedSCPHistoryEntry.v0 = XdrSCPHistoryEntryV0.decode(stream);
        break;
    }
    return decodedSCPHistoryEntry;
  }
}

class XdrSCPHistoryEntryV0 {
  List<XdrSCPQuorumSet> _quorumSets;
  List<XdrSCPQuorumSet> get quorumSets => this._quorumSets;
  set quorumSets(List<XdrSCPQuorumSet> value) => this._quorumSets = value;

  XdrLedgerSCPMessages _ledgerMessages;
  XdrLedgerSCPMessages get ledgerMessages => this._ledgerMessages;
  set ledgerMessages(XdrLedgerSCPMessages value) =>
      this._ledgerMessages = value;

  XdrSCPHistoryEntryV0(this._quorumSets, this._ledgerMessages);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPHistoryEntryV0 encodedSCPHistoryEntryV0,
  ) {
    int quorumSetsSize = encodedSCPHistoryEntryV0.quorumSets.length;
    stream.writeInt(quorumSetsSize);
    for (int i = 0; i < quorumSetsSize; i++) {
      XdrSCPQuorumSet.encode(stream, encodedSCPHistoryEntryV0.quorumSets[i]);
    }
    XdrLedgerSCPMessages.encode(
      stream,
      encodedSCPHistoryEntryV0.ledgerMessages,
    );
  }

  static XdrSCPHistoryEntryV0 decode(XdrDataInputStream stream) {
    int quorumSetsSize = stream.readInt();
    List<XdrSCPQuorumSet> xQuorumSets = List<XdrSCPQuorumSet>.empty(
      growable: true,
    );
    for (int i = 0; i < quorumSetsSize; i++) {
      xQuorumSets.add(XdrSCPQuorumSet.decode(stream));
    }
    XdrLedgerSCPMessages xLedgerMessages = XdrLedgerSCPMessages.decode(stream);
    return XdrSCPHistoryEntryV0(xQuorumSets, xLedgerMessages);
  }
}

class XdrTransactionHistoryEntry {
  XdrUint32 _ledgerSeq;
  XdrUint32 get ledgerSeq => this._ledgerSeq;
  set ledgerSeq(XdrUint32 value) => this._ledgerSeq = value;

  XdrTransactionSet _txSet;
  XdrTransactionSet get txSet => this._txSet;
  set txSet(XdrTransactionSet value) => this._txSet = value;

  XdrTransactionHistoryEntryExt _ext;
  XdrTransactionHistoryEntryExt get ext => this._ext;
  set ext(XdrTransactionHistoryEntryExt value) => this._ext = value;

  XdrTransactionHistoryEntry(this._ledgerSeq, this._txSet, this._ext);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionHistoryEntry encodedTransactionHistoryEntry,
  ) {
    XdrUint32.encode(stream, encodedTransactionHistoryEntry.ledgerSeq);
    XdrTransactionSet.encode(stream, encodedTransactionHistoryEntry.txSet);
    XdrTransactionHistoryEntryExt.encode(
      stream,
      encodedTransactionHistoryEntry.ext,
    );
  }

  static XdrTransactionHistoryEntry decode(XdrDataInputStream stream) {
    return XdrTransactionHistoryEntry(
      XdrUint32.decode(stream),
      XdrTransactionSet.decode(stream),
      XdrTransactionHistoryEntryExt.decode(stream),
    );
  }
}

class XdrTransactionHistoryEntryExt {
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrTransactionHistoryEntryExt(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionHistoryEntryExt encodedTransactionHistoryEntryExt,
  ) {
    stream.writeInt(encodedTransactionHistoryEntryExt.discriminant);
    switch (encodedTransactionHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionHistoryEntryExt decode(XdrDataInputStream stream) {
    XdrTransactionHistoryEntryExt decodedTransactionHistoryEntryExt =
        XdrTransactionHistoryEntryExt(stream.readInt());
    switch (decodedTransactionHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionHistoryEntryExt;
  }
}

class XdrTransactionHistoryResultEntry {
  XdrUint32 _ledgerSeq;
  XdrUint32 get ledgerSeq => this._ledgerSeq;
  set ledgerSeq(XdrUint32 value) => this.ledgerSeq = value;

  XdrTransactionResultSet _txResultSet;
  XdrTransactionResultSet get txResultSet => this._txResultSet;
  set txResultSet(XdrTransactionResultSet value) => this.txResultSet = value;

  XdrTransactionHistoryResultEntryExt _ext;
  XdrTransactionHistoryResultEntryExt get ext => this._ext;
  set ext(XdrTransactionHistoryResultEntryExt value) => this.ext = value;

  XdrTransactionHistoryResultEntry(
    this._ledgerSeq,
    this._txResultSet,
    this._ext,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionHistoryResultEntry encodedTransactionHistoryResultEntry,
  ) {
    XdrUint32.encode(stream, encodedTransactionHistoryResultEntry.ledgerSeq);
    XdrTransactionResultSet.encode(
      stream,
      encodedTransactionHistoryResultEntry.txResultSet,
    );
    XdrTransactionHistoryResultEntryExt.encode(
      stream,
      encodedTransactionHistoryResultEntry.ext,
    );
  }

  static XdrTransactionHistoryResultEntry decode(XdrDataInputStream stream) {
    return XdrTransactionHistoryResultEntry(
      XdrUint32.decode(stream),
      XdrTransactionResultSet.decode(stream),
      XdrTransactionHistoryResultEntryExt.decode(stream),
    );
  }
}

class XdrTransactionHistoryResultEntryExt {
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrTransactionHistoryResultEntryExt(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionHistoryResultEntryExt encodedTransactionHistoryResultEntryExt,
  ) {
    stream.writeInt(encodedTransactionHistoryResultEntryExt.discriminant);
    switch (encodedTransactionHistoryResultEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionHistoryResultEntryExt decode(XdrDataInputStream stream) {
    XdrTransactionHistoryResultEntryExt
    decodedTransactionHistoryResultEntryExt =
        XdrTransactionHistoryResultEntryExt(stream.readInt());
    switch (decodedTransactionHistoryResultEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionHistoryResultEntryExt;
  }
}
