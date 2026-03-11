// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';


import '../key_pair.dart' show StrKey;
import '../muxed_account.dart' show MuxedAccount;
import '../util.dart' show Util;
import 'xdr_account_id.dart';
import 'xdr_allow_trust_op_asset.dart';
import 'xdr_asset.dart';
import 'xdr_asset_alpha_num12.dart';
import 'xdr_asset_alpha_num4.dart';
import 'xdr_asset_type.dart';
import 'xdr_change_trust_asset.dart';
import 'xdr_hash.dart';
import 'xdr_muxed_account.dart';
import 'xdr_signer_key.dart';
import 'xdr_signer_key_type.dart';
import 'xdr_trustline_asset.dart';
import 'xdr_uint256.dart';

/// Shared utility functions for TxRep encoding and decoding.
///
/// Used by both generated and wrapper TxRep code to provide consistent
/// parsing, formatting, and Stellar type conversion.
class TxRepHelper {
  // ---------------------------------------------------------------------------
  // Parser utilities
  // ---------------------------------------------------------------------------

  /// Parse TxRep text into a key-value map.
  ///
  /// Handles blank lines, comment lines (starting with `:`), CRLF line endings,
  /// and lines with no colon (skipped). Splits on first `:` only and trims
  /// value whitespace.
  static Map<String, String> parse(String txRep) {
    Map<String, String> map = {};
    // Normalize CRLF to LF.
    List<String> lines = txRep.replaceAll('\r\n', '\n').split('\n');
    for (String line in lines) {
      // Skip blank lines.
      if (line.trim().isEmpty) continue;
      // Skip comment-only lines (leading colon with no key).
      if (line.trimLeft().startsWith(':')) continue;

      int colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue; // No colon — skip.

      String key = line.substring(0, colonIndex).trim();
      if (key.isEmpty) continue;

      String value = line.substring(colonIndex + 1).trim();
      map[key] = value;
    }
    return map;
  }

  /// Get a value from the map, stripping inline comments via [removeComment].
  ///
  /// Returns null if the key is not found.
  static String? getValue(Map<String, String> map, String key) {
    String? raw = map[key];
    if (raw == null) return null;
    return removeComment(raw);
  }

  /// Remove an inline comment from a TxRep value string.
  ///
  /// Comments appear after the value — either in parentheses or as trailing
  /// text after whitespace. Quoted strings are respected: a `(` inside double
  /// quotes is not treated as a comment delimiter.
  static String removeComment(String value) {
    // If the value starts with a double-quote, find the closing quote first,
    // then look for a comment after it.
    if (value.startsWith('"')) {
      int i = 1;
      while (i < value.length) {
        if (value[i] == '\\') {
          i += 2; // Skip escaped character.
          continue;
        }
        if (value[i] == '"') {
          // Found closing quote — return everything up to and including it.
          return value.substring(0, i + 1);
        }
        i++;
      }
      // No closing quote found — return as-is.
      return value;
    }

    // Not a quoted string — look for `(` as comment start.
    int idx = value.indexOf('(');
    if (idx == -1) {
      return value.trim();
    }
    return value.substring(0, idx).trim();
  }

  // ---------------------------------------------------------------------------
  // Formatting utilities
  // ---------------------------------------------------------------------------

  /// Encode bytes as a lowercase hex string.
  ///
  /// Returns `"0"` for empty input.
  static String bytesToHex(Uint8List bytes) {
    if (bytes.isEmpty) return '0';
    return Util.bytesToHex(bytes);
  }

  /// Decode a hex string to bytes.
  ///
  /// `"0"` decodes to an empty [Uint8List]. Odd-length hex strings are
  /// left-padded with a zero.
  static Uint8List hexToBytes(String hex) {
    if (hex == '0') return Uint8List(0);
    String h = hex;
    if (h.length % 2 != 0) {
      h = '0$h';
    }
    return Util.hexToBytes(h);
  }

  /// Escape a string for TxRep double-quoted format.
  ///
  /// Escapes `"`, `\`, represents `\n` as `\\n`, and encodes non-ASCII bytes
  /// (outside 0x20–0x7e) as `\\xNN`.
  static String escapeString(String s) {
    StringBuffer buf = StringBuffer();
    buf.write('"');
    for (int rune in s.runes) {
      if (rune == 0x5C) {
        // backslash
        buf.write(r'\\');
      } else if (rune == 0x22) {
        // double quote
        buf.write(r'\"');
      } else if (rune == 0x0A) {
        // newline
        buf.write(r'\n');
      } else if (rune >= 0x20 && rune <= 0x7E) {
        buf.writeCharCode(rune);
      } else {
        // Non-printable or non-ASCII — encode as \xNN per byte.
        List<int> bytes = utf8.encode(String.fromCharCode(rune));
        for (int b in bytes) {
          buf.write('\\x');
          buf.write(b.toRadixString(16).padLeft(2, '0'));
        }
      }
    }
    buf.write('"');
    return buf.toString();
  }

