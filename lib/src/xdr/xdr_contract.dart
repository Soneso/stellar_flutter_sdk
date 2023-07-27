// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:pinenacl/api.dart';
import '../key_pair.dart';
import '../soroban/soroban_auth.dart';
import '../util.dart';
import 'xdr_account.dart';
import 'xdr_asset.dart';
import 'xdr_data_entry.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger.dart';
import 'xdr_signing.dart';
import 'xdr_transaction.dart';
import 'xdr_type.dart';

class XdrSCValType {
  final _value;
  const XdrSCValType._internal(this._value);
  toString() => 'SCValType.$_value';
  XdrSCValType(this._value);
  get value => this._value;

  static const SCV_BOOL = const XdrSCValType._internal(0);
  static const SCV_VOID = const XdrSCValType._internal(1);
  static const SCV_ERROR = const XdrSCValType._internal(2);
  static const SCV_U32 = const XdrSCValType._internal(3);
  static const SCV_I32 = const XdrSCValType._internal(4);
  static const SCV_U64 = const XdrSCValType._internal(5);
  static const SCV_I64 = const XdrSCValType._internal(6);
  static const SCV_TIMEPOINT = const XdrSCValType._internal(7);
  static const SCV_DURATION = const XdrSCValType._internal(8);
  static const SCV_U128 = const XdrSCValType._internal(9);
  static const SCV_I128 = const XdrSCValType._internal(10);
  static const SCV_U256 = const XdrSCValType._internal(11);
  static const SCV_I256 = const XdrSCValType._internal(12);
  static const SCV_BYTES = const XdrSCValType._internal(13);
  static const SCV_STRING = const XdrSCValType._internal(14);
  static const SCV_SYMBOL = const XdrSCValType._internal(15);
  static const SCV_VEC = const XdrSCValType._internal(16);
  static const SCV_MAP = const XdrSCValType._internal(17);
  static const SCV_ADDRESS = const XdrSCValType._internal(18);
  static const SCV_CONTRACT_INSTANCE = const XdrSCValType._internal(19);
  static const SCV_LEDGER_KEY_CONTRACT_INSTANCE =
      const XdrSCValType._internal(20);
  static const SCV_LEDGER_KEY_NONCE = const XdrSCValType._internal(21);

