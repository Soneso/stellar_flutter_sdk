// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../xdr/txrep_helper.dart';

/// SEP-0011 TxRep: Human-readable transaction representation.
///
/// TxRep provides a human-readable, line-based text format for Stellar
/// transactions that is easier to read and verify than base64-encoded XDR.
///
/// This implementation works at the XDR level, delegating to generated
/// `toTxRep()`/`fromTxRep()` methods on XDR types for sub-components, with
/// manual handling for the top-level envelope structure, memo text, and
/// signatures.
///
/// Conversion:
/// - XDR to TxRep: [fromTransactionEnvelopeXdrBase64]
/// - TxRep to XDR: [transactionEnvelopeXdrBase64FromTxRep]
class TxRep {
  // ---------------------------------------------------------------------------
  // Encoding: XDR base64 → TxRep text
  // ---------------------------------------------------------------------------

  /// Converts a base64-encoded transaction envelope XDR to TxRep text.
  static String fromTransactionEnvelopeXdrBase64(
    String transactionEnvelopeXdrBase64,
  ) {
    XdrTransactionEnvelope envelope =
        XdrTransactionEnvelope.fromEnvelopeXdrString(
      transactionEnvelopeXdrBase64,
    );

    // Resolve the inner transaction and detect fee bump.
    XdrTransaction tx;
    List<XdrDecoratedSignature> innerSignatures;
    bool isFeeBump = false;
    XdrFeeBumpTransactionEnvelope? feeBumpEnv;

    switch (envelope.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        // Convert V0 to V1 for uniform handling.
        XdrTransactionV0 v0tx = envelope.v0!.tx;
        XdrMuxedAccount source = XdrMuxedAccount(
          XdrCryptoKeyType.KEY_TYPE_ED25519,
        );
        source.ed25519 = v0tx.sourceAccountEd25519;
        XdrPreconditions cond;
        if (v0tx.timeBounds != null) {
          cond = XdrPreconditions(XdrPreconditionType.PRECOND_TIME);
          cond.timeBounds = v0tx.timeBounds;
        } else {
          cond = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
        }
        tx = XdrTransaction(
          source,
          v0tx.fee,
          v0tx.seqNum,
          cond,
          v0tx.memo,
          v0tx.operations,
          XdrTransactionExt(0),
        );
        innerSignatures = envelope.v0!.signatures;
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        tx = envelope.v1!.tx;
        innerSignatures = envelope.v1!.signatures;
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        isFeeBump = true;
        feeBumpEnv = envelope.feeBump!;
        tx = feeBumpEnv.tx.innerTx.v1!.tx;
        innerSignatures = feeBumpEnv.tx.innerTx.v1!.signatures;
        break;
      default:
        throw Exception('unsupported envelope type: ${envelope.discriminant}');
    }

    List<String> lines = [];
    String type = isFeeBump ? 'ENVELOPE_TYPE_TX_FEE_BUMP' : 'ENVELOPE_TYPE_TX';
    String prefix = isFeeBump ? 'feeBump.tx.innerTx.tx' : 'tx';

    lines.add('type: $type');

    if (isFeeBump) {
      final fb = feeBumpEnv!;
      lines.add('feeBump.tx.feeSource: ${TxRepHelper.formatMuxedAccount(fb.tx.feeSource)}');
      lines.add('feeBump.tx.fee: ${fb.tx.fee.int64}');
      lines.add('feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX');
    }

    // Source account, fee, sequence number.
    lines.add(
      '$prefix.sourceAccount: ${TxRepHelper.formatMuxedAccount(tx.sourceAccount)}',
    );
    lines.add('$prefix.fee: ${tx.fee.uint32}');
    lines.add('$prefix.seqNum: ${tx.seqNum.sequenceNumber}');

    // Preconditions — delegate to generated code.
    tx.cond.toTxRep('$prefix.cond', lines);

    // Memo — handle manually because the facade uses jsonEncode/jsonDecode
    // for legacy format compatibility, while generated code uses
    // TxRepHelper.escapeString which emits \xNN hex escapes.
    _encodeMemo(tx.memo, lines, '$prefix.memo');

    // Operations.
    lines.add('$prefix.operations.len: ${tx.operations.length}');
    for (int i = 0; i < tx.operations.length; i++) {
      tx.operations[i].toTxRep('$prefix.operations[$i]', lines);
    }

    // Transaction ext — handle manually for sorobanData path compatibility.
    if (tx.ext.discriminant == 1) {
      lines.add('$prefix.ext.v: 1');
      tx.ext.sorobanData!.toTxRep('$prefix.sorobanData', lines);
    } else {
      lines.add('$prefix.ext.v: 0');
    }

    // Inner signatures.
    String sigPrefix = isFeeBump ? 'feeBump.tx.innerTx.' : '';
    _encodeSignatures(innerSignatures, lines, sigPrefix);

    // Fee bump outer envelope.
    if (isFeeBump) {
      final fb = feeBumpEnv!;
      lines.add('feeBump.tx.ext.v: 0');
      _encodeSignatures(fb.signatures, lines, 'feeBump.');
    }

    return lines.join('\n');
  }

