// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_value.dart';

class XdrSCPNomination {
  XdrSCPNomination(this._quorumSetHash, this._votes, this._accepted);
  XdrHash _quorumSetHash;
  XdrHash get quorumSetHash => this._quorumSetHash;
  set quorumSetHash(XdrHash value) => this._quorumSetHash = value;

  List<XdrValue> _votes;
  List<XdrValue> get votes => this._votes;
  set votes(List<XdrValue> value) => this._votes = value;

  List<XdrValue> _accepted;
  List<XdrValue> get accepted => this._accepted;
  set accepted(List<XdrValue> value) => this._accepted = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPNomination encodedSCPNomination,
  ) {
    XdrHash.encode(stream, encodedSCPNomination.quorumSetHash);
    int votesSize = encodedSCPNomination.votes.length;
    stream.writeInt(votesSize);
    for (int i = 0; i < votesSize; i++) {
      XdrValue.encode(stream, encodedSCPNomination.votes[i]);
    }
    int acceptedSize = encodedSCPNomination.accepted.length;
    stream.writeInt(acceptedSize);
    for (int i = 0; i < acceptedSize; i++) {
      XdrValue.encode(stream, encodedSCPNomination.accepted[i]);
    }
  }

  static XdrSCPNomination decode(XdrDataInputStream stream) {
    XdrHash quorumSetHash = XdrHash.decode(stream);

    int votesSize = stream.readInt();
    List<XdrValue> votes = List<XdrValue>.empty(growable: true);
    for (int i = 0; i < votesSize; i++) {
      votes.add(XdrValue.decode(stream));
    }

    int acceptedSize = stream.readInt();
    List<XdrValue> accepted = List<XdrValue>.empty(growable: true);
    for (int i = 0; i < acceptedSize; i++) {
      accepted.add(XdrValue.decode(stream));
    }
    return XdrSCPNomination(quorumSetHash, votes, accepted);
  }
}
