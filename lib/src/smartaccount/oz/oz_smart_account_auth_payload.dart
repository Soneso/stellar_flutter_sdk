// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../key_pair.dart';
import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_smart_account_types.dart';

/// Represents the AuthPayload format used by the OpenZeppelin Smart Account
/// contract on Stellar Soroban.
///
/// The signature payload is a Map-based named struct with two fields:
/// `context_rule_ids` and `signers`. The contract representation is:
///
/// ```text
/// ScVal::Map([
///   { key: Symbol("context_rule_ids"), val: Vec([U32(id), ...]) },
///   { key: Symbol("signers"),
///     val: Map([{ key: signer.toScVal(), val: Bytes(sig) }, ...]) }
/// ])
/// ```
///
/// The [signers] map is mutable so callers and codecs can add or replace
/// entries in place.
///
/// Not isolate-safe: the [signers] map is deliberately mutable so the
/// codec and signer pipeline can upsert in place. Callers wishing to share a
/// payload across isolates MUST take a copy of both the [signers] map and the
/// [contextRuleIds] list, or confine the instance to a single isolate.
class OZSmartAccountAuthPayload {
  /// Constructs an [OZSmartAccountAuthPayload] from a mutable [signers] map
  /// and an immutable [contextRuleIds] list.
  OZSmartAccountAuthPayload({
    required this.signers,
    required List<int> contextRuleIds,
  }) : contextRuleIds = List<int>.unmodifiable(contextRuleIds);

  /// Mutable map from signer to its verifier-appropriate signature bytes.
  ///
  /// For WebAuthn and Policy signers the bytes are the XDR-encoded [XdrSCVal];
  /// for Ed25519 signers the bytes are the raw 64-byte signature (no XDR
  /// wrapper). See [OZSmartAccountSignature.toAuthPayloadBytes].
  final Map<OZSmartAccountSigner, Uint8List> signers;

  /// Context rule IDs bound into the signing digest. The list is
  /// unmodifiable so the value remains stable once a payload is built.
  final List<int> contextRuleIds;
}

/// Codec for reading and writing [OZSmartAccountAuthPayload] to and from
/// [XdrSCVal].
///
/// Handles the OpenZeppelin Smart Account contract AuthPayload format, which
/// is a named struct (Map-based) with fields `context_rule_ids` and
/// `signers`.
///
/// All entry points are pure static functions over their arguments; safe to
/// call concurrently from any isolate.
abstract class OZSmartAccountAuthPayloadCodec {
  OZSmartAccountAuthPayloadCodec._();

  /// Reads an [OZSmartAccountAuthPayload] from its [XdrSCVal] representation.
  ///
  /// Accepts `XdrSCVal.SCV_VOID` (returns an empty payload) or
  /// `XdrSCVal.SCV_MAP` (the full payload). Throws
  /// [TransactionSigningFailed] when the input is not Void or Map, or when
  /// a signer entry has a value that is not a `Bytes` ScVal.
  static OZSmartAccountAuthPayload read(XdrSCVal signatureScVal) {
    if (signatureScVal.discriminant == XdrSCValType.SCV_VOID) {
      return OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
    }
    if (signatureScVal.discriminant != XdrSCValType.SCV_MAP) {
      throw TransactionException.signingFailed(
        'Smart account auth signature is not encoded as AuthPayload',
      );
    }

    final mapEntries = signatureScVal.map ?? const <XdrSCMapEntry>[];
    var contextRuleIds = const <int>[];
    final signers = <OZSmartAccountSigner, Uint8List>{};

    for (final entry in mapEntries) {
      final key = entry.key;
      if (key.discriminant != XdrSCValType.SCV_SYMBOL) {
        // Skip non-Symbol keys; they cannot carry meaningful struct field
        // names.
        continue;
      }
      final keyName = key.sym;
      if (keyName == 'context_rule_ids') {
        final valScVal = entry.val;
        if (valScVal.discriminant == XdrSCValType.SCV_VEC) {
          final ids = <int>[];
          for (final element in valScVal.vec ?? const <XdrSCVal>[]) {
            if (element.discriminant == XdrSCValType.SCV_U32 &&
                element.u32 != null) {
              ids.add(element.u32!.uint32);
            }
          }
          contextRuleIds = ids;
        }
      } else if (keyName == 'signers') {
        final signersMap = entry.val;
        if (signersMap.discriminant == XdrSCValType.SCV_MAP) {
          for (final signerEntry
              in signersMap.map ?? const <XdrSCMapEntry>[]) {
            final signer = signerFromScVal(signerEntry.key);
            final sigVal = signerEntry.val;
            if (sigVal.discriminant != XdrSCValType.SCV_BYTES ||
                sigVal.bytes == null) {
              throw TransactionException.signingFailed(
                'Signer signature value is not encoded as Bytes in '
                'AuthPayload',
              );
            }
            signers[signer] = Uint8List.fromList(sigVal.bytes!.sCBytes);
          }
        }
      }
    }

    return OZSmartAccountAuthPayload(
      signers: signers,
      contextRuleIds: contextRuleIds,
    );
  }

