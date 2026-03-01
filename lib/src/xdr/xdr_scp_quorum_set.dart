// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_public_key.dart';
import 'xdr_uint32.dart';

class XdrSCPQuorumSet {
  XdrSCPQuorumSet(this._threshold, this._validators, this._innerSets);
  XdrUint32 _threshold;
  XdrUint32 get threshold => this._threshold;
  set threshold(XdrUint32 value) => this._threshold = value;

  List<XdrPublicKey> _validators;
  List<XdrPublicKey> get validators => this._validators;
  set validators(List<XdrPublicKey> value) => this._validators = value;

  List<XdrSCPQuorumSet> _innerSets;
  List<XdrSCPQuorumSet> get innerSets => this._innerSets;
  set innerSets(List<XdrSCPQuorumSet> value) => this._innerSets = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPQuorumSet encodedSCPQuorumSet,
  ) {
    XdrUint32.encode(stream, encodedSCPQuorumSet._threshold);
    int validatorsSize = encodedSCPQuorumSet.validators.length;
    stream.writeInt(validatorsSize);
    for (int i = 0; i < validatorsSize; i++) {
      XdrPublicKey.encode(stream, encodedSCPQuorumSet._validators[i]);
    }
    int innerSetsSize = encodedSCPQuorumSet.innerSets.length;
    stream.writeInt(innerSetsSize);
    for (int i = 0; i < innerSetsSize; i++) {
      XdrSCPQuorumSet.encode(stream, encodedSCPQuorumSet._innerSets[i]);
    }
  }

  static XdrSCPQuorumSet decode(XdrDataInputStream stream) {
    XdrUint32 threshold = XdrUint32.decode(stream);

    int validatorsSize = stream.readInt();
    List<XdrPublicKey> validators = List<XdrPublicKey>.empty(growable: true);
    for (int i = 0; i < validatorsSize; i++) {
      validators.add(XdrPublicKey.decode(stream));
    }

    int innerSetsSize = stream.readInt();

    List<XdrSCPQuorumSet> innerSets = List<XdrSCPQuorumSet>.empty(
      growable: true,
    );
    for (int i = 0; i < innerSetsSize; i++) {
      innerSets.add(XdrSCPQuorumSet.decode(stream));
    }

    return XdrSCPQuorumSet(threshold, validators, innerSets);
  }
}
