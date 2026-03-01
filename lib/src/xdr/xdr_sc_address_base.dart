// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_claimable_balance_id.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_muxed_account_med25519.dart';
import 'xdr_sc_address_type.dart';

class XdrSCAddressBase {
  XdrSCAddressBase(this._type);
  XdrSCAddressType _type;
  XdrSCAddressType get discriminant => this._type;
  set discriminant(XdrSCAddressType value) => this._type = value;

  XdrAccountID? _accountId;
  XdrAccountID? get accountId => this._accountId;
  set accountId(XdrAccountID? value) => this._accountId = value;

  XdrHash? _contractId;
  XdrHash? get contractId => this._contractId;
  set contractId(XdrHash? value) => this._contractId = value;

  XdrMuxedAccountMed25519? _muxedAccount;
  XdrMuxedAccountMed25519? get muxedAccount => this._muxedAccount;
  set muxedAccount(XdrMuxedAccountMed25519? value) =>
      this._muxedAccount = value;

  XdrClaimableBalanceID? _claimableBalanceId;
  XdrClaimableBalanceID? get claimableBalanceId => this._claimableBalanceId;
  set claimableBalanceId(XdrClaimableBalanceID? value) =>
      this._claimableBalanceId = value;

  XdrHash? _liquidityPoolId;
  XdrHash? get liquidityPoolId => this._liquidityPoolId;
  set liquidityPoolId(XdrHash? value) => this._liquidityPoolId = value;

  static void encode(XdrDataOutputStream stream, XdrSCAddressBase encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
        XdrAccountID.encode(stream, encoded.accountId!);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT:
        XdrHash.encode(stream, encoded.contractId!);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT:
        XdrMuxedAccountMed25519.encode(stream, encoded.muxedAccount!);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE:
        XdrClaimableBalanceID.encode(stream, encoded.claimableBalanceId!);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL:
        XdrHash.encode(stream, encoded.liquidityPoolId!);
        break;
    }
  }

  static XdrSCAddressBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrSCAddressBase.new);
  }

  static T decodeAs<T extends XdrSCAddressBase>(
    XdrDataInputStream stream,
    T Function(XdrSCAddressType) constructor,
  ) {
    T decoded = constructor(XdrSCAddressType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
        decoded.accountId = XdrAccountID.decode(stream);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT:
        decoded.contractId = XdrHash.decode(stream);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT:
        decoded.muxedAccount = XdrMuxedAccountMed25519.decode(stream);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE:
        decoded.claimableBalanceId = XdrClaimableBalanceID.decode(stream);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL:
        decoded.liquidityPoolId = XdrHash.decode(stream);
        break;
    }
    return decoded;
  }
}