  /// Writes an [OZSmartAccountAuthPayload] to its [XdrSCVal] representation.
  ///
  /// Builds the outer map with exactly two entries in alphabetical
  /// insertion order (`context_rule_ids`, then `signers`), matching the
  /// Soroban Rust `#[contracttype]` derive ordering for the contract's
  /// `AuthPayload` struct. Inner signer entries are sorted by the
  /// lowercase-hex of their XDR-encoded keys so the encoding is
  /// deterministic and the host-side dynamic-Map ordering check is
  /// satisfied.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding of a signer key
  /// fails.
  static XdrSCVal write(OZSmartAccountAuthPayload payload) {
    // Build signer map entries, wrapping each raw signature byte array in
    // an XdrSCVal.forBytes value.
    final signerEntries = <XdrSCMapEntry>[];
    for (final entry in payload.signers.entries) {
      signerEntries.add(
        XdrSCMapEntry(
          entry.key.toScVal(),
          XdrSCVal.forBytes(entry.value),
        ),
      );
    }

    // Sort signer entries by lowercase-hex of their XDR-encoded key bytes.
    // Lowercase-hex(byte sequence) is monotone in the underlying byte
    // sequence, so the resulting order is identical to a raw byte
    // lexicographic sort.
    signerEntries.sort((a, b) {
      try {
        final keyA = _xdrHexOfScVal(a.key);
        final keyB = _xdrHexOfScVal(b.key);
        return keyA.compareTo(keyB);
      } catch (e) {
        throw TransactionException.signingFailed(
          'Failed to XDR-encode signer key for sorting: $e',
          cause: e,
        );
      }
    });

    final signersMapScVal = XdrSCVal.forMap(signerEntries);

    final ruleIdsVec = payload.contextRuleIds
        .map((id) => XdrSCVal.forU32(id))
        .toList(growable: false);
    final contextRuleIdsScVal = XdrSCVal.forVec(ruleIdsVec);

    // Outer struct map keys insert in alphabetical order to match the
    // Soroban Rust `#[contracttype]` derive convention. Inner dynamic-map
    // keys are sorted above by XDR-byte order.
    return XdrSCVal.forMap([
      XdrSCMapEntry(
        XdrSCVal.forSymbol('context_rule_ids'),
        contextRuleIdsScVal,
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('signers'),
        signersMapScVal,
      ),
    ]);
  }

  /// Upserts a signer entry in [payload].
  ///
  /// If a signer matching [signer] already exists (compared by signer
  /// type and field values), the old entry is removed before the new one
  /// is added. The input [payload.signers] map is mutated in place.
  static void upsertSigner(
    OZSmartAccountAuthPayload payload,
    OZSmartAccountSigner signer,
    Uint8List signatureBytes,
  ) {
    OZSmartAccountSigner? existingKey;
    for (final candidate in payload.signers.keys) {
      if (_signersEqual(candidate, signer)) {
        existingKey = candidate;
        break;
      }
    }
    if (existingKey != null) {
      payload.signers.remove(existingKey);
    }
    payload.signers[signer] = Uint8List.fromList(signatureBytes);
  }

  /// Local equality used by [upsertSigner] so the codec does not depend
  /// on the higher-level builders module. Performs field-by-field
  /// comparison by signer type.
  static bool _signersEqual(OZSmartAccountSigner a, OZSmartAccountSigner b) {
    if (a is OZDelegatedSigner && b is OZDelegatedSigner) {
      return a.address == b.address;
    }
    if (a is OZExternalSigner && b is OZExternalSigner) {
      if (a.verifierAddress != b.verifierAddress) return false;
      if (a.keyData.length != b.keyData.length) return false;
      for (var i = 0; i < a.keyData.length; i++) {
        if (a.keyData[i] != b.keyData[i]) return false;
      }
      return true;
    }
    return false;
  }

