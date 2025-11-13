// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_asset.dart';
import 'assets.dart';

/// Represents the native Stellar asset (XLM/lumens).
///
/// The native asset is the built-in cryptocurrency of the Stellar network.
/// Unlike other assets, it doesn't require a trustline and is used to pay
/// transaction fees and minimum account balances.
///
/// See [Stellar developer docs](https://developers.stellar.org)
/// for more information.
class AssetTypeNative extends Asset {
  /// Creates an instance of the native Stellar asset (XLM).
  ///
  /// The native asset requires no parameters as there is only one native
  /// asset on the Stellar network (lumens/XLM). It doesn't require a trustline
  /// and is automatically available to all accounts.
  ///
  /// Example:
  /// ```dart
  /// Asset xlm = AssetTypeNative();
  /// ```
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
    return XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  }

  @override
  XdrChangeTrustAsset toXdrChangeTrustAsset() {
    return XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  }

  @override
  XdrTrustlineAsset toXdrTrustLineAsset() {
    return XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  }
}
