// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrConfigSettingContractBandwidthV0 {
  // Maximum sum of all transaction sizes in the ledger in bytes
  XdrUint32 _ledgerMaxTxsSizeBytes;
  XdrUint32 get ledgerMaxTxsSizeBytes => this._ledgerMaxTxsSizeBytes;
  set ledgerMaxTxsSizeBytes(XdrUint32 value) =>
      this._ledgerMaxTxsSizeBytes = value;

  // Maximum size in bytes for a transaction
  XdrUint32 _txMaxSizeBytes;
  XdrUint32 get txMaxSizeBytes => this._txMaxSizeBytes;
  set txMaxSizeBytes(XdrUint32 value) => this._txMaxSizeBytes = value;

  // Fee for 1 KB of transaction size
  XdrInt64 _feeTxSize1KB;
  XdrInt64 get feeTxSize1KB => this._feeTxSize1KB;
  set feeTxSize1KB(XdrInt64 value) => this._feeTxSize1KB = value;

  XdrConfigSettingContractBandwidthV0(
      this._ledgerMaxTxsSizeBytes, this._txMaxSizeBytes, this._feeTxSize1KB);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingContractBandwidthV0 encoded) {
    XdrUint32.encode(stream, encoded.ledgerMaxTxsSizeBytes);
    XdrUint32.encode(stream, encoded.txMaxSizeBytes);
    XdrInt64.encode(stream, encoded.feeTxSize1KB);
  }

  static XdrConfigSettingContractBandwidthV0 decode(XdrDataInputStream stream) {
    XdrUint32 ledgerMaxTxsSizeBytes = XdrUint32.decode(stream);
    XdrUint32 txMaxSizeBytes = XdrUint32.decode(stream);
    XdrInt64 feeTxSize1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractBandwidthV0(
        ledgerMaxTxsSizeBytes, txMaxSizeBytes, feeTxSize1KB);
  }
}
