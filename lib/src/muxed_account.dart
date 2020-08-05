// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_data_io.dart';
import 'dart:typed_data';

/// Represents a muxed account to be used in transactions sent to the stellar network.
class MuxedAccount {
  String _accountId;
  String _ed25519AccountId;
  int _id;

  MuxedAccount(this._ed25519AccountId, this._id) {
    checkNotNull(_ed25519AccountId, "_ed25519AccountId cannot be null");
  }

  static MuxedAccount fromAccountId(String accountId) {
    checkNotNull(accountId, "accountId cannot be null");
    if (accountId.startsWith('M')) {
      return fromMed25519AccountId(accountId);
    } else if (accountId.startsWith('G')) {
      return MuxedAccount(accountId, null);
    }
    return null;
  }

  static MuxedAccount fromMed25519AccountId(String med25519AccountId) {
    checkNotNull(med25519AccountId, "med25519AccountId cannot be null");
    XdrMuxedAccount xdrMuxAccount = XdrMuxedAccount();
    xdrMuxAccount.discriminant = XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519;
    Uint8List bytes = StrKey.decodeStellarMuxedAccountId(med25519AccountId);
    XdrMuxedAccountMed25519 muxMed25519 =
        XdrMuxedAccountMed25519.decode(XdrDataInputStream(bytes));
    xdrMuxAccount.med25519 = muxMed25519;
    return fromXdr(xdrMuxAccount);
  }

  String get ed25519AccountId => _ed25519AccountId;

  int get id => _id;

  String get accountId {
    if (_accountId == null) {
      XdrMuxedAccount xdrMuxedAccount = toXdr();
      if (xdrMuxedAccount.discriminant ==
          XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519) {
        XdrDataOutputStream xdrOutputStream = new XdrDataOutputStream();
        XdrMuxedAccountMed25519.encode(
            xdrOutputStream, xdrMuxedAccount.med25519);
        Uint8List bytes = Uint8List.fromList(xdrOutputStream.bytes);
        _accountId = StrKey.encodeStellarMuxedAccountId(bytes);
      } else if (xdrMuxedAccount.discriminant ==
          XdrCryptoKeyType.KEY_TYPE_ED25519) {
        _accountId = _ed25519AccountId;
      }
    }
    return _accountId;
  }

  XdrMuxedAccount toXdr() {
    if (_id == null) {
      return KeyPair.fromAccountId(_ed25519AccountId).xdrMuxedAccount;
    } else {
      XdrMuxedAccount xdrMuxAccount = XdrMuxedAccount();
      xdrMuxAccount.discriminant = XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519;
      XdrMuxedAccountMed25519 muxMed25519 = XdrMuxedAccountMed25519();
      XdrUint256 uint256 = new XdrUint256();
      uint256.uint256 = StrKey.decodeStellarAccountId(_ed25519AccountId);
      muxMed25519.ed25519 = uint256;
      XdrUint64 id64 = XdrUint64();
      id64.uint64 = _id;
      muxMed25519.id = id64;
      xdrMuxAccount.med25519 = muxMed25519;
      return xdrMuxAccount;
    }
  }

  static MuxedAccount fromXdr(XdrMuxedAccount xdrMuxedAccount) {
    checkNotNull(xdrMuxedAccount, "xdrMuxedAccount cannot be null");
    String ed25519AccountId;
    int id;
    if (xdrMuxedAccount.discriminant ==
        XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519) {
      ed25519AccountId = StrKey.encodeStellarAccountId(
          xdrMuxedAccount.med25519.ed25519.uint256);
      id = xdrMuxedAccount.med25519.id.uint64;
    } else if (xdrMuxedAccount.discriminant ==
        XdrCryptoKeyType.KEY_TYPE_ED25519) {
      ed25519AccountId =
          StrKey.encodeStellarAccountId(xdrMuxedAccount.ed25519.uint256);
    }
    return MuxedAccount(ed25519AccountId, id);
  }
}
