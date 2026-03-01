// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_bounds.dart';
import 'xdr_signer_key.dart';
import 'xdr_time_bounds.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrPreconditionsV2 {
  XdrPreconditionsV2(
    this._minSeqAge,
    this._minSeqLedgerGap,
    this._extraSigners,
  );

  XdrTimeBounds? _timeBounds;
  XdrTimeBounds? get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds? value) => this._timeBounds = value;

  XdrLedgerBounds? _ledgerBounds;
  XdrLedgerBounds? get ledgerBounds => this._ledgerBounds;
  set ledgerBounds(XdrLedgerBounds? value) => this._ledgerBounds = value;

  XdrBigInt64? _sequenceNumber;
  XdrBigInt64? get sequenceNumber => this._sequenceNumber;
  set sequenceNumber(XdrBigInt64? value) => this._sequenceNumber = value;

  XdrUint64 _minSeqAge;
  XdrUint64 get minSeqAge => this._minSeqAge;
  set minSeqAge(XdrUint64 value) => this._minSeqAge = value;

  XdrUint32 _minSeqLedgerGap;
  XdrUint32 get minSeqLedgerGap => this._minSeqLedgerGap;
  set minSeqLedgerGap(XdrUint32 value) => this._minSeqLedgerGap = value;

  List<XdrSignerKey> _extraSigners;
  List<XdrSignerKey> get extraSigners => this._extraSigners;
  set extraSigners(List<XdrSignerKey> value) => this._extraSigners = value;

  static void encode(XdrDataOutputStream stream, XdrPreconditionsV2 encoded) {
    if (encoded._timeBounds != null) {
      stream.writeInt(1);
      XdrTimeBounds.encode(stream, encoded._timeBounds!);
    } else {
      stream.writeInt(0);
    }
    if (encoded._ledgerBounds != null) {
      stream.writeInt(1);
      XdrLedgerBounds.encode(stream, encoded._ledgerBounds!);
    } else {
      stream.writeInt(0);
    }

    if (encoded.sequenceNumber != null) {
      stream.writeInt(1);
      XdrBigInt64.encode(stream, encoded.sequenceNumber!);
    } else {
      stream.writeInt(0);
    }

    XdrUint64.encode(stream, encoded.minSeqAge);
    XdrUint32.encode(stream, encoded.minSeqLedgerGap);
    int signersSize = encoded.extraSigners.length;
    stream.writeInt(signersSize);
    for (int i = 0; i < signersSize; i++) {
      XdrSignerKey.encode(stream, encoded.extraSigners[i]);
    }
  }

  static XdrPreconditionsV2 decode(XdrDataInputStream stream) {
    XdrTimeBounds? tb;
    XdrLedgerBounds? lb;
    XdrBigInt64? sqN;

    int timeBoundsPresent = stream.readInt();
    if (timeBoundsPresent != 0) {
      tb = XdrTimeBounds.decode(stream);
    }

    int ledgerBoundsPresent = stream.readInt();
    if (ledgerBoundsPresent != 0) {
      lb = XdrLedgerBounds.decode(stream);
    }

    int sequenceNumberPresent = stream.readInt();
    if (sequenceNumberPresent != 0) {
      sqN = XdrBigInt64.decode(stream);
    }

    XdrUint64 minSA = XdrUint64.decode(stream);
    XdrUint32 minSLG = XdrUint32.decode(stream);

    int signersSize = stream.readInt();
    List<XdrSignerKey> keys = List<XdrSignerKey>.empty(growable: true);
    for (int i = 0; i < signersSize; i++) {
      keys.add(XdrSignerKey.decode(stream));
    }

    XdrPreconditionsV2 decoded = XdrPreconditionsV2(minSA, minSLG, keys);

    if (tb != null) {
      decoded.timeBounds = tb;
    }
    if (lb != null) {
      decoded.ledgerBounds = lb;
    }
    if (sqN != null) {
      decoded.sequenceNumber = sqN;
    }
    return decoded;
  }
}
