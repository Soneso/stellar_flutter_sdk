// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/asset_type_credit_alphanum12.dart';
import 'package:stellar_flutter_sdk/src/asset_type_credit_alphanum4.dart';
import 'package:stellar_flutter_sdk/src/operation.dart';
import 'package:decimal/decimal.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../../asset_type_credit_alphanum.dart';

String txRepOpTypeUpperCase(Operation operation) {
  int value = operation.toXdr().body.discriminant.value;
  switch (value) {
    case 0:
      return 'CREATE_ACCOUNT';
    case 1:
      return 'PAYMENT';
    case 2:
      return 'PATH_PAYMENT_STRICT_RECEIVE';
    case 3:
      return 'MANAGE_SELL_OFFER';
    case 4:
      return 'CREATE_PASSIVE_SELL_OFFER';
    case 5:
      return 'SET_OPTIONS';
    case 6:
      return 'CHANGE_TRUST';
    case 7:
      return 'ALLOW_TRUST';
    case 8:
      return 'ACCOUNT_MERGE';
    case 9:
      return 'INFLATION';
    case 10:
      return 'MANAGE_DATA';
    case 11:
      return 'BUMP_SEQUENCE';
    case 12:
      return 'MANAGE_BUY_OFFER';
    case 13:
      return 'PATH_PAYMENT_STRICT_SEND';
    default:
      throw Exception("Unknown enum value: $value");
  }
}

String txRepOpType(Operation operation) {
  int value = operation.toXdr().body.discriminant.value;
  switch (value) {
    case 0:
      return 'createAccountOp';
    case 1:
      return 'paymentOp';
    case 2:
      return 'pathPaymentStrictReceiveOp';
    case 3:
      return 'manageSellOfferOp';
    case 4:
      return 'createPasiveSellOfferOp';
    case 5:
      return 'setOptionsOp';
    case 6:
      return 'changeTrustOp';
    case 7:
      return 'allowTrustOp';
    case 8:
      return 'accountMergeOp';
    case 9:
      return 'inflationOp';
    case 10:
      return 'manageDataOp';
    case 11:
      return 'bumpSequenceOp';
    case 12:
      return 'manageBuyOfferOp';
    case 13:
      return 'pathPaymentStrictSendOp';
    default:
      throw Exception("Unknown enum value: $value");
  }
}

String toAmount(String value) {
  Decimal amount = Decimal.parse(value) * Decimal.parse('10000000.00');
  return amount.toString();
}

String fromAmount(String value) {
  Decimal amount = Decimal.parse(value) / Decimal.parse('10000000.00');
  return amount.toString();
}

String encodeAsset(Asset asset) {
  if (asset is AssetTypeNative) {
    return Asset.TYPE_NATIVE;
  } else if (asset is AssetTypeCreditAlphaNum) {
    AssetTypeCreditAlphaNum creditAsset = asset;
    return creditAsset.code + ":" + creditAsset.issuerId;
  } else {
    throw Exception("unsupported asset " + asset.type);
  }
}

Asset decodeAsset(String asset) {
  if (asset == null) {
    return null;
  }
  if (asset == Asset.TYPE_NATIVE) {
    return Asset.NATIVE;
  } else {
    List<String> components = asset.split(':');
    if (components.length != 2) {
      return null;
    } else {
      String code = components[0].trim();
      String issuerId = components[1].trim();
      if (code.length <= 4) {
        return AssetTypeCreditAlphaNum4(code, issuerId);
      } else if (code.length <= 12) {
        return AssetTypeCreditAlphaNum12(code, issuerId);
      }
    }
  }
  return null;
}