  static XdrSCValType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCV_BOOL;
      case 1:
        return SCV_VOID;
      case 2:
        return SCV_ERROR;
      case 3:
        return SCV_U32;
      case 4:
        return SCV_I32;
      case 5:
        return SCV_U64;
      case 6:
        return SCV_I64;
      case 7:
        return SCV_TIMEPOINT;
      case 8:
        return SCV_DURATION;
      case 9:
        return SCV_U128;
      case 10:
        return SCV_I128;
      case 11:
        return SCV_U256;
      case 12:
        return SCV_I256;
      case 13:
        return SCV_BYTES;
      case 14:
        return SCV_STRING;
      case 15:
        return SCV_SYMBOL;
      case 16:
        return SCV_VEC;
      case 17:
        return SCV_MAP;
      case 18:
        return SCV_ADDRESS;
      case 19:
        return SCV_CONTRACT_INSTANCE;
      case 20:
        return SCV_LEDGER_KEY_CONTRACT_INSTANCE;
      case 21:
        return SCV_LEDGER_KEY_NONCE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCValType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCErrorType {
  final _value;
  const XdrSCErrorType._internal(this._value);
  toString() => 'SCErrorType.$_value';
  XdrSCErrorType(this._value);
  get value => this._value;

  static const SCE_CONTRACT = const XdrSCErrorType._internal(0);
  static const SCE_WASM_VM = const XdrSCErrorType._internal(1);
  static const SCE_CONTEXT = const XdrSCErrorType._internal(2);
  static const SCE_STORAGE = const XdrSCErrorType._internal(3);
  static const SCE_OBJECT = const XdrSCErrorType._internal(4);
  static const SCE_CRYPTO = const XdrSCErrorType._internal(5);
  static const SCE_EVENTS = const XdrSCErrorType._internal(6);
  static const SCE_BUDGET = const XdrSCErrorType._internal(7);
  static const SCE_VALUE = const XdrSCErrorType._internal(8);
  static const SCE_AUTH = const XdrSCErrorType._internal(9);

  static XdrSCErrorType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCE_CONTRACT;
      case 1:
        return SCE_WASM_VM;
      case 2:
        return SCE_CONTEXT;
      case 3:
        return SCE_STORAGE;
      case 4:
        return SCE_OBJECT;
      case 5:
        return SCE_CRYPTO;
      case 6:
        return SCE_EVENTS;
      case 7:
        return SCE_BUDGET;
      case 8:
        return SCE_VALUE;
      case 9:
        return SCE_AUTH;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCErrorType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCErrorCode {
  final _value;
  const XdrSCErrorCode._internal(this._value);
  toString() => 'SCErrorCod.$_value';
  XdrSCErrorCode(this._value);
  get value => this._value;

  static const SCEC_ARITH_DOMAIN = const XdrSCErrorCode._internal(0);
  static const SCEC_INDEX_BOUNDS = const XdrSCErrorCode._internal(1);
  static const SCEC_INVALID_INPUT = const XdrSCErrorCode._internal(2);
  static const SCEC_MISSING_VALUE = const XdrSCErrorCode._internal(3);
  static const SCEC_EXISTING_VALUE = const XdrSCErrorCode._internal(4);
  static const SCEC_EXCEEDED_LIMIT = const XdrSCErrorCode._internal(5);
  static const SCEC_INVALID_ACTION = const XdrSCErrorCode._internal(6);
  static const SCEC_INTERNAL_ERROR = const XdrSCErrorCode._internal(7);
  static const SCEC_UNEXPECTED_TYPE = const XdrSCErrorCode._internal(8);
  static const SCEC_UNEXPECTED_SIZE = const XdrSCErrorCode._internal(9);

  static XdrSCErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCEC_ARITH_DOMAIN;
      case 1:
        return SCEC_INDEX_BOUNDS;
      case 2:
        return SCEC_INVALID_INPUT;
      case 3:
        return SCEC_MISSING_VALUE;
      case 4:
        return SCEC_EXISTING_VALUE;
      case 5:
        return SCEC_EXCEEDED_LIMIT;
      case 6:
        return SCEC_INVALID_ACTION;
      case 7:
        return SCEC_INTERNAL_ERROR;
      case 8:
        return SCEC_UNEXPECTED_TYPE;
      case 9:
        return SCEC_UNEXPECTED_SIZE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSorobanCredentialsType {
  final _value;
  const XdrSorobanCredentialsType._internal(this._value);
  toString() => 'SorobanCredentialsType.$_value';
  XdrSorobanCredentialsType(this._value);
  get value => this._value;

  static const SOROBAN_CREDENTIALS_SOURCE_ACCOUNT =
      const XdrSorobanCredentialsType._internal(0);
  static const SOROBAN_CREDENTIALS_ADDRESS =
      const XdrSorobanCredentialsType._internal(1);

  static XdrSorobanCredentialsType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SOROBAN_CREDENTIALS_SOURCE_ACCOUNT;
      case 1:
        return SOROBAN_CREDENTIALS_ADDRESS;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSorobanCredentialsType value) {
    stream.writeInt(value.value);
  }
}

class XdrSorobanCredentials {
  XdrSorobanCredentialsType _type;
  XdrSorobanCredentialsType get type => this._type;
  set type(XdrSorobanCredentialsType value) => this._type = value;

  XdrSorobanAddressCredentials? _address;
  XdrSorobanAddressCredentials? get address => this._address;
  set address(XdrSorobanAddressCredentials? value) => this._address = value;

  XdrSorobanCredentials(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanCredentials encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        XdrSorobanAddressCredentials.encode(stream, encoded.address!);
        break;
    }
  }

  static XdrSorobanCredentials decode(XdrDataInputStream stream) {
    XdrSorobanCredentials decoded =
        XdrSorobanCredentials(XdrSorobanCredentialsType.decode(stream));
    switch (decoded.type) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        decoded.address = XdrSorobanAddressCredentials.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrSCError {
  XdrSCErrorType _type;
  XdrSCErrorType get type => this._type;
  set type(XdrSCErrorType value) => this._type = value;

  XdrSCErrorCode _errorCode;
  XdrSCErrorCode get errorCode => this._errorCode;
  set errorCode(XdrSCErrorCode value) => this._errorCode = value;

  XdrSCError(this._type, this._errorCode);

  static void encode(XdrDataOutputStream stream, XdrSCError encoded) {
    XdrSCErrorType.encode(stream, encoded.type);
    XdrSCErrorCode.encode(stream, encoded.errorCode);
  }

  static XdrSCError decode(XdrDataInputStream stream) {
    return XdrSCError(
        XdrSCErrorType.decode(stream), XdrSCErrorCode.decode(stream));
  }
}

class XdrSCAddressType {
  final _value;
  const XdrSCAddressType._internal(this._value);
  toString() => 'SCAddressType.$_value';
  XdrSCAddressType(this._value);
  get value => this._value;

  static const SC_ADDRESS_TYPE_ACCOUNT = const XdrSCAddressType._internal(0);
  static const SC_ADDRESS_TYPE_CONTRACT = const XdrSCAddressType._internal(1);

  static XdrSCAddressType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_ADDRESS_TYPE_ACCOUNT;
      case 1:
        return SC_ADDRESS_TYPE_CONTRACT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCAddressType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCAddress {
  XdrSCAddress(this._type);
  XdrSCAddressType _type;
  XdrSCAddressType get discriminant => this._type;
  set discriminant(XdrSCAddressType value) => this._type = value;

  XdrAccountID? _accountId;
  XdrAccountID? get accountId => this._accountId;
  set accountId(XdrAccountID? value) => this._accountId = value;

  XdrHash? _contractId;
  XdrHash? get contractId => this._contractId;
  set contractId(XdrHash? value) => this._contractId = value;

  static void encode(XdrDataOutputStream stream, XdrSCAddress encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
        XdrAccountID.encode(stream, encoded.accountId!);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT:
        XdrHash.encode(stream, encoded.contractId!);
        break;
    }
  }

  static XdrSCAddress decode(XdrDataInputStream stream) {
    XdrSCAddress decoded = XdrSCAddress(XdrSCAddressType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
        decoded.accountId = XdrAccountID.decode(stream);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT:
        decoded.contractId = XdrHash.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrSCAddress forAccountId(String accountId) {
    XdrSCAddress result =
        XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
    result.accountId =
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey);
    return result;
  }

  static XdrSCAddress forContractId(String contractId) {
    XdrSCAddress result =
        XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
    result.contractId = XdrHash(Util.hexToBytes(contractId));
    return result;
  }
}

class XdrSCNonceKey {
  XdrInt64 _nonce;
  XdrInt64 get nonce => this._nonce;
  set nonce(XdrInt64 value) => this._nonce = value;

  XdrSCNonceKey(this._nonce);

  static void encode(XdrDataOutputStream stream, XdrSCNonceKey encoded) {
    XdrInt64.encode(stream, encoded.nonce);
  }

  static XdrSCNonceKey decode(XdrDataInputStream stream) {
    return XdrSCNonceKey(XdrInt64.decode(stream));
  }
}

class XdrSCMapEntry {
  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrSCVal _val;
  XdrSCVal get val => this._val;
  set val(XdrSCVal value) => this._val = value;

  XdrSCMapEntry(this._key, this._val);

  static void encode(XdrDataOutputStream stream, XdrSCMapEntry encoded) {
    XdrSCVal.encode(stream, encoded.key);
    XdrSCVal.encode(stream, encoded.val);
  }

  static XdrSCMapEntry decode(XdrDataInputStream stream) {
    return XdrSCMapEntry(XdrSCVal.decode(stream), XdrSCVal.decode(stream));
  }
}

class XdrInt128Parts {
  // Both signed and unsigned 128-bit ints
  // are transported in a pair of uint64s
  // to reduce the risk of sign-extension.
  XdrInt64 _hi;
  XdrInt64 get hi => this._hi;
  set hi(XdrInt64 value) => this._hi = value;

  XdrUint64 _lo;
  XdrUint64 get lo => this._lo;
  set lo(XdrUint64 value) => this._lo = value;

  XdrInt128Parts(this._hi, this._lo);

  static void encode(XdrDataOutputStream stream, XdrInt128Parts encoded) {
    XdrInt64.encode(stream, encoded.hi);
    XdrUint64.encode(stream, encoded.lo);
  }

  static XdrInt128Parts decode(XdrDataInputStream stream) {
    return XdrInt128Parts(XdrInt64.decode(stream), XdrUint64.decode(stream));
  }

  static XdrInt128Parts forHiLo(int hi, int lo) {
    return XdrInt128Parts(
      XdrInt64(hi),
      XdrUint64(lo),
    );
  }
}

class XdrUInt128Parts {
  XdrUint64 _hi;
  XdrUint64 get hi => this._hi;
  set hi(XdrUint64 value) => this._hi = value;

  XdrUint64 _lo;
  XdrUint64 get lo => this._lo;
  set lo(XdrUint64 value) => this._lo = value;

  XdrUInt128Parts(this._hi, this._lo);

  static void encode(XdrDataOutputStream stream, XdrUInt128Parts encoded) {
    XdrUint64.encode(stream, encoded.hi);
    XdrUint64.encode(stream, encoded.lo);
  }

  static XdrUInt128Parts decode(XdrDataInputStream stream) {
    return XdrUInt128Parts(XdrUint64.decode(stream), XdrUint64.decode(stream));
  }

  static XdrUInt128Parts forHiLo(int hi, int lo) {
    return XdrUInt128Parts(
      XdrUint64(hi),
      XdrUint64(lo),
    );
  }
}

class XdrInt256Parts {
  XdrInt64 _hiHi;
  XdrInt64 get hiHi => this._hiHi;
  set hiHi(XdrInt64 value) => this._hiHi = value;

  XdrUint64 _hiLo;
  XdrUint64 get hiLo => this._hiLo;
  set hiLo(XdrUint64 value) => this._hiLo = value;

  XdrUint64 _loHi;
  XdrUint64 get loHi => this._loHi;
  set loHi(XdrUint64 value) => this._loHi = value;

  XdrUint64 _loLo;
  XdrUint64 get loLo => this._loLo;
  set loLo(XdrUint64 value) => this._loLo = value;

  XdrInt256Parts(this._hiHi, this._hiLo, this._loHi, this._loLo);

  static void encode(XdrDataOutputStream stream, XdrInt256Parts encoded) {
    XdrInt64.encode(stream, encoded.hiHi);
    XdrUint64.encode(stream, encoded.hiLo);
    XdrUint64.encode(stream, encoded.loHi);
    XdrUint64.encode(stream, encoded.loLo);
  }

  static XdrInt256Parts decode(XdrDataInputStream stream) {
    return XdrInt256Parts(XdrInt64.decode(stream), XdrUint64.decode(stream),
        XdrUint64.decode(stream), XdrUint64.decode(stream));
  }

  static XdrInt256Parts forHiHiHiLoLoHiLoLo(
    int hiHi,
    int hiLo,
    int loHi,
    int loLo,
  ) {
    return XdrInt256Parts(
        XdrInt64(hiHi), XdrUint64(hiLo), XdrUint64(loHi), XdrUint64(loLo));
  }
}

class XdrUInt256Parts {
  XdrUint64 _hiHi;
  XdrUint64 get hiHi => this._hiHi;
  set hiHi(XdrUint64 value) => this._hiHi = value;

  XdrUint64 _hiLo;
  XdrUint64 get hiLo => this._hiLo;
  set hiLo(XdrUint64 value) => this._hiLo = value;

  XdrUint64 _loHi;
  XdrUint64 get loHi => this._loHi;
  set loHi(XdrUint64 value) => this._loHi = value;

  XdrUint64 _loLo;
  XdrUint64 get loLo => this._loLo;
  set loLo(XdrUint64 value) => this._loLo = value;

  XdrUInt256Parts(this._hiHi, this._hiLo, this._loHi, this._loLo);

  static void encode(XdrDataOutputStream stream, XdrUInt256Parts encoded) {
    XdrUint64.encode(stream, encoded.hiHi);
    XdrUint64.encode(stream, encoded.hiLo);
    XdrUint64.encode(stream, encoded.loHi);
    XdrUint64.encode(stream, encoded.loLo);
  }

  static XdrUInt256Parts decode(XdrDataInputStream stream) {
    return XdrUInt256Parts(XdrUint64.decode(stream), XdrUint64.decode(stream),
        XdrUint64.decode(stream), XdrUint64.decode(stream));
  }

  static XdrUInt256Parts forHiHiHiLoLoHiLoLo(
    int hiHi,
    int hiLo,
    int loHi,
    int loLo,
  ) {
    return XdrUInt256Parts(
        XdrUint64(hiHi), XdrUint64(hiLo), XdrUint64(loHi), XdrUint64(loLo));
  }
}

class XdrContractExecutableType {
  final _value;
  const XdrContractExecutableType._internal(this._value);
  toString() => 'SCContractExecutableType.$_value';
  XdrContractExecutableType(this._value);
  get value => this._value;

  static const CONTRACT_EXECUTABLE_WASM =
      const XdrContractExecutableType._internal(0);
  static const CONTRACT_EXECUTABLE_TOKEN =
      const XdrContractExecutableType._internal(1);

  static XdrContractExecutableType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONTRACT_EXECUTABLE_WASM;
      case 1:
        return CONTRACT_EXECUTABLE_TOKEN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrContractExecutableType value) {
    stream.writeInt(value.value);
  }
}

class XdrContractExecutable {
  XdrContractExecutable(this._type);
  XdrContractExecutableType _type;
  XdrContractExecutableType get type => this._type;
  set type(XdrContractExecutableType value) => this._type = value;

  XdrHash? _wasmHash;
  XdrHash? get wasmHash => this._wasmHash;
  set wasmHash(XdrHash? value) => this._wasmHash = value;

  static void encode(
      XdrDataOutputStream stream, XdrContractExecutable encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        XdrHash.encode(stream, encoded.wasmHash!);
        break;
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_TOKEN:
        break;
    }
  }

  static XdrContractExecutable decode(XdrDataInputStream stream) {
    XdrContractExecutable decoded =
        XdrContractExecutable(XdrContractExecutableType.decode(stream));
    switch (decoded.type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        decoded.wasmHash = XdrHash.decode(stream);
        break;
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_TOKEN:
        break;
    }
    return decoded;
  }
}

class XdrSCContractInstance {
  XdrContractExecutable _executable;
  XdrContractExecutable get executable => this._executable;
  set executable(XdrContractExecutable value) => this._executable = value;

  List<XdrSCMapEntry>? _storage;
  List<XdrSCMapEntry>? get storage => this._storage;
  set storage(List<XdrSCMapEntry>? value) => this._storage = value;

  XdrSCContractInstance(this._executable, this._storage);

  static void encode(
      XdrDataOutputStream stream, XdrSCContractInstance encoded) {
    XdrContractExecutable.encode(stream, encoded.executable);
    if (encoded.storage == null) {
      stream.writeInt(0);
    } else {
      stream.writeInt(1);
      int mapSize = encoded.storage!.length;
      stream.writeInt(mapSize);
      for (int i = 0; i < mapSize; i++) {
        XdrSCMapEntry.encode(stream, encoded.storage![i]);
      }
    }
  }

  static XdrSCContractInstance decode(XdrDataInputStream stream) {
    XdrContractExecutable executable = XdrContractExecutable.decode(stream);
    List<XdrSCMapEntry>? storage;
    int mapPresent = stream.readInt();
    if (mapPresent != 0) {
      int mapSize = stream.readInt();
      storage = List<XdrSCMapEntry>.empty(growable: true);
      for (int i = 0; i < mapSize; i++) {
        storage.add(XdrSCMapEntry.decode(stream));
      }
    }
    return XdrSCContractInstance(executable, storage);
  }
}

class XdrSCVal {
  XdrSCVal(this._type);
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

  static void encode(XdrDataOutputStream stream, XdrSCVal encoded) {
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

  static XdrSCVal decode(XdrDataInputStream stream) {
    XdrSCVal decoded = XdrSCVal(XdrSCValType.decode(stream));
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

  static XdrSCVal forBool(bool value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_BOOL);
    val.b = value;
    return val;
  }

  static XdrSCVal forVoid() {
    return XdrSCVal(XdrSCValType.SCV_VOID);
  }

  static XdrSCVal forError(XdrSCError value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ERROR);
    val.error = value;
    return val;
  }

  static XdrSCVal forU32(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U32);
    val.u32 = XdrUint32(value);
    return val;
  }

  static XdrSCVal forI32(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I32);
    val.i32 = XdrInt32(value);
    return val;
  }

