// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_asset.dart';
import 'assets.dart';

/// Represents a stellar native asset.
/// See: <a href="https://www.stellar.org/developers/learn/concepts/assets.html" target="_blank">lumens (XLM)</a>
class AssetTypeNative extends Asset {
  AssetTypeNative();

  @override
  String get type => Asset.TYPE_NATIVE;

  @override
  bool operator ==(Object object) {
    return object is AssetTypeNative;
  }

  @override
  int get hashCode {
    return 0;
  }

  @override
  XdrAsset toXdr() {
    XdrAsset xdrAsset = XdrAsset();
    xdrAsset.discriminant = XdrAssetType.ASSET_TYPE_NATIVE;
    return xdrAsset;
  }
}