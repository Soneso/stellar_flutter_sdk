// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';

class XdrLiabilities {

  XdrInt64 _buying;
  XdrInt64 get buying => this._buying;
  set buying(XdrInt64 value) => this._buying = value;

  XdrInt64 _selling;
  XdrInt64 get selling => this._selling;
  set selling(XdrInt64 value) => this._selling = value;

  XdrLiabilities(this._buying, this._selling);

  static void encode(XdrDataOutputStream stream, XdrLiabilities encodedLiabilities) {
    XdrInt64.encode(stream, encodedLiabilities.buying);
    XdrInt64.encode(stream, encodedLiabilities.selling);
  }

  static XdrLiabilities decode(XdrDataInputStream stream) {
    XdrInt64 buying = XdrInt64.decode(stream);
    XdrInt64 selling = XdrInt64.decode(stream);
    return XdrLiabilities(buying, selling);
  }
}
