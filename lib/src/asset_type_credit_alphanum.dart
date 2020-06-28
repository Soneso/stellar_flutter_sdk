// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'util.dart';

/// Base class for AssetTypeCreditAlphaNum4 and AssetTypeCreditAlphaNum12 subclasses.
abstract class AssetTypeCreditAlphaNum extends Asset {
  String mCode;
  String issuerId;

  AssetTypeCreditAlphaNum(String code, this.issuerId) {
    checkNotNull(code, "code cannot be null");
    checkNotNull(issuerId, "issuer id cannot be null");
    mCode = code;
  }

  /// Returns the asset code
  String get code => String.fromCharCodes(mCode.codeUnits);

  @override
  int get hashCode {
    return "${this.code}\$${this.issuerId}".hashCode;
  }

  @override
  bool operator ==(Object object) {
    if (!(object is AssetTypeCreditAlphaNum)) {
      return false;
    }

    AssetTypeCreditAlphaNum o = object as AssetTypeCreditAlphaNum;

    return (this.code == o.code) && (this.issuerId == o.issuerId);
  }
}
