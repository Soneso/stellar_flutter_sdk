// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_type.dart';
import 'xdr_sc_spec_type_bytes_n.dart';
import 'xdr_sc_spec_type_def_base.dart';
import 'xdr_sc_spec_type_map.dart';
import 'xdr_sc_spec_type_option.dart';
import 'xdr_sc_spec_type_result.dart';
import 'xdr_sc_spec_type_tuple.dart';
import 'xdr_sc_spec_type_udt.dart';
import 'xdr_sc_spec_type_vec.dart';

class XdrSCSpecTypeDef extends XdrSCSpecTypeDefBase {
  XdrSCSpecTypeDef(super.type);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeDef val) {
    XdrSCSpecTypeDefBase.encode(stream, val);
  }

  static XdrSCSpecTypeDef decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeDefBase.decodeAs(stream, XdrSCSpecTypeDef.new);
  }

  static XdrSCSpecTypeDef fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrSCSpecTypeDefBase.fromTxRep(map, prefix);
    var result = XdrSCSpecTypeDef(b.discriminant);
    result.option = b.option;
    result.result = b.result;
    result.vec = b.vec;
    result.map = b.map;
    result.tuple = b.tuple;
    result.bytesN = b.bytesN;
    result.udt = b.udt;
    return result;
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
