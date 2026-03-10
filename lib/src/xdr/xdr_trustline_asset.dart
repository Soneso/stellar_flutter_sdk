// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_asset_type.dart';
import 'xdr_data_io.dart';
import 'xdr_trustline_asset_base.dart';

class XdrTrustlineAsset extends XdrTrustlineAssetBase {
  XdrTrustlineAsset(super.type);

  static void encode(XdrDataOutputStream stream, XdrTrustlineAsset val) {
    XdrTrustlineAssetBase.encode(stream, val);
  }

  static XdrTrustlineAsset decode(XdrDataInputStream stream) {
    return XdrTrustlineAssetBase.decodeAs(stream, XdrTrustlineAsset.new);
  }

  static XdrTrustlineAsset fromXdrAsset(XdrAsset asset) {
    XdrTrustlineAsset result = XdrTrustlineAsset(asset.discriminant);
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
        throw Exception("Unsupported asset type");
    }
    return result;
  }
}