  /// Unescape a TxRep string value.
  ///
  /// Handles `\"`, `\\`, `\n`, and `\xNN` escape sequences. If the input is
  /// enclosed in double quotes, they are stripped.
  static String unescapeString(String s) {
    String input = s;
    if (input.startsWith('"') && input.endsWith('"') && input.length >= 2) {
      input = input.substring(1, input.length - 1);
    }

    StringBuffer buf = StringBuffer();
    List<int> pendingBytes = [];

    void flushPendingBytes() {
      if (pendingBytes.isNotEmpty) {
        buf.write(utf8.decode(pendingBytes, allowMalformed: false));
        pendingBytes.clear();
      }
    }

    int i = 0;
    while (i < input.length) {
      if (input[i] == '\\' && i + 1 < input.length) {
        String next = input[i + 1];
        if (next == '"') {
          flushPendingBytes();
          buf.write('"');
          i += 2;
        } else if (next == '\\') {
          flushPendingBytes();
          buf.write('\\');
          i += 2;
        } else if (next == 'n') {
          flushPendingBytes();
          buf.write('\n');
          i += 2;
        } else if (next == 'x' && i + 3 < input.length) {
          String hexStr = input.substring(i + 2, i + 4);
          int? byteVal = int.tryParse(hexStr, radix: 16);
          if (byteVal != null) {
            pendingBytes.add(byteVal);
            i += 4;
          } else {
            flushPendingBytes();
            buf.write(input[i]);
            i++;
          }
        } else {
          flushPendingBytes();
          buf.write(input[i]);
          i++;
        }
      } else {
        flushPendingBytes();
        buf.write(input[i]);
        i++;
      }
    }
    flushPendingBytes();
    return buf.toString();
  }

