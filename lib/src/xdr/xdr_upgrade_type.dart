// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrUpgradeType {
  XdrUpgradeType(this._upgradeType);

  Uint8List _upgradeType;
  Uint8List get upgradeType => this._upgradeType;
  set upgradeType(Uint8List value) => this._upgradeType = value;

  static void encode(XdrDataOutputStream stream, XdrUpgradeType encodedUpgradeType) {
    int upgradeTypeSize = encodedUpgradeType.upgradeType.length;
    stream.writeInt(upgradeTypeSize);
    stream.write(encodedUpgradeType.upgradeType);
  }

  static XdrUpgradeType decode(XdrDataInputStream stream) {
    int upgradeTypeSize = stream.readInt();
    return XdrUpgradeType(stream.readBytes(upgradeTypeSize));
  }
}
