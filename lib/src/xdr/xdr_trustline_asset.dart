// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'txrep_helper.dart';
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

  @override
  void toTxRep(String prefix, List<String> lines) {
    if (discriminant == XdrAssetType.ASSET_TYPE_POOL_SHARE) {
      super.toTxRep(prefix, lines);
    } else {
      lines.add('$prefix: ${TxRepHelper.formatTrustlineAsset(this)}');
    }
  }

  static XdrTrustlineAsset fromTxRep(Map<String, String> map, String prefix) {
    // Check for compact format (single value at prefix).
    String? compactValue = TxRepHelper.getValue(map, prefix);
    if (compactValue != null) {
      return TxRepHelper.parseTrustlineAsset(compactValue);
    }
    // Fall back to expanded format (pool share).
    var b = XdrTrustlineAssetBase.fromTxRep(map, prefix);
    var result = XdrTrustlineAsset(b.discriminant);
    result.alphaNum4 = b.alphaNum4;
    result.alphaNum12 = b.alphaNum12;
    result.liquidityPoolID = b.liquidityPoolID;
    return result;
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
