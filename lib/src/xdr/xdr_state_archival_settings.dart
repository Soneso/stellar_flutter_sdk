// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint32.dart';

class XdrStateArchivalSettings {
  XdrUint32 _maxEntryTTL;
  XdrUint32 get maxEntryTTL => this._maxEntryTTL;
  set maxEntryTTL(XdrUint32 value) => this.maxEntryTTL = value;

  XdrUint32 _minTemporaryTTL;
  XdrUint32 get minTemporaryTTL => this._minTemporaryTTL;
  set minTemporaryTTL(XdrUint32 value) => this._minTemporaryTTL = value;

  XdrUint32 _minPersistentTTL;
  XdrUint32 get minPersistentTTL => this._minPersistentTTL;
  set minPersistentTTL(XdrUint32 value) => this.minPersistentTTL = value;

  // rent_fee = wfee_rate_average / rent_rate_denominator_for_type
  XdrInt64 _persistentRentRateDenominator;
  XdrInt64 get persistentRentRateDenominator =>
      this._persistentRentRateDenominator;
  set persistentRentRateDenominator(XdrInt64 value) =>
      this._persistentRentRateDenominator = value;

  XdrInt64 _tempRentRateDenominator;
  XdrInt64 get tempRentRateDenominator => this._tempRentRateDenominator;
  set tempRentRateDenominator(XdrInt64 value) =>
      this._tempRentRateDenominator = value;

  // max number of entries that emit archival meta in a single ledger
  XdrUint32 _maxEntriesToArchive;
  XdrUint32 get maxEntriesToArchive => this._maxEntriesToArchive;
  set maxEntriesToArchive(XdrUint32 value) => this._maxEntriesToArchive = value;

  // Number of snapshots to use when calculating average live Soroban State size
  XdrUint32 _liveSorobanStateSizeWindowSampleSize;
  XdrUint32 get liveSorobanStateSizeWindowSampleSize =>
      this._liveSorobanStateSizeWindowSampleSize;
  set liveSorobanStateSizeWindowSampleSize(XdrUint32 value) =>
      this._liveSorobanStateSizeWindowSampleSize = value;

  // How often to sample the live Soroban State size for the average, in ledgers
  XdrUint32 _liveSorobanStateSizeWindowSamplePeriod;
  XdrUint32 get liveSorobanStateSizeWindowSamplePeriod =>
      this._liveSorobanStateSizeWindowSamplePeriod;
  set liveSorobanStateSizeWindowSamplePeriod(XdrUint32 value) =>
      this._liveSorobanStateSizeWindowSamplePeriod = value;

  // Maximum number of bytes that we scan for eviction per ledger
  XdrUint32 _evictionScanSize;
  XdrUint32 get evictionScanSize => this._evictionScanSize;
  set evictionScanSize(XdrUint32 value) => this._evictionScanSize = value;

  // Lowest BucketList level to be scanned to evict entries
  XdrUint32 _startingEvictionScanLevel;
  XdrUint32 get startingEvictionScanLevel => this._startingEvictionScanLevel;
  set startingEvictionScanLevel(XdrUint32 value) =>
      this._startingEvictionScanLevel = value;

  XdrStateArchivalSettings(
    this._maxEntryTTL,
    this._minTemporaryTTL,
    this._minPersistentTTL,
    this._persistentRentRateDenominator,
    this._tempRentRateDenominator,
    this._maxEntriesToArchive,
    this._liveSorobanStateSizeWindowSampleSize,
    this._liveSorobanStateSizeWindowSamplePeriod,
    this._evictionScanSize,
    this._startingEvictionScanLevel,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrStateArchivalSettings encoded,
  ) {
    XdrUint32.encode(stream, encoded.maxEntryTTL);
    XdrUint32.encode(stream, encoded.minTemporaryTTL);
    XdrUint32.encode(stream, encoded.minPersistentTTL);
    XdrInt64.encode(stream, encoded.persistentRentRateDenominator);
    XdrInt64.encode(stream, encoded.tempRentRateDenominator);
    XdrUint32.encode(stream, encoded.maxEntriesToArchive);
    XdrUint32.encode(stream, encoded.liveSorobanStateSizeWindowSampleSize);
    XdrUint32.encode(stream, encoded.liveSorobanStateSizeWindowSamplePeriod);
    XdrUint32.encode(stream, encoded.evictionScanSize);
    XdrUint32.encode(stream, encoded.startingEvictionScanLevel);
  }

  static XdrStateArchivalSettings decode(XdrDataInputStream stream) {
    XdrUint32 maxEntryTTL = XdrUint32.decode(stream);
    XdrUint32 minTemporaryTTL = XdrUint32.decode(stream);
    XdrUint32 minPersistentTTL = XdrUint32.decode(stream);
    XdrInt64 persistentRentRateDenominator = XdrInt64.decode(stream);
    XdrInt64 tempRentRateDenominator = XdrInt64.decode(stream);
    XdrUint32 maxEntriesToArchive = XdrUint32.decode(stream);
    XdrUint32 liveSorobanStateSizeWindowSampleSize = XdrUint32.decode(stream);
    XdrUint32 liveSorobanStateSizeWindowSamplePeriod = XdrUint32.decode(stream);
    XdrUint32 evictionScanSize = XdrUint32.decode(stream);
    XdrUint32 startingEvictionScanLevel = XdrUint32.decode(stream);

    return XdrStateArchivalSettings(
      maxEntryTTL,
      minTemporaryTTL,
      minPersistentTTL,
      persistentRentRateDenominator,
      tempRentRateDenominator,
      maxEntriesToArchive,
      liveSorobanStateSizeWindowSampleSize,
      liveSorobanStateSizeWindowSamplePeriod,
      evictionScanSize,
      startingEvictionScanLevel,
    );
  }
}