  static XdrSCVal forU64(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U64);
    val.u64 = XdrUint64(value);
    return val;
  }

  static XdrSCVal forI64(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I64);
    val.i64 = XdrInt64(value);
    return val;
  }

  static XdrSCVal forTimepoint(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_TIMEPOINT);
    val.timepoint = XdrUint64(value);
    return val;
  }

  static XdrSCVal forDuration(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_DURATION);
    val.duration = XdrUint64(value);
    return val;
  }

  static XdrSCVal forU128(XdrUInt128Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U128);
    val.u128 = value;
    return val;
  }

  static XdrSCVal forU128Parts(int hi, int lo) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U128);
    val.u128 = XdrUInt128Parts(XdrUint64(hi), XdrUint64(lo));
    return val;
  }

  static XdrSCVal forI128(XdrInt128Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I128);
    val.i128 = value;
    return val;
  }

  static XdrSCVal forI128Parts(int hi, int lo) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I128);
    val.i128 = XdrInt128Parts(XdrInt64(hi), XdrUint64(lo));
    return val;
  }

  static XdrSCVal forU256(XdrUInt256Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U256);
    val.u256 = value;
    return val;
  }

  static XdrSCVal forI256(XdrInt256Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I256);
    val.i256 = value;
    return val;
  }

  static XdrSCVal forBytes(Uint8List value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_BYTES);
    val.bytes = XdrDataValue(value);
    return val;
  }

  static XdrSCVal forString(String str) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_STRING);
    val.str = str;
    return val;
  }

  static XdrSCVal forSymbol(String symbol) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_SYMBOL);
    val.sym = symbol;
    return val;
  }

  static XdrSCVal forVec(List<XdrSCVal> value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_VEC);
    val.vec = value;
    return val;
  }

  static XdrSCVal forMap(List<XdrSCMapEntry> value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_MAP);
    val.map = value;
    return val;
  }

  static XdrSCVal forAddress(XdrSCAddress address) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ADDRESS);
    val.address = address;
    return val;
  }

  static XdrSCVal forAccountAddress(String accountId) {
    final address = Address.forAccountId(accountId);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ADDRESS);
    val.address = address.toXdr();
    return val;
  }

  static XdrSCVal forContractAddress(String contractId) {
    final address = Address.forContractId(contractId);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ADDRESS);
    val.address = address.toXdr();
    return val;
  }

  static XdrSCVal forNonceKey(XdrSCNonceKey nonceKey) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_LEDGER_KEY_NONCE);
    val.nonce_key = nonceKey;
    return val;
  }

  static XdrSCVal forContractInstance(XdrSCContractInstance instance) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_CONTRACT_INSTANCE);
    val.instance = instance;
    return val;
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSCVal.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrSCVal fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSCVal.decode(XdrDataInputStream(bytes));
  }
}

