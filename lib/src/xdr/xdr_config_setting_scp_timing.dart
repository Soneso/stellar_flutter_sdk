// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingSCPTiming {
  XdrUint32 _ledgerTargetCloseTimeMilliseconds;
  XdrUint32 get ledgerTargetCloseTimeMilliseconds =>
      this._ledgerTargetCloseTimeMilliseconds;
  set ledgerTargetCloseTimeMilliseconds(XdrUint32 value) =>
      this.ledgerTargetCloseTimeMilliseconds = value;

  XdrUint32 _nominationTimeoutInitialMilliseconds;
  XdrUint32 get nominationTimeoutInitialMilliseconds =>
      this._nominationTimeoutInitialMilliseconds;
  set nominationTimeoutInitialMilliseconds(XdrUint32 value) =>
      this.nominationTimeoutInitialMilliseconds = value;

  XdrUint32 _nominationTimeoutIncrementMilliseconds;
  XdrUint32 get nominationTimeoutIncrementMilliseconds =>
      this._nominationTimeoutIncrementMilliseconds;
  set nominationTimeoutIncrementMilliseconds(XdrUint32 value) =>
      this.nominationTimeoutIncrementMilliseconds = value;

  XdrUint32 _ballotTimeoutInitialMilliseconds;
  XdrUint32 get ballotTimeoutInitialMilliseconds =>
      this._ballotTimeoutInitialMilliseconds;
  set ballotTimeoutInitialMilliseconds(XdrUint32 value) =>
      this.ballotTimeoutInitialMilliseconds = value;

  XdrUint32 _ballotTimeoutIncrementMilliseconds;
  XdrUint32 get ballotTimeoutIncrementMilliseconds =>
      this._ballotTimeoutIncrementMilliseconds;
  set ballotTimeoutIncrementMilliseconds(XdrUint32 value) =>
      this.ballotTimeoutIncrementMilliseconds = value;

  XdrConfigSettingSCPTiming(
    this._ledgerTargetCloseTimeMilliseconds,
    this._nominationTimeoutInitialMilliseconds,
    this._nominationTimeoutIncrementMilliseconds,
    this._ballotTimeoutInitialMilliseconds,
    this._ballotTimeoutIncrementMilliseconds,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrConfigSettingSCPTiming encoded,
  ) {
    XdrUint32.encode(stream, encoded.ledgerTargetCloseTimeMilliseconds);
    XdrUint32.encode(stream, encoded.nominationTimeoutInitialMilliseconds);
    XdrUint32.encode(stream, encoded.nominationTimeoutIncrementMilliseconds);
    XdrUint32.encode(stream, encoded.ballotTimeoutInitialMilliseconds);
    XdrUint32.encode(stream, encoded.ballotTimeoutIncrementMilliseconds);
  }

  static XdrConfigSettingSCPTiming decode(XdrDataInputStream stream) {
    final ledgerTargetCloseTimeMilliseconds = XdrUint32.decode(stream);
    final nominationTimeoutInitialMilliseconds = XdrUint32.decode(stream);
    final nominationTimeoutIncrementMilliseconds = XdrUint32.decode(stream);
    final ballotTimeoutInitialMilliseconds = XdrUint32.decode(stream);
    final ballotTimeoutIncrementMilliseconds = XdrUint32.decode(stream);

    return XdrConfigSettingSCPTiming(
      ledgerTargetCloseTimeMilliseconds,
      nominationTimeoutInitialMilliseconds,
      nominationTimeoutIncrementMilliseconds,
      ballotTimeoutInitialMilliseconds,
      ballotTimeoutIncrementMilliseconds,
    );
  }
}
