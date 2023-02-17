// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_entry.dart';
import 'xdr_type.dart';
import 'xdr_account.dart';
import 'xdr_data_io.dart';
import 'xdr_asset.dart';
import 'xdr_signing.dart';
import 'xdr_ledger.dart';

class XdrSCValType {
  final _value;
  const XdrSCValType._internal(this._value);
  toString() => 'SCValType.$_value';
  XdrSCValType(this._value);
  get value => this._value;

  static const SCV_U63 = const XdrSCValType._internal(0);
  static const SCV_U32 = const XdrSCValType._internal(1);
  static const SCV_I32 = const XdrSCValType._internal(2);
  static const SCV_STATIC = const XdrSCValType._internal(3);
  static const SCV_OBJECT = const XdrSCValType._internal(4);
  static const SCV_SYMBOL = const XdrSCValType._internal(5);
  static const SCV_BITSET = const XdrSCValType._internal(6);
  static const SCV_STATUS = const XdrSCValType._internal(7);

  static XdrSCValType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCV_U63;
      case 1:
        return SCV_U32;
      case 2:
        return SCV_I32;
      case 3:
        return SCV_STATIC;
      case 4:
        return SCV_OBJECT;
      case 5:
        return SCV_SYMBOL;
      case 6:
        return SCV_BITSET;
      case 7:
        return SCV_STATUS;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCValType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCStatic {
  final _value;
  const XdrSCStatic._internal(this._value);
  toString() => 'SCStatic.$_value';
  XdrSCStatic(this._value);
  get value => this._value;

  static const SCS_VOID = const XdrSCStatic._internal(0);
  static const SCS_TRUE = const XdrSCStatic._internal(1);
  static const SCS_FALSE = const XdrSCStatic._internal(2);
  static const SCS_LEDGER_KEY_CONTRACT_CODE = const XdrSCStatic._internal(3);

  static XdrSCStatic decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCS_VOID;
      case 1:
        return SCS_TRUE;
      case 2:
        return SCS_FALSE;
      case 3:
        return SCS_LEDGER_KEY_CONTRACT_CODE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCStatic value) {
    stream.writeInt(value.value);
  }
}

class XdrSCStatusType {
  final _value;
  const XdrSCStatusType._internal(this._value);
  toString() => 'SCStatusType.$_value';
  XdrSCStatusType(this._value);
  get value => this._value;

  static const SST_OK = const XdrSCStatusType._internal(0);
  static const SST_UNKNOWN_ERROR = const XdrSCStatusType._internal(1);
  static const SST_HOST_VALUE_ERROR = const XdrSCStatusType._internal(2);
  static const SST_HOST_OBJECT_ERROR = const XdrSCStatusType._internal(3);
  static const SST_HOST_FUNCTION_ERROR = const XdrSCStatusType._internal(4);
  static const SST_HOST_STORAGE_ERROR = const XdrSCStatusType._internal(5);
  static const SST_HOST_CONTEXT_ERROR = const XdrSCStatusType._internal(6);
  static const SST_VM_ERROR = const XdrSCStatusType._internal(7);
  static const SST_CONTRACT_ERROR = const XdrSCStatusType._internal(8);
  static const SST_HOST_AUTH_ERROR = const XdrSCStatusType._internal(9);

