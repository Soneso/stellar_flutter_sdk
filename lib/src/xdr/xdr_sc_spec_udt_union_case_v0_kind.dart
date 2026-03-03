// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCSpecUDTUnionCaseV0Kind {
  final _value;
  const XdrSCSpecUDTUnionCaseV0Kind._internal(this._value);
  toString() => 'SCSpecUDTUnionCaseV0Kind.$_value';
  XdrSCSpecUDTUnionCaseV0Kind(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrSCSpecUDTUnionCaseV0Kind && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SC_SPEC_UDT_UNION_CASE_VOID_V0 = const XdrSCSpecUDTUnionCaseV0Kind._internal(0);
  static const SC_SPEC_UDT_UNION_CASE_TUPLE_V0 = const XdrSCSpecUDTUnionCaseV0Kind._internal(1);

  static XdrSCSpecUDTUnionCaseV0Kind decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_SPEC_UDT_UNION_CASE_VOID_V0;
      case 1:
        return SC_SPEC_UDT_UNION_CASE_TUPLE_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseV0Kind value) {
    stream.writeInt(value.value);
  }
}
