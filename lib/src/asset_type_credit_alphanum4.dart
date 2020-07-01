// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'asset_type_credit_alphanum.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_asset.dart';
import 'key_pair.dart';
import 'util.dart';

/// Represents all assets with codes 1-4 characters long.
class AssetTypeCreditAlphaNum4 extends AssetTypeCreditAlphaNum {
  AssetTypeCreditAlphaNum4(String code, String issuerId)
      : super(code, issuerId) {
    if (code.length < 1 || code.length > 4) {
      throw new AssetCodeLengthInvalidException();
    }
  }

  @override
  String get type => "credit_alphanum4";

  @override
  XdrAsset toXdr() {
    XdrAsset xdrAsset = XdrAsset();
    xdrAsset.discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4;
    XdrAssetAlphaNum4 credit = XdrAssetAlphaNum4();
    credit.assetCode = Util.paddedByteArrayString(mCode, 4);
    XdrAccountID accountID = XdrAccountID();
    accountID.accountID = KeyPair.fromAccountId(issuerId).xdrPublicKey;
    credit.issuer = accountID;
    xdrAsset.alphaNum4 = credit;
    return xdrAsset;
  }
}
