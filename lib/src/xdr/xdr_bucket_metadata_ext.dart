// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_bucket_list_type.dart';
import 'xdr_data_io.dart';

class XdrBucketMetadataExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrBucketListType? _bucketListType;

  XdrBucketListType? get bucketListType => this._bucketListType;

  XdrBucketMetadataExt(this._v);

  set bucketListType(XdrBucketListType? value) => this._bucketListType = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrBucketMetadataExt encodedBucketMetadataExt,
  ) {
    stream.writeInt(encodedBucketMetadataExt.discriminant);
    switch (encodedBucketMetadataExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrBucketListType.encode(
          stream,
          encodedBucketMetadataExt._bucketListType!,
        );
        break;
      default:
        break;
    }
  }

  static XdrBucketMetadataExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrBucketMetadataExt decodedBucketMetadataExt = XdrBucketMetadataExt(
      discriminant,
    );
    switch (decodedBucketMetadataExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedBucketMetadataExt._bucketListType = XdrBucketListType.decode(
          stream,
        );
        break;
      default:
        break;
    }
    return decodedBucketMetadataExt;
  }
}