class XdrSCEnvMetaKind {
  final _value;
  const XdrSCEnvMetaKind._internal(this._value);
  toString() => 'SCEnvMetaKind.$_value';
  XdrSCEnvMetaKind(this._value);
  get value => this._value;

  static const SC_ENV_META_KIND_INTERFACE_VERSION =
      const XdrSCEnvMetaKind._internal(0);

  static XdrSCEnvMetaKind decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_ENV_META_KIND_INTERFACE_VERSION;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCEnvMetaKind value) {
    stream.writeInt(value.value);
  }
}

class XdrSCEnvMetaEntry {
  XdrSCEnvMetaEntry(this._kind);
  XdrSCEnvMetaKind _kind;
  XdrSCEnvMetaKind get discriminant => this._kind;
  set discriminant(XdrSCEnvMetaKind value) => this._kind = value;

  XdrUint64? _interfaceVersion;
  XdrUint64? get interfaceVersion => this._interfaceVersion;
  set interfaceVersion(XdrUint64? value) => this._interfaceVersion = value;

  static void encode(XdrDataOutputStream stream, XdrSCEnvMetaEntry encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION:
        XdrUint64.encode(stream, encoded.interfaceVersion!);
        break;
    }
  }

  static XdrSCEnvMetaEntry decode(XdrDataInputStream stream) {
    XdrSCEnvMetaEntry decoded =
        XdrSCEnvMetaEntry(XdrSCEnvMetaKind.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION:
        decoded.interfaceVersion = XdrUint64.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrSCSpecTypeOption {
  XdrSCSpecTypeDef _valueType;
  XdrSCSpecTypeDef get valueType => this._valueType;
  set valueType(XdrSCSpecTypeDef value) => this._valueType = value;

  XdrSCSpecTypeOption(this._valueType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeOption encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.valueType);
  }

  static XdrSCSpecTypeOption decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeOption(XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecTypeResult {
  XdrSCSpecTypeDef _okType;
  XdrSCSpecTypeDef get okType => this._okType;
  set okType(XdrSCSpecTypeDef value) => this._okType = value;

  XdrSCSpecTypeDef _errorType;
  XdrSCSpecTypeDef get errorType => this._errorType;
  set errorType(XdrSCSpecTypeDef value) => this._errorType = value;

  XdrSCSpecTypeResult(this._okType, this._errorType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeResult encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.okType);
    XdrSCSpecTypeDef.encode(stream, encoded.errorType);
  }

  static XdrSCSpecTypeResult decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeResult(
        XdrSCSpecTypeDef.decode(stream), XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecTypeVec {
  XdrSCSpecTypeDef _elementType;
  XdrSCSpecTypeDef get elementType => this._elementType;
  set elementType(XdrSCSpecTypeDef value) => this._elementType = value;

  XdrSCSpecTypeVec(this._elementType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeVec encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.elementType);
  }

  static XdrSCSpecTypeVec decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeVec(XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecTypeMap {
  XdrSCSpecTypeDef _keyType;
  XdrSCSpecTypeDef get keyType => this._keyType;
  set keyType(XdrSCSpecTypeDef value) => this._keyType = value;

  XdrSCSpecTypeDef _valueType;
  XdrSCSpecTypeDef get valueType => this._valueType;
  set valueType(XdrSCSpecTypeDef value) => this._valueType = value;

  XdrSCSpecTypeMap(this._keyType, this._valueType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeMap encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.keyType);
    XdrSCSpecTypeDef.encode(stream, encoded.valueType);
  }

  static XdrSCSpecTypeMap decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeMap(
        XdrSCSpecTypeDef.decode(stream), XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecTypeSet {
  XdrSCSpecTypeDef _elementType;
  XdrSCSpecTypeDef get elementType => this._elementType;
  set elementType(XdrSCSpecTypeDef value) => this._elementType = value;

  XdrSCSpecTypeSet(this._elementType);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeSet encoded) {
    XdrSCSpecTypeDef.encode(stream, encoded.elementType);
  }

  static XdrSCSpecTypeSet decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeSet(XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecTypeTuple {
  List<XdrSCSpecTypeDef> _valueTypes;
  List<XdrSCSpecTypeDef> get valueTypes => this._valueTypes;
  set valueTypes(List<XdrSCSpecTypeDef> value) => this._valueTypes = value;

  XdrSCSpecTypeTuple(this._valueTypes);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeTuple encoded) {
    int valueTypesSize = encoded.valueTypes.length;
    stream.writeInt(valueTypesSize);
    for (int i = 0; i < valueTypesSize; i++) {
      XdrSCSpecTypeDef.encode(stream, encoded.valueTypes[i]);
    }
  }

  static XdrSCSpecTypeTuple decode(XdrDataInputStream stream) {
    int valueTypesSize = stream.readInt();
    List<XdrSCSpecTypeDef> valTypes =
        List<XdrSCSpecTypeDef>.empty(growable: true);
    for (int i = 0; i < valueTypesSize; i++) {
      valTypes.add(XdrSCSpecTypeDef.decode(stream));
    }
    return XdrSCSpecTypeTuple(valTypes);
  }
}

class XdrSCSpecTypeBytesN {
  XdrUint32 _n;
  XdrUint32 get n => this._n;
  set n(XdrUint32 value) => this._n = value;

  XdrSCSpecTypeBytesN(this._n);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeBytesN encoded) {
    XdrUint32.encode(stream, encoded.n);
  }

  static XdrSCSpecTypeBytesN decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeBytesN(XdrUint32.decode(stream));
  }
}

class XdrSCSpecTypeUDT {
  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeUDT(this._name);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeUDT encoded) {
    stream.writeString(encoded.name);
  }

  static XdrSCSpecTypeUDT decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeUDT(stream.readString());
  }
}

class XdrSCSpecType {
  final _value;
  const XdrSCSpecType._internal(this._value);
  toString() => 'SCSpecType.$_value';
  XdrSCSpecType(this._value);
  get value => this._value;

  static const SC_SPEC_TYPE_VAL = const XdrSCSpecType._internal(0);

  // Types with no parameters.
  static const SC_SPEC_TYPE_BOOL = const XdrSCSpecType._internal(1);
  static const SC_SPEC_TYPE_VOID = const XdrSCSpecType._internal(2);
  static const SC_SPEC_TYPE_ERROR = const XdrSCSpecType._internal(3);
  static const SC_SPEC_TYPE_U32 = const XdrSCSpecType._internal(4);
  static const SC_SPEC_TYPE_I32 = const XdrSCSpecType._internal(5);
  static const SC_SPEC_TYPE_U64 = const XdrSCSpecType._internal(6);
  static const SC_SPEC_TYPE_I64 = const XdrSCSpecType._internal(7);
  static const SC_SPEC_TYPE_TIMEPOINT = const XdrSCSpecType._internal(8);
  static const SC_SPEC_TYPE_DURATION = const XdrSCSpecType._internal(9);
  static const SC_SPEC_TYPE_U128 = const XdrSCSpecType._internal(10);
  static const SC_SPEC_TYPE_I128 = const XdrSCSpecType._internal(11);
  static const SC_SPEC_TYPE_U256 = const XdrSCSpecType._internal(12);
  static const SC_SPEC_TYPE_I256 = const XdrSCSpecType._internal(13);
  static const SC_SPEC_TYPE_BYTES = const XdrSCSpecType._internal(14);
  static const SC_SPEC_TYPE_STRING = const XdrSCSpecType._internal(16);
  static const SC_SPEC_TYPE_SYMBOL = const XdrSCSpecType._internal(17);
  static const SC_SPEC_TYPE_ADDRESS = const XdrSCSpecType._internal(19);

  // Types with parameters.
  static const SC_SPEC_TYPE_OPTION = const XdrSCSpecType._internal(1000);
  static const SC_SPEC_TYPE_RESULT = const XdrSCSpecType._internal(1001);
  static const SC_SPEC_TYPE_VEC = const XdrSCSpecType._internal(1002);
  static const SC_SPEC_TYPE_SET = const XdrSCSpecType._internal(1003);
  static const SC_SPEC_TYPE_MAP = const XdrSCSpecType._internal(1004);
  static const SC_SPEC_TYPE_TUPLE = const XdrSCSpecType._internal(1005);
  static const SC_SPEC_TYPE_BYTES_N = const XdrSCSpecType._internal(1006);

  // User defined types.
  static const SC_SPEC_TYPE_UDT = const XdrSCSpecType._internal(2000);

  static XdrSCSpecType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_SPEC_TYPE_VAL;
      case 1:
        return SC_SPEC_TYPE_BOOL;
      case 2:
        return SC_SPEC_TYPE_VOID;
      case 3:
        return SC_SPEC_TYPE_ERROR;
      case 4:
        return SC_SPEC_TYPE_U32;
      case 5:
        return SC_SPEC_TYPE_I32;
      case 6:
        return SC_SPEC_TYPE_U64;
      case 7:
        return SC_SPEC_TYPE_I64;
      case 8:
        return SC_SPEC_TYPE_TIMEPOINT;
      case 9:
        return SC_SPEC_TYPE_DURATION;
      case 10:
        return SC_SPEC_TYPE_U128;
      case 11:
        return SC_SPEC_TYPE_I128;
      case 12:
        return SC_SPEC_TYPE_U256;
      case 13:
        return SC_SPEC_TYPE_I256;
      case 14:
        return SC_SPEC_TYPE_BYTES;
      case 16:
        return SC_SPEC_TYPE_STRING;
      case 17:
        return SC_SPEC_TYPE_SYMBOL;
      case 19:
        return SC_SPEC_TYPE_ADDRESS;
      case 1000:
        return SC_SPEC_TYPE_OPTION;
      case 1001:
        return SC_SPEC_TYPE_RESULT;
      case 1002:
        return SC_SPEC_TYPE_VEC;
      case 1003:
        return SC_SPEC_TYPE_SET;
      case 1004:
        return SC_SPEC_TYPE_MAP;
      case 1005:
        return SC_SPEC_TYPE_TUPLE;
      case 1006:
        return SC_SPEC_TYPE_BYTES_N;
      case 2000:
        return SC_SPEC_TYPE_UDT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCSpecType value) {
    stream.writeInt(value.value);
  }
}

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

  XdrSCSpecTypeSet? _set;
  XdrSCSpecTypeSet? get set => this._set;
  set set(XdrSCSpecTypeSet? value) => this._set = value;

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
      case XdrSCSpecType.SC_SPEC_TYPE_SET:
        XdrSCSpecTypeSet.encode(stream, encoded.set!);
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
      case XdrSCSpecType.SC_SPEC_TYPE_SET:
        decoded.set = XdrSCSpecTypeSet.decode(stream);
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

class XdrSCSpecUDTStructFieldV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeDef _type;
  XdrSCSpecTypeDef get type => this._type;
  set type(XdrSCSpecTypeDef value) => this._type = value;

  XdrSCSpecUDTStructFieldV0(this._doc, this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTStructFieldV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    XdrSCSpecTypeDef.encode(stream, encoded.type);
  }

  static XdrSCSpecUDTStructFieldV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecUDTStructFieldV0(
        doc, name, XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecUDTStructV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTStructFieldV0> _fields;
  List<XdrSCSpecUDTStructFieldV0> get fields => this._fields;
  set fields(List<XdrSCSpecUDTStructFieldV0> value) => this._fields = value;

  XdrSCSpecUDTStructV0(this._doc, this._lib, this._name, this._fields);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTStructV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);
    int casesSize = encoded.fields.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTStructFieldV0.encode(stream, encoded.fields[i]);
    }
  }

  static XdrSCSpecUDTStructV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();
    int fieldsSize = stream.readInt();
    List<XdrSCSpecUDTStructFieldV0> fields =
        List<XdrSCSpecUDTStructFieldV0>.empty(growable: true);
    for (int i = 0; i < fieldsSize; i++) {
      fields.add(XdrSCSpecUDTStructFieldV0.decode(stream));
    }

    return XdrSCSpecUDTStructV0(doc, lib, name, fields);
  }
}

