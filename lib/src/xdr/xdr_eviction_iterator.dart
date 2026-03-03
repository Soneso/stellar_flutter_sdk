// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrEvictionIterator {
  XdrUint32 _bucketListLevel;
  XdrUint32 get bucketListLevel => this._bucketListLevel;
  set bucketListLevel(XdrUint32 value) => this._bucketListLevel = value;

  bool _isCurrBucket;
  bool get isCurrBucket => this._isCurrBucket;
  set isCurrBucket(bool value) => this._isCurrBucket = value;

  XdrUint64 _bucketFileOffset;
  XdrUint64 get bucketFileOffset => this._bucketFileOffset;
  set bucketFileOffset(XdrUint64 value) => this._bucketFileOffset = value;

  XdrEvictionIterator(
    this._bucketListLevel,
    this._isCurrBucket,
    this._bucketFileOffset,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrEvictionIterator encodedEvictionIterator,
  ) {
    XdrUint32.encode(stream, encodedEvictionIterator.bucketListLevel);
    stream.writeBoolean(encodedEvictionIterator.isCurrBucket);
    XdrUint64.encode(stream, encodedEvictionIterator.bucketFileOffset);
  }

  static XdrEvictionIterator decode(XdrDataInputStream stream) {
    XdrUint32 bucketListLevel = XdrUint32.decode(stream);
    bool isCurrBucket = stream.readBoolean();
    XdrUint64 bucketFileOffset = XdrUint64.decode(stream);
    return XdrEvictionIterator(bucketListLevel, isCurrBucket, bucketFileOffset);
  }
}
