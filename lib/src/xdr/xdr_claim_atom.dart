// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claim_atom_type.dart';
import 'xdr_claim_liquidity_atom.dart';
import 'xdr_claim_offer_atom.dart';
import 'xdr_claim_offer_atom_v0.dart';
import 'xdr_data_io.dart';

class XdrClaimAtom {
  XdrClaimAtom(this._type);

  XdrClaimAtomType _type;
  XdrClaimAtomType get discriminant => this._type;
  set discriminant(XdrClaimAtomType value) => this._type = value;

  XdrClaimOfferAtomV0? _v0;
  XdrClaimOfferAtomV0? get v0 => this._v0;
  set v0(XdrClaimOfferAtomV0? value) => this._v0 = value;

  XdrClaimOfferAtom? _orderBook;
  XdrClaimOfferAtom? get orderBook => this._orderBook;
  set orderBook(XdrClaimOfferAtom? value) => this._orderBook = value;

  XdrClaimLiquidityAtom? _liquidityPool;
  XdrClaimLiquidityAtom? get liquidityPool => this._liquidityPool;
  set liquidityPool(XdrClaimLiquidityAtom? value) =>
      this._liquidityPool = value;

  static void encode(XdrDataOutputStream stream, XdrClaimAtom encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrClaimAtomType.CLAIM_ATOM_TYPE_V0:
        XdrClaimOfferAtomV0.encode(stream, encoded.v0!);
        break;
      case XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK:
        XdrClaimOfferAtom.encode(stream, encoded.orderBook!);
        break;
      case XdrClaimAtomType.CLAIM_ATOM_TYPE_LIQUIDITY_POOL:
        XdrClaimLiquidityAtom.encode(stream, encoded.liquidityPool!);
        break;
    }
  }

  static XdrClaimAtom decode(XdrDataInputStream stream) {
    XdrClaimAtom decoded = XdrClaimAtom(XdrClaimAtomType.decode(stream));
    switch (decoded.discriminant) {
      case XdrClaimAtomType.CLAIM_ATOM_TYPE_V0:
        decoded.v0 = XdrClaimOfferAtomV0.decode(stream);
        break;
      case XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK:
        decoded.orderBook = XdrClaimOfferAtom.decode(stream);
        break;
      case XdrClaimAtomType.CLAIM_ATOM_TYPE_LIQUIDITY_POOL:
        decoded.liquidityPool = XdrClaimLiquidityAtom.decode(stream);
        break;
    }
    return decoded;
  }
}
