// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_big_int64.dart';
import 'xdr_change_trust_asset.dart';
import 'xdr_data_io.dart';

class XdrChangeTrustOp {

  XdrChangeTrustAsset _line;
  XdrChangeTrustAsset get line => this._line;
  set line(XdrChangeTrustAsset value) => this._line = value;

  XdrBigInt64 _limit;
  XdrBigInt64 get limit => this._limit;
  set limit(XdrBigInt64 value) => this._limit = value;

  XdrChangeTrustOp(this._line, this._limit);

  static void encode(XdrDataOutputStream stream, XdrChangeTrustOp encodedChangeTrustOp) {
    XdrChangeTrustAsset.encode(stream, encodedChangeTrustOp.line);
    XdrBigInt64.encode(stream, encodedChangeTrustOp.limit);
  }

  static XdrChangeTrustOp decode(XdrDataInputStream stream) {
    XdrChangeTrustAsset line = XdrChangeTrustAsset.decode(stream);
    XdrBigInt64 limit = XdrBigInt64.decode(stream);
    return XdrChangeTrustOp(line, limit);
  }
}
