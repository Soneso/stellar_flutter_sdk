// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_other.dart';
import 'xdr_asset.dart';
import 'xdr_account.dart';

class XdrOfferEntryFlags {
  final _value;
  const XdrOfferEntryFlags._internal(this._value);
  toString() => 'OfferEntryFlags.$_value';
  XdrOfferEntryFlags(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrOfferEntryFlags && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Issuer has authorized account to perform transactions with its credit.
  static const PASSIVE_FLAG = const XdrOfferEntryFlags._internal(1);

  static XdrOfferEntryFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return PASSIVE_FLAG;

      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrOfferEntryFlags value) {
    stream.writeInt(value.value);
  }
}

class XdrOfferEntry {
  XdrOfferEntry(this._sellerID, this._offerID, this._selling, this._buying,
      this._amount, this._price, this._flags, this._ext);
  XdrAccountID _sellerID;
  XdrAccountID get sellerID => this._sellerID;
  set sellerID(XdrAccountID value) => this._sellerID = value;

  XdrUint64 _offerID;
  XdrUint64 get offerID => this._offerID;
  set offerID(XdrUint64 value) => this._offerID = value;

  XdrAsset _selling;
  XdrAsset get selling => this._selling;
  set selling(XdrAsset value) => this._selling = value;

  XdrAsset _buying;
  XdrAsset get buying => this._buying;
  set buying(XdrAsset value) => this._buying = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  XdrPrice _price;
  XdrPrice get price => this._price;
  set price(XdrPrice value) => this._price = value;

  XdrUint32 _flags;
  XdrUint32 get flags => this._flags;
  set flags(XdrUint32 value) => this._flags = value;

  XdrOfferEntryExt _ext;
  XdrOfferEntryExt get ext => this._ext;
  set ext(XdrOfferEntryExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrOfferEntry encodedOfferEntry) {
    XdrAccountID.encode(stream, encodedOfferEntry.sellerID);
    XdrUint64.encode(stream, encodedOfferEntry.offerID);
    XdrAsset.encode(stream, encodedOfferEntry.selling);
    XdrAsset.encode(stream, encodedOfferEntry.buying);
    XdrInt64.encode(stream, encodedOfferEntry.amount);
    XdrPrice.encode(stream, encodedOfferEntry.price);
    XdrUint32.encode(stream, encodedOfferEntry.flags);
    XdrOfferEntryExt.encode(stream, encodedOfferEntry.ext);
  }

  static XdrOfferEntry decode(XdrDataInputStream stream) {
    XdrAccountID sellerID = XdrAccountID.decode(stream);
    XdrUint64 offerID = XdrUint64.decode(stream);
    XdrAsset selling = XdrAsset.decode(stream);
    XdrAsset buying = XdrAsset.decode(stream);
    XdrInt64 amount = XdrInt64.decode(stream);
    XdrPrice price = XdrPrice.decode(stream);
    XdrUint32 flags = XdrUint32.decode(stream);
    XdrOfferEntryExt ext = XdrOfferEntryExt.decode(stream);
    return XdrOfferEntry(
        sellerID, offerID, selling, buying, amount, price, flags, ext);
  }
}

class XdrOfferEntryExt {
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrOfferEntryExt(this._v);

