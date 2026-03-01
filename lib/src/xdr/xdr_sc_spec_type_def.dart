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

class XdrSCSpecTypeDef {
  XdrSCSpecTypeDef(this._type);
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

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeDef encoded) {
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

  static XdrSCSpecTypeDef decode(XdrDataInputStream stream) {
    XdrSCSpecTypeDef decoded = XdrSCSpecTypeDef(XdrSCSpecType.decode(stream));
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

  static XdrSCSpecTypeDef forVal() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
  }

  static XdrSCSpecTypeDef forBool() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);
  }

  static XdrSCSpecTypeDef forVoid() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID);
  }

  static XdrSCSpecTypeDef forError() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ERROR);
  }

  static XdrSCSpecTypeDef forU32() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
  }

  static XdrSCSpecTypeDef forI32() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);
  }

  static XdrSCSpecTypeDef forU64() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U64);
  }

  static XdrSCSpecTypeDef forI64() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I64);
  }

  static XdrSCSpecTypeDef forTimepoint() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT);
  }

  static XdrSCSpecTypeDef forDuration() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_DURATION);
  }

  static XdrSCSpecTypeDef forU128() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);
  }

  static XdrSCSpecTypeDef forI128() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128);
  }

  static XdrSCSpecTypeDef forU256() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U256);
  }

  static XdrSCSpecTypeDef forI256() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I256);
  }

  static XdrSCSpecTypeDef forBytes() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);
  }

  static XdrSCSpecTypeDef forString() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
  }

  static XdrSCSpecTypeDef forSymbol() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL);
  }

  static XdrSCSpecTypeDef forAddress() {
    return XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);
  }

  static XdrSCSpecTypeDef forOption(XdrSCSpecTypeOption option) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_OPTION);
    def.option = option;
    return def;
  }

  static XdrSCSpecTypeDef forResult(XdrSCSpecTypeResult result) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_RESULT);
    def.result = result;
    return def;
  }

  static XdrSCSpecTypeDef forVec(XdrSCSpecTypeVec vec) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
    def.vec = vec;
    return def;
  }

  static XdrSCSpecTypeDef forMap(XdrSCSpecTypeMap map) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_MAP);
    def.map = map;
    return def;
  }

  static XdrSCSpecTypeDef forTuple(XdrSCSpecTypeTuple tuple) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TUPLE);
    def.tuple = tuple;
    return def;
  }

  static XdrSCSpecTypeDef forBytesN(XdrSCSpecTypeBytesN bytesN) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
    def.bytesN = bytesN;
    return def;
  }

  static XdrSCSpecTypeDef forUdt(XdrSCSpecTypeUDT udt) {
    final def = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
    def.udt = udt;
    return def;
  }
}
