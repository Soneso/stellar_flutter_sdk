// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_scp_messages.dart';
import 'xdr_scp_quorum_set.dart';

class XdrSCPHistoryEntryV0 {
  List<XdrSCPQuorumSet> _quorumSets;
  List<XdrSCPQuorumSet> get quorumSets => this._quorumSets;
  set quorumSets(List<XdrSCPQuorumSet> value) => this._quorumSets = value;

  XdrLedgerSCPMessages _ledgerMessages;
  XdrLedgerSCPMessages get ledgerMessages => this._ledgerMessages;
  set ledgerMessages(XdrLedgerSCPMessages value) =>
      this._ledgerMessages = value;

  XdrSCPHistoryEntryV0(this._quorumSets, this._ledgerMessages);

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
    int quorumSetsSize = stream.readInt();
    List<XdrSCPQuorumSet> xQuorumSets =
        List<XdrSCPQuorumSet>.empty(growable: true);
    for (int i = 0; i < quorumSetsSize; i++) {
      xQuorumSets.add(XdrSCPQuorumSet.decode(stream));
    }
    XdrLedgerSCPMessages xLedgerMessages = XdrLedgerSCPMessages.decode(stream);
    return XdrSCPHistoryEntryV0(xQuorumSets, xLedgerMessages);
  }
}
