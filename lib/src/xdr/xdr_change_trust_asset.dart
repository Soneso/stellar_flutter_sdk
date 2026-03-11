// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'txrep_helper.dart';
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

  @override
  void toTxRep(String prefix, List<String> lines) {
    if (discriminant == XdrAssetType.ASSET_TYPE_POOL_SHARE) {
      super.toTxRep(prefix, lines);
    } else {
      lines.add('$prefix: ${TxRepHelper.formatChangeTrustAsset(this)}');
    }
  }

  static XdrChangeTrustAsset fromTxRep(Map<String, String> map, String prefix) {
    // Check for compact format (single value at prefix).
    String? compactValue = TxRepHelper.getValue(map, prefix);
    if (compactValue != null) {
      return TxRepHelper.parseChangeTrustAsset(compactValue);
    }
    // Fall back to expanded format (pool share).
    var b = XdrChangeTrustAssetBase.fromTxRep(map, prefix);
    var result = XdrChangeTrustAsset(b.discriminant);
    result.alphaNum4 = b.alphaNum4;
    result.alphaNum12 = b.alphaNum12;
    result.liquidityPool = b.liquidityPool;
    return result;
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
        throw ArgumentError(
          'XdrAsset cannot represent ASSET_TYPE_POOL_SHARE. '
          'Use XdrChangeTrustAsset.decode() instead.',
        );
    }
    return result;
  }
}