  /// Parses an [OZSmartAccountSigner] from its [XdrSCVal] representation.
  ///
  /// Supported formats:
  ///
  /// - `Vec([Symbol("Delegated"), Address(...)])` returns an
  ///   [OZDelegatedSigner].
  /// - `Vec([Symbol("External"), Address(...), Bytes(...)])` returns an
  ///   [OZExternalSigner].
  ///
  /// Throws [TransactionSigningFailed] when the input is not a Vec, the
  /// Vec is empty, the first element is not a Symbol, the type tag is
  /// unknown, or any required positional element has the wrong shape.
  static OZSmartAccountSigner signerFromScVal(XdrSCVal scVal) {
    if (scVal.discriminant != XdrSCValType.SCV_VEC) {
      throw TransactionException.signingFailed(
        'Signer ScVal is not a Vec',
      );
    }
    final elements = scVal.vec;
    if (elements == null) {
      throw TransactionException.signingFailed(
        'Signer ScVal Vec is null or empty',
      );
    }
    if (elements.isEmpty) {
      throw TransactionException.signingFailed(
        'Signer ScVal Vec is empty',
      );
    }

    final typeTag = elements[0];
    if (typeTag.discriminant != XdrSCValType.SCV_SYMBOL) {
      throw TransactionException.signingFailed(
        'First element of signer Vec is not a Symbol',
      );
    }

    final tag = typeTag.sym;
    switch (tag) {
      case 'Delegated':
        if (elements.length < 2) {
          throw TransactionException.signingFailed(
            'Delegated signer Vec must have at least 2 elements',
          );
        }
        final addressScVal = elements[1];
        if (addressScVal.discriminant != XdrSCValType.SCV_ADDRESS ||
            addressScVal.address == null) {
          throw TransactionException.signingFailed(
            'Delegated signer second element is not an Address',
          );
        }
        final addressStr =
            _addressXdrToString(addressScVal.address!);
        return OZDelegatedSigner(addressStr);
      case 'External':
        if (elements.length < 3) {
          throw TransactionException.signingFailed(
            'External signer Vec must have at least 3 elements',
          );
        }
        final addressScVal = elements[1];
        if (addressScVal.discriminant != XdrSCValType.SCV_ADDRESS ||
            addressScVal.address == null) {
          throw TransactionException.signingFailed(
            'External signer second element is not an Address',
          );
        }
        final verifierAddressStr =
            _addressXdrToString(addressScVal.address!);
        final keyDataScVal = elements[2];
        if (keyDataScVal.discriminant != XdrSCValType.SCV_BYTES ||
            keyDataScVal.bytes == null) {
          throw TransactionException.signingFailed(
            'External signer third element is not Bytes',
          );
        }
        final keyData = Uint8List.fromList(keyDataScVal.bytes!.sCBytes);
        return OZExternalSigner(verifierAddressStr, keyData);
      default:
        throw TransactionException.signingFailed(
          "Unknown signer type tag: '$tag'",
        );
    }
  }

  /// Returns the lowercase-hex of the XDR-encoded byte representation of a
  /// signer key ScVal. Used by [write] to obtain a deterministic ordering
  /// key.
  static String _xdrHexOfScVal(XdrSCVal value) {
    final stream = XdrDataOutputStream();
    XdrSCVal.encode(stream, value);
    return Util.bytesToHex(Uint8List.fromList(stream.bytes));
  }

  /// Decodes an [XdrSCAddress] back to its strkey representation. Used to
  /// reconstruct signer addresses from their on-chain encoding.
  static String _addressXdrToString(XdrSCAddress address) {
    final addr = Address.fromXdr(address);
    if (addr.type == Address.TYPE_ACCOUNT && addr.accountId != null) {
      return addr.accountId!;
    }
    if (addr.type == Address.TYPE_CONTRACT && addr.contractId != null) {
      // `Address.fromXdr` returns the contract ID as hex; re-encode it as
      // its strkey C-address form so signer types accept it.
      return StrKey.encodeContractIdHex(addr.contractId!);
    }
    if (addr.type == Address.TYPE_MUXED_ACCOUNT && addr.muxedAccountId != null) {
      return addr.muxedAccountId!;
    }
    throw TransactionException.signingFailed(
      'Unsupported signer address type: ${addr.type}',
    );
  }
}
