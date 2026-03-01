// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_udt_union_case_tuple_v0.dart';
import 'xdr_sc_spec_udt_union_case_v0_kind.dart';
import 'xdr_sc_spec_udt_union_case_void_v0.dart';

class XdrSCSpecUDTUnionCaseV0 {
  XdrSCSpecUDTUnionCaseV0(this._kind);
  XdrSCSpecUDTUnionCaseV0Kind _kind;
  XdrSCSpecUDTUnionCaseV0Kind get discriminant => this._kind;
  set discriminant(XdrSCSpecUDTUnionCaseV0Kind value) => this._kind = value;

  XdrSCSpecUDTUnionCaseVoidV0? _voidCase;
  XdrSCSpecUDTUnionCaseVoidV0? get voidCase => this._voidCase;
  set voidCase(XdrSCSpecUDTUnionCaseVoidV0? value) => this._voidCase = value;

  XdrSCSpecUDTUnionCaseTupleV0? _tupleCase;
  XdrSCSpecUDTUnionCaseTupleV0? get tupleCase => this._tupleCase;
  set tupleCase(XdrSCSpecUDTUnionCaseTupleV0? value) => this._tupleCase = value;

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseV0 encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0:
        XdrSCSpecUDTUnionCaseVoidV0.encode(stream, encoded.voidCase!);
        break;
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
        XdrSCSpecUDTUnionCaseTupleV0.encode(stream, encoded.tupleCase!);
        break;
    }
  }

  static XdrSCSpecUDTUnionCaseV0 decode(XdrDataInputStream stream) {
    XdrSCSpecUDTUnionCaseV0 decoded =
        XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0:
        decoded.voidCase = XdrSCSpecUDTUnionCaseVoidV0.decode(stream);
        break;
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
        decoded.tupleCase = XdrSCSpecUDTUnionCaseTupleV0.decode(stream);
        break;
    }
    return decoded;
  }
}
