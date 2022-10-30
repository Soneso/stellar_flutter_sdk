// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'xdr/xdr_ledger.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import "dart:typed_data";
import 'xdr/xdr_type.dart';

class ClaimClaimableBalanceOperation extends Operation {
  String _balanceId;

  ClaimClaimableBalanceOperation(this._balanceId);

  String get balanceId => _balanceId;

  @override
  XdrOperationBody toOperationBody() {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID(
        XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
    Uint8List bytes = Util.hexToBytes(balanceId.toUpperCase());
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      bytes = bytes.sublist(bytes.length - 32, bytes.length);
    }

    XdrHash hash = XdrHash();
    hash.hash = bytes;
    bId.v0 = hash;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CLAIM_CLAIMABLE_BALANCE;
    body.claimClaimableBalanceOp = XdrClaimClaimableBalanceOp(bId);
    return body;
  }

  static ClaimClaimableBalanceOperationBuilder builder(
      XdrClaimClaimableBalanceOp op) {
    String balanceId = Util.bytesToHex(op.balanceID.v0!.hash!);
    return ClaimClaimableBalanceOperationBuilder(balanceId);
  }
}

class ClaimClaimableBalanceOperationBuilder {
  String _balanceId;
  MuxedAccount? _mSourceAccount;

  ClaimClaimableBalanceOperationBuilder(this._balanceId);

  /// Sets the source account for this operation represented by [sourceAccountId].
  ClaimClaimableBalanceOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  ClaimClaimableBalanceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  ClaimClaimableBalanceOperation build() {
    ClaimClaimableBalanceOperation operation =
        ClaimClaimableBalanceOperation(_balanceId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
