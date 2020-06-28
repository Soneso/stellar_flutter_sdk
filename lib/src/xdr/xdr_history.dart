// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger.dart';
import 'xdr_scp.dart';
import 'xdr_transaction.dart';

class XdrSCPHistoryEntry {
  XdrSCPHistoryEntry();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrSCPHistoryEntryV0 _v0;
  XdrSCPHistoryEntryV0 get v0 => this._v0;
  set v0(XdrSCPHistoryEntryV0 value) => this._v0 = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCPHistoryEntry encodedSCPHistoryEntry) {
    stream.writeInt(encodedSCPHistoryEntry.discriminant);
    switch (encodedSCPHistoryEntry.discriminant) {
      case 0:
        XdrSCPHistoryEntryV0.encode(stream, encodedSCPHistoryEntry.v0);
        break;
    }
  }

  static XdrSCPHistoryEntry decode(XdrDataInputStream stream) {
    XdrSCPHistoryEntry decodedSCPHistoryEntry = XdrSCPHistoryEntry();
    int discriminant = stream.readInt();
    decodedSCPHistoryEntry.discriminant = discriminant;
    switch (decodedSCPHistoryEntry.discriminant) {
      case 0:
        decodedSCPHistoryEntry.v0 = XdrSCPHistoryEntryV0.decode(stream);
        break;
    }
    return decodedSCPHistoryEntry;
  }
}

class XdrSCPHistoryEntryV0 {
  XdrSCPHistoryEntryV0();
  List<XdrSCPQuorumSet> _quorumSets;
  List<XdrSCPQuorumSet> get quorumSets => this._quorumSets;
  set quorumSets(List<XdrSCPQuorumSet> value) => this._quorumSets = value;

  XdrLedgerSCPMessages _ledgerMessages;
  XdrLedgerSCPMessages get ledgerMessages => this._ledgerMessages;
  set ledgerMessages(XdrLedgerSCPMessages value) =>
      this._ledgerMessages = value;

  static void encode(XdrDataOutputStream stream,
      XdrSCPHistoryEntryV0 encodedSCPHistoryEntryV0) {
    int quorumSetsSize = encodedSCPHistoryEntryV0.quorumSets.length;
    stream.writeInt(quorumSetsSize);
    for (int i = 0; i < quorumSetsSize; i++) {
      XdrSCPQuorumSet.encode(stream, encodedSCPHistoryEntryV0.quorumSets[i]);
    }
    XdrLedgerSCPMessages.encode(
        stream, encodedSCPHistoryEntryV0.ledgerMessages);
  }

  static XdrSCPHistoryEntryV0 decode(XdrDataInputStream stream) {
    XdrSCPHistoryEntryV0 decodedSCPHistoryEntryV0 = XdrSCPHistoryEntryV0();
    int quorumSetsSize = stream.readInt();
    decodedSCPHistoryEntryV0.quorumSets = List<XdrSCPQuorumSet>(quorumSetsSize);
    for (int i = 0; i < quorumSetsSize; i++) {
      decodedSCPHistoryEntryV0.quorumSets[i] = XdrSCPQuorumSet.decode(stream);
    }
    decodedSCPHistoryEntryV0.ledgerMessages =
        XdrLedgerSCPMessages.decode(stream);
    return decodedSCPHistoryEntryV0;
  }
}

class XdrTransactionHistoryEntry {
  XdrTransactionHistoryEntry();
  XdrUint32 _ledgerSeq;
  XdrUint32 get ledgerSeq => this._ledgerSeq;
  set ledgerSeq(XdrUint32 value) => this._ledgerSeq = value;

  XdrTransactionSet _txSet;
  XdrTransactionSet get txSet => this._txSet;
  set txSet(XdrTransactionSet value) => this._txSet = value;

