// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'muxed_account.dart';
import 'xdr/xdr_data_io.dart';
import 'xdr/xdr_operation.dart';
import 'create_account_operation.dart';
import 'payment_operation.dart';
import 'path_payment_strict_receive_operation.dart';
import 'path_payment_strict_send_operation.dart';
import 'manage_buy_offer_operation.dart';
import 'manage_sell_offer_operation.dart';
import 'create_passive_sell_offer_operation.dart';
import 'set_options_operation.dart';
import 'change_trust_operation.dart';
import 'allow_trust_operation.dart';
import 'account_merge_operation.dart';
import 'manage_data_operation.dart';
import 'bump_sequence_operation.dart';
import 'begin_sponsoring_future_reserves_operation.dart';
import 'end_sponsoring_future_reserves_operation.dart';
import 'create_claimable_balance_operation.dart';
import 'claim_claimable_balance_operation.dart';
import 'revoke_sponsorship_operation.dart';
import 'clawback_operation.dart';
import 'clawback_claimable_balance_operation.dart';
import 'set_trustline_flags_operation.dart';
import 'liquidity_pool_deposit_operation.dart';
import 'liquidity_pool_withdraw_operation.dart';
import 'invoke_host_function_operation.dart';
import 'extend_footprint_ttl_operation.dart';
import 'restore_footprint_operation.dart';

/// Base class for all operations in a Stellar transaction.
///
/// Operations are the commands that mutate the ledger state. A transaction
/// contains one or more operations that are executed atomically. Each operation
/// can optionally specify a source account that differs from the transaction's
/// source account.
///
/// Available operation types:
/// - [CreateAccountOperation] - Create and fund a new account
/// - [PaymentOperation] - Send assets to an account
/// - [PathPaymentStrictReceiveOperation] - Send through a payment path with exact receive amount
/// - [PathPaymentStrictSendOperation] - Send through a payment path with exact send amount
/// - [ManageSellOfferOperation] - Create, update, or delete a sell offer
/// - [ManageBuyOfferOperation] - Create, update, or delete a buy offer
/// - [CreatePassiveSellOfferOperation] - Create a passive sell offer
/// - [SetOptionsOperation] - Set account options (inflation, thresholds, signers, etc.)
/// - [ChangeTrustOperation] - Create, update, or delete a trustline
/// - [AllowTrustOperation] - Authorize or deauthorize an account to hold an asset
/// - [AccountMergeOperation] - Merge one account into another
/// - [ManageDataOperation] - Set, modify, or delete a data entry
/// - [BumpSequenceOperation] - Bump account sequence number
/// - [CreateClaimableBalanceOperation] - Create a claimable balance entry
/// - [ClaimClaimableBalanceOperation] - Claim a claimable balance
/// - [BeginSponsoringFutureReservesOperation] - Begin sponsoring reserves for another account
/// - [EndSponsoringFutureReservesOperation] - End sponsoring reserves
/// - [RevokeSponsorshipOperation] - Revoke sponsorship of a ledger entry or signer
/// - [ClawbackOperation] - Clawback an asset from an account
/// - [ClawbackClaimableBalanceOperation] - Clawback a claimable balance
/// - [SetTrustLineFlagsOperation] - Set flags on a trustline
/// - [LiquidityPoolDepositOperation] - Deposit assets into a liquidity pool
/// - [LiquidityPoolWithdrawOperation] - Withdraw assets from a liquidity pool
/// - [InvokeHostFunctionOperation] - Invoke a Soroban smart contract function
/// - [ExtendFootprintTTLOperation] - Extend the TTL of Soroban contract storage entries
/// - [RestoreFootprintOperation] - Restore archived Soroban contract storage entries
///
/// Example:
/// ```dart
/// // Create a payment operation
/// var payment = PaymentOperationBuilder(
///   destinationAccountId,
///   Asset.native(),
///   "100.50"
/// ).build();
///
/// // Create a payment with custom source account
/// var paymentWithSource = PaymentOperationBuilder(
///   destinationAccountId,
///   Asset.native(),
///   "100.50"
/// ).setSourceAccount(customSourceAccount).build();
///
/// // Add operation to a transaction
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(payment)
///   .build();
/// ```
///
/// See also:
/// - [Transaction] for building and submitting transactions
/// - [TransactionBuilder] for constructing transactions with operations
/// - [Stellar developer docs](https://developers.stellar.org)
abstract class Operation {
  Operation();

  /// Optional source account for this operation.
  ///
  /// If not set, the operation uses the transaction's source account.
  /// This allows different operations in the same transaction to have
  /// different source accounts.
  MuxedAccount? sourceAccount;

  /// Converts this operation to its XDR representation.
  ///
  /// Returns an [XdrOperation] object that can be serialized for network transmission.
  /// The XDR format is used for all Stellar protocol communications.
  ///
  /// Returns: XDR representation of this operation.
  XdrOperation toXdr() {
    XdrOperation xdrOp = XdrOperation(toOperationBody());
    if (sourceAccount != null) {
      xdrOp.sourceAccount = sourceAccount?.toXdr();
    }
    return xdrOp;
  }

  /// Returns base64-encoded Operation XDR object from this operation.
  String toXdrBase64() {
    try {
      XdrOperation operation = this.toXdr();
      var xdrOutputStream = XdrDataOutputStream();
      XdrOperation.encode(xdrOutputStream, operation);
      return base64Encode(xdrOutputStream.data);
    } catch (e) {
      throw AssertionError(e);
    }
  }

