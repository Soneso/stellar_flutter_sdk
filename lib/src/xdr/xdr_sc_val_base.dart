// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_int128_parts.dart';
import 'xdr_int256_parts.dart';
import 'xdr_int32.dart';
import 'xdr_int64.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_contract_instance.dart';
import 'xdr_sc_error.dart';
import 'xdr_sc_map_entry.dart';
import 'xdr_sc_nonce_key.dart';
import 'xdr_sc_val.dart';
import 'xdr_sc_val_type.dart';
import 'xdr_u_int128_parts.dart';
import 'xdr_u_int256_parts.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrSCValBase {
  XdrSCValBase(this._type);
  XdrSCValType _type;
  XdrSCValType get discriminant => this._type;
  set discriminant(XdrSCValType value) => this._type = value;

  bool? _b;
  bool? get b => this._b;
  set b(bool? value) => this._b = value;

  XdrSCError? _error;
  XdrSCError? get error => this._error;
  set error(XdrSCError? value) => this._error = value;

  XdrUint32? _u32;
  XdrUint32? get u32 => this._u32;
  set u32(XdrUint32? value) => this._u32 = value;

  XdrInt32? _i32;
  XdrInt32? get i32 => this._i32;
  set i32(XdrInt32? value) => this._i32 = value;

  XdrUint64? _u64;
  XdrUint64? get u64 => this._u64;
  set u64(XdrUint64? value) => this._u64 = value;

  XdrInt64? _i64;
  XdrInt64? get i64 => this._i64;
  set i64(XdrInt64? value) => this._i64 = value;

  XdrUint64? _timepoint;
  XdrUint64? get timepoint => this._timepoint;
  set timepoint(XdrUint64? value) => this._timepoint = value;

  XdrUint64? _duration;
  XdrUint64? get duration => this._duration;
  set duration(XdrUint64? value) => this._duration = value;

  XdrUInt128Parts? _u128;
  XdrUInt128Parts? get u128 => this._u128;
  set u128(XdrUInt128Parts? value) => this._u128 = value;

  XdrInt128Parts? _i128;
  XdrInt128Parts? get i128 => this._i128;
  set i128(XdrInt128Parts? value) => this._i128 = value;

  XdrUInt256Parts? _u256;
  XdrUInt256Parts? get u256 => this._u256;
  set u256(XdrUInt256Parts? value) => this._u256 = value;

  XdrInt256Parts? _i256;
  XdrInt256Parts? get i256 => this._i256;
  set i256(XdrInt256Parts? value) => this._i256 = value;

  XdrDataValue? _bytes;
  XdrDataValue? get bytes => this._bytes;
  set bytes(XdrDataValue? value) => this._bytes = value;

  String? _str;
  String? get str => this._str;
  set str(String? value) => this._str = value;

  String? _sym;
  String? get sym => this._sym;
  set sym(String? value) => this._sym = value;

  List<XdrSCVal>? _vec;
  List<XdrSCVal>? get vec => this._vec;
  set vec(List<XdrSCVal>? value) => this._vec = value;

  List<XdrSCMapEntry>? _map;
  List<XdrSCMapEntry>? get map => this._map;
  set map(List<XdrSCMapEntry>? value) => this._map = value;

  XdrSCAddress? _address;
  XdrSCAddress? get address => this._address;
  set address(XdrSCAddress? value) => this._address = value;

  XdrSCNonceKey? _nonce_key;
  XdrSCNonceKey? get nonce_key => this._nonce_key;
  set nonce_key(XdrSCNonceKey? value) => this._nonce_key = value;

  XdrSCContractInstance? _instance;
  XdrSCContractInstance? get instance => this._instance;
  set instance(XdrSCContractInstance? value) => this._instance = value;

  static void encode(XdrDataOutputStream stream, XdrSCValBase encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCValType.SCV_BOOL:
        stream.writeBoolean(encoded.b!);
        break;
      case XdrSCValType.SCV_VOID:
        break;
      case XdrSCValType.SCV_ERROR:
        XdrSCError.encode(stream, encoded.error!);
        break;
      case XdrSCValType.SCV_U32:
        XdrUint32.encode(stream, encoded.u32!);
        break;
      case XdrSCValType.SCV_I32:
        XdrInt32.encode(stream, encoded.i32!);
        break;
      case XdrSCValType.SCV_U64:
        XdrUint64.encode(stream, encoded.u64!);
        break;
      case XdrSCValType.SCV_I64:
        XdrInt64.encode(stream, encoded.i64!);
        break;
      case XdrSCValType.SCV_TIMEPOINT:
        XdrUint64.encode(stream, encoded.timepoint!);
        break;
      case XdrSCValType.SCV_DURATION:
        XdrUint64.encode(stream, encoded.duration!);
        break;
      case XdrSCValType.SCV_U128:
        XdrUInt128Parts.encode(stream, encoded.u128!);
        break;
      case XdrSCValType.SCV_I128:
        XdrInt128Parts.encode(stream, encoded.i128!);
        break;
      case XdrSCValType.SCV_U256:
        XdrUInt256Parts.encode(stream, encoded.u256!);
        break;
      case XdrSCValType.SCV_I256:
        XdrInt256Parts.encode(stream, encoded.i256!);
        break;
      case XdrSCValType.SCV_BYTES:
        XdrDataValue.encode(stream, encoded.bytes!);
        break;
      case XdrSCValType.SCV_STRING:
        stream.writeString(encoded.str!);
        break;
      case XdrSCValType.SCV_SYMBOL:
        stream.writeString(encoded.sym!);
        break;
      case XdrSCValType.SCV_VEC:
        if (encoded.vec == null) {
          stream.writeInt(0);
        } else {
          stream.writeInt(1);
          int vecSize = encoded.vec!.length;
          stream.writeInt(vecSize);
          for (int i = 0; i < vecSize; i++) {
            XdrSCVal.encode(stream, encoded.vec![i]);
          }
        }
        break;
      case XdrSCValType.SCV_MAP:
        if (encoded.map == null) {
          stream.writeInt(0);
        } else {
          stream.writeInt(1);
          int mapSize = encoded.map!.length;
          stream.writeInt(mapSize);
          for (int i = 0; i < mapSize; i++) {
            XdrSCMapEntry.encode(stream, encoded.map![i]);
          }
        }
        break;
      case XdrSCValType.SCV_ADDRESS:
        XdrSCAddress.encode(stream, encoded.address!);
        break;
      case XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE:
        break;
      case XdrSCValType.SCV_LEDGER_KEY_NONCE:
        XdrSCNonceKey.encode(stream, encoded.nonce_key!);
        break;
      case XdrSCValType.SCV_CONTRACT_INSTANCE:
        XdrSCContractInstance.encode(stream, encoded.instance!);
        break;
    }
  }

  static XdrSCValBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrSCValBase.new);
  }

  static T decodeAs<T extends XdrSCValBase>(
    XdrDataInputStream stream,
    T Function(XdrSCValType) constructor,
  ) {
    T decoded = constructor(XdrSCValType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCValType.SCV_BOOL:
        decoded.b = stream.readBoolean();
        break;
      case XdrSCValType.SCV_VOID:
        break;
      case XdrSCValType.SCV_ERROR:
        decoded.error = XdrSCError.decode(stream);
        break;
      case XdrSCValType.SCV_U32:
        decoded.u32 = XdrUint32.decode(stream);
        break;
      case XdrSCValType.SCV_I32:
        decoded.i32 = XdrInt32.decode(stream);
        break;
      case XdrSCValType.SCV_U64:
        decoded.u64 = XdrUint64.decode(stream);
        break;
      case XdrSCValType.SCV_I64:
        decoded.i64 = XdrInt64.decode(stream);
        break;
      case XdrSCValType.SCV_TIMEPOINT:
        decoded.timepoint = XdrUint64.decode(stream);
        break;
      case XdrSCValType.SCV_DURATION:
        decoded.duration = XdrUint64.decode(stream);
        break;
      case XdrSCValType.SCV_U128:
        decoded.u128 = XdrUInt128Parts.decode(stream);
        break;
      case XdrSCValType.SCV_I128:
        decoded.i128 = XdrInt128Parts.decode(stream);
        break;
      case XdrSCValType.SCV_U256:
        decoded.u256 = XdrUInt256Parts.decode(stream);
        break;
      case XdrSCValType.SCV_I256:
        decoded.i256 = XdrInt256Parts.decode(stream);
        break;
      case XdrSCValType.SCV_BYTES:
        decoded.bytes = XdrDataValue.decode(stream);
        break;
      case XdrSCValType.SCV_STRING:
        decoded.str = stream.readString();
        break;
      case XdrSCValType.SCV_SYMBOL:
        decoded.sym = stream.readString();
        break;
      case XdrSCValType.SCV_VEC:
        int vecPresent = stream.readInt();
        if (vecPresent != 0) {
          int vecSize = stream.readInt();
          decoded.vec = List<XdrSCVal>.empty(growable: true);
          for (int i = 0; i < vecSize; i++) {
            decoded.vec!.add(XdrSCVal.decode(stream));
          }
        }
        break;
      case XdrSCValType.SCV_MAP:
        int mapPresent = stream.readInt();
        if (mapPresent != 0) {
          int mapSize = stream.readInt();
          decoded.map = List<XdrSCMapEntry>.empty(growable: true);
          for (int i = 0; i < mapSize; i++) {
            decoded.map!.add(XdrSCMapEntry.decode(stream));
          }
        }
        break;
      case XdrSCValType.SCV_ADDRESS:
        decoded.address = XdrSCAddress.decode(stream);
        break;
      case XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE:
        break;
      case XdrSCValType.SCV_LEDGER_KEY_NONCE:
        decoded.nonce_key = XdrSCNonceKey.decode(stream);
        break;
      case XdrSCValType.SCV_CONTRACT_INSTANCE:
        decoded.instance = XdrSCContractInstance.decode(stream);
        break;
    }
    return decoded;
  }
}
