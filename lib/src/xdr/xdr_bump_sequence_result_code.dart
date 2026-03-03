// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrBumpSequenceResultCode {
  final _value;
  const XdrBumpSequenceResultCode._internal(this._value);
  toString() => 'BumpSequenceResultCode.$_value';
  XdrBumpSequenceResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrBumpSequenceResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const BUMP_SEQUENCE_SUCCESS = const XdrBumpSequenceResultCode._internal(0);
  static const BUMP_SEQUENCE_BAD_SEQ = const XdrBumpSequenceResultCode._internal(-1);

  static XdrBumpSequenceResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return BUMP_SEQUENCE_SUCCESS;
      case -1:
        return BUMP_SEQUENCE_BAD_SEQ;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrBumpSequenceResultCode value) {
    stream.writeInt(value.value);
  }
}
