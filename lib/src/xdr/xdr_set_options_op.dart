// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_signer.dart';
import 'xdr_string32.dart';
import 'xdr_uint32.dart';

class XdrSetOptionsOp {
  XdrSetOptionsOp();

  XdrAccountID? _inflationDest;

  XdrAccountID? get inflationDest => this._inflationDest;

  set inflationDest(XdrAccountID? value) => this._inflationDest = value;

  XdrUint32? _clearFlags;

  XdrUint32? get clearFlags => this._clearFlags;

  set clearFlags(XdrUint32? value) => this._clearFlags = value;

  XdrUint32? _setFlags;

  XdrUint32? get setFlags => this._setFlags;

  set setFlags(XdrUint32? value) => this._setFlags = value;

  XdrUint32? _masterWeight;

  XdrUint32? get masterWeight => this._masterWeight;

  set masterWeight(XdrUint32? value) => this._masterWeight = value;

  XdrUint32? _lowThreshold;

  XdrUint32? get lowThreshold => this._lowThreshold;

  set lowThreshold(XdrUint32? value) => this._lowThreshold = value;

  XdrUint32? _medThreshold;

  XdrUint32? get medThreshold => this._medThreshold;

  set medThreshold(XdrUint32? value) => this._medThreshold = value;

  XdrUint32? _highThreshold;

  XdrUint32? get highThreshold => this._highThreshold;

  set highThreshold(XdrUint32? value) => this._highThreshold = value;

  XdrString32? _homeDomain;

  XdrString32? get homeDomain => this._homeDomain;

  set homeDomain(XdrString32? value) => this._homeDomain = value;

  XdrSigner? _signer;

  XdrSigner? get signer => this._signer;

  set signer(XdrSigner? value) => this._signer = value;

  static void encode(
      XdrDataOutputStream stream, XdrSetOptionsOp encodedSetOptionsOp) {
    if (encodedSetOptionsOp.inflationDest != null) {
      stream.writeInt(1);
      XdrAccountID.encode(stream, encodedSetOptionsOp.inflationDest);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.clearFlags != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.clearFlags!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.setFlags != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.setFlags!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.masterWeight != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.masterWeight!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.lowThreshold != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.lowThreshold!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.medThreshold != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.medThreshold!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.highThreshold != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.highThreshold!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.homeDomain != null) {
      stream.writeInt(1);
      XdrString32.encode(stream, encodedSetOptionsOp.homeDomain!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.signer != null) {
      stream.writeInt(1);
      XdrSigner.encode(stream, encodedSetOptionsOp.signer!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrSetOptionsOp decode(XdrDataInputStream stream) {
    XdrSetOptionsOp decodedSetOptionsOp = XdrSetOptionsOp();
    int inflationDestPresent = stream.readInt();
    if (inflationDestPresent != 0) {
      decodedSetOptionsOp.inflationDest = XdrAccountID.decode(stream);
    }
    int clearFlagsPresent = stream.readInt();
    if (clearFlagsPresent != 0) {
      decodedSetOptionsOp.clearFlags = XdrUint32.decode(stream);
    }
    int setFlagsPresent = stream.readInt();
    if (setFlagsPresent != 0) {
      decodedSetOptionsOp.setFlags = XdrUint32.decode(stream);
    }
    int masterWeightPresent = stream.readInt();
    if (masterWeightPresent != 0) {
      decodedSetOptionsOp.masterWeight = XdrUint32.decode(stream);
    }
    int lowThresholdPresent = stream.readInt();
    if (lowThresholdPresent != 0) {
      decodedSetOptionsOp.lowThreshold = XdrUint32.decode(stream);
    }
    int medThresholdPresent = stream.readInt();
    if (medThresholdPresent != 0) {
      decodedSetOptionsOp.medThreshold = XdrUint32.decode(stream);
    }
    int highThresholdPresent = stream.readInt();
    if (highThresholdPresent != 0) {
      decodedSetOptionsOp.highThreshold = XdrUint32.decode(stream);
    }
    int homeDomainPresent = stream.readInt();
    if (homeDomainPresent != 0) {
      decodedSetOptionsOp.homeDomain = XdrString32.decode(stream);
    }
    int signerPresent = stream.readInt();
    if (signerPresent != 0) {
      decodedSetOptionsOp.signer = XdrSigner.decode(stream);
    }
    return decodedSetOptionsOp;
  }
}