class XdrSCSpecUDTUnionCaseVoidV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecUDTUnionCaseVoidV0(this._doc, this._name);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseVoidV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
  }

  static XdrSCSpecUDTUnionCaseVoidV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecUDTUnionCaseVoidV0(doc, name);
  }
}

class XdrSCSpecUDTUnionCaseTupleV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeDef? _type;
  XdrSCSpecTypeDef? get type => this._type;
  set type(XdrSCSpecTypeDef? value) => this._type = value;

  XdrSCSpecUDTUnionCaseTupleV0(this._doc, this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseTupleV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    if (encoded.type != null) {
      stream.writeInt(1);
      XdrSCSpecTypeDef.encode(stream, encoded.type!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrSCSpecUDTUnionCaseTupleV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    XdrSCSpecTypeDef? typ;
    int typePresent = stream.readInt();
    if (typePresent != 0) {
      typ = XdrSCSpecTypeDef.decode(stream);
    }
    return XdrSCSpecUDTUnionCaseTupleV0(doc, name, typ);
  }
}

class XdrSCSpecUDTUnionCaseV0Kind {
  final _value;
  const XdrSCSpecUDTUnionCaseV0Kind._internal(this._value);
  toString() => 'SCSpecUDTUnionCaseV0Kind.$_value';
  XdrSCSpecUDTUnionCaseV0Kind(this._value);
  get value => this._value;

  static const SC_SPEC_UDT_UNION_CASE_VOID_V0 =
      const XdrSCSpecUDTUnionCaseV0Kind._internal(0);
  static const SC_SPEC_UDT_UNION_CASE_TUPLE_V0 =
      const XdrSCSpecUDTUnionCaseV0Kind._internal(1);

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

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseV0Kind value) {
    stream.writeInt(value.value);
  }
}

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

class XdrSCSpecUDTUnionV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTUnionCaseV0> _cases;
  List<XdrSCSpecUDTUnionCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTUnionCaseV0> value) => this._cases = value;

  XdrSCSpecUDTUnionV0(this._doc, this._lib, this._name, this._cases);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTUnionV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTUnionCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTUnionV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTUnionCaseV0> cases =
        List<XdrSCSpecUDTUnionCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTUnionCaseV0.decode(stream));
    }

    return XdrSCSpecUDTUnionV0(doc, lib, name, cases);
  }
}

