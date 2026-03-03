// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_node_id.dart';
import 'xdr_uint32.dart';

class XdrTimeSlicedSurveyStopCollectingMessage {
  XdrNodeID _surveyorID;
  XdrNodeID get surveyorID => this._surveyorID;
  set surveyorID(XdrNodeID value) => this._surveyorID = value;

  XdrUint32 _nonce;
  XdrUint32 get nonce => this._nonce;
  set nonce(XdrUint32 value) => this._nonce = value;

  XdrUint32 _ledgerNum;
  XdrUint32 get ledgerNum => this._ledgerNum;
  set ledgerNum(XdrUint32 value) => this._ledgerNum = value;

  XdrTimeSlicedSurveyStopCollectingMessage(
    this._surveyorID,
    this._nonce,
    this._ledgerNum,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrTimeSlicedSurveyStopCollectingMessage
    encodedTimeSlicedSurveyStopCollectingMessage,
  ) {
    XdrNodeID.encode(
      stream,
      encodedTimeSlicedSurveyStopCollectingMessage.surveyorID,
    );
    XdrUint32.encode(
      stream,
      encodedTimeSlicedSurveyStopCollectingMessage.nonce,
    );
    XdrUint32.encode(
      stream,
      encodedTimeSlicedSurveyStopCollectingMessage.ledgerNum,
    );
  }

  static XdrTimeSlicedSurveyStopCollectingMessage decode(
    XdrDataInputStream stream,
  ) {
    XdrNodeID surveyorID = XdrNodeID.decode(stream);
    XdrUint32 nonce = XdrUint32.decode(stream);
    XdrUint32 ledgerNum = XdrUint32.decode(stream);
    return XdrTimeSlicedSurveyStopCollectingMessage(
      surveyorID,
      nonce,
      ledgerNum,
    );
  }
}
