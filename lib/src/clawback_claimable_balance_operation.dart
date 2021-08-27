// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
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

class ClawbackClaimableBalanceOperation extends Operation {
  String? _balanceId;

  ClawbackClaimableBalanceOperation(String balanceId) {
    this._balanceId = checkNotNull(balanceId, "balanceId cannot be null");
  }

  String? get balanceId => _balanceId;

  @override
  XdrOperationBody toOperationBody() {
    XdrClawbackClaimableBalanceOp op = XdrClawbackClaimableBalanceOp();

    XdrClaimableBalanceID bId = XdrClaimableBalanceID();
    bId.discriminant = XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0;
    Uint8List bytes = Util.hexToBytes(balanceId!.toUpperCase());
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      bytes = bytes.sublist(bytes.length - 32, bytes.length);
    }

    XdrHash hash = XdrHash();
    hash.hash = bytes;
    bId.v0 = hash;
    op.balanceID = bId;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE;
    body.clawbackClaimableBalanceOp = op;
    return body;
  }

  static ClawbackClaimableBalanceOperation builder(XdrClawbackClaimableBalanceOp op) {
    String balanceId = String.fromCharCodes(op.balanceID!.v0!.hash!);
    return ClawbackClaimableBalanceOperation(balanceId);
  }
}

class ClawbackClaimableBalanceOperationBuilder {
  String? _balanceId;
  MuxedAccount? _mSourceAccount;

  ClawbackClaimableBalanceOperationBuilder(this._balanceId);

  /// Sets the source account for this operation represented by [sourceAccount].
  ClawbackClaimableBalanceOperationBuilder setSourceAccount(String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccountId].
  ClawbackClaimableBalanceOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  ///Builds an operation
  ClawbackClaimableBalanceOperation build() {
    ClawbackClaimableBalanceOperation operation = ClawbackClaimableBalanceOperation(_balanceId!);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