class XdrSCSpecUDTEnumCaseV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrUint32 _value;
  XdrUint32 get value => this._value;
  set value(XdrUint32 value) => this._value = value;

  XdrSCSpecUDTEnumCaseV0(this._doc, this._name, this._value);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTEnumCaseV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    XdrUint32.encode(stream, encoded.value);
  }

  static XdrSCSpecUDTEnumCaseV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecUDTEnumCaseV0(doc, name, XdrUint32.decode(stream));
  }
}

class XdrSCSpecUDTEnumV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTEnumCaseV0> _cases;
  List<XdrSCSpecUDTEnumCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTEnumCaseV0> value) => this._cases = value;

  XdrSCSpecUDTEnumV0(this._doc, this._lib, this._name, this._cases);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTEnumV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTEnumCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTEnumV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTEnumCaseV0> cases =
        List<XdrSCSpecUDTEnumCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTEnumCaseV0.decode(stream));
    }

    return XdrSCSpecUDTEnumV0(doc, lib, name, cases);
  }
}

class XdrSCSpecUDTErrorEnumCaseV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrUint32 _value;
  XdrUint32 get value => this._value;
  set value(XdrUint32 value) => this._value = value;

  XdrSCSpecUDTErrorEnumCaseV0(this._doc, this._name, this._value);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTErrorEnumCaseV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    XdrUint32.encode(stream, encoded.value);
  }

  static XdrSCSpecUDTErrorEnumCaseV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecUDTErrorEnumCaseV0(doc, name, XdrUint32.decode(stream));
  }
}

class XdrSCSpecUDTErrorEnumV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecUDTErrorEnumCaseV0> _cases;
  List<XdrSCSpecUDTErrorEnumCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTErrorEnumCaseV0> value) => this._cases = value;

  XdrSCSpecUDTErrorEnumV0(this._doc, this._lib, this._name, this._cases);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTErrorEnumV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTErrorEnumCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTErrorEnumV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String lib = stream.readString();
    String name = stream.readString();

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTErrorEnumCaseV0> cases =
        List<XdrSCSpecUDTErrorEnumCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTErrorEnumCaseV0.decode(stream));
    }

    return XdrSCSpecUDTErrorEnumV0(doc, lib, name, cases);
  }
}

class XdrSCSpecFunctionInputV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeDef _type;
  XdrSCSpecTypeDef get type => this._type;
  set type(XdrSCSpecTypeDef value) => this._type = value;

  XdrSCSpecFunctionInputV0(this._doc, this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecFunctionInputV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    XdrSCSpecTypeDef.encode(stream, encoded.type);
  }

  static XdrSCSpecFunctionInputV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();
    return XdrSCSpecFunctionInputV0(doc, name, XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecFunctionV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name; // symbol
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecFunctionInputV0> _inputs;
  List<XdrSCSpecFunctionInputV0> get inputs => this._inputs;
  set inputs(List<XdrSCSpecFunctionInputV0> value) => this._inputs = value;

  List<XdrSCSpecTypeDef> _outputs;
  List<XdrSCSpecTypeDef> get outputs => this._outputs;
  set outputs(List<XdrSCSpecTypeDef> value) => this._outputs = value;

  XdrSCSpecFunctionV0(this._doc, this._name, this._inputs, this._outputs);

  static void encode(XdrDataOutputStream stream, XdrSCSpecFunctionV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);

    int inputsSize = encoded.inputs.length;
    stream.writeInt(inputsSize);
    for (int i = 0; i < inputsSize; i++) {
      XdrSCSpecFunctionInputV0.encode(stream, encoded.inputs[i]);
    }

    int outputsSize = encoded.outputs.length;
    stream.writeInt(outputsSize);
    for (int i = 0; i < outputsSize; i++) {
      XdrSCSpecTypeDef.encode(stream, encoded.outputs[i]);
    }
  }

  static XdrSCSpecFunctionV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();

    int inputsSize = stream.readInt();
    List<XdrSCSpecFunctionInputV0> inputs =
        List<XdrSCSpecFunctionInputV0>.empty(growable: true);
    for (int i = 0; i < inputsSize; i++) {
      inputs.add(XdrSCSpecFunctionInputV0.decode(stream));
    }

    int outputsSize = stream.readInt();
    List<XdrSCSpecTypeDef> outputs =
        List<XdrSCSpecTypeDef>.empty(growable: true);
    for (int i = 0; i < outputsSize; i++) {
      outputs.add(XdrSCSpecTypeDef.decode(stream));
    }
    return XdrSCSpecFunctionV0(doc, name, inputs, outputs);
  }
}

class XdrSCSpecEntryKind {
  final _value;
  const XdrSCSpecEntryKind._internal(this._value);
  toString() => 'SCSpecEntryKind.$_value';
  XdrSCSpecEntryKind(this._value);
  get value => this._value;

  static const SC_SPEC_ENTRY_FUNCTION_V0 =
      const XdrSCSpecEntryKind._internal(0);
  static const SC_SPEC_ENTRY_UDT_STRUCT_V0 =
      const XdrSCSpecEntryKind._internal(1);
  static const SC_SPEC_ENTRY_UDT_UNION_V0 =
      const XdrSCSpecEntryKind._internal(2);
  static const SC_SPEC_ENTRY_UDT_ENUM_V0 =
      const XdrSCSpecEntryKind._internal(3);
  static const SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 =
      const XdrSCSpecEntryKind._internal(4);

  static XdrSCSpecEntryKind decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_SPEC_ENTRY_FUNCTION_V0;
      case 1:
        return SC_SPEC_ENTRY_UDT_STRUCT_V0;
      case 2:
        return SC_SPEC_ENTRY_UDT_UNION_V0;
      case 3:
        return SC_SPEC_ENTRY_UDT_ENUM_V0;
      case 4:
        return SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCSpecEntryKind value) {
    stream.writeInt(value.value);
  }
}

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
    }
    return decoded;
  }
}

// Soroban support

class XdrHostFunctionType {
  final _value;
  const XdrHostFunctionType._internal(this._value);
  toString() => 'HostFunctionType.$_value';
  XdrHostFunctionType(this._value);
  get value => this._value;

  static const HOST_FUNCTION_TYPE_INVOKE_CONTRACT =
      const XdrHostFunctionType._internal(0);
  static const HOST_FUNCTION_TYPE_CREATE_CONTRACT =
      const XdrHostFunctionType._internal(1);
  static const HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM =
      const XdrHostFunctionType._internal(2);

  static XdrHostFunctionType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_FUNCTION_TYPE_INVOKE_CONTRACT;
      case 1:
        return HOST_FUNCTION_TYPE_CREATE_CONTRACT;
      case 2:
        return HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrHostFunctionType value) {
    stream.writeInt(value.value);
  }
}

class XdrContractIDPreimageType {
  final _value;
  const XdrContractIDPreimageType._internal(this._value);
  toString() => 'ContractIDPreimageType.$_value';
  XdrContractIDPreimageType(this._value);
  get value => this._value;

  static const CONTRACT_ID_PREIMAGE_FROM_ADDRESS =
      const XdrContractIDPreimageType._internal(0);
  static const CONTRACT_ID_PREIMAGE_FROM_ASSET =
      const XdrContractIDPreimageType._internal(1);

  static XdrContractIDPreimageType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONTRACT_ID_PREIMAGE_FROM_ADDRESS;
      case 1:
        return CONTRACT_ID_PREIMAGE_FROM_ASSET;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrContractIDPreimageType value) {
    stream.writeInt(value.value);
  }
}

class XdrContractIDPreimage {
  XdrContractIDPreimage(this._type);
  XdrContractIDPreimageType _type;
  XdrContractIDPreimageType get type => this._type;
  set type(XdrContractIDPreimageType value) => this._type = value;

  XdrUint256? _salt;
  XdrUint256? get salt => this._salt;
  set salt(XdrUint256? value) => this._salt = value;