  static XdrSCStatusType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SST_OK;
      case 1:
        return SST_UNKNOWN_ERROR;
      case 2:
        return SST_HOST_VALUE_ERROR;
      case 3:
        return SST_HOST_OBJECT_ERROR;
      case 4:
        return SST_HOST_FUNCTION_ERROR;
      case 5:
        return SST_HOST_STORAGE_ERROR;
      case 6:
        return SST_HOST_CONTEXT_ERROR;
      case 7:
        return SST_VM_ERROR;
      case 8:
        return SST_CONTRACT_ERROR;
      case 9:
        return SST_HOST_AUTH_ERROR;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCStatusType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCHostAuthErrorCode {
  final _value;
  const XdrSCHostAuthErrorCode._internal(this._value);
  toString() => 'SCHostAuthErrorCode.$_value';
  XdrSCHostAuthErrorCode(this._value);
  get value => this._value;

  static const HOST_AUTH_UNKNOWN_ERROR =
  const XdrSCHostAuthErrorCode._internal(0);
  static const HOST_AUTH_NONCE_ERROR =
  const XdrSCHostAuthErrorCode._internal(1);
  static const HOST_AUTH_DUPLICATE_AUTHORIZATION =
  const XdrSCHostAuthErrorCode._internal(2);
  static const HOST_AUTH_NOT_AUTHORIZED =
  const XdrSCHostAuthErrorCode._internal(3);

  static XdrSCHostAuthErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_AUTH_UNKNOWN_ERROR;
      case 1:
        return HOST_AUTH_NONCE_ERROR;
      case 2:
        return HOST_AUTH_DUPLICATE_AUTHORIZATION;
      case 3:
        return HOST_AUTH_NOT_AUTHORIZED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCHostAuthErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCHostValErrorCode {
  final _value;
  const XdrSCHostValErrorCode._internal(this._value);
  toString() => 'SCHostValErrorCode.$_value';
  XdrSCHostValErrorCode(this._value);
  get value => this._value;

  static const HOST_VALUE_UNKNOWN_ERROR =
      const XdrSCHostValErrorCode._internal(0);
  static const HOST_VALUE_RESERVED_TAG_VALUE =
      const XdrSCHostValErrorCode._internal(1);
  static const HOST_VALUE_UNEXPECTED_VAL_TYPE =
      const XdrSCHostValErrorCode._internal(2);
  static const HOST_VALUE_U63_OUT_OF_RANGE =
      const XdrSCHostValErrorCode._internal(3);
  static const HOST_VALUE_U32_OUT_OF_RANGE =
      const XdrSCHostValErrorCode._internal(4);
  static const HOST_VALUE_STATIC_UNKNOWN =
      const XdrSCHostValErrorCode._internal(5);
  static const HOST_VALUE_MISSING_OBJECT =
      const XdrSCHostValErrorCode._internal(6);
  static const HOST_VALUE_SYMBOL_TOO_LONG =
      const XdrSCHostValErrorCode._internal(7);
  static const HOST_VALUE_SYMBOL_BAD_CHAR =
      const XdrSCHostValErrorCode._internal(8);
  static const HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8 =
      const XdrSCHostValErrorCode._internal(9);
  static const HOST_VALUE_BITSET_TOO_MANY_BITS =
      const XdrSCHostValErrorCode._internal(10);
  static const HOST_VALUE_STATUS_UNKNOWN =
      const XdrSCHostValErrorCode._internal(11);

  static XdrSCHostValErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_VALUE_UNKNOWN_ERROR;
      case 1:
        return HOST_VALUE_RESERVED_TAG_VALUE;
      case 2:
        return HOST_VALUE_UNEXPECTED_VAL_TYPE;
      case 3:
        return HOST_VALUE_U63_OUT_OF_RANGE;
      case 4:
        return HOST_VALUE_U32_OUT_OF_RANGE;
      case 5:
        return HOST_VALUE_STATIC_UNKNOWN;
      case 6:
        return HOST_VALUE_MISSING_OBJECT;
      case 7:
        return HOST_VALUE_SYMBOL_TOO_LONG;
      case 8:
        return HOST_VALUE_SYMBOL_BAD_CHAR;
      case 9:
        return HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8;
      case 10:
        return HOST_VALUE_BITSET_TOO_MANY_BITS;
      case 11:
        return HOST_VALUE_STATUS_UNKNOWN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCHostValErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCHostObjErrorCode {
  final _value;
  const XdrSCHostObjErrorCode._internal(this._value);
  toString() => 'SCHostObjErrorCode.$_value';
  XdrSCHostObjErrorCode(this._value);
  get value => this._value;

  static const HOST_OBJECT_UNKNOWN_ERROR =
      const XdrSCHostObjErrorCode._internal(0);
  static const HOST_OBJECT_UNKNOWN_REFERENCE =
      const XdrSCHostObjErrorCode._internal(1);
  static const HOST_OBJECT_UNEXPECTED_TYPE =
      const XdrSCHostObjErrorCode._internal(2);
  static const HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX =
      const XdrSCHostObjErrorCode._internal(3);
  static const HOST_OBJECT_OBJECT_NOT_EXIST =
      const XdrSCHostObjErrorCode._internal(4);
  static const HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND =
      const XdrSCHostObjErrorCode._internal(5);
  static const HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH =
      const XdrSCHostObjErrorCode._internal(6);

  static XdrSCHostObjErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_OBJECT_UNKNOWN_ERROR;
      case 1:
        return HOST_OBJECT_UNKNOWN_REFERENCE;
      case 2:
        return HOST_OBJECT_UNEXPECTED_TYPE;
      case 3:
        return HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX;
      case 4:
        return HOST_OBJECT_OBJECT_NOT_EXIST;
      case 5:
        return HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND;
      case 6:
        return HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCHostObjErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCHostFnErrorCode {
  final _value;
  const XdrSCHostFnErrorCode._internal(this._value);
  toString() => 'SCHostFnErrorCode.$_value';
  XdrSCHostFnErrorCode(this._value);
  get value => this._value;

  static const HOST_FN_UNKNOWN_ERROR = const XdrSCHostFnErrorCode._internal(0);
  static const HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION =
      const XdrSCHostFnErrorCode._internal(1);
  static const HOST_FN_INPUT_ARGS_WRONG_LENGTH =
      const XdrSCHostFnErrorCode._internal(2);
  static const HOST_FN_INPUT_ARGS_WRONG_TYPE =
      const XdrSCHostFnErrorCode._internal(3);
  static const HOST_FN_INPUT_ARGS_INVALID =
      const XdrSCHostFnErrorCode._internal(4);

  static XdrSCHostFnErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_FN_UNKNOWN_ERROR;
      case 1:
        return HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION;
      case 2:
        return HOST_FN_INPUT_ARGS_WRONG_LENGTH;
      case 3:
        return HOST_FN_INPUT_ARGS_WRONG_TYPE;
      case 4:
        return HOST_FN_INPUT_ARGS_INVALID;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCHostFnErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCHostStorageErrorCode {
  final _value;
  const XdrSCHostStorageErrorCode._internal(this._value);
  toString() => 'SCHostStorageErrorCode.$_value';
  XdrSCHostStorageErrorCode(this._value);
  get value => this._value;

  static const HOST_STORAGE_UNKNOWN_ERROR =
      const XdrSCHostStorageErrorCode._internal(0);
  static const HOST_STORAGE_EXPECT_CONTRACT_DATA =
      const XdrSCHostStorageErrorCode._internal(1);
  static const HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY =
      const XdrSCHostStorageErrorCode._internal(2);
  static const HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY =
      const XdrSCHostStorageErrorCode._internal(3);
  static const HOST_STORAGE_MISSING_KEY_IN_GET =
      const XdrSCHostStorageErrorCode._internal(4);
  static const HOST_STORAGE_GET_ON_DELETED_KEY =
      const XdrSCHostStorageErrorCode._internal(5);

  static XdrSCHostStorageErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_STORAGE_UNKNOWN_ERROR;
      case 1:
        return HOST_STORAGE_EXPECT_CONTRACT_DATA;
      case 2:
        return HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY;
      case 3:
        return HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY;
      case 4:
        return HOST_STORAGE_MISSING_KEY_IN_GET;
      case 5:
        return HOST_STORAGE_GET_ON_DELETED_KEY;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSCHostStorageErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCHostContextErrorCode {
  final _value;
  const XdrSCHostContextErrorCode._internal(this._value);
  toString() => 'SCHostContextErrorCode.$_value';
  XdrSCHostContextErrorCode(this._value);
  get value => this._value;

  static const HOST_CONTEXT_UNKNOWN_ERROR =
      const XdrSCHostContextErrorCode._internal(0);
  static const HOST_CONTEXT_NO_CONTRACT_RUNNING =
      const XdrSCHostContextErrorCode._internal(1);

  static XdrSCHostContextErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_CONTEXT_UNKNOWN_ERROR;
      case 1:
        return HOST_CONTEXT_NO_CONTRACT_RUNNING;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSCHostContextErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCVmErrorCode {
  final _value;
  const XdrSCVmErrorCode._internal(this._value);
  toString() => 'SCVmErrorCode.$_value';
  XdrSCVmErrorCode(this._value);
  get value => this._value;

  static const VM_UNKNOWN = const XdrSCVmErrorCode._internal(0);
  static const VM_VALIDATION = const XdrSCVmErrorCode._internal(1);
  static const VM_INSTANTIATION = const XdrSCVmErrorCode._internal(2);
  static const VM_FUNCTION = const XdrSCVmErrorCode._internal(3);
  static const VM_TABLE = const XdrSCVmErrorCode._internal(4);
  static const VM_MEMORY = const XdrSCVmErrorCode._internal(5);
  static const VM_GLOBAL = const XdrSCVmErrorCode._internal(6);
  static const VM_VALUE = const XdrSCVmErrorCode._internal(7);
  static const VM_TRAP_UNREACHABLE = const XdrSCVmErrorCode._internal(8);
  static const VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS =
      const XdrSCVmErrorCode._internal(9);
  static const VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS =
      const XdrSCVmErrorCode._internal(10);
  static const VM_TRAP_ELEM_UNINITIALIZED =
      const XdrSCVmErrorCode._internal(11);
  static const VM_TRAP_DIVISION_BY_ZERO = const XdrSCVmErrorCode._internal(12);
  static const VM_TRAP_INTEGER_OVERFLOW = const XdrSCVmErrorCode._internal(13);
  static const VM_TRAP_INVALID_CONVERSION_TO_INT =
      const XdrSCVmErrorCode._internal(14);
  static const VM_TRAP_STACK_OVERFLOW = const XdrSCVmErrorCode._internal(15);
  static const VM_TRAP_UNEXPECTED_SIGNATURE =
      const XdrSCVmErrorCode._internal(16);
  static const VM_TRAP_MEM_LIMIT_EXCEEDED =
      const XdrSCVmErrorCode._internal(17);
  static const VM_TRAP_CPU_LIMIT_EXCEEDED =
      const XdrSCVmErrorCode._internal(18);

  static XdrSCVmErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return VM_UNKNOWN;
      case 1:
        return VM_VALIDATION;
      case 2:
        return VM_INSTANTIATION;
      case 3:
        return VM_FUNCTION;
      case 4:
        return VM_TABLE;
      case 5:
        return VM_MEMORY;
      case 6:
        return VM_GLOBAL;
      case 7:
        return VM_VALUE;
      case 8:
        return VM_TRAP_UNREACHABLE;
      case 9:
        return VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS;
      case 10:
        return VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS;
      case 11:
        return VM_TRAP_ELEM_UNINITIALIZED;
      case 12:
        return VM_TRAP_DIVISION_BY_ZERO;
      case 13:
        return VM_TRAP_INTEGER_OVERFLOW;
      case 14:
        return VM_TRAP_INVALID_CONVERSION_TO_INT;
      case 15:
        return VM_TRAP_STACK_OVERFLOW;
      case 16:
        return VM_TRAP_UNEXPECTED_SIGNATURE;
      case 17:
        return VM_TRAP_MEM_LIMIT_EXCEEDED;
      case 18:
        return VM_TRAP_CPU_LIMIT_EXCEEDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCVmErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCUnknownErrorCode {
  final _value;
  const XdrSCUnknownErrorCode._internal(this._value);
  toString() => 'SCUnknownErrorCode.$_value';
  XdrSCUnknownErrorCode(this._value);
  get value => this._value;

  static const UNKNOWN_ERROR_GENERAL =
      const XdrSCUnknownErrorCode._internal(0);
  static const UNKNOWN_ERROR_XDR =
      const XdrSCUnknownErrorCode._internal(1);

  static XdrSCUnknownErrorCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return UNKNOWN_ERROR_GENERAL;
      case 1:
        return UNKNOWN_ERROR_XDR;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCUnknownErrorCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSCStatus {
  XdrSCStatus(this._type);
  XdrSCStatusType _type;
  XdrSCStatusType get discriminant => this._type;
  set discriminant(XdrSCStatusType value) => this._type = value;

  XdrSCUnknownErrorCode? _unknownCode;
  XdrSCUnknownErrorCode? get unknownCode => this._unknownCode;
  set unknownCode(XdrSCUnknownErrorCode? value) => this._unknownCode = value;

  XdrSCHostValErrorCode? _valCode;
  XdrSCHostValErrorCode? get valCode => this._valCode;
  set valCode(XdrSCHostValErrorCode? value) => this._valCode = value;

  XdrSCHostObjErrorCode? _objCode;
  XdrSCHostObjErrorCode? get objCode => this._objCode;
  set objCode(XdrSCHostObjErrorCode? value) => this._objCode = value;

  XdrSCHostFnErrorCode? _fnCode;
  XdrSCHostFnErrorCode? get fnCode => this._fnCode;
  set fnCode(XdrSCHostFnErrorCode? value) => this._fnCode = value;

  XdrSCHostStorageErrorCode? _storageCode;
  XdrSCHostStorageErrorCode? get storageCode => this._storageCode;
  set storageCode(XdrSCHostStorageErrorCode? value) =>
      this._storageCode = value;

  XdrSCHostContextErrorCode? _contextCode;
  XdrSCHostContextErrorCode? get contextCode => this._contextCode;
  set contextCode(XdrSCHostContextErrorCode? value) =>
      this._contextCode = value;

  XdrSCVmErrorCode? _vmCode;
  XdrSCVmErrorCode? get vmCode => this._vmCode;
  set vmCode(XdrSCVmErrorCode? value) => this._vmCode = value;

  XdrUint32? _contractCode;
  XdrUint32? get contractCode => this._contractCode;
  set contractCode(XdrUint32? value) => this._contractCode = value;

  XdrSCHostAuthErrorCode? _authCode;
  XdrSCHostAuthErrorCode? get authCode => this._authCode;
  set authCode(XdrSCHostAuthErrorCode? value) => this._authCode = value;

  static void encode(XdrDataOutputStream stream, XdrSCStatus encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCStatusType.SST_OK:
        break;
      case XdrSCStatusType.SST_UNKNOWN_ERROR:
        XdrSCUnknownErrorCode.encode(stream, encoded.unknownCode!);
        break;
      case XdrSCStatusType.SST_HOST_VALUE_ERROR:
        XdrSCHostValErrorCode.encode(stream, encoded.valCode!);
        break;
      case XdrSCStatusType.SST_HOST_OBJECT_ERROR:
        XdrSCHostObjErrorCode.encode(stream, encoded.objCode!);
        break;
      case XdrSCStatusType.SST_HOST_FUNCTION_ERROR:
        XdrSCHostFnErrorCode.encode(stream, encoded.fnCode!);
        break;
      case XdrSCStatusType.SST_HOST_STORAGE_ERROR:
        XdrSCHostStorageErrorCode.encode(stream, encoded.storageCode!);
        break;
      case XdrSCStatusType.SST_HOST_CONTEXT_ERROR:
        XdrSCHostStorageErrorCode.encode(stream, encoded.storageCode!);
        break;
      case XdrSCStatusType.SST_HOST_CONTEXT_ERROR:
        XdrSCHostContextErrorCode.encode(stream, encoded.contextCode!);
        break;
      case XdrSCStatusType.SST_VM_ERROR:
        XdrSCVmErrorCode.encode(stream, encoded.vmCode!);
        break;
      case XdrSCStatusType.SST_CONTRACT_ERROR:
        XdrUint32.encode(stream, encoded.contractCode!);
        break;
      case XdrSCStatusType.SST_HOST_AUTH_ERROR:
        XdrSCHostAuthErrorCode.encode(stream, encoded.authCode!);
        break;
    }
  }

  static XdrSCStatus decode(XdrDataInputStream stream) {
    XdrSCStatus decoded = XdrSCStatus(XdrSCStatusType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCStatusType.SST_OK:
        break;
      case XdrSCStatusType.SST_UNKNOWN_ERROR:
        decoded.unknownCode = XdrSCUnknownErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_HOST_VALUE_ERROR:
        decoded.valCode = XdrSCHostValErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_HOST_OBJECT_ERROR:
        decoded.objCode = XdrSCHostObjErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_HOST_FUNCTION_ERROR:
        decoded.fnCode = XdrSCHostFnErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_HOST_STORAGE_ERROR:
        decoded.storageCode = XdrSCHostStorageErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_HOST_CONTEXT_ERROR:
        decoded.contextCode = XdrSCHostContextErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_VM_ERROR:
        decoded.vmCode = XdrSCVmErrorCode.decode(stream);
        break;
      case XdrSCStatusType.SST_CONTRACT_ERROR:
        decoded.contractCode = XdrUint32.decode(stream);
        break;
      case XdrSCStatusType.SST_HOST_AUTH_ERROR:
        decoded.authCode = XdrSCHostAuthErrorCode.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrSCObjectType {
  final _value;
  const XdrSCObjectType._internal(this._value);
  toString() => 'SCObjectType.$_value';
  XdrSCObjectType(this._value);
  get value => this._value;

  static const SCO_VEC = const XdrSCObjectType._internal(0);
  static const SCO_MAP = const XdrSCObjectType._internal(1);
  static const SCO_U64 = const XdrSCObjectType._internal(2);
  static const SCO_I64 = const XdrSCObjectType._internal(3);
  static const SCO_U128 = const XdrSCObjectType._internal(4);
  static const SCO_I128 = const XdrSCObjectType._internal(5);
  static const SCO_BYTES = const XdrSCObjectType._internal(6);
  static const SCO_CONTRACT_CODE = const XdrSCObjectType._internal(7);
  static const SCO_ACCOUNT_ID = const XdrSCObjectType._internal(8);

  static XdrSCObjectType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCO_VEC;
      case 1:
        return SCO_MAP;
      case 2:
        return SCO_U64;
      case 3:
        return SCO_I64;
      case 4:
        return SCO_U128;
      case 5:
        return SCO_I128;
      case 6:
        return SCO_BYTES;
      case 7:
        return SCO_CONTRACT_CODE;
      case 8:
        return SCO_ACCOUNT_ID;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCObjectType value) {
    stream.writeInt(value.value);
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
  XdrUint64 _lo;
  XdrUint64 get lo => this._lo;
  set lo(XdrUint64 value) => this._lo = value;

  XdrUint64 _hi;
  XdrUint64 get hi => this._hi;
  set hi(XdrUint64 value) => this._hi = value;

  XdrInt128Parts(this._lo, this._hi);

  static void encode(XdrDataOutputStream stream, XdrInt128Parts encoded) {
    XdrUint64.encode(stream, encoded.lo);
    XdrUint64.encode(stream, encoded.hi);
  }

  static XdrInt128Parts decode(XdrDataInputStream stream) {
    return XdrInt128Parts(XdrUint64.decode(stream), XdrUint64.decode(stream));
  }
}

class XdrSCContractCodeType {
  final _value;
  const XdrSCContractCodeType._internal(this._value);
  toString() => 'SCContractCodeType.$_value';
  XdrSCContractCodeType(this._value);
  get value => this._value;

  static const SCCONTRACT_CODE_WASM_REF =
      const XdrSCContractCodeType._internal(0);
  static const SCCONTRACT_CODE_TOKEN = const XdrSCContractCodeType._internal(1);

  static XdrSCContractCodeType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCCONTRACT_CODE_WASM_REF;
      case 1:
        return SCCONTRACT_CODE_TOKEN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCContractCodeType value) {
    stream.writeInt(value.value);
  }
}

class XdrSCContractCode {
  XdrSCContractCode(this._type);
  XdrSCContractCodeType _type;
  XdrSCContractCodeType get discriminant => this._type;
  set discriminant(XdrSCContractCodeType value) => this._type = value;

  XdrHash? _wasmId;
  XdrHash? get wasmId => this._wasmId;
  set wasmId(XdrHash? value) => this._wasmId = value;

  static void encode(XdrDataOutputStream stream, XdrSCContractCode encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF:
        XdrHash.encode(stream, encoded.wasmId!);
        break;
      case XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN:
        break;
    }
  }

  static XdrSCContractCode decode(XdrDataInputStream stream) {
    XdrSCContractCode decoded =
        XdrSCContractCode(XdrSCContractCodeType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF:
        decoded.wasmId = XdrHash.decode(stream);
        break;
      case XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN:
        break;
    }
    return decoded;
  }
}

class XdrSCObject {
  XdrSCObject(this._type);
  XdrSCObjectType _type;
  XdrSCObjectType get discriminant => this._type;
  set discriminant(XdrSCObjectType value) => this._type = value;

  List<XdrSCVal>? _vec;
  List<XdrSCVal>? get vec => this._vec;
  set vec(List<XdrSCVal>? value) => this._vec = value;

  List<XdrSCMapEntry>? _map;
  List<XdrSCMapEntry>? get map => this._map;
  set map(List<XdrSCMapEntry>? value) => this._map = value;

  XdrUint64? _u64;
  XdrUint64? get u64 => this._u64;
  set u64(XdrUint64? value) => this._u64 = value;

  XdrInt64? _i64;
  XdrInt64? get i64 => this._i64;
  set i64(XdrInt64? value) => this._i64 = value;

  XdrInt128Parts? _u128;
  XdrInt128Parts? get u128 => this._u128;
  set u128(XdrInt128Parts? value) => this._u128 = value;

  XdrInt128Parts? _i128;
  XdrInt128Parts? get i128 => this._i128;
  set i128(XdrInt128Parts? value) => this._i128 = value;

  XdrDataValue? _bin;
  XdrDataValue? get bin => this._bin;
  set bin(XdrDataValue? value) => this._bin = value;

  XdrSCContractCode? _contractCode;
  XdrSCContractCode? get contractCode => this._contractCode;
  set contractCode(XdrSCContractCode? value) => this._contractCode = value;

  XdrAccountID? _accountID;
  XdrAccountID? get accountID => this._accountID;
  set accountID(XdrAccountID? value) => this._accountID = value;

  static void encode(XdrDataOutputStream stream, XdrSCObject encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCObjectType.SCO_VEC:
        int vecSize = encoded.vec!.length;
        stream.writeInt(vecSize);
        for (int i = 0; i < vecSize; i++) {
          XdrSCVal.encode(stream, encoded.vec![i]);
        }
        break;
      case XdrSCObjectType.SCO_MAP:
        int mapSize = encoded.map!.length;
        stream.writeInt(mapSize);
        for (int i = 0; i < mapSize; i++) {
          XdrSCMapEntry.encode(stream, encoded.map![i]);
        }
        break;
      case XdrSCObjectType.SCO_U64:
        XdrUint64.encode(stream, encoded.u64!);
        break;
      case XdrSCObjectType.SCO_I64:
        XdrInt64.encode(stream, encoded.i64!);
        break;
      case XdrSCObjectType.SCO_U128:
        XdrInt128Parts.encode(stream, encoded.u128!);
        break;
      case XdrSCObjectType.SCO_I128:
        XdrInt128Parts.encode(stream, encoded.i128!);
        break;
      case XdrSCObjectType.SCO_BYTES:
        XdrDataValue.encode(stream, encoded.bin!);
        break;
      case XdrSCObjectType.SCO_CONTRACT_CODE:
        XdrSCContractCode.encode(stream, encoded.contractCode!);
        break;
      case XdrSCObjectType.SCO_ACCOUNT_ID:
        XdrAccountID.encode(stream, encoded.accountID!);
        break;
    }
  }

  static XdrSCObject decode(XdrDataInputStream stream) {
    XdrSCObject decoded = XdrSCObject(XdrSCObjectType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCObjectType.SCO_VEC:
        int vecSize = stream.readInt();
        decoded.vec = List<XdrSCVal>.empty(growable: true);
        for (int i = 0; i < vecSize; i++) {
          decoded.vec!.add(XdrSCVal.decode(stream));
        }
        break;
      case XdrSCObjectType.SCO_MAP:
        int mapSize = stream.readInt();
        decoded.map = List<XdrSCMapEntry>.empty(growable: true);
        for (int i = 0; i < mapSize; i++) {
          decoded.map!.add(XdrSCMapEntry.decode(stream));
        }
        break;
      case XdrSCObjectType.SCO_U64:
        decoded.u64 = XdrUint64.decode(stream);
        break;
      case XdrSCObjectType.SCO_I64:
        decoded.i64 = XdrInt64.decode(stream);
        break;
      case XdrSCObjectType.SCO_U128:
        decoded.u128 = XdrInt128Parts.decode(stream);
        break;
      case XdrSCObjectType.SCO_I128:
        decoded.i128 = XdrInt128Parts.decode(stream);
        break;
      case XdrSCObjectType.SCO_BYTES:
        decoded.bin = XdrDataValue.decode(stream);
        break;
      case XdrSCObjectType.SCO_CONTRACT_CODE:
        decoded.contractCode = XdrSCContractCode.decode(stream);
        break;
      case XdrSCObjectType.SCO_ACCOUNT_ID:
        decoded.accountID = XdrAccountID.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrSCObject forVec(List<XdrSCVal> value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_VEC);
    val.vec = value;
    return val;
  }

  static XdrSCObject forMap(List<XdrSCMapEntry> value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_MAP);
    val.map = value;
    return val;
  }

  static XdrSCObject forU64(int value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_U64);
    val.u64 = XdrUint64(value);
    return val;
  }

  static XdrSCObject forI64(int value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_I64);
    val.i64 = XdrInt64(value);
    return val;
  }

  static XdrSCObject forU128(XdrInt128Parts value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_U128);
    val.u128 = value;
    return val;
  }

  static XdrSCObject forI128(XdrInt128Parts value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_I128);
    val.i128 = value;
    return val;
  }

  static XdrSCObject forBytes(Uint8List value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_BYTES);
    val.bin = XdrDataValue(value);
    return val;
  }

  static XdrSCObject forContractCode(XdrSCContractCode value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_CONTRACT_CODE);
    val.contractCode = value;
    return val;
  }

  static XdrSCObject forAccountId(XdrAccountID value) {
    XdrSCObject val = XdrSCObject(XdrSCObjectType.SCO_ACCOUNT_ID);
    val.accountID = value;
    return val;
  }

  static XdrSCObject fromBase64EncodedString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSCObject.decode(XdrDataInputStream(bytes));
  }
}

class XdrSCVal {
  XdrSCVal(this._type);
  XdrSCValType _type;
  XdrSCValType get discriminant => this._type;
  set discriminant(XdrSCValType value) => this._type = value;

