// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrManageDataResultCode {
  final _value;

  const XdrManageDataResultCode._internal(this._value);

  toString() => 'ManageDataResultCode.$_value';

  XdrManageDataResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrManageDataResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const MANAGE_DATA_SUCCESS = const XdrManageDataResultCode._internal(0);

  /// The network hasn't moved to this protocol change yet.
  static const MANAGE_DATA_NOT_SUPPORTED_YET =
      const XdrManageDataResultCode._internal(-1);

  /// Trying to remove a Data Entry that isn't there.
  static const MANAGE_DATA_NAME_NOT_FOUND =
      const XdrManageDataResultCode._internal(-2);

  /// Not enough funds to create a new Data Entry.
  static const MANAGE_DATA_LOW_RESERVE =
      const XdrManageDataResultCode._internal(-3);

  /// Name not a valid string.
  static const MANAGE_DATA_INVALID_NAME =
      const XdrManageDataResultCode._internal(-4);

  static XdrManageDataResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MANAGE_DATA_SUCCESS;
      case -1:
        return MANAGE_DATA_NOT_SUPPORTED_YET;
      case -2:
        return MANAGE_DATA_NAME_NOT_FOUND;
      case -3:
        return MANAGE_DATA_LOW_RESERVE;
      case -4:
        return MANAGE_DATA_INVALID_NAME;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrManageDataResultCode value) {
    stream.writeInt(value.value);
  }
}