  static void encode(
      XdrDataOutputStream stream, XdrOfferEntryExt encodedOfferEntryExt) {
    stream.writeInt(encodedOfferEntryExt.discriminant);
    switch (encodedOfferEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrOfferEntryExt decode(XdrDataInputStream stream) {
    XdrOfferEntryExt decodedOfferEntryExt = XdrOfferEntryExt(stream.readInt());
    switch (decodedOfferEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedOfferEntryExt;
  }
}

class XdrManageOfferEffect {
  final _value;
  const XdrManageOfferEffect._internal(this._value);
  toString() => 'ManageOfferEffect.$_value';
  XdrManageOfferEffect(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrManageOfferEffect && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const MANAGE_OFFER_CREATED = const XdrManageOfferEffect._internal(0);
  static const MANAGE_OFFER_UPDATED = const XdrManageOfferEffect._internal(1);
  static const MANAGE_OFFER_DELETED = const XdrManageOfferEffect._internal(2);

  static XdrManageOfferEffect decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MANAGE_OFFER_CREATED;
      case 1:
        return MANAGE_OFFER_UPDATED;
      case 2:
        return MANAGE_OFFER_DELETED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrManageOfferEffect value) {
    stream.writeInt(value.value);
  }
}

class XdrCreatePassiveSellOfferOp {
  XdrCreatePassiveSellOfferOp(
      this._selling, this._buying, this._amount, this._price);

  XdrAsset _selling;
  XdrAsset get selling => this._selling;
  set selling(XdrAsset value) => this._selling = value;

  XdrAsset _buying;
  XdrAsset get buying => this._buying;
  set buying(XdrAsset value) => this._buying = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  XdrPrice _price;
  XdrPrice get price => this._price;
  set price(XdrPrice value) => this._price = value;

  static void encode(XdrDataOutputStream stream,
      XdrCreatePassiveSellOfferOp encodedCreatePassiveOfferOp) {
    XdrAsset.encode(stream, encodedCreatePassiveOfferOp.selling);
    XdrAsset.encode(stream, encodedCreatePassiveOfferOp.buying);
    XdrBigInt64.encode(stream, encodedCreatePassiveOfferOp.amount);
    XdrPrice.encode(stream, encodedCreatePassiveOfferOp.price);
  }

  static XdrCreatePassiveSellOfferOp decode(XdrDataInputStream stream) {
    return XdrCreatePassiveSellOfferOp(
        XdrAsset.decode(stream),
        XdrAsset.decode(stream),
        XdrBigInt64.decode(stream),
        XdrPrice.decode(stream));
  }
}

class XdrManageBuyOfferOp {
  XdrAsset _selling;
  XdrAsset get selling => this._selling;
  set selling(XdrAsset value) => this._selling = value;

  XdrAsset _buying;
  XdrAsset get buying => this._buying;
  set buying(XdrAsset value) => this._buying = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  XdrPrice _price;
  XdrPrice get price => this._price;
  set price(XdrPrice value) => this._price = value;

  XdrUint64 _offerID;
  XdrUint64 get offerID => this._offerID;
  set offerID(XdrUint64 value) => this._offerID = value;

  static void encode(
      XdrDataOutputStream stream, XdrManageBuyOfferOp encodedManageOfferOp) {
    XdrAsset.encode(stream, encodedManageOfferOp.selling);
    XdrAsset.encode(stream, encodedManageOfferOp.buying);
    XdrBigInt64.encode(stream, encodedManageOfferOp.amount);
    XdrPrice.encode(stream, encodedManageOfferOp.price);
    XdrUint64.encode(stream, encodedManageOfferOp.offerID);
  }

  static XdrManageBuyOfferOp decode(XdrDataInputStream stream) {
    return XdrManageBuyOfferOp(
        XdrAsset.decode(stream),
        XdrAsset.decode(stream),
        XdrBigInt64.decode(stream),
        XdrPrice.decode(stream),
        XdrUint64.decode(stream));
  }

  XdrManageBuyOfferOp(
      this._selling, this._buying, this._amount, this._price, this._offerID);
}

class XdrManageSellOfferOp {
  XdrAsset _selling;
  XdrAsset get selling => this._selling;
  set selling(XdrAsset value) => this._selling = value;

  XdrAsset _buying;
  XdrAsset get buying => this._buying;
  set buying(XdrAsset value) => this._buying = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  XdrPrice _price;
  XdrPrice get price => this._price;
  set price(XdrPrice value) => this._price = value;

  XdrUint64 _offerID;
  XdrUint64 get offerID => this._offerID;
  set offerID(XdrUint64 value) => this._offerID = value;

  static void encode(
      XdrDataOutputStream stream, XdrManageSellOfferOp encodedManageOfferOp) {
    XdrAsset.encode(stream, encodedManageOfferOp.selling);
    XdrAsset.encode(stream, encodedManageOfferOp.buying);
    XdrBigInt64.encode(stream, encodedManageOfferOp.amount);
    XdrPrice.encode(stream, encodedManageOfferOp.price);
    XdrUint64.encode(stream, encodedManageOfferOp.offerID);
  }

  static XdrManageSellOfferOp decode(XdrDataInputStream stream) {
    return XdrManageSellOfferOp(
        XdrAsset.decode(stream),
        XdrAsset.decode(stream),
        XdrBigInt64.decode(stream),
        XdrPrice.decode(stream),
        XdrUint64.decode(stream));
  }

  XdrManageSellOfferOp(
      this._selling, this._buying, this._amount, this._price, this._offerID);
}

class XdrManageOfferResult {
  XdrManageOfferResultCode _code;
  XdrManageOfferResultCode get discriminant => this._code;
  set discriminant(XdrManageOfferResultCode value) => this._code = value;

  XdrManageOfferSuccessResult? _success;
  XdrManageOfferSuccessResult? get success => this._success;
  set success(XdrManageOfferSuccessResult? value) => this._success = value;

  XdrManageOfferResult(this._code, this._success);

  static void encode(XdrDataOutputStream stream,
      XdrManageOfferResult encodedManageOfferResult) {
    stream.writeInt(encodedManageOfferResult.discriminant.value);
    switch (encodedManageOfferResult.discriminant) {
      case XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS:
        XdrManageOfferSuccessResult.encode(
            stream, encodedManageOfferResult.success!);
        break;
      default:
        break;
    }
  }

  static XdrManageOfferResult decode(XdrDataInputStream stream) {
    XdrManageOfferResult decodedManageOfferResult =
        XdrManageOfferResult(XdrManageOfferResultCode.decode(stream), null);
    switch (decodedManageOfferResult.discriminant) {
      case XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS:
        decodedManageOfferResult.success =
            XdrManageOfferSuccessResult.decode(stream);
        break;
      default:
        break;
    }
    return decodedManageOfferResult;
  }
}

class XdrManageOfferSuccessResult {
  List<XdrClaimAtom> _offersClaimed;
  List<XdrClaimAtom> get offersClaimed => this._offersClaimed;
  set offersClaimed(List<XdrClaimAtom> value) => this._offersClaimed = value;

  XdrManageOfferSuccessResultOffer _offer;
  XdrManageOfferSuccessResultOffer get offer => this._offer;
  set offer(XdrManageOfferSuccessResultOffer value) => this._offer = value;

  XdrManageOfferSuccessResult(this._offersClaimed, this._offer);

  static void encode(XdrDataOutputStream stream,
      XdrManageOfferSuccessResult encodedManageOfferSuccessResult) {
    int offersClaimedSize =
        encodedManageOfferSuccessResult.offersClaimed.length;
    stream.writeInt(offersClaimedSize);
    for (int i = 0; i < offersClaimedSize; i++) {
      XdrClaimAtom.encode(
          stream, encodedManageOfferSuccessResult.offersClaimed[i]);
    }
    XdrManageOfferSuccessResultOffer.encode(
        stream, encodedManageOfferSuccessResult.offer);
  }

  static XdrManageOfferSuccessResult decode(XdrDataInputStream stream) {
    int offersClaimedSize = stream.readInt();
    var offersClaimed = List<XdrClaimAtom>.empty(growable: true);
    for (int i = 0; i < offersClaimedSize; i++) {
      offersClaimed.add(XdrClaimAtom.decode(stream));
    }
    var offer = XdrManageOfferSuccessResultOffer.decode(stream);
    return XdrManageOfferSuccessResult(offersClaimed, offer);
  }
}

class XdrManageOfferSuccessResultOffer {
  XdrManageOfferEffect _effect;
  XdrManageOfferEffect get discriminant => this._effect;
  set discriminant(XdrManageOfferEffect value) => this._effect = value;

  XdrOfferEntry? _offer;
  XdrOfferEntry? get offer => this._offer;
  set offer(XdrOfferEntry? value) => this._offer = value;

  XdrManageOfferSuccessResultOffer(this._effect, this._offer);

  static void encode(XdrDataOutputStream stream,
      XdrManageOfferSuccessResultOffer encodedManageOfferSuccessResultOffer) {
    stream.writeInt(encodedManageOfferSuccessResultOffer.discriminant.value);
    switch (encodedManageOfferSuccessResultOffer.discriminant) {
      case XdrManageOfferEffect.MANAGE_OFFER_CREATED:
      case XdrManageOfferEffect.MANAGE_OFFER_UPDATED:
        XdrOfferEntry.encode(
            stream, encodedManageOfferSuccessResultOffer.offer!);
        break;
      default:
        break;
    }
  }

  static XdrManageOfferSuccessResultOffer decode(XdrDataInputStream stream) {
    XdrManageOfferSuccessResultOffer decodedManageOfferSuccessResultOffer =
        XdrManageOfferSuccessResultOffer(
            XdrManageOfferEffect.decode(stream), null);

    switch (decodedManageOfferSuccessResultOffer.discriminant) {
      case XdrManageOfferEffect.MANAGE_OFFER_CREATED:
      case XdrManageOfferEffect.MANAGE_OFFER_UPDATED:
        decodedManageOfferSuccessResultOffer.offer =
            XdrOfferEntry.decode(stream);
        break;
      default:
        break;
    }
    return decodedManageOfferSuccessResultOffer;
  }
}

class XdrManageOfferResultCode {
  final _value;
  const XdrManageOfferResultCode._internal(this._value);
  toString() => 'ManageOfferResultCode.$_value';
  XdrManageOfferResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrManageOfferResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const MANAGE_OFFER_SUCCESS =
      const XdrManageOfferResultCode._internal(0);

  /// Generated offer would be invalid.
  static const MANAGE_OFFER_MALFORMED =
      const XdrManageOfferResultCode._internal(-1);

  /// No trust line for what we're selling.
  static const MANAGE_OFFER_SELL_NO_TRUST =
      const XdrManageOfferResultCode._internal(-2);

  /// No trust line for what we're buying.
  static const MANAGE_OFFER_BUY_NO_TRUST =
      const XdrManageOfferResultCode._internal(-3);

  /// Not authorized to sell.
  static const MANAGE_OFFER_SELL_NOT_AUTHORIZED =
      const XdrManageOfferResultCode._internal(-4);

  /// Not authorized to buy.
  static const MANAGE_OFFER_BUY_NOT_AUTHORIZED =
      const XdrManageOfferResultCode._internal(-5);

  /// Can't receive more of what it's buying.
  static const MANAGE_OFFER_LINE_FULL =
      const XdrManageOfferResultCode._internal(-6);

  /// Doesn't hold what it's trying to sell.
  static const MANAGE_OFFER_UNDERFUNDED =
      const XdrManageOfferResultCode._internal(-7);

  /// Would cross an offer from the same user.
  static const MANAGE_OFFER_CROSS_SELF =
      const XdrManageOfferResultCode._internal(-8);

  /// No issuer for what we're selling.
  static const MANAGE_OFFER_SELL_NO_ISSUER =
      const XdrManageOfferResultCode._internal(-9);

  /// No issuer for what we're buying.
  static const MANAGE_OFFER_BUY_NO_ISSUER =
      const XdrManageOfferResultCode._internal(-10);

  /// OfferID does not match an existing offer.
  static const MANAGE_OFFER_NOT_FOUND =
      const XdrManageOfferResultCode._internal(-11);

  /// Not enough funds to create a new Offer.
  static const MANAGE_OFFER_LOW_RESERVE =
      const XdrManageOfferResultCode._internal(-12);

  static XdrManageOfferResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MANAGE_OFFER_SUCCESS;
      case -1:
        return MANAGE_OFFER_MALFORMED;
      case -2:
        return MANAGE_OFFER_SELL_NO_TRUST;
      case -3:
        return MANAGE_OFFER_BUY_NO_TRUST;
      case -4:
        return MANAGE_OFFER_SELL_NOT_AUTHORIZED;
      case -5:
        return MANAGE_OFFER_BUY_NOT_AUTHORIZED;
      case -6:
        return MANAGE_OFFER_LINE_FULL;
      case -7:
        return MANAGE_OFFER_UNDERFUNDED;
      case -8:
        return MANAGE_OFFER_CROSS_SELF;
      case -9:
        return MANAGE_OFFER_SELL_NO_ISSUER;
      case -10:
        return MANAGE_OFFER_BUY_NO_ISSUER;
      case -11:
        return MANAGE_OFFER_NOT_FOUND;
      case -12:
        return MANAGE_OFFER_LOW_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrManageOfferResultCode value) {
    stream.writeInt(value.value);
  }
}
