// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_asset_type.dart';
import 'xdr_change_trust_asset_base.dart';
import 'xdr_data_io.dart';

class XdrChangeTrustAsset extends XdrChangeTrustAssetBase {
  XdrChangeTrustAsset(super.type);

  static void encode(XdrDataOutputStream stream, XdrChangeTrustAsset val) {
    XdrChangeTrustAssetBase.encode(stream, val);
  }

  static XdrChangeTrustAsset decode(XdrDataInputStream stream) {
    return XdrChangeTrustAssetBase.decodeAs(stream, XdrChangeTrustAsset.new);
  }

  static XdrChangeTrustAsset fromXdrAsset(XdrAsset asset) {
    XdrChangeTrustAsset result = XdrChangeTrustAsset(asset.discriminant);
    switch (asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        result.alphaNum4 = asset.alphaNum4;
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        result.alphaNum12 = asset.alphaNum12;
        break;
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        result = asset as XdrChangeTrustAsset;
        break;
    }
    return result;
  }
}