  // ---------------------------------------------------------------------------
  // Decoding: TxRep text → XDR base64
  // ---------------------------------------------------------------------------

  /// Converts TxRep text to a base64-encoded transaction envelope XDR.
  static String transactionEnvelopeXdrBase64FromTxRep(String txRep) {
    Map<String, String> map = TxRepHelper.parse(txRep);

    String? typeStr = TxRepHelper.getValue(map, 'type');
    if (typeStr != 'ENVELOPE_TYPE_TX' && typeStr != 'ENVELOPE_TYPE_TX_FEE_BUMP') {
      throw Exception('unsupported or missing TxRep type: $typeStr');
    }
    bool isFeeBump = typeStr == 'ENVELOPE_TYPE_TX_FEE_BUMP';
    String prefix = isFeeBump ? 'feeBump.tx.innerTx.tx' : 'tx';

    // Validate inner transaction type for fee bump envelopes.
    if (isFeeBump) {
      String? innerType =
          TxRepHelper.getValue(map, 'feeBump.tx.innerTx.type');
      if (innerType != null && innerType != 'ENVELOPE_TYPE_TX') {
        throw Exception(
          'unexpected feeBump.tx.innerTx.type: $innerType',
        );
      }
    }

    // Parse inner transaction.
    XdrTransaction tx = _decodeTransaction(map, prefix);

    // Parse inner signatures.
    String sigPrefix = isFeeBump ? 'feeBump.tx.innerTx.' : '';
    List<XdrDecoratedSignature> innerSignatures =
        _decodeSignatures(map, sigPrefix);

    XdrTransactionEnvelope envelope;

    if (isFeeBump) {
      // Build inner V1 envelope.
      XdrTransactionV1Envelope innerEnv =
          XdrTransactionV1Envelope(tx, innerSignatures);

      // Parse fee bump fields.
      String? feeSourceStr =
          TxRepHelper.getValue(map, 'feeBump.tx.feeSource');
      if (feeSourceStr == null) {
        throw Exception('missing feeBump.tx.feeSource');
      }
      XdrMuxedAccount feeSource = TxRepHelper.parseMuxedAccount(feeSourceStr);

      String? feeStr = TxRepHelper.getValue(map, 'feeBump.tx.fee');
      if (feeStr == null) {
        throw Exception('missing feeBump.tx.fee');
      }
      XdrInt64 fee = XdrInt64(BigInt.parse(feeStr));

      XdrFeeBumpTransactionInnerTx innerTx =
          XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.v1 = innerEnv;

      XdrFeeBumpTransactionExt fbExt = XdrFeeBumpTransactionExt(0);
      XdrFeeBumpTransaction fbTx =
          XdrFeeBumpTransaction(feeSource, fee, innerTx, fbExt);

      List<XdrDecoratedSignature> fbSignatures =
          _decodeSignatures(map, 'feeBump.');

      XdrFeeBumpTransactionEnvelope fbEnv =
          XdrFeeBumpTransactionEnvelope(fbTx, fbSignatures);

      envelope =
          XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);
      envelope.feeBump = fbEnv;
    } else {
      XdrTransactionV1Envelope v1Env =
          XdrTransactionV1Envelope(tx, innerSignatures);
      envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope.v1 = v1Env;
    }