  XdrTransactionHistoryEntryExt _ext;
  XdrTransactionHistoryEntryExt get ext => this._ext;
  set ext(XdrTransactionHistoryEntryExt value) => this._ext = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionHistoryEntry encodedTransactionHistoryEntry) {
    XdrUint32.encode(stream, encodedTransactionHistoryEntry.ledgerSeq);
    XdrTransactionSet.encode(stream, encodedTransactionHistoryEntry.txSet);
    XdrTransactionHistoryEntryExt.encode(
        stream, encodedTransactionHistoryEntry.ext);
  }

  static XdrTransactionHistoryEntry decode(XdrDataInputStream stream) {
    XdrTransactionHistoryEntry decodedTransactionHistoryEntry =
        XdrTransactionHistoryEntry();
    decodedTransactionHistoryEntry.ledgerSeq = XdrUint32.decode(stream);
    decodedTransactionHistoryEntry.txSet = XdrTransactionSet.decode(stream);
    decodedTransactionHistoryEntry.ext =
        XdrTransactionHistoryEntryExt.decode(stream);
    return decodedTransactionHistoryEntry;
  }
}

class XdrTransactionHistoryEntryExt {
  XdrTransactionHistoryEntryExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionHistoryEntryExt encodedTransactionHistoryEntryExt) {
    stream.writeInt(encodedTransactionHistoryEntryExt.discriminant);
    switch (encodedTransactionHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionHistoryEntryExt decode(XdrDataInputStream stream) {
    XdrTransactionHistoryEntryExt decodedTransactionHistoryEntryExt =
        XdrTransactionHistoryEntryExt();
    int discriminant = stream.readInt();
    decodedTransactionHistoryEntryExt.discriminant = discriminant;
    switch (decodedTransactionHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionHistoryEntryExt;
  }
}

class XdrTransactionHistoryResultEntry {
  XdrTransactionHistoryResultEntry();
  XdrUint32 _ledgerSeq;
  XdrUint32 get ledgerSeq => this._ledgerSeq;
  set ledgerSeq(XdrUint32 value) => this.ledgerSeq = value;

  XdrTransactionResultSet _txResultSet;
  XdrTransactionResultSet get txResultSet => this._txResultSet;
  set txResultSet(XdrTransactionResultSet value) => this.txResultSet = value;

  XdrTransactionHistoryResultEntryExt _ext;
  XdrTransactionHistoryResultEntryExt get ext => this._ext;
  set ext(XdrTransactionHistoryResultEntryExt value) => this.ext = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionHistoryResultEntry encodedTransactionHistoryResultEntry) {
    XdrUint32.encode(stream, encodedTransactionHistoryResultEntry.ledgerSeq);
    XdrTransactionResultSet.encode(
        stream, encodedTransactionHistoryResultEntry.txResultSet);
    XdrTransactionHistoryResultEntryExt.encode(
        stream, encodedTransactionHistoryResultEntry.ext);
  }

  static XdrTransactionHistoryResultEntry decode(XdrDataInputStream stream) {
    XdrTransactionHistoryResultEntry decodedTransactionHistoryResultEntry =
        XdrTransactionHistoryResultEntry();
    decodedTransactionHistoryResultEntry.ledgerSeq = XdrUint32.decode(stream);
    decodedTransactionHistoryResultEntry.txResultSet =
        XdrTransactionResultSet.decode(stream);
    decodedTransactionHistoryResultEntry.ext =
        XdrTransactionHistoryResultEntryExt.decode(stream);
    return decodedTransactionHistoryResultEntry;
  }
}

class XdrTransactionHistoryResultEntryExt {
  XdrTransactionHistoryResultEntryExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream,
      XdrTransactionHistoryResultEntryExt
          encodedTransactionHistoryResultEntryExt) {
    stream.writeInt(encodedTransactionHistoryResultEntryExt.discriminant);
    switch (encodedTransactionHistoryResultEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTransactionHistoryResultEntryExt decode(XdrDataInputStream stream) {
    XdrTransactionHistoryResultEntryExt
        decodedTransactionHistoryResultEntryExt =
        XdrTransactionHistoryResultEntryExt();
    int discriminant = stream.readInt();
    decodedTransactionHistoryResultEntryExt.discriminant = discriminant;
    switch (decodedTransactionHistoryResultEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedTransactionHistoryResultEntryExt;
  }
}