  /// Parse an integer string supporting decimal and hex (`0x` prefix) notation.
  static int parseInt(String s) {
    String trimmed = s.trim();
    bool negative = false;
    if (trimmed.startsWith('-')) {
      negative = true;
      trimmed = trimmed.substring(1);
    }
    int result;
    if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
      result = int.parse(trimmed.substring(2), radix: 16);
    } else {
      result = int.parse(trimmed);
    }
    return negative ? -result : result;
  }

  /// Parse a big integer string supporting decimal and hex (`0x` prefix) notation.
  static BigInt parseBigInt(String s) {
    String trimmed = s.trim();
    bool negative = false;
    if (trimmed.startsWith('-')) {
      negative = true;
      trimmed = trimmed.substring(1);
    }
    BigInt result;
    if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
      result = BigInt.parse(trimmed.substring(2), radix: 16);
    } else {
      result = BigInt.parse(trimmed);
    }
    return negative ? -result : result;
  }

  // ---------------------------------------------------------------------------
  // Stellar type formatters
  // ---------------------------------------------------------------------------

  /// Convert an [XdrAccountID] to a StrKey string (G...).
  static String formatAccountId(XdrAccountID accountId) {
    return StrKey.encodeStellarAccountId(
      accountId.accountID.getEd25519()!.uint256,
    );
  }

  /// Convert an [XdrMuxedAccount] to a StrKey string.
  ///
  /// Returns a G... address for ed25519 or an M... address for muxed ed25519.
  static String formatMuxedAccount(XdrMuxedAccount muxed) {
    MuxedAccount ma = MuxedAccount.fromXdr(muxed);
    return ma.accountId;
  }

  /// Parse a StrKey string to an [XdrAccountID].
  ///
  /// Accepts G... addresses (standard Ed25519 accounts).
  static XdrAccountID parseAccountId(String strKey) {
    return XdrAccountID.forAccountId(strKey);
  }

  /// Parse a StrKey string to an [XdrMuxedAccount].
  ///
  /// Handles both G... (standard) and M... (muxed) addresses.
  static XdrMuxedAccount parseMuxedAccount(String strKey) {
    MuxedAccount? mux = MuxedAccount.fromAccountId(strKey);
    if (mux == null) {
      throw Exception('invalid muxed account: $strKey');
    }
    return mux.toXdr();
  }

  /// Format an [XdrAsset] as a TxRep asset string.
  ///
  /// Returns `XLM` for ASSET_TYPE_NATIVE, `CODE:ISSUER` for credit assets.
  static String formatAsset(XdrAsset asset) {
    switch (asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        return 'XLM';
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        String code = _assetCodeFromBytes(asset.alphaNum4!.assetCode);
        String issuer = formatAccountId(asset.alphaNum4!.issuer);
        return '$code:$issuer';
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        String code = _assetCodeFromBytes(asset.alphaNum12!.assetCode);
        String issuer = formatAccountId(asset.alphaNum12!.issuer);
        return '$code:$issuer';
      default:
        throw Exception('unsupported asset type: ${asset.discriminant}');
    }
  }

  /// Parse a TxRep asset string (`native` or `CODE:ISSUER`) to an [XdrAsset].
  static XdrAsset parseAsset(String value) {
    if (value == 'native' || value == 'XLM') {
      return XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
    }

    List<String> parts = value.split(':');
    if (parts.length != 2) {
      throw Exception('invalid asset: $value');
    }

    String code = parts[0].trim();
    String issuer = parts[1].trim();
    XdrAccountID issuerId = XdrAccountID.forAccountId(issuer);

    if (code.length <= 4) {
      XdrAsset result = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      result.alphaNum4 = XdrAssetAlphaNum4(
        _assetCodeToBytes(code, 4),
        issuerId,
      );
      return result;
    } else if (code.length <= 12) {
      XdrAsset result = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      result.alphaNum12 = XdrAssetAlphaNum12(
        _assetCodeToBytes(code, 12),
        issuerId,
      );
      return result;
    } else {
      throw Exception('asset code too long: $code');
    }
  }

  /// Format an [XdrChangeTrustAsset] as a TxRep string.
  ///
  /// Includes pool share assets, formatted as the underlying liquidity pool
  /// parameters.
  static String formatChangeTrustAsset(XdrChangeTrustAsset asset) {
    switch (asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        return 'XLM';
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        String code = _assetCodeFromBytes(asset.alphaNum4!.assetCode);
        String issuer = formatAccountId(asset.alphaNum4!.issuer);
        return '$code:$issuer';
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        String code = _assetCodeFromBytes(asset.alphaNum12!.assetCode);
        String issuer = formatAccountId(asset.alphaNum12!.issuer);
        return '$code:$issuer';
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        // Pool share assets are expanded field-by-field by the caller,
        // not representable as a single compact string.
        throw Exception(
          'pool share assets must be serialized field-by-field, '
          'not as a compact string',
        );
      default:
        throw Exception(
          'unsupported change trust asset type: ${asset.discriminant}',
        );
    }
  }

  /// Parse a TxRep string to an [XdrChangeTrustAsset].
  ///
  /// Handles `native`, `CODE:ISSUER`, and pool share representations.
  static XdrChangeTrustAsset parseChangeTrustAsset(String value) {
    if (value == 'native' || value == 'XLM') {
      return XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE);
    }

    List<String> parts = value.split(':');
    if (parts.length != 2) {
      throw Exception('invalid change trust asset: $value');
    }

    String code = parts[0].trim();
    String issuer = parts[1].trim();
    XdrAccountID issuerId = XdrAccountID.forAccountId(issuer);

    if (code.length <= 4) {
      XdrChangeTrustAsset result = XdrChangeTrustAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      );
      result.alphaNum4 = XdrAssetAlphaNum4(
        _assetCodeToBytes(code, 4),
        issuerId,
      );
      return result;
    } else if (code.length <= 12) {
      XdrChangeTrustAsset result = XdrChangeTrustAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      );
      result.alphaNum12 = XdrAssetAlphaNum12(
        _assetCodeToBytes(code, 12),
        issuerId,
      );
      return result;
    } else {
      throw Exception('asset code too long: $code');
    }
  }

  /// Format an [XdrTrustlineAsset] as a TxRep string.
  ///
  /// Includes pool share assets (formatted as hex pool ID).
  static String formatTrustlineAsset(XdrTrustlineAsset asset) {
    switch (asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        return 'XLM';
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        String code = _assetCodeFromBytes(asset.alphaNum4!.assetCode);
        String issuer = formatAccountId(asset.alphaNum4!.issuer);
        return '$code:$issuer';
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        String code = _assetCodeFromBytes(asset.alphaNum12!.assetCode);
        String issuer = formatAccountId(asset.alphaNum12!.issuer);
        return '$code:$issuer';
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        return Util.bytesToHex(asset.liquidityPoolID!.hash);
      default:
        throw Exception(
          'unsupported trustline asset type: ${asset.discriminant}',
        );
    }
  }

  /// Parse a TxRep string to an [XdrTrustlineAsset].
  ///
  /// Handles `native`, `CODE:ISSUER`, and pool share (hex pool ID).
  static XdrTrustlineAsset parseTrustlineAsset(String value) {
    if (value == 'native' || value == 'XLM') {
      return XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
    }

    // If it looks like a 64-char hex string, treat it as a pool share ID.
    if (value.length == 64 && !value.contains(':')) {
      try {
        Uint8List hash = Util.hexToBytes(value);
        if (hash.length == 32) {
          XdrTrustlineAsset result = XdrTrustlineAsset(
            XdrAssetType.ASSET_TYPE_POOL_SHARE,
          );
          result.liquidityPoolID = XdrHash(hash);
          return result;
        }
      } catch (_) {
        // Fall through to CODE:ISSUER parsing.
      }
    }

    List<String> parts = value.split(':');
    if (parts.length != 2) {
      throw Exception('invalid trustline asset: $value');
    }

    String code = parts[0].trim();
    String issuer = parts[1].trim();
    XdrAccountID issuerId = XdrAccountID.forAccountId(issuer);

    if (code.length <= 4) {
      XdrTrustlineAsset result = XdrTrustlineAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      );
      result.alphaNum4 = XdrAssetAlphaNum4(
        _assetCodeToBytes(code, 4),
        issuerId,
      );
      return result;
    } else if (code.length <= 12) {
      XdrTrustlineAsset result = XdrTrustlineAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      );
      result.alphaNum12 = XdrAssetAlphaNum12(
        _assetCodeToBytes(code, 12),
        issuerId,
      );
      return result;
    } else {
      throw Exception('asset code too long: $code');
    }
  }

  /// Format an [XdrSignerKey] as a StrKey string.
  ///
  /// Uses the appropriate prefix: G for ed25519, T for preAuthTx, X for hashX,
  /// P for signedPayload.
  static String formatSignerKey(XdrSignerKey key) {
    switch (key.discriminant) {
      case XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519:
        return StrKey.encodeStellarAccountId(key.ed25519!.uint256);
      case XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX:
        return StrKey.encodePreAuthTx(key.preAuthTx!.uint256);
      case XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X:
        return StrKey.encodeSha256Hash(key.hashX!.uint256);
      case XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD:
        return StrKey.encodeXdrSignedPayload(key.signedPayload!);
      default:
        throw Exception('unknown signer key type: ${key.discriminant}');
    }
  }

  /// Parse a StrKey string to an [XdrSignerKey].
  ///
  /// Detects the key type from the StrKey prefix: G (ed25519), T (preAuthTx),
  /// X (hashX), P (signedPayload).
  static XdrSignerKey parseSignerKey(String value) {
    if (value.startsWith('G')) {
      XdrSignerKey signer = XdrSignerKey(
        XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519,
      );
      signer.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(value));
      return signer;
    } else if (value.startsWith('T')) {
      XdrSignerKey signer = XdrSignerKey(
        XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX,
      );
      signer.preAuthTx = XdrUint256(StrKey.decodePreAuthTx(value));
      return signer;
    } else if (value.startsWith('X')) {
      XdrSignerKey signer = XdrSignerKey(
        XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X,
      );
      signer.hashX = XdrUint256(StrKey.decodeSha256Hash(value));
      return signer;
    } else if (value.startsWith('P')) {
      XdrSignerKey signer = XdrSignerKey(
        XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD,
      );
      signer.signedPayload = StrKey.decodeXdrSignedPayload(value);
      return signer;
    } else {
      throw Exception('unknown signer key prefix: $value');
    }
  }

  /// Format an [XdrAllowTrustOpAsset] as a compact asset code string.
  static String formatAllowTrustAsset(XdrAllowTrustOpAsset asset) {
    switch (asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        return _assetCodeFromBytes(asset.assetCode4!);
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        return _assetCodeFromBytes(asset.assetCode12!);
      default:
        throw Exception(
          'unsupported allow trust asset type: ${asset.discriminant}',
        );
    }
  }

  /// Parse an asset code string to an [XdrAllowTrustOpAsset].
  static XdrAllowTrustOpAsset parseAllowTrustAsset(String code) {
    if (code.length <= 4) {
      XdrAllowTrustOpAsset result = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      );
      result.assetCode4 = _assetCodeToBytes(code, 4);
      return result;
    } else if (code.length <= 12) {
      XdrAllowTrustOpAsset result = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      );
      result.assetCode12 = _assetCodeToBytes(code, 12);
      return result;
    } else {
      throw Exception('asset code too long: $code');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Extract an asset code string from raw XDR bytes, stripping trailing nulls.
  static String _assetCodeFromBytes(Uint8List bytes) {
    int end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) {
      end--;
    }
    return utf8.decode(bytes.sublist(0, end));
  }

  /// Convert an asset code string to null-padded bytes of the given [length].
  static Uint8List _assetCodeToBytes(String code, int length) {
    List<int> encoded = utf8.encode(code);
    Uint8List result = Uint8List(length);
    for (int i = 0; i < encoded.length && i < length; i++) {
      result[i] = encoded[i];
    }
    return result;
  }
}