  /// Returns Operation object from an Operation XDR object [xdrOp].
  static Operation fromXdr(XdrOperation xdrOp) {
    XdrOperationBody body = xdrOp.body;
    Operation operation;
    switch (body.discriminant) {
      case XdrOperationType.CREATE_ACCOUNT:
        operation =
            CreateAccountOperation.builder(body.createAccountOp!).build();
        break;
      case XdrOperationType.PAYMENT:
        operation = PaymentOperation.builder(body.paymentOp!).build();
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE:
        operation = PathPaymentStrictReceiveOperation.builder(
                body.pathPaymentStrictReceiveOp!)
            .build();
        break;
      case XdrOperationType.MANAGE_SELL_OFFER:
        operation =
            ManageSellOfferOperation.builder(body.manageSellOfferOp!).build();
        break;
      case XdrOperationType.CREATE_PASSIVE_SELL_OFFER:
        operation = CreatePassiveSellOfferOperation.builder(
                body.createPassiveSellOfferOp!)
            .build();
        break;
      case XdrOperationType.SET_OPTIONS:
        operation = SetOptionsOperation.builder(body.setOptionsOp!).build();
        break;
      case XdrOperationType.CHANGE_TRUST:
        operation = ChangeTrustOperation.builder(body.changeTrustOp!).build();
        break;
      case XdrOperationType.ALLOW_TRUST:
        operation = AllowTrustOperation.builder(body.allowTrustOp!).build();
        break;
      case XdrOperationType.ACCOUNT_MERGE:
        operation = AccountMergeOperation.builder(body).build();
        break;
      case XdrOperationType.MANAGE_DATA:
        operation = ManageDataOperation.builder(body.manageDataOp!).build();
        break;
      case XdrOperationType.BUMP_SEQUENCE:
        operation = BumpSequenceOperation.builder(body.bumpSequenceOp!).build();
        break;
      case XdrOperationType.MANAGE_BUY_OFFER:
        operation =
            ManageBuyOfferOperation.builder(body.manageBuyOfferOp!).build();
        break;
      case XdrOperationType.PATH_PAYMENT_STRICT_SEND:
        operation = PathPaymentStrictSendOperation.builder(
                body.pathPaymentStrictSendOp!)
            .build();
        break;
      case XdrOperationType.CREATE_CLAIMABLE_BALANCE:
        operation = CreateClaimableBalanceOperation.builder(
                body.createClaimableBalanceOp!)
            .build();
        break;
      case XdrOperationType.CLAIM_CLAIMABLE_BALANCE:
        operation = ClaimClaimableBalanceOperation.builder(
                body.claimClaimableBalanceOp!)
            .build();
        break;
      case XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES:
        final op = BeginSponsoringFutureReservesOperation.builder(
            body.beginSponsoringFutureReservesOp!);
        operation =
            BeginSponsoringFutureReservesOperationBuilder(op.sponsoredId)
                .build();
        break;
      case XdrOperationType.END_SPONSORING_FUTURE_RESERVES:
        operation = EndSponsoringFutureReservesOperationBuilder().build();
        break;
      case XdrOperationType.REVOKE_SPONSORSHIP:
        operation =
            RevokeSponsorshipOperation.fromXdr(body.revokeSponsorshipOp!)!;
        break;
      case XdrOperationType.CLAWBACK:
        operation = ClawbackOperation.builder(body.clawbackOp!).build();
        break;
      case XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE:
        operation = ClawbackClaimableBalanceOperation.builder(
                body.clawbackClaimableBalanceOp!)
            .build();
        break;
      case XdrOperationType.SET_TRUST_LINE_FLAGS:
        operation =
            SetTrustLineFlagsOperation.builder(body.setTrustLineFlagsOp!)
                .build();
        break;
      case XdrOperationType.LIQUIDITY_POOL_DEPOSIT:
        operation =
            LiquidityPoolDepositOperation.builder(body.liquidityPoolDepositOp!)
                .build();
        break;
      case XdrOperationType.LIQUIDITY_POOL_WITHDRAW:
        operation = LiquidityPoolWithdrawOperation.builder(
                body.liquidityPoolWithdrawOp!)
            .build();
        break;
      case XdrOperationType.INVOKE_HOST_FUNCTION:
        operation =
            InvokeHostFunctionOperation.builder(body.invokeHostFunctionOp!)
                .build();
        break;
      case XdrOperationType.EXTEND_FOOTPRINT_TTL:
        operation =
            ExtendFootprintTTLOperation.builder(body.bumpExpirationOp!)
                .build();
        break;
      case XdrOperationType.RESTORE_FOOTPRINT:
        operation =
            RestoreFootprintOperation.builder(body.restoreFootprintOp!)
                .build();
        break;
      default:
        throw Exception("Unknown operation body ${body.discriminant}");
    }
    if (xdrOp.sourceAccount != null) {
      operation.sourceAccount = MuxedAccount.fromXdr(xdrOp.sourceAccount!);
    }
    return operation;
  }

  /// Converts this operation to its XDR operation body representation.
  ///
  /// This abstract method must be implemented by each operation type to provide
  /// its specific XDR body structure. The body contains the operation-specific
  /// parameters and discriminant.
  ///
  /// Returns: XDR operation body for this specific operation type.
  XdrOperationBody toOperationBody();
}
