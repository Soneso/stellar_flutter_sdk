// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_survey_response_message.dart';
import 'xdr_uint32.dart';

class XdrTimeSlicedSurveyResponseMessage {

  XdrSurveyResponseMessage _response;
  XdrSurveyResponseMessage get response => this._response;
  set response(XdrSurveyResponseMessage value) => this._response = value;

  XdrUint32 _nonce;
  XdrUint32 get nonce => this._nonce;
  set nonce(XdrUint32 value) => this._nonce = value;

  XdrTimeSlicedSurveyResponseMessage(this._response, this._nonce);

  static void encode(XdrDataOutputStream stream, XdrTimeSlicedSurveyResponseMessage encodedTimeSlicedSurveyResponseMessage) {
    XdrSurveyResponseMessage.encode(stream, encodedTimeSlicedSurveyResponseMessage.response);
    XdrUint32.encode(stream, encodedTimeSlicedSurveyResponseMessage.nonce);
  }

  static XdrTimeSlicedSurveyResponseMessage decode(XdrDataInputStream stream) {
    XdrSurveyResponseMessage response = XdrSurveyResponseMessage.decode(stream);
    XdrUint32 nonce = XdrUint32.decode(stream);
    return XdrTimeSlicedSurveyResponseMessage(response, nonce);
  }
}