  XdrInt64? _u63;
  XdrInt64? get u63 => this._u63;
  set u63(XdrInt64? value) => this._u63 = value;

  XdrUint32? _u32;
  XdrUint32? get u32 => this._u32;
  set u32(XdrUint32? value) => this._u32 = value;

  XdrInt32? _i32;
  XdrInt32? get i32 => this._i32;
  set i32(XdrInt32? value) => this._i32 = value;

  XdrSCStatic? _ic;
  XdrSCStatic? get ic => this._ic;
  set ic(XdrSCStatic? value) => this._ic = value;

  XdrSCObject? _obj;
  XdrSCObject? get obj => this._obj;
  set obj(XdrSCObject? value) => this._obj = value;

  String? _sym;
  String? get sym => this._sym;
  set sym(String? value) => this._sym = value;

  XdrUint64? _bits;
  XdrUint64? get bits => this._bits;
  set bits(XdrUint64? value) => this._bits = value;

  XdrSCStatus? _status;
  XdrSCStatus? get status => this._status;
  set status(XdrSCStatus? value) => this._status = value;

  static void encode(XdrDataOutputStream stream, XdrSCVal encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCValType.SCV_U63:
        XdrInt64.encode(stream, encoded.u63!);
        break;
      case XdrSCValType.SCV_U32:
        XdrUint32.encode(stream, encoded.u32!);
        break;
      case XdrSCValType.SCV_I32:
        XdrInt32.encode(stream, encoded.i32!);
        break;
      case XdrSCValType.SCV_STATIC:
        XdrSCStatic.encode(stream, encoded.ic!);
        break;
      case XdrSCValType.SCV_OBJECT:
        if (encoded.obj != null) {
          stream.writeInt(1);
          XdrSCObject.encode(stream, encoded.obj!);
        } else {
          stream.writeInt(0);
        }
        break;
      case XdrSCValType.SCV_SYMBOL:
        stream.writeString(encoded.sym!);
        break;
      case XdrSCValType.SCV_BITSET:
        XdrUint64.encode(stream, encoded.bits!);
        break;
      case XdrSCValType.SCV_STATUS:
        XdrSCStatus.encode(stream, encoded.status!);
        break;
    }
  }

