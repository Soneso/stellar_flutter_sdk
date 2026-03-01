// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_stellar_value_ext.dart';
import 'xdr_uint64.dart';
import 'xdr_upgrade_type.dart';

class XdrStellarValue {
  XdrStellarValue(this._txSetHash, this._closeTime, this._upgrades, this._ext);
  XdrHash _txSetHash;
  XdrHash get txSetHash => this._txSetHash;
  set txSetHash(XdrHash value) => this._txSetHash = value;

  XdrUint64 _closeTime;
  XdrUint64 get closeTime => this._closeTime;
  set closeTime(XdrUint64 value) => this._closeTime = value;

  List<XdrUpgradeType> _upgrades;
  List<XdrUpgradeType> get upgrades => this._upgrades;
  set upgrades(List<XdrUpgradeType> value) => this._upgrades = value;

  XdrStellarValueExt _ext;
  XdrStellarValueExt get ext => this._ext;
  set ext(XdrStellarValueExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrStellarValue encodedStellarValue) {
    XdrHash.encode(stream, encodedStellarValue.txSetHash);
    XdrUint64.encode(stream, encodedStellarValue.closeTime);
    int upgradessize = encodedStellarValue.upgrades.length;
    stream.writeInt(upgradessize);
    for (int i = 0; i < upgradessize; i++) {
      XdrUpgradeType.encode(stream, encodedStellarValue.upgrades[i]);
    }
    XdrStellarValueExt.encode(stream, encodedStellarValue.ext);
  }

  static XdrStellarValue decode(XdrDataInputStream stream) {
    XdrHash txSetHash = XdrHash.decode(stream);
    XdrUint64 closeTime = XdrUint64.decode(stream);
    int upgradessize = stream.readInt();
    List<XdrUpgradeType> upgrades = List<XdrUpgradeType>.empty(growable: true);
    for (int i = 0; i < upgradessize; i++) {
      upgrades.add(XdrUpgradeType.decode(stream));
    }
    XdrStellarValueExt ext = XdrStellarValueExt.decode(stream);
    return XdrStellarValue(txSetHash, closeTime, upgrades, ext);
  }
}
