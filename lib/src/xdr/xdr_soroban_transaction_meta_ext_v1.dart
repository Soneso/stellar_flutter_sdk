// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_int64.dart';

class XdrSorobanTransactionMetaExtV1 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  // The following are the components of the overall Soroban resource fee
  // charged for the transaction.
  // The following relation holds:
  // `resourceFeeCharged = totalNonRefundableResourceFeeCharged + totalRefundableResourceFeeCharged`
  // where `resourceFeeCharged` is the overall fee charged for the
  // transaction. Also, `resourceFeeCharged` <= `sorobanData.resourceFee`
  // i.e.we never charge more than the declared resource fee.
  // The inclusion fee for charged the Soroban transaction can be found using
  // the following equation:
  // `result.feeCharged = resourceFeeCharged + inclusionFeeCharged`.
  // Total amount (in stroops) that has been charged for non-refundable
  // Soroban resources.
  // Non-refundable resources are charged based on the usage declared in
  // the transaction envelope (such as `instructions`, `readBytes` etc.) and
  // is charged regardless of the success of the transaction.
  XdrInt64 _totalNonRefundableResourceFeeCharged;
  XdrInt64 get totalNonRefundableResourceFeeCharged =>
      this._totalNonRefundableResourceFeeCharged;
  set totalNonRefundableResourceFeeCharged(XdrInt64 value) =>
      this._totalNonRefundableResourceFeeCharged = value;

  // Total amount (in stroops) that has been charged for refundable
  // Soroban resource fees.
  // Currently this comprises the rent fee (`rentFeeCharged`) and the
  // fee for the events and return value.
  // Refundable resources are charged based on the actual resources usage.
  // Since currently refundable resources are only used for the successful
  // transactions, this will be `0` for failed transactions.
  XdrInt64 _totalRefundableResourceFeeCharged;
  XdrInt64 get totalRefundableResourceFeeCharged =>
      this._totalRefundableResourceFeeCharged;
  set totalRefundableResourceFeeCharged(XdrInt64 value) =>
      this._totalRefundableResourceFeeCharged = value;

  // Amount (in stroops) that has been charged for rent.
  // This is a part of `totalNonRefundableResourceFeeCharged`.
  XdrInt64 _rentFeeCharged;
  XdrInt64 get rentFeeCharged => this._rentFeeCharged;
  set rentFeeCharged(XdrInt64 value) => this._rentFeeCharged = value;

  XdrSorobanTransactionMetaExtV1(
      this._ext,
      this._totalNonRefundableResourceFeeCharged,
      this._totalRefundableResourceFeeCharged,
      this._rentFeeCharged);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionMetaExtV1 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrInt64.encode(stream, encoded.totalNonRefundableResourceFeeCharged);
    XdrInt64.encode(stream, encoded.totalRefundableResourceFeeCharged);
    XdrInt64.encode(stream, encoded.rentFeeCharged);
  }

  static XdrSorobanTransactionMetaExtV1 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrInt64 totalNonRefundableResourceFeeCharged = XdrInt64.decode(stream);
    XdrInt64 totalRefundableResourceFeeCharged = XdrInt64.decode(stream);
    XdrInt64 rentFeeCharged = XdrInt64.decode(stream);
    return XdrSorobanTransactionMetaExtV1(
        ext,
        totalNonRefundableResourceFeeCharged,
        totalRefundableResourceFeeCharged,
        rentFeeCharged);
  }
}