  static XdrSCVal decode(XdrDataInputStream stream) {
    XdrSCVal decoded = XdrSCVal(XdrSCValType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCValType.SCV_U63:
        decoded.u63 = XdrInt64.decode(stream);
        break;
      case XdrSCValType.SCV_U32:
        decoded.u32 = XdrUint32.decode(stream);
        break;
      case XdrSCValType.SCV_I32:
        decoded.i32 = XdrInt32.decode(stream);
        break;
      case XdrSCValType.SCV_STATIC:
        decoded.ic = XdrSCStatic.decode(stream);
        break;
      case XdrSCValType.SCV_OBJECT:
        int objPresent = stream.readInt();
        if (objPresent != 0) {
          decoded.obj = XdrSCObject.decode(stream);
        }
        break;
      case XdrSCValType.SCV_SYMBOL:
        decoded.sym = stream.readString();
        break;
      case XdrSCValType.SCV_BITSET:
        decoded.bits = XdrUint64.decode(stream);
        break;
      case XdrSCValType.SCV_STATUS:
        decoded.status = XdrSCStatus.decode(stream);
        break;
    }
    return decoded;
  }

  List<XdrSCVal>? getVec() {
    return this.obj?.vec;
  }

  List<XdrSCMapEntry>? getMap() {
    return this.obj?.map;
  }

