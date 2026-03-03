// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_bump_sequence_result_code.dart';
import 'xdr_data_io.dart';

class XdrBumpSequenceResult {
  XdrBumpSequenceResultCode _code;

  XdrBumpSequenceResultCode get discriminant => this._code;

  set discriminant(XdrBumpSequenceResultCode value) => this._code = value;

  XdrBumpSequenceResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrBumpSequenceResult encodedBumpSequenceResult,
  ) {
    stream.writeInt(encodedBumpSequenceResult.discriminant.value);
    switch (encodedBumpSequenceResult.discriminant) {
      case XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS:
        break;
      case XdrBumpSequenceResultCode.BUMP_SEQUENCE_BAD_SEQ:
        break;
      default:
        break;
    }
  }

  static XdrBumpSequenceResult decode(XdrDataInputStream stream) {
    XdrBumpSequenceResult decodedBumpSequenceResult = XdrBumpSequenceResult(
      XdrBumpSequenceResultCode.decode(stream),
    );
    switch (decodedBumpSequenceResult.discriminant) {
      case XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS:
        break;
      case XdrBumpSequenceResultCode.BUMP_SEQUENCE_BAD_SEQ:
        break;
      default:
        break;
    }
    return decodedBumpSequenceResult;
  }
}
