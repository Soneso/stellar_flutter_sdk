// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_bucket_metadata_ext.dart';
import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrBucketMetadata {

  XdrUint32 _ledgerVersion;
  XdrUint32 get ledgerVersion => this._ledgerVersion;
  set ledgerVersion(XdrUint32 value) => this._ledgerVersion = value;

  XdrBucketMetadataExt _ext;
  XdrBucketMetadataExt get ext => this._ext;
  set ext(XdrBucketMetadataExt value) => this._ext = value;

  XdrBucketMetadata(this._ledgerVersion, this._ext);

  static void encode(XdrDataOutputStream stream, XdrBucketMetadata encodedBucketMetadata) {
    XdrUint32.encode(stream, encodedBucketMetadata.ledgerVersion);
    XdrBucketMetadataExt.encode(stream, encodedBucketMetadata.ext);
  }

  static XdrBucketMetadata decode(XdrDataInputStream stream) {
    XdrUint32 ledgerVersion = XdrUint32.decode(stream);
    XdrBucketMetadataExt ext = XdrBucketMetadataExt.decode(stream);
    return XdrBucketMetadata(ledgerVersion, ext);
  }
}