  int? getU64() {
    return this.obj?.u64?.uint64;
  }

  int? getI64() {
    return this.obj?.i64?.int64;
  }

  XdrInt128Parts? getU128() {
    return this.obj?.u128;
  }

  XdrInt128Parts? getI128() {
    return this.obj?.i128;
  }

  Uint8List? getBytes() {
    return this.obj?.bin?.dataValue;
  }

  XdrSCContractCode? getContractCode() {
    return this.obj?.contractCode;
  }

  XdrAccountID? getAccountID() {
    return this.obj?.accountID;
  }

  static XdrSCVal forU63(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U63);
    val.u63 = XdrInt64(value);
    return val;
  }

  static XdrSCVal forU32(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U63);
    val.u32 = XdrUint32(value);
    return val;
  }

  static XdrSCVal forI32(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I32);
    val.i32 = XdrInt32(value);
    return val;
  }

  static XdrSCVal forStatic(XdrSCStatic value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_STATIC);
    val.ic = value;
    return val;
  }

  static XdrSCVal forObject(XdrSCObject value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_OBJECT);
    val.obj = value;
    return val;
  }

  static XdrSCVal forSymbol(String symbol) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_SYMBOL);
    val.sym = symbol;
    return val;
  }

  static XdrSCVal forBitset(int value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_BITSET);
    val.bits = XdrUint64(value);
    return val;
  }

  static XdrSCVal forStatus(XdrSCStatus value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_STATUS);
    val.status = value;
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
  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  XdrSCSpecTypeUDT(this._name);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeUDT encoded) {
    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }
  }

  static XdrSCSpecTypeUDT decode(XdrDataInputStream stream) {
    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }
    return XdrSCSpecTypeUDT(name);
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
  static const SC_SPEC_TYPE_U32 = const XdrSCSpecType._internal(1);
  static const SC_SPEC_TYPE_I32 = const XdrSCSpecType._internal(2);
  static const SC_SPEC_TYPE_U64 = const XdrSCSpecType._internal(3);
  static const SC_SPEC_TYPE_I64 = const XdrSCSpecType._internal(4);
  static const SC_SPEC_TYPE_U128 = const XdrSCSpecType._internal(5);
  static const SC_SPEC_TYPE_I128 = const XdrSCSpecType._internal(6);
  static const SC_SPEC_TYPE_BOOL = const XdrSCSpecType._internal(7);
  static const SC_SPEC_TYPE_SYMBOL = const XdrSCSpecType._internal(8);
  static const SC_SPEC_TYPE_BITSET = const XdrSCSpecType._internal(9);
  static const SC_SPEC_TYPE_STATUS = const XdrSCSpecType._internal(10);
  static const SC_SPEC_TYPE_BYTES = const XdrSCSpecType._internal(11);
  static const SC_SPEC_TYPE_INVOKER = const XdrSCSpecType._internal(12);
  static const SC_SPEC_TYPE_ACCOUNT_ID = const XdrSCSpecType._internal(13);

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
        return SC_SPEC_TYPE_U32;
      case 2:
        return SC_SPEC_TYPE_I32;
      case 3:
        return SC_SPEC_TYPE_U64;
      case 4:
        return SC_SPEC_TYPE_I64;
      case 5:
        return SC_SPEC_TYPE_U128;
      case 6:
        return SC_SPEC_TYPE_I128;
      case 7:
        return SC_SPEC_TYPE_BOOL;
      case 8:
        return SC_SPEC_TYPE_SYMBOL;
      case 9:
        return SC_SPEC_TYPE_BITSET;
      case 10:
        return SC_SPEC_TYPE_STATUS;
      case 11:
        return SC_SPEC_TYPE_BYTES;
      case 12:
        return SC_SPEC_TYPE_INVOKER;
      case 13:
        return SC_SPEC_TYPE_ACCOUNT_ID;
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
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
      case XdrSCSpecType.SC_SPEC_TYPE_BITSET:
      case XdrSCSpecType.SC_SPEC_TYPE_STATUS:
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
      case XdrSCSpecType.SC_SPEC_TYPE_INVOKER:
      case XdrSCSpecType.SC_SPEC_TYPE_ACCOUNT_ID:
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
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
      case XdrSCSpecType.SC_SPEC_TYPE_BITSET:
      case XdrSCSpecType.SC_SPEC_TYPE_STATUS:
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
      case XdrSCSpecType.SC_SPEC_TYPE_INVOKER:
      case XdrSCSpecType.SC_SPEC_TYPE_ACCOUNT_ID:
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
  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  XdrSCSpecTypeDef _type;
  XdrSCSpecTypeDef get type => this._type;
  set type(XdrSCSpecTypeDef value) => this._type = value;

  XdrSCSpecUDTStructFieldV0(this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTStructFieldV0 encoded) {
    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }
    XdrSCSpecTypeDef.encode(stream, encoded.type);
  }

  static XdrSCSpecUDTStructFieldV0 decode(XdrDataInputStream stream) {
    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }
    return XdrSCSpecUDTStructFieldV0(name, XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecUDTStructV0 {
  List<String> _lib;
  List<String> get lib => this._lib;
  set lib(List<String> value) => this._lib = value;

  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  List<XdrSCSpecUDTStructFieldV0> _fields;
  List<XdrSCSpecUDTStructFieldV0> get fields => this._fields;
  set fields(List<XdrSCSpecUDTStructFieldV0> value) => this._fields = value;

  XdrSCSpecUDTStructV0(this._lib, this._name, this._fields);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTStructV0 encoded) {
    int libSize = encoded.lib.length;
    stream.writeInt(libSize);
    for (int i = 0; i < libSize; i++) {
      stream.writeString(encoded.lib[i]);
    }

    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    int casesSize = encoded.fields.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTStructFieldV0.encode(stream, encoded.fields[i]);
    }
  }

  static XdrSCSpecUDTStructV0 decode(XdrDataInputStream stream) {
    int libSize = stream.readInt();
    List<String> lib = List<String>.empty(growable: true);
    for (int i = 0; i < libSize; i++) {
      lib.add(stream.readString());
    }

    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    int fieldsSize = stream.readInt();
    List<XdrSCSpecUDTStructFieldV0> fields =
        List<XdrSCSpecUDTStructFieldV0>.empty(growable: true);
    for (int i = 0; i < fieldsSize; i++) {
      fields.add(XdrSCSpecUDTStructFieldV0.decode(stream));
    }

    return XdrSCSpecUDTStructV0(lib, name, fields);
  }
}