    return envelope.toEnvelopeXdrBase64();
  }

  // ---------------------------------------------------------------------------
  // Encoding helpers
  // ---------------------------------------------------------------------------

  /// Encode a memo, handling text escaping manually.
  static void _encodeMemo(
    XdrMemo memo,
    List<String> lines,
    String prefix,
  ) {
    lines.add('$prefix.type: ${memo.discriminant.enumName()}');
    switch (memo.discriminant) {
      case XdrMemoType.MEMO_NONE:
        break;
      case XdrMemoType.MEMO_TEXT:
        // Use JSON encoding for compatibility with the legacy format.
        lines.add('$prefix.text: ${jsonEncode(memo.text)}');
        break;
      case XdrMemoType.MEMO_ID:
        memo.id!.toTxRep('$prefix.id', lines);
        break;
      case XdrMemoType.MEMO_HASH:
        memo.hash!.toTxRep('$prefix.hash', lines);
        break;
      case XdrMemoType.MEMO_RETURN:
        memo.retHash!.toTxRep('$prefix.retHash', lines);
        break;
      default:
        break;
    }
  }

  /// Encode signatures.
  static void _encodeSignatures(
    List<XdrDecoratedSignature> signatures,
    List<String> lines,
    String prefix,
  ) {
    lines.add('${prefix}signatures.len: ${signatures.length}');
    for (int i = 0; i < signatures.length; i++) {
      lines.add(
        '${prefix}signatures[$i].hint: ${Util.bytesToHex(signatures[i].hint.signatureHint)}',
      );
      lines.add(
        '${prefix}signatures[$i].signature: ${Util.bytesToHex(signatures[i].signature.signature)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Decoding helpers
  // ---------------------------------------------------------------------------

  /// Decode a transaction from the TxRep map.
  static XdrTransaction _decodeTransaction(
    Map<String, String> map,
    String prefix,
  ) {
    // Source account.
    String? sourceAccountStr = TxRepHelper.getValue(map, '$prefix.sourceAccount');
    if (sourceAccountStr == null) {
      throw Exception('missing $prefix.sourceAccount');
    }
    XdrMuxedAccount sourceAccount =
        TxRepHelper.parseMuxedAccount(sourceAccountStr);

    // Fee.
    String? feeStr = TxRepHelper.getValue(map, '$prefix.fee');
    if (feeStr == null) throw Exception('missing $prefix.fee');
    XdrUint32 fee = XdrUint32(int.parse(feeStr));

    // Sequence number.
    String? seqStr = TxRepHelper.getValue(map, '$prefix.seqNum');
    if (seqStr == null) throw Exception('missing $prefix.seqNum');
    XdrSequenceNumber seqNum = XdrSequenceNumber(BigInt.parse(seqStr));

    // Preconditions — delegate to generated code, with backward compat
    // for old format (tx.timeBounds._present instead of tx.cond.type).
    XdrPreconditions cond;
    String? condType = TxRepHelper.getValue(map, '$prefix.cond.type');
    if (condType != null) {
      cond = XdrPreconditions.fromTxRep(map, '$prefix.cond');
    } else {
      // Legacy format: check for tx.timeBounds._present.
      String? tbPresent =
          TxRepHelper.getValue(map, '$prefix.timeBounds._present');
      if (tbPresent == 'true') {
        cond = XdrPreconditions(XdrPreconditionType.PRECOND_TIME);
        cond.timeBounds = XdrTimeBounds.fromTxRep(map, '$prefix.timeBounds');
      } else {
        cond = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      }
    }

    // Memo — handle manually for text unescaping compatibility.
    XdrMemo memo = _decodeMemo(map, '$prefix.memo');

    // Operations.
    String? opsLenStr = TxRepHelper.getValue(map, '$prefix.operations.len');
    if (opsLenStr == null) throw Exception('missing $prefix.operations.len');
    int opsLen = int.parse(opsLenStr);
    List<XdrOperation> operations = [];
    for (int i = 0; i < opsLen; i++) {
      operations.add(XdrOperation.fromTxRep(map, '$prefix.operations[$i]'));
    }

    // Transaction ext — handle manually for sorobanData path compatibility.
    String? extV = TxRepHelper.getValue(map, '$prefix.ext.v');
    XdrTransactionExt ext;
    if (extV != null && extV == '1') {
      ext = XdrTransactionExt(1);
      ext.sorobanData =
          XdrSorobanTransactionData.fromTxRep(map, '$prefix.sorobanData');
    } else {
      ext = XdrTransactionExt(0);
    }

    return XdrTransaction(
      sourceAccount,
      fee,
      seqNum,
      cond,
      memo,
      operations,
      ext,
    );
  }

  /// Decode a memo from the TxRep map, handling text unescaping.
  static XdrMemo _decodeMemo(Map<String, String> map, String prefix) {
    String? memoTypeStr = TxRepHelper.getValue(map, '$prefix.type');
    if (memoTypeStr == null) throw Exception('missing $prefix.type');

    if (memoTypeStr == 'MEMO_NONE') {
      return XdrMemo(XdrMemoType.MEMO_NONE);
    } else if (memoTypeStr == 'MEMO_TEXT') {
      String? textStr = TxRepHelper.getValue(map, '$prefix.text');
      if (textStr == null) throw Exception('missing $prefix.text');
      // Decode JSON-encoded string (reverses jsonEncode() in encode).
      String text;
      if (textStr.startsWith('"') && textStr.endsWith('"')) {
        text = jsonDecode(textStr) as String;
      } else {
        text = textStr;
      }
      XdrMemo memo = XdrMemo(XdrMemoType.MEMO_TEXT);
      memo.text = text;
      return memo;
    } else if (memoTypeStr == 'MEMO_ID') {
      XdrMemo memo = XdrMemo(XdrMemoType.MEMO_ID);
      memo.id = XdrUint64.fromTxRep(map, '$prefix.id');
      return memo;
    } else if (memoTypeStr == 'MEMO_HASH') {
      XdrMemo memo = XdrMemo(XdrMemoType.MEMO_HASH);
      memo.hash = XdrHash.fromTxRep(map, '$prefix.hash');
      return memo;
    } else if (memoTypeStr == 'MEMO_RETURN') {
      XdrMemo memo = XdrMemo(XdrMemoType.MEMO_RETURN);
      memo.retHash = XdrHash.fromTxRep(map, '$prefix.retHash');
      return memo;
    } else {
      throw Exception('unknown memo type: $memoTypeStr');
    }
  }

  /// Decode signatures from the TxRep map.
  /// Returns an empty list if the signatures section is missing (unsigned
  /// transactions are valid per SEP-0011).
  static List<XdrDecoratedSignature> _decodeSignatures(
    Map<String, String> map,
    String prefix,
  ) {
    String? lenStr = TxRepHelper.getValue(map, '${prefix}signatures.len');
    if (lenStr == null) return [];
    int len = int.parse(lenStr);
    List<XdrDecoratedSignature> signatures = [];
    for (int i = 0; i < len; i++) {
      String? hintStr =
          TxRepHelper.getValue(map, '${prefix}signatures[$i].hint');
      if (hintStr == null) {
        throw Exception('missing ${prefix}signatures[$i].hint');
      }
      String? sigStr =
          TxRepHelper.getValue(map, '${prefix}signatures[$i].signature');
      if (sigStr == null) {
        throw Exception('missing ${prefix}signatures[$i].signature');
      }
      signatures.add(XdrDecoratedSignature(
        XdrSignatureHint(Util.hexToBytes(hintStr)),
        XdrSignature(Util.hexToBytes(sigStr)),
      ));
    }
    return signatures;
  }

}
