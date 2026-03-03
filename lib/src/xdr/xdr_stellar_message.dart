// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_auth.dart';
import 'xdr_data_io.dart';
import 'xdr_dont_have.dart';
import 'xdr_error.dart';
import 'xdr_hello.dart';
import 'xdr_message_type.dart';
import 'xdr_peer_address.dart';
import 'xdr_scp_envelope.dart';
import 'xdr_scp_quorum_set.dart';
import 'xdr_transaction_envelope.dart';
import 'xdr_transaction_set.dart';
import 'xdr_uint256.dart';
import 'xdr_uint32.dart';

class XdrStellarMessage {
  XdrStellarMessage(this._type);

  XdrMessageType _type;
  XdrMessageType get discriminant => this._type;
  set discriminant(XdrMessageType value) => this._type = value;

  XdrError? _error;
  XdrError? get error => this._error;
  set error(XdrError? value) => this._error = value;

  XdrHello? _hello;
  XdrHello? get hello => this._hello;
  set hello(XdrHello? value) => this._hello = value;

  XdrAuth? _auth;
  XdrAuth? get auth => this._auth;
  set auth(XdrAuth? value) => this._auth = value;

  XdrDontHave? _dontHave;
  XdrDontHave? get dontHave => this._dontHave;
  set dontHave(XdrDontHave? value) => this._dontHave = value;

  List<XdrPeerAddress?>? _peers;
  List<XdrPeerAddress?>? get peers => this._peers;
  set peers(List<XdrPeerAddress?>? value) => this._peers = value;

  XdrUint256? _txSetHash;
  XdrUint256? get txSetHash => this._txSetHash;
  set txSetHash(XdrUint256? value) => this._txSetHash = value;

  XdrTransactionSet? _txSet;
  XdrTransactionSet? get txSet => this._txSet;
  set txSet(XdrTransactionSet? value) => this._txSet = value;

  XdrTransactionEnvelope? _transaction;
  XdrTransactionEnvelope? get transaction => this._transaction;
  set transaction(XdrTransactionEnvelope? value) => this._transaction = value;

  XdrUint256? _qSetHash;
  XdrUint256? get qSetHash => this._qSetHash;
  set qSetHash(XdrUint256? value) => this._qSetHash = value;

  XdrSCPQuorumSet? _qSet;
  XdrSCPQuorumSet? get qSet => this._qSet;
  set qSet(XdrSCPQuorumSet? value) => this._qSet = value;

  XdrSCPEnvelope? _envelope;
  XdrSCPEnvelope? get envelope => this._envelope;
  set envelope(XdrSCPEnvelope? value) => this._envelope = value;

  XdrUint32? _getSCPLedgerSeq;
  XdrUint32? get getSCPLedgerSeq => this._getSCPLedgerSeq;
  set getSCPLedgerSeq(XdrUint32? value) => this._getSCPLedgerSeq = value;

  // TODO: add survey request message and survey response message.

  static void encode(
    XdrDataOutputStream stream,
    XdrStellarMessage encodedStellarMessage,
  ) {
    stream.writeInt(encodedStellarMessage.discriminant.value);
    switch (encodedStellarMessage.discriminant) {
      case XdrMessageType.ERROR_MSG:
        XdrError.encode(stream, encodedStellarMessage.error!);
        break;
      case XdrMessageType.HELLO:
        XdrHello.encode(stream, encodedStellarMessage.hello!);
        break;
      case XdrMessageType.AUTH:
        XdrAuth.encode(stream, encodedStellarMessage.auth!);
        break;
      case XdrMessageType.DONT_HAVE:
        XdrDontHave.encode(stream, encodedStellarMessage.dontHave!);
        break;
      case XdrMessageType.PEERS:
        int peerssize = encodedStellarMessage.peers!.length;
        stream.writeInt(peerssize);
        for (int i = 0; i < peerssize; i++) {
          XdrPeerAddress.encode(stream, encodedStellarMessage.peers![i]!);
        }
        break;
      case XdrMessageType.GET_TX_SET:
        XdrUint256.encode(stream, encodedStellarMessage.txSetHash!);
        break;
      case XdrMessageType.TX_SET:
        XdrTransactionSet.encode(stream, encodedStellarMessage.txSet!);
        break;
      case XdrMessageType.TRANSACTION:
        XdrTransactionEnvelope.encode(
          stream,
          encodedStellarMessage.transaction!,
        );
        break;
      case XdrMessageType.GET_SCP_QUORUMSET:
        XdrUint256.encode(stream, encodedStellarMessage.qSetHash!);
        break;
      case XdrMessageType.SCP_QUORUMSET:
        XdrSCPQuorumSet.encode(stream, encodedStellarMessage.qSet!);
        break;
      case XdrMessageType.SCP_MESSAGE:
        XdrSCPEnvelope.encode(stream, encodedStellarMessage.envelope!);
        break;
      case XdrMessageType.GET_SCP_STATE:
        XdrUint32.encode(stream, encodedStellarMessage.getSCPLedgerSeq!);
        break;
    }
  }

  static XdrStellarMessage decode(XdrDataInputStream stream) {
    XdrStellarMessage decodedStellarMessage = XdrStellarMessage(
      XdrMessageType.decode(stream),
    );
    switch (decodedStellarMessage.discriminant) {
      case XdrMessageType.ERROR_MSG:
        decodedStellarMessage.error = XdrError.decode(stream);
        break;
      case XdrMessageType.HELLO:
        decodedStellarMessage.hello = XdrHello.decode(stream);
        break;
      case XdrMessageType.AUTH:
        decodedStellarMessage.auth = XdrAuth.decode(stream);
        break;
      case XdrMessageType.DONT_HAVE:
        decodedStellarMessage.dontHave = XdrDontHave.decode(stream);
        break;
      case XdrMessageType.PEERS:
        int peerssize = stream.readInt();
        // decodedStellarMessage.peers = List<XdrPeerAddress>(peerssize);
        decodedStellarMessage.peers = []..length = peerssize;
        for (int i = 0; i < peerssize; i++) {
          decodedStellarMessage.peers![i] = XdrPeerAddress.decode(stream);
        }
        break;
      case XdrMessageType.GET_TX_SET:
        decodedStellarMessage.txSetHash = XdrUint256.decode(stream);
        break;
      case XdrMessageType.TX_SET:
        decodedStellarMessage.txSet = XdrTransactionSet.decode(stream);
        break;
      case XdrMessageType.TRANSACTION:
        decodedStellarMessage.transaction = XdrTransactionEnvelope.decode(
          stream,
        );
        break;
      case XdrMessageType.GET_SCP_QUORUMSET:
        decodedStellarMessage.qSetHash = XdrUint256.decode(stream);
        break;
      case XdrMessageType.SCP_QUORUMSET:
        decodedStellarMessage.qSet = XdrSCPQuorumSet.decode(stream);
        break;
      case XdrMessageType.SCP_MESSAGE:
        decodedStellarMessage.envelope = XdrSCPEnvelope.decode(stream);
        break;
      case XdrMessageType.GET_SCP_STATE:
        decodedStellarMessage.getSCPLedgerSeq = XdrUint32.decode(stream);
        break;
    }
    // TODO: survey
    return decodedStellarMessage;
  }
}