class XdrSCSpecUDTUnionCaseV0 {
  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  XdrSCSpecTypeDef? _type;
  XdrSCSpecTypeDef? get type => this._type;
  set type(XdrSCSpecTypeDef? value) => this._type = value;

  XdrSCSpecUDTUnionCaseV0(this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTUnionCaseV0 encoded) {
    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }
    if (encoded.type != null) {
      stream.writeInt(1);
      XdrSCSpecTypeDef.encode(stream, encoded.type!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrSCSpecUDTUnionCaseV0 decode(XdrDataInputStream stream) {
    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }
    XdrSCSpecTypeDef? typ;
    int typePresent = stream.readInt();
    if (typePresent != 0) {
      typ = XdrSCSpecTypeDef.decode(stream);
    }
    return XdrSCSpecUDTUnionCaseV0(name, typ);
  }
}

class XdrSCSpecUDTUnionV0 {
  List<String> _lib;
  List<String> get lib => this._lib;
  set lib(List<String> value) => this._lib = value;

  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  List<XdrSCSpecUDTUnionCaseV0> _cases;
  List<XdrSCSpecUDTUnionCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTUnionCaseV0> value) => this._cases = value;

  XdrSCSpecUDTUnionV0(this._lib, this._name, this._cases);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTUnionV0 encoded) {
    int libSize = encoded.lib.length;
    stream.writeInt(libSize);
    for (int i = 0; i < libSize; i++) {
      stream.writeString(encoded.lib[i]);
    }

    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTUnionCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTUnionV0 decode(XdrDataInputStream stream) {
    int libSize = stream.readInt();
    List<String> lib = List<String>.empty(growable: true);
    for (int i = 0; i < libSize; i++) {
      lib.add(stream.readString());
    }

    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTUnionCaseV0> cases =
        List<XdrSCSpecUDTUnionCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTUnionCaseV0.decode(stream));
    }

    return XdrSCSpecUDTUnionV0(lib, name, cases);
  }
}

class XdrSCSpecUDTEnumCaseV0 {
  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  XdrUint32 _value;
  XdrUint32 get value => this._value;
  set value(XdrUint32 value) => this._value = value;

  XdrSCSpecUDTEnumCaseV0(this._name, this._value);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTEnumCaseV0 encoded) {
    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    XdrUint32.encode(stream, encoded.value);
  }

  static XdrSCSpecUDTEnumCaseV0 decode(XdrDataInputStream stream) {
    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    return XdrSCSpecUDTEnumCaseV0(name, XdrUint32.decode(stream));
  }
}

