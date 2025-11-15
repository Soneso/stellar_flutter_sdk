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

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [object] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object object) {
    return object is AssetTypeNative;
  }

  /// Returns the hash code for this instance based on its fields.
  @override
  int get hashCode {
    return 0;
  }

  /// Converts this asset to its XDR Asset representation.
  ///
  /// Returns: XDR Asset for the native asset (XLM).
  @override
  XdrAsset toXdr() {
    return XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  }

  /// Converts this asset to its XDR ChangeTrustAsset representation.
  ///
  /// Returns: XDR ChangeTrustAsset for the native asset (XLM).
  @override
  XdrChangeTrustAsset toXdrChangeTrustAsset() {
    return XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  }

  /// Converts this asset to its XDR TrustlineAsset representation.
  ///
  /// Returns: XDR TrustlineAsset for the native asset (XLM).
  @override
  XdrTrustlineAsset toXdrTrustLineAsset() {
    return XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  }
}
