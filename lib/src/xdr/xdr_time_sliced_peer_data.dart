// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_peer_stats.dart';
import 'xdr_uint32.dart';

class XdrTimeSlicedPeerData {

  XdrPeerStats _peerStats;
  XdrPeerStats get peerStats => this._peerStats;
  set peerStats(XdrPeerStats value) => this._peerStats = value;

  XdrUint32 _averageLatencyMs;
  XdrUint32 get averageLatencyMs => this._averageLatencyMs;
  set averageLatencyMs(XdrUint32 value) => this._averageLatencyMs = value;

  XdrTimeSlicedPeerData(this._peerStats, this._averageLatencyMs);

  static void encode(XdrDataOutputStream stream, XdrTimeSlicedPeerData encodedTimeSlicedPeerData) {
    XdrPeerStats.encode(stream, encodedTimeSlicedPeerData.peerStats);
    XdrUint32.encode(stream, encodedTimeSlicedPeerData.averageLatencyMs);
  }

  static XdrTimeSlicedPeerData decode(XdrDataInputStream stream) {
    XdrPeerStats peerStats = XdrPeerStats.decode(stream);
    XdrUint32 averageLatencyMs = XdrUint32.decode(stream);
    return XdrTimeSlicedPeerData(peerStats, averageLatencyMs);
  }
}
