// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import '../constants/stellar_protocol_constants.dart';
import 'xdr_claimable_balance_id_base.dart';
import 'xdr_claimable_balance_id_type.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_json_helper.dart';

class XdrClaimableBalanceID extends XdrClaimableBalanceIDBase {
  XdrClaimableBalanceID(super.type);

  static void encode(XdrDataOutputStream stream, XdrClaimableBalanceID val) {
    XdrClaimableBalanceIDBase.encode(stream, val);
  }

  static XdrClaimableBalanceID decode(XdrDataInputStream stream) {
    return XdrClaimableBalanceIDBase.decodeAs(
      stream,
      XdrClaimableBalanceID.new,
    );
  }

  static XdrClaimableBalanceID fromTxRep(
    Map<String, String> map,
    String prefix,
  ) {
    var b = XdrClaimableBalanceIDBase.fromTxRep(map, prefix);
    var result = XdrClaimableBalanceID(b.discriminant);
    result.v0 = b.v0;
    return result;
  }

  /// Builds a claimable balance id from [claimableBalanceId], given either as
  /// the strkey rendering of the id (B...) or as its hex rendering.
  ///
  /// A claimable balance strkey is
  /// [StellarProtocolConstants.STRKEY_CLAIMABLE_BALANCE_LENGTH] characters, so
  /// a string of that length beginning with "B" is read as one; every other
  /// string is read as hex and fitted to the width of the hash by
  /// [Util.stringIdToXdrHash].
  ///
  /// A hex rendering may carry the balance id type ahead of the hash, either
  /// as the single byte the strkey form leads with or as the four-byte
  /// big-endian XDR union discriminant Horizon writes. Both widths are held to
  /// [XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0].
  ///
  /// Throws:
  /// - [FormatException]: if a strkey is not one this codec accepts, if a hex
  ///   rendering is not hexadecimal, or if a hex rendering carries a
  ///   discriminant, in either width, that names no claimable balance id type
  static XdrClaimableBalanceID forId(String claimableBalanceId) {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID(
      XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0,
    );

    if (claimableBalanceId.startsWith("B") &&
        claimableBalanceId.length ==
            StellarProtocolConstants.STRKEY_CLAIMABLE_BALANCE_LENGTH) {
      // decodeClaimableBalanceId returns exactly the discriminant byte and the
      // 32-byte hash, with the discriminant already held to V0.
      final Uint8List decoded = StrKey.decodeClaimableBalanceId(
        claimableBalanceId,
      );
      bId.v0 = XdrHash(
        Uint8List.sublistView(
          decoded,
          StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_BYTES,
        ),
      );
      return bId;
    }

    const int taggedHexLength =
        (StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_BYTES +
            StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) *
        2;
    const int unionTaggedHexLength =
        (StellarProtocolConstants.XDR_UNION_DISCRIMINANT_BYTES +
            StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) *
        2;
    int? tag;
    if (claimableBalanceId.length == taggedHexLength) {
      tag = Util.hexToBytes(claimableBalanceId.toUpperCase())[0];
    } else if (claimableBalanceId.length == unionTaggedHexLength) {
      tag = ByteData.sublistView(
        Util.hexToBytes(claimableBalanceId.toUpperCase()),
      ).getUint32(0, Endian.big);
    }
    if (tag != null &&
        tag != XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0.value) {
      throw FormatException(
        "Claimable balance id carries the discriminant $tag, "
        "which names no claimable balance id type",
      );
    }

    bId.v0 = Util.stringIdToXdrHash(claimableBalanceId);
    return bId;
  }

  String get claimableBalanceIdString {
    return Util.bytesToHex(
      Uint8List.fromList([discriminant.value, ...v0!.hash]),
    );
  }

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrClaimableBalanceID.
  ///
  /// Dart does not inherit statics, so this narrows the base class rendering to
  /// this type rather than relying on the one the base declares.
  static XdrClaimableBalanceID fromXdrJson(String json) => fromXdrJsonValue(
    XdrJsonHelper.decodeDocument(json, type: 'XdrClaimableBalanceID'),
  );

  static XdrClaimableBalanceID fromXdrJsonValue(Object? value) =>
      XdrClaimableBalanceIDBase.fromXdrJsonValueAs(
        value,
        XdrClaimableBalanceID.new,
      );
}
