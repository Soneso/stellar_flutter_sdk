// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_entry_kind.dart';
import 'xdr_sc_spec_event_v0.dart';
import 'xdr_sc_spec_function_v0.dart';
import 'xdr_sc_spec_udt_enum_v0.dart';
import 'xdr_sc_spec_udt_error_enum_v0.dart';
import 'xdr_sc_spec_udt_struct_v0.dart';
import 'xdr_sc_spec_udt_union_v0.dart';

class XdrSCSpecEntry {
  XdrSCSpecEntry(this._kind);
  XdrSCSpecEntryKind _kind;
  XdrSCSpecEntryKind get discriminant => this._kind;
  set discriminant(XdrSCSpecEntryKind value) => this._kind = value;

  XdrSCSpecFunctionV0? _functionV0;
  XdrSCSpecFunctionV0? get functionV0 => this._functionV0;
  set functionV0(XdrSCSpecFunctionV0? value) => this._functionV0 = value;

  XdrSCSpecUDTStructV0? _udtStructV0;
  XdrSCSpecUDTStructV0? get udtStructV0 => this._udtStructV0;
  set udtStructV0(XdrSCSpecUDTStructV0? value) => this._udtStructV0 = value;

  XdrSCSpecUDTUnionV0? _udtUnionV0;
  XdrSCSpecUDTUnionV0? get udtUnionV0 => this._udtUnionV0;
  set udtUnionV0(XdrSCSpecUDTUnionV0? value) => this._udtUnionV0 = value;

  XdrSCSpecUDTEnumV0? _udtEnumV0;
  XdrSCSpecUDTEnumV0? get udtEnumV0 => this._udtEnumV0;
  set udtEnumV0(XdrSCSpecUDTEnumV0? value) => this._udtEnumV0 = value;

  XdrSCSpecUDTErrorEnumV0? _udtErrorEnumV0;
  XdrSCSpecUDTErrorEnumV0? get udtErrorEnumV0 => this._udtErrorEnumV0;
  set udtErrorEnumV0(XdrSCSpecUDTErrorEnumV0? value) =>
      this._udtErrorEnumV0 = value;

  XdrSCSpecEventV0? _eventV0;
  XdrSCSpecEventV0? get eventV0 => this._eventV0;
  set eventV0(XdrSCSpecEventV0? value) => this._eventV0 = value;

  static void encode(XdrDataOutputStream stream, XdrSCSpecEntry encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0:
        XdrSCSpecFunctionV0.encode(stream, encoded.functionV0!);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0:
        XdrSCSpecUDTStructV0.encode(stream, encoded.udtStructV0!);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0:
        XdrSCSpecUDTUnionV0.encode(stream, encoded.udtUnionV0!);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0:
        XdrSCSpecUDTEnumV0.encode(stream, encoded.udtEnumV0!);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0:
        XdrSCSpecUDTErrorEnumV0.encode(stream, encoded.udtErrorEnumV0!);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0:
        XdrSCSpecEventV0.encode(stream, encoded.eventV0!);
        break;
    }
  }

  static XdrSCSpecEntry decode(XdrDataInputStream stream) {
    XdrSCSpecEntry decoded = XdrSCSpecEntry(XdrSCSpecEntryKind.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0:
        decoded.functionV0 = XdrSCSpecFunctionV0.decode(stream);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0:
        decoded.udtStructV0 = XdrSCSpecUDTStructV0.decode(stream);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0:
        decoded.udtUnionV0 = XdrSCSpecUDTUnionV0.decode(stream);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0:
        decoded.udtEnumV0 = XdrSCSpecUDTEnumV0.decode(stream);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0:
        decoded.udtErrorEnumV0 = XdrSCSpecUDTErrorEnumV0.decode(stream);
        break;
      case XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0:
        decoded.eventV0 = XdrSCSpecEventV0.decode(stream);
        break;
    }
    return decoded;
  }
}
