// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/constants/bit_constants.dart';
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_auth.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_data_io.dart';
import 'xdr_json_helper.dart';
import 'xdr_int128_parts.dart';
import 'xdr_int256_parts.dart';
import 'xdr_int32.dart';
import 'xdr_int64.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_bytes.dart';
import 'xdr_sc_contract_instance.dart';
import 'xdr_sc_error.dart';
import 'xdr_sc_map_entry.dart';
import 'xdr_sc_nonce_key.dart';
import 'xdr_sc_val_base.dart';
import 'xdr_sc_val_type.dart';
import 'xdr_u_int128_parts.dart';
import 'xdr_u_int256_parts.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrSCVal extends XdrSCValBase {
  XdrSCVal(super.type);

  static void encode(XdrDataOutputStream stream, XdrSCVal val) {
    XdrSCValBase.encode(stream, val);
  }

  static XdrSCVal decode(XdrDataInputStream stream) {
    return XdrSCValBase.decodeAs(stream, XdrSCVal.new);
  }

  static XdrSCVal fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrSCValBase.fromTxRep(map, prefix);
    var result = XdrSCVal(b.discriminant);
    result.b = b.b;
    result.error = b.error;
    result.u32 = b.u32;
    result.i32 = b.i32;
    result.u64 = b.u64;
    result.i64 = b.i64;
    result.timepoint = b.timepoint;
    result.duration = b.duration;
    result.u128 = b.u128;
    result.i128 = b.i128;
    result.u256 = b.u256;
    result.i256 = b.i256;
    result.bytes = b.bytes;
    result.str = b.str;
    result.sym = b.sym;
    result.vec = b.vec;
    result.map = b.map;
    result.address = b.address;
    result.instance = b.instance;
    result.nonce_key = b.nonce_key;
    result.executableTag = b.executableTag;
    return result;
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

  static XdrSCVal forU64(BigInt value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U64);
    val.u64 = XdrUint64(value);
    return val;
  }

  static XdrSCVal forI64(BigInt value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I64);
    val.i64 = XdrInt64(value);
    return val;
  }

  static XdrSCVal forTimepoint(BigInt value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_TIMEPOINT);
    val.timepoint = XdrUint64(value);
    return val;
  }

  static XdrSCVal forDuration(BigInt value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_DURATION);
    val.duration = XdrUint64(value);
    return val;
  }

  static XdrSCVal forU128(XdrUInt128Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U128);
    val.u128 = value;
    return val;
  }

  static XdrSCVal forU128Parts(BigInt hi, BigInt lo) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U128);
    val.u128 = XdrUInt128Parts.forHiLo(hi, lo);
    return val;
  }

  static XdrSCVal forI128(XdrInt128Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I128);
    val.i128 = value;
    return val;
  }

  static XdrSCVal forI128Parts(BigInt hi, BigInt lo) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I128);
    val.i128 = XdrInt128Parts.forHiLo(hi, lo);
    return val;
  }

  static XdrSCVal forU256(XdrUInt256Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U256);
    val.u256 = value;
    return val;
  }

  static XdrSCVal forU256Parts(
    BigInt hiHi,
    BigInt hiLo,
    BigInt loHi,
    BigInt loLo,
  ) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U256);
    val.u256 = XdrUInt256Parts.forHiHiHiLoLoHiLoLo(hiHi, hiLo, loHi, loLo);
    return val;
  }

  static XdrSCVal forI256(XdrInt256Parts value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I256);
    val.i256 = value;
    return val;
  }

  static XdrSCVal forI256Parts(
    BigInt hiHi,
    BigInt hiLo,
    BigInt loHi,
    BigInt loLo,
  ) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I256);
    val.i256 = XdrInt256Parts.forHiHiHiLoLoHiLoLo(hiHi, hiLo, loHi, loLo);
    return val;
  }

  static XdrSCVal forBytes(Uint8List value) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_BYTES);
    val.bytes = XdrSCBytes(value);
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

  static XdrSCVal forMuxedAccountAddress(String muxedAccountId) {
    final address = Address.forMuxedAccountId(muxedAccountId);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ADDRESS);
    val.address = address.toXdr();
    return val;
  }

  static XdrSCVal forClaimableBalanceAddress(String claimableBalanceId) {
    final address = Address.forClaimableBalanceId(claimableBalanceId);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ADDRESS);
    val.address = address.toXdr();
    return val;
  }

  static XdrSCVal forLiquidityPoolAddress(String liquidityPoolId) {
    final address = Address.forLiquidityPoolId(liquidityPoolId);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_ADDRESS);
    val.address = address.toXdr();
    return val;
  }

  static XdrSCVal forAddressStrKey(String address) {
    if (StrKey.isValidStellarAccountId(address)) {
      return XdrSCVal.forAccountAddress(address);
    } else if (StrKey.isValidContractId(address)) {
      return XdrSCVal.forContractAddress(address);
    } else if (StrKey.isValidStellarMuxedAccountId(address)) {
      return XdrSCVal.forMuxedAccountAddress(address);
    } else if (StrKey.isValidClaimableBalanceId(address)) {
      return XdrSCVal.forClaimableBalanceAddress(address);
    } else if (StrKey.isValidLiquidityPoolId(address)) {
      return XdrSCVal.forLiquidityPoolAddress(address);
    }
    throw Exception("Unknown StrKey address type: $address");
  }

  static XdrSCVal forNonceKey(XdrSCNonceKey nonceKey) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_LEDGER_KEY_NONCE);
    val.nonce_key = nonceKey;
    return val;
  }

  static XdrSCVal forLedgerKeyNonce(int nonce) {
    return XdrSCVal.forNonceKey(XdrSCNonceKey(XdrInt64(BigInt.from(nonce))));
  }

  static XdrSCVal forContractInstance(XdrSCContractInstance instance) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_CONTRACT_INSTANCE);
    val.instance = instance;
    return val;
  }

  static XdrSCVal forLedgerKeyContractInstance() {
    return XdrSCVal(XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE);
  }

  /// Builds an SCV_EXECUTABLE_TAG value over the raw bytes of [executableTag].
  ///
  /// An executable tag is an XDR string, which carries arbitrary bytes. A tag
  /// read off the ledger is matched byte for byte, so a lookup key built from
  /// it is built from its bytes.
  static XdrSCVal forExecutableTagBytes(Uint8List executableTag) {
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_EXECUTABLE_TAG);
    val.executableTag = executableTag;
    return val;
  }

  /// Builds an SCV_EXECUTABLE_TAG value over the UTF-8 encoding of
  /// [executableTag].
  static XdrSCVal forExecutableTag(String executableTag) {
    return forExecutableTagBytes(
      Uint8List.fromList(utf8.encode(executableTag)),
    );
  }

  /// Splits a BigInt into hi/lo 64-bit parts for 128-bit representation.
  /// Returns [hi, lo] as BigInt values (web-safe).
  static List<BigInt> bigInt128Parts(BigInt value) {
    var bytes = _bigIntToFixedBytes(value, 16); // 16 bytes for 128 bits

    // Build hi from first 8 bytes using BigInt (no overflow)
    BigInt hi = BigInt.zero;
    for (int i = 0; i < BitConstants.BYTES_PER_INT64; i++) {
      hi =
          (hi << BitConstants.BITS_PER_BYTE) |
          BigInt.from(bytes[i] & BitConstants.BYTE_MASK);
    }
    // Sign extend if negative (check MSB)
    if ((bytes[0] & 0x80) != 0) {
      hi = hi.toSigned(64);
    }

    // Build lo from last 8 bytes using BigInt (always unsigned)
    BigInt lo = BigInt.zero;
    for (
      int i = BitConstants.BYTES_PER_INT64;
      i < BitConstants.BYTES_PER_INT128;
      i++
    ) {
      lo =
          (lo << BitConstants.BITS_PER_BYTE) |
          BigInt.from(bytes[i] & BitConstants.BYTE_MASK);
    }

    return [hi, lo];
  }

  /// Splits a BigInt into 4 64-bit parts for 256-bit representation.
  /// Returns [hiHi, hiLo, loHi, loLo] as BigInt values (web-safe).
  static List<BigInt> bigInt256Parts(BigInt value) {
    var bytes = _bigIntToFixedBytes(value, BitConstants.BYTES_PER_INT256);

    // hiHi - first 8 bytes, signed for sign extension
    BigInt hiHi = BigInt.zero;
    for (int i = 0; i < BitConstants.BYTES_PER_INT64; i++) {
      hiHi =
          (hiHi << BitConstants.BITS_PER_BYTE) |
          BigInt.from(bytes[i] & BitConstants.BYTE_MASK);
    }
    if ((bytes[0] & 0x80) != 0) {
      hiHi = hiHi.toSigned(64);
    }

    // hiLo - bytes 8-15, unsigned
    BigInt hiLo = BigInt.zero;
    for (
      int i = BitConstants.BYTES_PER_INT64;
      i < BitConstants.BYTES_PER_INT64 * 2;
      i++
    ) {
      hiLo =
          (hiLo << BitConstants.BITS_PER_BYTE) |
          BigInt.from(bytes[i] & BitConstants.BYTE_MASK);
    }

    // loHi - bytes 16-23, unsigned
    BigInt loHi = BigInt.zero;
    for (
      int i = BitConstants.BYTES_PER_INT64 * 2;
      i < BitConstants.BYTES_PER_INT64 * 3;
      i++
    ) {
      loHi =
          (loHi << BitConstants.BITS_PER_BYTE) |
          BigInt.from(bytes[i] & BitConstants.BYTE_MASK);
    }

    // loLo - bytes 24-31, unsigned
    BigInt loLo = BigInt.zero;
    for (
      int i = BitConstants.BYTES_PER_INT64 * 3;
      i < BitConstants.BYTES_PER_INT256;
      i++
    ) {
      loLo =
          (loLo << BitConstants.BITS_PER_BYTE) |
          BigInt.from(bytes[i] & BitConstants.BYTE_MASK);
    }

    return [hiHi, hiLo, loHi, loLo];
  }

  // Helper function to convert BigInt to fixed-size byte array with proper sign extension
  static List<int> _bigIntToFixedBytes(BigInt value, int byteLength) {
    // Get the minimal byte representation
    var bytes = _bigIntToBytes(value);
    var paddedBytes = List<int>.filled(byteLength, 0);

    if (value.isNegative) {
      // For negative numbers, fill with 0xFF for sign extension
      paddedBytes = List<int>.filled(byteLength, BitConstants.BYTE_MASK);
      // Copy the actual bytes to the end
      var startIndex = byteLength - bytes.length;
      if (startIndex < 0) {
        // Value is too large, truncate from the left
        var offset = -startIndex;
        for (int i = 0; i < byteLength; i++) {
          paddedBytes[i] = bytes[offset + i];
        }
      } else {
        for (int i = 0; i < bytes.length; i++) {
          paddedBytes[startIndex + i] = bytes[i];
        }
      }
    } else {
      // For positive numbers, copy to the end (zero-filled by default)
      var startIndex = byteLength - bytes.length;
      if (startIndex < 0) {
        // Value is too large, take rightmost bytes
        var offset = -startIndex;
        for (int i = 0; i < byteLength; i++) {
          paddedBytes[i] = bytes[offset + i];
        }
      } else {
        for (int i = 0; i < bytes.length; i++) {
          paddedBytes[startIndex + i] = bytes[i];
        }
      }
    }

    return paddedBytes;
  }

  // Helper function to convert BigInt to minimal byte array
  static List<int> _bigIntToBytes(BigInt value) {
    if (value == BigInt.zero) {
      return [0];
    }

    List<int> bytes = [];
    BigInt temp = value.abs();

    while (temp > BigInt.zero) {
      bytes.insert(0, temp.remainder(BigInt.from(256)).toInt());
      temp = temp >> 8;
    }

    // Handle negative numbers - add sign bit if needed
    if (value.isNegative) {
      // Convert to two's complement
      bool carry = true;
      for (int i = bytes.length - 1; i >= 0; i--) {
        bytes[i] = (~bytes[i]) & BitConstants.BYTE_MASK;
        if (carry) {
          bytes[i] = (bytes[i] + 1) & BitConstants.BYTE_MASK;
          if (bytes[i] != 0) carry = false;
        }
      }

      // Add sign extension byte if the most significant bit is 0
      if (bytes.isNotEmpty && (bytes[0] & BitConstants.SIGN_BIT_MASK) == 0) {
        bytes.insert(0, BitConstants.BYTE_MASK);
      }
    } else {
      // Add sign extension byte if the most significant bit is 1 (for positive numbers)
      if (bytes.isNotEmpty && (bytes[0] & BitConstants.SIGN_BIT_MASK) != 0) {
        bytes.insert(0, BitConstants.ZERO_FILL);
      }
    }

    return bytes;
  }

  static XdrSCVal forU128BigInt(BigInt value) {
    List<BigInt> hilo = XdrSCVal.bigInt128Parts(value);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U128);
    val.u128 = XdrUInt128Parts.forHiLo(hilo[0], hilo[1]);
    return val;
  }

  static XdrSCVal forI128BigInt(BigInt value) {
    List<BigInt> hilo = XdrSCVal.bigInt128Parts(value);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I128);
    val.i128 = XdrInt128Parts.forHiLo(hilo[0], hilo[1]);
    return val;
  }

  static XdrSCVal forU256BigInt(BigInt value) {
    List<BigInt> parts = XdrSCVal.bigInt256Parts(value);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_U256);
    val.u256 = XdrUInt256Parts.forHiHiHiLoLoHiLoLo(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
    );
    return val;
  }

  static XdrSCVal forI256BigInt(BigInt value) {
    List<BigInt> parts = XdrSCVal.bigInt256Parts(value);
    XdrSCVal val = XdrSCVal(XdrSCValType.SCV_I256);
    val.i256 = XdrInt256Parts.forHiHiHiLoLoHiLoLo(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
    );
    return val;
  }

  // Helper function to convert 128-bit parts back to BigInt
  static BigInt _bigIntFrom128Parts(
    BigInt hi,
    BigInt lo, {
    bool unsigned = false,
  }) {
    // Convert the hi and lo parts to bytes (8 bytes each)
    List<int> hiBytes = _int64ToBytes(hi);
    List<int> loBytes = _int64ToBytes(lo);

    // Combine into 16-byte array
    List<int> fullBytes = List<int>.filled(BitConstants.BYTES_PER_INT128, 0);
    for (int i = 0; i < BitConstants.BYTES_PER_INT64; i++) {
      fullBytes[i] = hiBytes[i];
      fullBytes[i + BitConstants.BYTES_PER_INT64] = loBytes[i];
    }

    return _bigIntFromBytes(fullBytes, unsigned: unsigned);
  }

  // Helper function to convert 256-bit parts back to BigInt
  static BigInt _bigIntFrom256Parts(
    BigInt hihi,
    BigInt hilo,
    BigInt lohi,
    BigInt lolo, {
    bool unsigned = false,
  }) {
    // Convert each part to bytes (8 bytes each)
    List<int> hiHiBytes = _int64ToBytes(hihi);
    List<int> hiLoBytes = _int64ToBytes(hilo);
    List<int> loHiBytes = _int64ToBytes(lohi);
    List<int> loLoBytes = _int64ToBytes(lolo);

    // Combine into 32-byte array
    List<int> fullBytes = List<int>.filled(BitConstants.BYTES_PER_INT256, 0);
    for (int i = 0; i < BitConstants.BYTES_PER_INT64; i++) {
      fullBytes[i] = hiHiBytes[i];
      fullBytes[i + BitConstants.BYTES_PER_INT64] = hiLoBytes[i];
      fullBytes[i + BitConstants.BYTES_PER_INT64 * 2] = loHiBytes[i];
      fullBytes[i + BitConstants.BYTES_PER_INT64 * 3] = loLoBytes[i];
    }

    return _bigIntFromBytes(fullBytes, unsigned: unsigned);
  }

  /// Converts a 64-bit integer to 8 bytes in big-endian format.
  ///
  /// Works for both signed and unsigned int64 values. Uses BigInt internally
  /// for web compatibility where native 64-bit operations are not available.
  static List<int> _int64ToBytes(BigInt value) {
    List<int> bytes = List<int>.filled(BitConstants.BYTES_PER_INT64, 0);

    // Use BigInt for web compatibility (64-bit unsigned conversion)
    BigInt unsignedValue = value.toUnsigned(64);
    for (int i = BitConstants.BYTES_PER_INT64 - 1; i >= 0; i--) {
      bytes[i] = (unsignedValue & BigInt.from(BitConstants.BYTE_MASK)).toInt();
      unsignedValue >>= BitConstants.BITS_PER_BYTE;
    }
    return bytes;
  }

  // Helper function to convert byte array back to BigInt
  static BigInt _bigIntFromBytes(List<int> bytes, {bool unsigned = false}) {
    if (bytes.isEmpty) {
      return BigInt.zero;
    }

    // Check if it's a negative number (most significant bit is 1)
    // For unsigned types, we always treat as positive
    bool isNegative = !unsigned && (bytes[0] & BitConstants.SIGN_BIT_MASK) != 0;

    if (!isNegative) {
      // Positive number - straightforward conversion
      BigInt result = BigInt.zero;
      for (int byte in bytes) {
        result =
            (result << BitConstants.BITS_PER_BYTE) |
            BigInt.from(byte & BitConstants.BYTE_MASK);
      }
      return result;
    } else {
      // Negative number - convert from two's complement
      List<int> workingBytes = List<int>.from(bytes);

      // Convert from two's complement
      bool borrow = true;
      for (int i = workingBytes.length - 1; i >= 0; i--) {
        if (borrow) {
          if (workingBytes[i] == 0) {
            workingBytes[i] = BitConstants.BYTE_MASK;
          } else {
            workingBytes[i] = (workingBytes[i] - 1) & BitConstants.BYTE_MASK;
            borrow = false;
          }
        }
        workingBytes[i] = (~workingBytes[i]) & BitConstants.BYTE_MASK;
      }

      // Convert to positive BigInt
      BigInt result = BigInt.zero;
      for (int byte in workingBytes) {
        result =
            (result << BitConstants.BITS_PER_BYTE) |
            BigInt.from(byte & BitConstants.BYTE_MASK);
      }

      return -result;
    }
  }

  /// Converts this XdrSCVal to BigInt.
  /// Only supports the value types SCV_U128, SCV_I128, SCV_U256 and SCV_I256.
  /// Returns null for unsupported types.
  BigInt? toBigInt() {
    switch (discriminant) {
      case XdrSCValType.SCV_U128:
        if (u128 != null) {
          return _bigIntFrom128Parts(
            u128!.hi.uint64,
            u128!.lo.uint64,
            unsigned: true,
          );
        }
        break;
      case XdrSCValType.SCV_I128:
        if (i128 != null) {
          return _bigIntFrom128Parts(
            i128!.hi.int64,
            i128!.lo.uint64,
            unsigned: false,
          );
        }
        break;
      case XdrSCValType.SCV_U256:
        if (u256 != null) {
          return _bigIntFrom256Parts(
            u256!.hiHi.uint64,
            u256!.hiLo.uint64,
            u256!.loHi.uint64,
            u256!.loLo.uint64,
            unsigned: true,
          );
        }
        break;
      case XdrSCValType.SCV_I256:
        if (i256 != null) {
          return _bigIntFrom256Parts(
            i256!.hiHi.int64,
            i256!.hiLo.uint64,
            i256!.loHi.uint64,
            i256!.loLo.uint64,
            unsigned: false,
          );
        }
        break;
    }
    return null;
  }

  /// Converts this value to a native Dart value on a best-effort basis.
  ///
  /// Every 64-bit-and-wider integer arm (SCV_U64, SCV_I64, SCV_TIMEPOINT,
  /// SCV_DURATION, SCV_U128, SCV_I128, SCV_U256 and SCV_I256) converts to
  /// BigInt rather than int, so the value is exact on every platform this
  /// SDK targets, including Flutter web. SCV_ADDRESS converts to an
  /// [Address]. SCV_MAP converts to a Map whose keys use a narrower
  /// conversion than values: a bytes key becomes a lowercase hex String and
  /// an address key becomes its StrKey String, because Uint8List and
  /// Address have no value equality and so cannot serve as usable map
  /// keys. A Dart int key and a BigInt key holding the same numeric value
  /// are distinct map entries. This method never throws: an arm with no
  /// native representation, an ill-formed payload, or a map with an
  /// unrepresentable or colliding key converts to this XdrSCVal itself,
  /// which a caller can detect with `is XdrSCVal`. The Uint8List returned
  /// for SCV_BYTES is the stored instance, not a copy.
  dynamic toNative() {
    switch (discriminant) {
      case XdrSCValType.SCV_BOOL:
        if (b != null) {
          return b!;
        }
        break;
      case XdrSCValType.SCV_VOID:
        return null;
      case XdrSCValType.SCV_U32:
        if (u32 != null) {
          return u32!.uint32;
        }
        break;
      case XdrSCValType.SCV_I32:
        if (i32 != null) {
          return i32!.int32;
        }
        break;
      case XdrSCValType.SCV_U64:
        if (u64 != null) {
          return u64!.uint64;
        }
        break;
      case XdrSCValType.SCV_I64:
        if (i64 != null) {
          return i64!.int64;
        }
        break;
      case XdrSCValType.SCV_TIMEPOINT:
        if (timepoint != null) {
          return timepoint!.uint64;
        }
        break;
      case XdrSCValType.SCV_DURATION:
        if (duration != null) {
          return duration!.uint64;
        }
        break;
      case XdrSCValType.SCV_U128:
      case XdrSCValType.SCV_I128:
      case XdrSCValType.SCV_U256:
      case XdrSCValType.SCV_I256:
        final BigInt? value = toBigInt();
        if (value != null) {
          return value;
        }
        break;
      case XdrSCValType.SCV_BYTES:
        if (bytes != null) {
          return bytes!.sCBytes;
        }
        break;
      case XdrSCValType.SCV_STRING:
        if (str != null) {
          return str!;
        }
        break;
      case XdrSCValType.SCV_SYMBOL:
        if (sym != null) {
          return sym!;
        }
        break;
      case XdrSCValType.SCV_VEC:
        return (vec ?? const <XdrSCVal>[])
            .map((XdrSCVal e) => e.toNative())
            .toList();
      case XdrSCValType.SCV_MAP:
        return _mapToNative();
      case XdrSCValType.SCV_ADDRESS:
        if (address != null) {
          try {
            return Address.fromXdr(address!);
          } catch (_) {
            return this;
          }
        }
        break;
    }
    return this;
  }

  /// Converts this SCV_MAP value's entries to a native Dart Map.
  ///
  /// A null [map] payload converts to an empty Map. The whole map falls
  /// back to this XdrSCVal itself when a key is unrepresentable (per
  /// [_mapKeyToNative]) or when two entries collide on the same Dart key,
  /// detected by comparing the entry count with the resulting Map's
  /// length.
  dynamic _mapToNative() {
    final List<XdrSCMapEntry>? entries = map;
    if (entries == null) {
      return <dynamic, dynamic>{};
    }
    final Map<dynamic, dynamic> result = <dynamic, dynamic>{};
    for (final XdrSCMapEntry entry in entries) {
      final Object? key = _mapKeyToNative(entry.key);
      if (identical(key, _unrepresentableKey)) {
        return this;
      }
      result[key] = entry.val.toNative();
    }
    if (result.length != entries.length) {
      return this;
    }
    return result;
  }

  /// Sentinel returned by [_mapKeyToNative] for a key with no usable native
  /// map-key representation. `null` is a legitimate key result (the
  /// SCV_VOID key), so the sentinel is checked by identity, not equality.
  static final Object _unrepresentableKey = Object();

  /// Converts [key] to a native Dart map key, or [_unrepresentableKey] when
  /// [key]'s arm, or an ill-formed payload, has no usable native map-key
  /// representation.
  static Object? _mapKeyToNative(XdrSCVal key) {
    switch (key.discriminant) {
      case XdrSCValType.SCV_SYMBOL:
        if (key.sym != null) {
          return key.sym!;
        }
        break;
      case XdrSCValType.SCV_STRING:
        if (key.str != null) {
          return key.str!;
        }
        break;
      case XdrSCValType.SCV_U32:
        if (key.u32 != null) {
          return key.u32!.uint32;
        }
        break;
      case XdrSCValType.SCV_I32:
        if (key.i32 != null) {
          return key.i32!.int32;
        }
        break;
      case XdrSCValType.SCV_U64:
        if (key.u64 != null) {
          return key.u64!.uint64;
        }
        break;
      case XdrSCValType.SCV_I64:
        if (key.i64 != null) {
          return key.i64!.int64;
        }
        break;
      case XdrSCValType.SCV_TIMEPOINT:
        if (key.timepoint != null) {
          return key.timepoint!.uint64;
        }
        break;
      case XdrSCValType.SCV_DURATION:
        if (key.duration != null) {
          return key.duration!.uint64;
        }
        break;
      case XdrSCValType.SCV_U128:
      case XdrSCValType.SCV_I128:
      case XdrSCValType.SCV_U256:
      case XdrSCValType.SCV_I256:
        final BigInt? value = key.toBigInt();
        if (value != null) {
          return value;
        }
        break;
      case XdrSCValType.SCV_BOOL:
        if (key.b != null) {
          return key.b!;
        }
        break;
      case XdrSCValType.SCV_VOID:
        return null;
      case XdrSCValType.SCV_BYTES:
        if (key.bytes != null) {
          return Util.bytesToHex(key.bytes!.sCBytes);
        }
        break;
      case XdrSCValType.SCV_ADDRESS:
        if (key.address != null) {
          try {
            return key.address!.toStrKey();
          } catch (_) {
            return _unrepresentableKey;
          }
        }
        break;
    }
    return _unrepresentableKey;
  }

  static XdrSCVal fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSCVal.decode(XdrDataInputStream(bytes));
  }

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrSCVal.
  ///
  /// Dart does not inherit statics, so this narrows the base class rendering to
  /// this type rather than relying on the one the base declares.
  static XdrSCVal fromXdrJson(String json) =>
      fromXdrJsonValue(XdrJsonHelper.decodeDocument(json, type: 'XdrSCVal'));

  static XdrSCVal fromXdrJsonValue(Object? value) =>
      XdrSCValBase.fromXdrJsonValueAs(value, XdrSCVal.new);
}
