// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrAccountMergeResultCode {
  final _value;
  const XdrAccountMergeResultCode._internal(this._value);
  toString() => 'AccountMergeResultCode.$_value';
  XdrAccountMergeResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrAccountMergeResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const ACCOUNT_MERGE_SUCCESS =
      const XdrAccountMergeResultCode._internal(0);
  static const ACCOUNT_MERGE_MALFORMED =
      const XdrAccountMergeResultCode._internal(-1);
  static const ACCOUNT_MERGE_NO_ACCOUNT =
      const XdrAccountMergeResultCode._internal(-2);
  static const ACCOUNT_MERGE_IMMUTABLE_SET =
      const XdrAccountMergeResultCode._internal(-3);
  static const ACCOUNT_MERGE_HAS_SUB_ENTRIES =
      const XdrAccountMergeResultCode._internal(-4);
  static const ACCOUNT_MERGE_SEQNUM_TOO_FAR =
      const XdrAccountMergeResultCode._internal(-5);
  static const ACCOUNT_MERGE_DEST_FULL =
      const XdrAccountMergeResultCode._internal(-6);
  static const ACCOUNT_MERGE_IS_SPONSOR =
      const XdrAccountMergeResultCode._internal(-7);

  static XdrAccountMergeResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ACCOUNT_MERGE_SUCCESS;
      case -1:
        return ACCOUNT_MERGE_MALFORMED;
      case -2:
        return ACCOUNT_MERGE_NO_ACCOUNT;
      case -3:
        return ACCOUNT_MERGE_IMMUTABLE_SET;
      case -4:
        return ACCOUNT_MERGE_HAS_SUB_ENTRIES;
      case -5:
        return ACCOUNT_MERGE_SEQNUM_TOO_FAR;
      case -6:
        return ACCOUNT_MERGE_DEST_FULL;
      case -7:
        return ACCOUNT_MERGE_IS_SPONSOR;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrAccountMergeResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
