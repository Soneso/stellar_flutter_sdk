// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'util.dart';

/// Base class for AssetTypeCreditAlphaNum4 and AssetTypeCreditAlphaNum12 subclasses.
abstract class AssetTypeCreditAlphaNum extends Asset {
  String mCode;
  String issuer;

  AssetTypeCreditAlphaNum(String code, this.issuer) {
    checkNotNull(code, "code cannot be null");
    checkNotNull(issuer, "issuer cannot be null");
    mCode = code;
  }

  /// Returns the asset code
  String get code => String.fromCharCodes(mCode.codeUnits);

  @override
  int get hashCode {
    return "${this.code}\$${this.issuer}".hashCode;
  }

  @override
  bool operator ==(Object object) {
    if (!(object is AssetTypeCreditAlphaNum)) {
      return false;
    }

    AssetTypeCreditAlphaNum o = object as AssetTypeCreditAlphaNum;

    return (this.code == o.code) && (this.issuer == o.issuer);
  }
}
