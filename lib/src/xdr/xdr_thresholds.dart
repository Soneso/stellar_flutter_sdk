// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrThresholds {
  XdrThresholds(this._thresholds);

  Uint8List _thresholds;
  Uint8List get thresholds => this._thresholds;
  set thresholds(Uint8List value) => this._thresholds = value;

  static void encode(XdrDataOutputStream stream, XdrThresholds encodedThresholds) {
    stream.write(encodedThresholds.thresholds);
  }

  static XdrThresholds decode(XdrDataInputStream stream) {
    int thresholdsSize = 4;
    return XdrThresholds(stream.readBytes(thresholdsSize));
  }
}
