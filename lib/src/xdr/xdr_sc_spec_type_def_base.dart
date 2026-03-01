// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type.dart';
import 'xdr_sc_spec_type_bytes_n.dart';
import 'xdr_sc_spec_type_map.dart';
import 'xdr_sc_spec_type_option.dart';
import 'xdr_sc_spec_type_result.dart';
import 'xdr_sc_spec_type_tuple.dart';
import 'xdr_sc_spec_type_udt.dart';
import 'xdr_sc_spec_type_vec.dart';

class XdrSCSpecTypeDefBase {
  XdrSCSpecTypeDefBase(this._type);
  XdrSCSpecType _type;
  XdrSCSpecType get discriminant => this._type;
  set discriminant(XdrSCSpecType value) => this._type = value;

  XdrSCSpecTypeOption? _option;
  XdrSCSpecTypeOption? get option => this._option;
  set option(XdrSCSpecTypeOption? value) => this._option = value;

  XdrSCSpecTypeResult? _result;
  XdrSCSpecTypeResult? get result => this._result;
  set result(XdrSCSpecTypeResult? value) => this._result = value;

  XdrSCSpecTypeVec? _vec;
  XdrSCSpecTypeVec? get vec => this._vec;
  set vec(XdrSCSpecTypeVec? value) => this._vec = value;

  XdrSCSpecTypeMap? _map;
  XdrSCSpecTypeMap? get map => this._map;
  set map(XdrSCSpecTypeMap? value) => this._map = value;

  XdrSCSpecTypeTuple? _tuple;
  XdrSCSpecTypeTuple? get tuple => this._tuple;
  set tuple(XdrSCSpecTypeTuple? value) => this._tuple = value;

  XdrSCSpecTypeBytesN? _bytesN;
  XdrSCSpecTypeBytesN? get bytesN => this._bytesN;
  set bytesN(XdrSCSpecTypeBytesN? value) => this._bytesN = value;

  XdrSCSpecTypeUDT? _udt;
  XdrSCSpecTypeUDT? get udt => this._udt;
  set udt(XdrSCSpecTypeUDT? value) => this._udt = value;

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeDefBase encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCSpecType.SC_SPEC_TYPE_VAL:
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
      case XdrSCSpecType.SC_SPEC_TYPE_VOID:
      case XdrSCSpecType.SC_SPEC_TYPE_ERROR:
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
      case XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT:
      case XdrSCSpecType.SC_SPEC_TYPE_DURATION:
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
      case XdrSCSpecType.SC_SPEC_TYPE_U256:
      case XdrSCSpecType.SC_SPEC_TYPE_I256:
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
      case XdrSCSpecType.SC_SPEC_TYPE_STRING:
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
      case XdrSCSpecType.SC_SPEC_TYPE_ADDRESS:
      case XdrSCSpecType.SC_SPEC_TYPE_MUXED_ADDRESS:
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_OPTION:
        XdrSCSpecTypeOption.encode(stream, encoded.option!);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_RESULT:
        XdrSCSpecTypeResult.encode(stream, encoded.result!);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_VEC:
        XdrSCSpecTypeVec.encode(stream, encoded.vec!);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_MAP:
        XdrSCSpecTypeMap.encode(stream, encoded.map!);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_TUPLE:
        XdrSCSpecTypeTuple.encode(stream, encoded.tuple!);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES_N:
        XdrSCSpecTypeBytesN.encode(stream, encoded.bytesN!);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_UDT:
        XdrSCSpecTypeUDT.encode(stream, encoded.udt!);
        break;
    }
  }

  static XdrSCSpecTypeDefBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrSCSpecTypeDefBase.new);
  }

  static T decodeAs<T extends XdrSCSpecTypeDefBase>(
    XdrDataInputStream stream,
    T Function(XdrSCSpecType) constructor,
  ) {
    T decoded = constructor(XdrSCSpecType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCSpecType.SC_SPEC_TYPE_VAL:
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
      case XdrSCSpecType.SC_SPEC_TYPE_VOID:
      case XdrSCSpecType.SC_SPEC_TYPE_ERROR:
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
      case XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT:
      case XdrSCSpecType.SC_SPEC_TYPE_DURATION:
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
      case XdrSCSpecType.SC_SPEC_TYPE_U256:
      case XdrSCSpecType.SC_SPEC_TYPE_I256:
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
      case XdrSCSpecType.SC_SPEC_TYPE_STRING:
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
      case XdrSCSpecType.SC_SPEC_TYPE_ADDRESS:
      case XdrSCSpecType.SC_SPEC_TYPE_MUXED_ADDRESS:
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_OPTION:
        decoded.option = XdrSCSpecTypeOption.decode(stream);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_RESULT:
        decoded.result = XdrSCSpecTypeResult.decode(stream);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_VEC:
        decoded.vec = XdrSCSpecTypeVec.decode(stream);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_MAP:
        decoded.map = XdrSCSpecTypeMap.decode(stream);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_TUPLE:
        decoded.tuple = XdrSCSpecTypeTuple.decode(stream);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES_N:
        decoded.bytesN = XdrSCSpecTypeBytesN.decode(stream);
        break;
      case XdrSCSpecType.SC_SPEC_TYPE_UDT:
        decoded.udt = XdrSCSpecTypeUDT.decode(stream);
        break;
    }
    return decoded;
  }
}