class XdrSCSpecUDTEnumV0 {
  List<String> _lib;
  List<String> get lib => this._lib;
  set lib(List<String> value) => this._lib = value;

  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  List<XdrSCSpecUDTEnumCaseV0> _cases;
  List<XdrSCSpecUDTEnumCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTEnumCaseV0> value) => this._cases = value;

  XdrSCSpecUDTEnumV0(this._lib, this._name, this._cases);

  static void encode(XdrDataOutputStream stream, XdrSCSpecUDTEnumV0 encoded) {
    int libSize = encoded.lib.length;
    stream.writeInt(libSize);
    for (int i = 0; i < libSize; i++) {
      stream.writeString(encoded.lib[i]);
    }

    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTEnumCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTEnumV0 decode(XdrDataInputStream stream) {
    int libSize = stream.readInt();
    List<String> lib = List<String>.empty(growable: true);
    for (int i = 0; i < libSize; i++) {
      lib.add(stream.readString());
    }

    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTEnumCaseV0> cases =
        List<XdrSCSpecUDTEnumCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTEnumCaseV0.decode(stream));
    }

    return XdrSCSpecUDTEnumV0(lib, name, cases);
  }
}

class XdrSCSpecUDTErrorEnumCaseV0 {
  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  XdrUint32 _value;
  XdrUint32 get value => this._value;
  set value(XdrUint32 value) => this._value = value;

  XdrSCSpecUDTErrorEnumCaseV0(this._name, this._value);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTErrorEnumCaseV0 encoded) {
    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    XdrUint32.encode(stream, encoded.value);
  }

  static XdrSCSpecUDTErrorEnumCaseV0 decode(XdrDataInputStream stream) {
    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    return XdrSCSpecUDTErrorEnumCaseV0(name, XdrUint32.decode(stream));
  }
}

class XdrSCSpecUDTErrorEnumV0 {
  List<String> _lib;
  List<String> get lib => this._lib;
  set lib(List<String> value) => this._lib = value;

  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  List<XdrSCSpecUDTErrorEnumCaseV0> _cases;
  List<XdrSCSpecUDTErrorEnumCaseV0> get cases => this._cases;
  set cases(List<XdrSCSpecUDTErrorEnumCaseV0> value) => this._cases = value;

  XdrSCSpecUDTErrorEnumV0(this._lib, this._name, this._cases);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecUDTErrorEnumV0 encoded) {
    int libSize = encoded.lib.length;
    stream.writeInt(libSize);
    for (int i = 0; i < libSize; i++) {
      stream.writeString(encoded.lib[i]);
    }

    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    int casesSize = encoded.cases.length;
    stream.writeInt(casesSize);
    for (int i = 0; i < casesSize; i++) {
      XdrSCSpecUDTErrorEnumCaseV0.encode(stream, encoded.cases[i]);
    }
  }

  static XdrSCSpecUDTErrorEnumV0 decode(XdrDataInputStream stream) {
    int libSize = stream.readInt();
    List<String> lib = List<String>.empty(growable: true);
    for (int i = 0; i < libSize; i++) {
      lib.add(stream.readString());
    }

    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    int casesSize = stream.readInt();
    List<XdrSCSpecUDTErrorEnumCaseV0> cases =
        List<XdrSCSpecUDTErrorEnumCaseV0>.empty(growable: true);
    for (int i = 0; i < casesSize; i++) {
      cases.add(XdrSCSpecUDTErrorEnumCaseV0.decode(stream));
    }

    return XdrSCSpecUDTErrorEnumV0(lib, name, cases);
  }
}

class XdrSCSpecFunctionInputV0 {
  List<String> _name;
  List<String> get name => this._name;
  set name(List<String> value) => this._name = value;

  XdrSCSpecTypeDef _type;
  XdrSCSpecTypeDef get type => this._type;
  set type(XdrSCSpecTypeDef value) => this._type = value;

  XdrSCSpecFunctionInputV0(this._name, this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSCSpecFunctionInputV0 encoded) {
    int nameSize = encoded.name.length;
    stream.writeInt(nameSize);
    for (int i = 0; i < nameSize; i++) {
      stream.writeString(encoded.name[i]);
    }

    XdrSCSpecTypeDef.encode(stream, encoded.type);
  }

  static XdrSCSpecFunctionInputV0 decode(XdrDataInputStream stream) {
    int namesSize = stream.readInt();
    List<String> name = List<String>.empty(growable: true);
    for (int i = 0; i < namesSize; i++) {
      name.add(stream.readString());
    }

    return XdrSCSpecFunctionInputV0(name, XdrSCSpecTypeDef.decode(stream));
  }
}

class XdrSCSpecFunctionV0 {
  String _name; // symbol
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecFunctionInputV0> _inputs;
  List<XdrSCSpecFunctionInputV0> get inputs => this._inputs;
  set inputs(List<XdrSCSpecFunctionInputV0> value) => this._inputs = value;

  List<XdrSCSpecTypeDef> _outputs;
  List<XdrSCSpecTypeDef> get outputs => this._outputs;
  set outputs(List<XdrSCSpecTypeDef> value) => this._outputs = value;

  XdrSCSpecFunctionV0(this._name, this._inputs, this._outputs);

  static void encode(XdrDataOutputStream stream, XdrSCSpecFunctionV0 encoded) {
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
    return XdrSCSpecFunctionV0(name, inputs, outputs);
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
  static const HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE =
      const XdrHostFunctionType._internal(2);

  static XdrHostFunctionType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return HOST_FUNCTION_TYPE_INVOKE_CONTRACT;
      case 1:
        return HOST_FUNCTION_TYPE_CREATE_CONTRACT;
      case 2:
        return HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrHostFunctionType value) {
    stream.writeInt(value.value);
  }
}

class XdrContractIDType {
  final _value;
  const XdrContractIDType._internal(this._value);
  toString() => 'ContractIDType.$_value';
  XdrContractIDType(this._value);
  get value => this._value;

  static const CONTRACT_ID_FROM_SOURCE_ACCOUNT =
      const XdrContractIDType._internal(0);
  static const CONTRACT_ID_FROM_ED25519_PUBLIC_KEY =
      const XdrContractIDType._internal(1);
  static const CONTRACT_ID_FROM_ASSET = const XdrContractIDType._internal(2);

  static XdrContractIDType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONTRACT_ID_FROM_SOURCE_ACCOUNT;
      case 1:
        return CONTRACT_ID_FROM_ED25519_PUBLIC_KEY;
      case 2:
        return CONTRACT_ID_FROM_ASSET;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrContractIDType value) {
    stream.writeInt(value.value);
  }
}

class XdrContractIDPublicKeyType {
  final _value;
  const XdrContractIDPublicKeyType._internal(this._value);
  toString() => 'ContractIDPublicKeyType.$_value';
  XdrContractIDPublicKeyType(this._value);
  get value => this._value;

  static const CONTRACT_ID_PUBLIC_KEY_SOURCE_ACCOUNT =
      const XdrContractIDPublicKeyType._internal(0);
  static const CONTRACT_ID_PUBLIC_KEY_ED25519 =
      const XdrContractIDPublicKeyType._internal(1);

  static XdrContractIDPublicKeyType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONTRACT_ID_PUBLIC_KEY_SOURCE_ACCOUNT;
      case 1:
        return CONTRACT_ID_PUBLIC_KEY_ED25519;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrContractIDPublicKeyType value) {
    stream.writeInt(value.value);
  }
}

class XdrInstallContractCodeArgs {
  XdrDataValue _code;
  XdrDataValue get code => this._code;
  set code(XdrDataValue value) => this._code = value;

  XdrInstallContractCodeArgs(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrInstallContractCodeArgs encoded) {
    XdrDataValue.encode(stream, encoded.code);
  }