  XdrSCAddress? _address;
  XdrSCAddress? get address => this._address;
  set address(XdrSCAddress? value) => this._address = value;

  XdrAsset? _fromAsset;
  XdrAsset? get fromAsset => this._fromAsset;
  set fromAsset(XdrAsset? value) => this._fromAsset = value;

  static void encode(
      XdrDataOutputStream stream, XdrContractIDPreimage encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS:
        XdrSCAddress.encode(stream, encoded.address!);
        XdrUint256.encode(stream, encoded.salt!);
        break;
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET:
        XdrAsset.encode(stream, encoded.fromAsset!);
        break;
    }
  }

  static XdrContractIDPreimage decode(XdrDataInputStream stream) {
    XdrContractIDPreimage decoded =
        XdrContractIDPreimage(XdrContractIDPreimageType.decode(stream));
    switch (decoded.type) {
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS:
        decoded.address = XdrSCAddress.decode(stream);
        decoded.salt = XdrUint256.decode(stream);
        break;
      case XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET:
        decoded.fromAsset = XdrAsset.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrCreateContractArgs {
  XdrContractIDPreimage _contractIDPreimage;
  XdrContractIDPreimage get contractIDPreimage => this._contractIDPreimage;
  set contractIDPreimage(XdrContractIDPreimage value) =>
      this._contractIDPreimage = value;

  XdrContractExecutable _executable;
  XdrContractExecutable get executable => this._executable;
  set executable(XdrContractExecutable value) => this._executable = value;

  XdrCreateContractArgs(this._contractIDPreimage, this._executable);

  static void encode(
      XdrDataOutputStream stream, XdrCreateContractArgs encoded) {
    XdrContractIDPreimage.encode(stream, encoded.contractIDPreimage);
    XdrContractExecutable.encode(stream, encoded.executable);
  }

  static XdrCreateContractArgs decode(XdrDataInputStream stream) {
    return XdrCreateContractArgs(XdrContractIDPreimage.decode(stream),
        XdrContractExecutable.decode(stream));
  }
}

class XdrHostFunction {
  XdrHostFunctionType _type;
  XdrHostFunctionType get type => this._type;
  set type(XdrHostFunctionType value) => this._type = value;

  List<XdrSCVal>? _invokeContract; // SCVec
  List<XdrSCVal>? get invokeContract => this._invokeContract;
  set invokeContract(List<XdrSCVal>? value) => this._invokeContract = value;

  XdrCreateContractArgs? _createContract;
  XdrCreateContractArgs? get createContract => this._createContract;
  set createContract(XdrCreateContractArgs? value) =>
      this._createContract = value;

  XdrDataValue? _wasm;
  XdrDataValue? get wasm => this._wasm;
  set wasm(XdrDataValue? value) => this._wasm = value;

  XdrHostFunction(this._type);

  static void encode(XdrDataOutputStream stream, XdrHostFunction encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        int vecSize = encoded.invokeContract!.length;
        stream.writeInt(vecSize);
        for (int i = 0; i < vecSize; i++) {
          XdrSCVal.encode(stream, encoded.invokeContract![i]);
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        XdrCreateContractArgs.encode(stream, encoded.createContract!);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        XdrDataValue.encode(stream, encoded.wasm!);
        break;
    }
  }

  static XdrHostFunction decode(XdrDataInputStream stream) {
    XdrHostFunction decoded =
        XdrHostFunction(XdrHostFunctionType.decode(stream));
    switch (decoded.type) {
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        int vecSize = stream.readInt();
        decoded.invokeContract = List<XdrSCVal>.empty(growable: true);
        for (int i = 0; i < vecSize; i++) {
          decoded.invokeContract!.add(XdrSCVal.decode(stream));
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        decoded.createContract = XdrCreateContractArgs.decode(stream);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        decoded.wasm = XdrDataValue.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrHostFunction forUploadContractWasm(Uint8List contractCode) {
    XdrHostFunction result = XdrHostFunction(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM);
    result.wasm = XdrDataValue(contractCode);
    return result;
  }

  static XdrHostFunction forCreatingContract(
      XdrSCAddress address, XdrUint256 salt, String wasmId) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractIDPreimage cId = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    cId.address = address;
    cId.salt = salt;
    XdrContractExecutable cCode = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
    cCode.wasmHash = XdrHash(Util.hexToBytes(wasmId));
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forDeploySACWithSourceAccount(
      XdrSCAddress address, XdrUint256 salt) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractIDPreimage cId = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    cId.address = address;
    cId.salt = salt;
    XdrContractExecutable cCode = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_TOKEN);
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forDeploySACWithAsset(XdrAsset fromAsset) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractIDPreimage cId = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
    cId.fromAsset = fromAsset;
    XdrContractExecutable cCode = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_TOKEN);
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forInvokingContractWithArgs(List<XdrSCVal> args) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
    result.invokeContract = args;
    return result;
  }
}

class XdrInvokeHostFunctionResultCode {
  final _value;
  const XdrInvokeHostFunctionResultCode._internal(this._value);
  toString() => 'InvokeHostFunctionResultCode.$_value';
  XdrInvokeHostFunctionResultCode(this._value);
  get value => this._value;

  /// Success
  static const INVOKE_HOST_FUNCTION_SUCCESS =
      const XdrInvokeHostFunctionResultCode._internal(0);

  /// Invalid
  static const INVOKE_HOST_FUNCTION_MALFORMED =
      const XdrInvokeHostFunctionResultCode._internal(-1);

  /// Trapped
  static const INVOKE_HOST_FUNCTION_TRAPPED =
      const XdrInvokeHostFunctionResultCode._internal(-2);

  static const INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED =
      const XdrInvokeHostFunctionResultCode._internal(-3);

  static XdrInvokeHostFunctionResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return INVOKE_HOST_FUNCTION_SUCCESS;
      case -1:
        return INVOKE_HOST_FUNCTION_MALFORMED;
      case -2:
        return INVOKE_HOST_FUNCTION_TRAPPED;
      case -3:
        return INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrInvokeHostFunctionResult {
  XdrInvokeHostFunctionResultCode _code;
  XdrInvokeHostFunctionResultCode get discriminant => this._code;
  set discriminant(XdrInvokeHostFunctionResultCode value) => this._code = value;

  XdrHash? _success; // sha256(XdrInvokeHostFunctionSuccessPreImage)
  XdrHash? get success => this._success;
  set success(XdrHash? value) => this._success = value;

  XdrInvokeHostFunctionResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        XdrHash.encode(stream, encoded.success!);
        break;
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED:
      case XdrInvokeHostFunctionResultCode
          .INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED:
        break;
      default:
        break;
    }
  }

  static XdrInvokeHostFunctionResult decode(XdrDataInputStream stream) {
    XdrInvokeHostFunctionResult decoded = XdrInvokeHostFunctionResult(
        XdrInvokeHostFunctionResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        decoded.success = XdrHash.decode(stream);
        break;
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED:
      case XdrInvokeHostFunctionResultCode
          .INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrBumpFootprintExpirationResultCode {
  final _value;
  const XdrBumpFootprintExpirationResultCode._internal(this._value);
  toString() => 'BumpFootprintExpirationResultCode.$_value';
  XdrBumpFootprintExpirationResultCode(this._value);
  get value => this._value;

  /// Success
  static const BUMP_FOOTPRINT_EXPIRATION_SUCCESS =
      const XdrBumpFootprintExpirationResultCode._internal(0);

  // codes considered as "failure" for the operation
  static const BUMP_FOOTPRINT_EXPIRATION_MALFORMED =
      const XdrBumpFootprintExpirationResultCode._internal(-1);
  static const BUMP_FOOTPRINT_EXPIRATION_RESOURCE_LIMIT_EXCEEDED =
      const XdrBumpFootprintExpirationResultCode._internal(-2);

  static XdrBumpFootprintExpirationResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return BUMP_FOOTPRINT_EXPIRATION_SUCCESS;
      case -1:
        return BUMP_FOOTPRINT_EXPIRATION_MALFORMED;
      case -2:
        return BUMP_FOOTPRINT_EXPIRATION_RESOURCE_LIMIT_EXCEEDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrBumpFootprintExpirationResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrBumpFootprintExpirationResult {
  XdrBumpFootprintExpirationResultCode _code;
  XdrBumpFootprintExpirationResultCode get discriminant => this._code;
  set discriminant(XdrBumpFootprintExpirationResultCode value) =>
      this._code = value;

  XdrBumpFootprintExpirationResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrBumpFootprintExpirationResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrBumpFootprintExpirationResultCode
          .BUMP_FOOTPRINT_EXPIRATION_SUCCESS:
      case XdrBumpFootprintExpirationResultCode
          .BUMP_FOOTPRINT_EXPIRATION_MALFORMED:
      case XdrBumpFootprintExpirationResultCode
          .BUMP_FOOTPRINT_EXPIRATION_RESOURCE_LIMIT_EXCEEDED:
        break;
      default:
        break;
    }
  }

  static XdrBumpFootprintExpirationResult decode(XdrDataInputStream stream) {
    XdrBumpFootprintExpirationResult decoded = XdrBumpFootprintExpirationResult(
        XdrBumpFootprintExpirationResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrBumpFootprintExpirationResultCode
          .BUMP_FOOTPRINT_EXPIRATION_SUCCESS:
      case XdrBumpFootprintExpirationResultCode
          .BUMP_FOOTPRINT_EXPIRATION_MALFORMED:
      case XdrBumpFootprintExpirationResultCode
          .BUMP_FOOTPRINT_EXPIRATION_RESOURCE_LIMIT_EXCEEDED:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrRestoreFootprintResultCode {
  final _value;
  const XdrRestoreFootprintResultCode._internal(this._value);
  toString() => 'RestoreFootprintResultCode.$_value';
  XdrRestoreFootprintResultCode(this._value);
  get value => this._value;

  /// Success
  static const RESTORE_FOOTPRINT_SUCCESS =
      const XdrRestoreFootprintResultCode._internal(0);

  // codes considered as "failure" for the operation
  static const RESTORE_FOOTPRINT_MALFORMED =
      const XdrRestoreFootprintResultCode._internal(-1);
  static const RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED =
      const XdrRestoreFootprintResultCode._internal(-2);

  static XdrRestoreFootprintResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return RESTORE_FOOTPRINT_SUCCESS;
      case -1:
        return RESTORE_FOOTPRINT_MALFORMED;
      case -2:
        return RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrRestoreFootprintResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrRestoreFootprintResult {
  XdrRestoreFootprintResultCode _code;
  XdrRestoreFootprintResultCode get discriminant => this._code;
  set discriminant(XdrRestoreFootprintResultCode value) => this._code = value;

  XdrRestoreFootprintResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrRestoreFootprintResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS:
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED:
      case XdrRestoreFootprintResultCode
          .RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED:
        break;
      default:
        break;
    }
  }

  static XdrRestoreFootprintResult decode(XdrDataInputStream stream) {
    XdrRestoreFootprintResult decoded =
        XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS:
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED:
      case XdrRestoreFootprintResultCode
          .RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrLedgerFootprint {
  List<XdrLedgerKey> _readOnly;
  List<XdrLedgerKey> get readOnly => this._readOnly;
  set readOnly(List<XdrLedgerKey> value) => this._readOnly = value;

  List<XdrLedgerKey> _readWrite;
  List<XdrLedgerKey> get readWrite => this._readWrite;
  set readWrite(List<XdrLedgerKey> value) => this._readWrite = value;

  XdrLedgerFootprint(this._readOnly, this._readWrite);

  static void encode(XdrDataOutputStream stream, XdrLedgerFootprint encoded) {
    int readOnlySize = encoded.readOnly.length;
    stream.writeInt(readOnlySize);
    for (int i = 0; i < readOnlySize; i++) {
      XdrLedgerKey.encode(stream, encoded.readOnly[i]);
    }

    int readWriteSize = encoded.readWrite.length;
    stream.writeInt(readWriteSize);
    for (int i = 0; i < readWriteSize; i++) {
      XdrLedgerKey.encode(stream, encoded.readWrite[i]);
    }
  }

  static XdrLedgerFootprint decode(XdrDataInputStream stream) {
    int readOnlySize = stream.readInt();
    List<XdrLedgerKey> readOnly = List<XdrLedgerKey>.empty(growable: true);
    for (int i = 0; i < readOnlySize; i++) {
      readOnly.add(XdrLedgerKey.decode(stream));
    }

    int readWriteSize = stream.readInt();
    List<XdrLedgerKey> readWrite = List<XdrLedgerKey>.empty(growable: true);
    for (int i = 0; i < readWriteSize; i++) {
      readWrite.add(XdrLedgerKey.decode(stream));
    }

    return XdrLedgerFootprint(readOnly, readWrite);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerFootprint.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerFootprint fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerFootprint.decode(XdrDataInputStream(bytes));
  }
}

class XdrInvokeHostFunctionOp {
  XdrHostFunction _function;
  XdrHostFunction get function => this._function;
  set function(XdrHostFunction value) => this._function = value;

  List<XdrSorobanAuthorizationEntry> _auth;
  List<XdrSorobanAuthorizationEntry> get auth => this._auth;
  set auth(List<XdrSorobanAuthorizationEntry> value) => this._auth = value;

  XdrInvokeHostFunctionOp(this._function, this._auth);

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionOp encoded) {
    XdrHostFunction.encode(stream, encoded.function);
    int authSize = encoded.auth.length;
    stream.writeInt(authSize);
    for (int i = 0; i < authSize; i++) {
      XdrSorobanAuthorizationEntry.encode(stream, encoded.auth[i]);
    }
  }

  static XdrInvokeHostFunctionOp decode(XdrDataInputStream stream) {
    XdrHostFunction function = XdrHostFunction.decode(stream);
    int authSize = stream.readInt();
    List<XdrSorobanAuthorizationEntry> auth =
        List<XdrSorobanAuthorizationEntry>.empty(growable: true);
    for (int i = 0; i < authSize; i++) {
      auth.add(XdrSorobanAuthorizationEntry.decode(stream));
    }
    return XdrInvokeHostFunctionOp(function, auth);
  }
}

class XdrBumpFootprintExpirationOp {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrUint32 _ledgersToExpire;
  XdrUint32 get ledgersToExpire => this._ledgersToExpire;
  set ledgersToExpire(XdrUint32 value) => this._ledgersToExpire = value;

  XdrBumpFootprintExpirationOp(this._ext, this._ledgersToExpire);

  static void encode(
      XdrDataOutputStream stream, XdrBumpFootprintExpirationOp encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrUint32.encode(stream, encoded.ledgersToExpire);
  }

  static XdrBumpFootprintExpirationOp decode(XdrDataInputStream stream) {
    return XdrBumpFootprintExpirationOp(
        XdrExtensionPoint.decode(stream), XdrUint32.decode(stream));
  }
}

class XdrRestoreFootprintOp {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrRestoreFootprintOp(this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrRestoreFootprintOp encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
  }

  static XdrRestoreFootprintOp decode(XdrDataInputStream stream) {
    return XdrRestoreFootprintOp(XdrExtensionPoint.decode(stream));
  }
}
