// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'asset_type_credit_alphanum.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_asset.dart';
import 'key_pair.dart';
import 'util.dart';

/// Represents all assets with codes 5-12 characters long.
class AssetTypeCreditAlphaNum12 extends AssetTypeCreditAlphaNum {
  AssetTypeCreditAlphaNum12(String code, String issuerId)
      : super(code, issuerId) {
    if (code.length < 5 || code.length > 12) {
      throw new AssetCodeLengthInvalidException();
    }
  }

  @override
  String get type => "credit_alphanum12";

  @override
  XdrAsset toXdr() {
    XdrAsset xdrAsset = XdrAsset();
    xdrAsset.discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12;
    XdrAssetAlphaNum12 credit = XdrAssetAlphaNum12();
    credit.assetCode = Util.paddedByteArrayString(mCode, 12);
    XdrAccountID accountID = XdrAccountID();
    accountID.accountID = KeyPair.fromAccountId(issuerId).xdrPublicKey;
    credit.issuer = accountID;
    xdrAsset.alphaNum12 = credit;
    return xdrAsset;
  }
}
