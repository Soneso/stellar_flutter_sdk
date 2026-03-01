// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_scp_envelope.dart';
import 'xdr_uint32.dart';

class XdrLedgerSCPMessages {
  XdrLedgerSCPMessages(this._ledgerSeq, this._messages);

  XdrUint32 _ledgerSeq;

  XdrUint32 get ledgerSeq => this._ledgerSeq;

  set ledgerSeq(XdrUint32 value) => this._ledgerSeq = value;

  List<XdrSCPEnvelope> _messages;

  List<XdrSCPEnvelope> get messages => this._messages;

  set messages(List<XdrSCPEnvelope> value) => this._messages = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerSCPMessages encodedLedgerSCPMessages,
  ) {
    XdrUint32.encode(stream, encodedLedgerSCPMessages.ledgerSeq);
    int messagessize = encodedLedgerSCPMessages.messages.length;
    stream.writeInt(messagessize);
    for (int i = 0; i < messagessize; i++) {
      XdrSCPEnvelope.encode(stream, encodedLedgerSCPMessages.messages[i]);
    }
  }

  static XdrLedgerSCPMessages decode(XdrDataInputStream stream) {
    XdrUint32 ledgerSeq = XdrUint32.decode(stream);
    int messagessize = stream.readInt();
    List<XdrSCPEnvelope> messages = List<XdrSCPEnvelope>.empty(growable: true);
    for (int i = 0; i < messagessize; i++) {
      messages.add(XdrSCPEnvelope.decode(stream));
    }
    return XdrLedgerSCPMessages(ledgerSeq, messages);
  }
}