  static XdrInstallContractCodeArgs decode(XdrDataInputStream stream) {
    return XdrInstallContractCodeArgs(XdrDataValue.decode(stream));
  }
}

class XdrFromEd25519PublicKey {
  XdrUint256 _key;
  XdrUint256 get key => this._key;
  set key(XdrUint256 value) => this._key = value;

  XdrSignature _signature;
  XdrSignature get signature => this._signature;
  set signature(XdrSignature value) => this._signature = value;

  XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  XdrFromEd25519PublicKey(this._key, this._signature, this._salt);

  static void encode(
      XdrDataOutputStream stream, XdrFromEd25519PublicKey encoded) {
    XdrUint256.encode(stream, encoded.key);
    XdrSignature.encode(stream, encoded.signature);
    XdrUint256.encode(stream, encoded.salt);
  }

  static XdrFromEd25519PublicKey decode(XdrDataInputStream stream) {
    return XdrFromEd25519PublicKey(XdrUint256.decode(stream),
        XdrSignature.decode(stream), XdrUint256.decode(stream));
  }
}

class XdrContractID {
  XdrContractID(this._type);
  XdrContractIDType _type;
  XdrContractIDType get discriminant => this._type;
  set discriminant(XdrContractIDType value) => this._type = value;

  XdrUint256? _salt;
  XdrUint256? get salt => this._salt;
  set salt(XdrUint256? value) => this._salt = value;

  XdrFromEd25519PublicKey? _fromEd25519PublicKey;
  XdrFromEd25519PublicKey? get fromEd25519PublicKey =>
      this._fromEd25519PublicKey;
  set fromEd25519PublicKey(XdrFromEd25519PublicKey? value) =>
      this._fromEd25519PublicKey = value;

  XdrAsset? _asset;
  XdrAsset? get asset => this._asset;
  set asset(XdrAsset? value) => this._asset = value;

  static void encode(XdrDataOutputStream stream, XdrContractID encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT:
        XdrUint256.encode(stream, encoded.salt!);
        break;
      case XdrContractIDType.CONTRACT_ID_FROM_ED25519_PUBLIC_KEY:
        XdrFromEd25519PublicKey.encode(stream, encoded.fromEd25519PublicKey!);
        break;
      case XdrContractIDType.CONTRACT_ID_FROM_ASSET:
        XdrAsset.encode(stream, encoded.asset!);
        break;
    }
  }

  static XdrContractID decode(XdrDataInputStream stream) {
    XdrContractID decoded = XdrContractID(XdrContractIDType.decode(stream));
    switch (decoded.discriminant) {
      case XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT:
        decoded.salt = XdrUint256.decode(stream);
        break;
      case XdrContractIDType.CONTRACT_ID_FROM_ED25519_PUBLIC_KEY:
        decoded.fromEd25519PublicKey = XdrFromEd25519PublicKey.decode(stream);
        break;
      case XdrContractIDType.CONTRACT_ID_FROM_ASSET:
        decoded.asset = XdrAsset.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrCreateContractArgs {
  XdrContractID _contractID;
  XdrContractID get contractID => this._contractID;
  set contractID(XdrContractID value) => this._contractID = value;

  XdrSCContractCode _source;
  XdrSCContractCode get source => this._source;
  set source(XdrSCContractCode value) => this._source = value;

  XdrCreateContractArgs(this._contractID, this._source);

  static void encode(
      XdrDataOutputStream stream, XdrCreateContractArgs encoded) {
    XdrContractID.encode(stream, encoded.contractID);
    XdrSCContractCode.encode(stream, encoded.source);
  }

  static XdrCreateContractArgs decode(XdrDataInputStream stream) {
    return XdrCreateContractArgs(
        XdrContractID.decode(stream), XdrSCContractCode.decode(stream));
  }
}

class XdrHostFunction {
  XdrHostFunction(this._type);
  XdrHostFunctionType _type;
  XdrHostFunctionType get discriminant => this._type;
  set discriminant(XdrHostFunctionType value) => this._type = value;

  List<XdrSCVal>? _invokeArgs; // SCVec
  List<XdrSCVal>? get invokeArgs => this._invokeArgs;
  set invokeArgs(List<XdrSCVal>? value) => this._invokeArgs = value;

  XdrCreateContractArgs? _createContractArgs;
  XdrCreateContractArgs? get createContractArgs => this._createContractArgs;
  set createContractArgs(XdrCreateContractArgs? value) =>
      this._createContractArgs = value;

  XdrInstallContractCodeArgs? _installContractCodeArgs;
  XdrInstallContractCodeArgs? get installContractCodeArgs =>
      this._installContractCodeArgs;
  set installContractCodeArgs(XdrInstallContractCodeArgs? value) =>
      this._installContractCodeArgs = value;

  static void encode(XdrDataOutputStream stream, XdrHostFunction encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        int vecSize = encoded.invokeArgs!.length;
        stream.writeInt(vecSize);
        for (int i = 0; i < vecSize; i++) {
          XdrSCVal.encode(stream, encoded.invokeArgs![i]);
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        XdrCreateContractArgs.encode(stream, encoded.createContractArgs!);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE:
        XdrInstallContractCodeArgs.encode(
            stream, encoded.installContractCodeArgs!);
        break;
    }
  }

  static XdrHostFunction decode(XdrDataInputStream stream) {
    XdrHostFunction decoded =
        XdrHostFunction(XdrHostFunctionType.decode(stream));
    switch (decoded.discriminant) {
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        int vecSize = stream.readInt();
        decoded.invokeArgs = List<XdrSCVal>.empty(growable: true);
        for (int i = 0; i < vecSize; i++) {
          decoded.invokeArgs!.add(XdrSCVal.decode(stream));
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        decoded.createContractArgs = XdrCreateContractArgs.decode(stream);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE:
        decoded.installContractCodeArgs =
            XdrInstallContractCodeArgs.decode(stream);
        break;
    }
    return decoded;
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

  static XdrInvokeHostFunctionResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return INVOKE_HOST_FUNCTION_SUCCESS;
      case -1:
        return INVOKE_HOST_FUNCTION_MALFORMED;
      case -2:
        return INVOKE_HOST_FUNCTION_TRAPPED;
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

  XdrInvokeHostFunctionResult(this._code);

  XdrSCVal? _success;
  XdrSCVal? get success => this._success;
  set success(XdrSCVal? value) => this._success = value;

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        XdrSCVal.encode(stream, encoded.success!);
        break;
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED:
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
        decoded.success = XdrSCVal.decode(stream);
        break;
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED:
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
  // The host function to invoke
  XdrHostFunction _function;
  XdrHostFunction get function => this._function;
  set function(XdrHostFunction value) => this._function = value;

  // The footprint for this invocation
  XdrLedgerFootprint _footprint;
  XdrLedgerFootprint get footprint => this._footprint;
  set footprint(XdrLedgerFootprint value) => this._footprint = value;

  XdrInvokeHostFunctionOp(this._function, this._footprint);

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionOp encoded) {
    XdrHostFunction.encode(stream, encoded.function);
    XdrLedgerFootprint.encode(stream, encoded.footprint);
  }

  static XdrInvokeHostFunctionOp decode(XdrDataInputStream stream) {
    return XdrInvokeHostFunctionOp(
        XdrHostFunction.decode(stream), XdrLedgerFootprint.decode(stream));
  }
}
