// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrContractCostType {
  final _value;
  const XdrContractCostType._internal(this._value);
  toString() => 'ContractCostType.$_value';

  XdrContractCostType(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrContractCostType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  // Cost of running 1 wasm instruction
  static const WasmInsnExec = const XdrContractCostType._internal(0);

  // Cost of allocating a slice of memory (in bytes)
  static const MemAlloc = const XdrContractCostType._internal(1);

  // Cost of copying a slice of bytes into a pre-allocated memory
  static const MemCpy = const XdrContractCostType._internal(2);

  // Cost of comparing two slices of memory
  static const MemCmp = const XdrContractCostType._internal(3);

  // Cost of a host function dispatch, not including the actual work done by
  // the function nor the cost of VM invocation machinary
  static const DispatchHostFunction = const XdrContractCostType._internal(4);

  // Cost of visiting a host object from the host object storage. Exists to
  // make sure some baseline cost coverage, i.e. repeatly visiting objects
  // by the guest will always incur some charges.
  static const VisitObject = const XdrContractCostType._internal(5);

  // Cost of serializing an xdr object to bytes
  static const ValSer = const XdrContractCostType._internal(6);

  // Cost of deserializing an xdr object from bytes
  static const ValDeser = const XdrContractCostType._internal(7);

  // Cost of computing the sha256 hash from bytes
  static const ComputeSha256Hash = const XdrContractCostType._internal(8);

  // Cost of computing the ed25519 pubkey from bytes
  static const ComputeEd25519PubKey = const XdrContractCostType._internal(9);

  // Cost of verifying ed25519 signature of a payload.
  static const VerifyEd25519Sig = const XdrContractCostType._internal(10);

  // Cost of instantiation a VM from wasm bytes code.
  static const VmInstantiation = const XdrContractCostType._internal(11);

  // Cost of instantiation a VM from a cached state.
  static const VmCachedInstantiation = const XdrContractCostType._internal(12);

  // Cost of invoking a function on the VM. If the function is a host function,
  // additional cost will be covered by `DispatchHostFunction`.
  static const InvokeVmFunction = const XdrContractCostType._internal(13);

  // Cost of computing a keccak256 hash from bytes.
  static const ComputeKeccak256Hash = const XdrContractCostType._internal(14);

  // Cost of decoding an ECDSA signature computed from a 256-bit prime modulus
  // curve (e.g. secp256k1 and secp256r1)
  static const DecodeEcdsaCurve256Sig = const XdrContractCostType._internal(15);

  // Cost of recovering an ECDSA secp256k1 key from a signature.
  static const RecoverEcdsaSecp256k1Key =
      const XdrContractCostType._internal(16);

  // Cost of int256 addition (`+`) and subtraction (`-`) operations
  static const Int256AddSub = const XdrContractCostType._internal(17);

  // Cost of int256 multiplication (`*`) operation
  static const Int256Mul = const XdrContractCostType._internal(18);

  // Cost of int256 division (`/`) operation
  static const Int256Div = const XdrContractCostType._internal(19);

  // Cost of int256 power (`exp`) operation
  static const Int256Pow = const XdrContractCostType._internal(20);

  // Cost of int256 shift (`shl`, `shr`) operation
  static const Int256Shift = const XdrContractCostType._internal(21);

  // Cost of drawing random bytes using a ChaCha20 PRNG
  static const ChaCha20DrawBytes = const XdrContractCostType._internal(22);

  // Cost of parsing wasm bytes that only encode instructions.
  static const ParseWasmInstructions = const XdrContractCostType._internal(23);

  // Cost of parsing a known number of wasm functions.
  static const ParseWasmFunctions = const XdrContractCostType._internal(24);

  // Cost of parsing a known number of wasm globals.
  static const ParseWasmGlobals = const XdrContractCostType._internal(25);

  // Cost of parsing a known number of wasm table entries.
  static const ParseWasmTableEntries = const XdrContractCostType._internal(26);

  // Cost of parsing a known number of wasm types.
  static const ParseWasmTypes = const XdrContractCostType._internal(27);

  // Cost of parsing a known number of wasm data segments.
  static const ParseWasmDataSegments = const XdrContractCostType._internal(28);

  // Cost of parsing a known number of wasm element segments.
  static const ParseWasmElemSegments = const XdrContractCostType._internal(29);

  // Cost of parsing a known number of wasm imports.
  static const ParseWasmImports = const XdrContractCostType._internal(30);

  // Cost of parsing a known number of wasm exports.
  static const ParseWasmExports = const XdrContractCostType._internal(31);

  // Cost of parsing a known number of data segment bytes.
  static const ParseWasmDataSegmentBytes =
      const XdrContractCostType._internal(32);

  // Cost of instantiating wasm bytes that only encode instructions.
  static const InstantiateWasmInstructions =
      const XdrContractCostType._internal(33);

  // Cost of instantiating a known number of wasm functions.
  static const InstantiateWasmFunctions =
      const XdrContractCostType._internal(34);

  // Cost of instantiating a known number of wasm globals.
  static const InstantiateWasmGlobals = const XdrContractCostType._internal(35);

  // Cost of instantiating a known number of wasm table entries.
  static const InstantiateWasmTableEntries =
      const XdrContractCostType._internal(36);

  // Cost of instantiating a known number of wasm types.
  static const InstantiateWasmTypes = const XdrContractCostType._internal(37);

  // Cost of instantiating a known number of wasm data segments.
  static const InstantiateWasmDataSegments =
      const XdrContractCostType._internal(38);

  // Cost of instantiating a known number of wasm element segments.
  static const InstantiateWasmElemSegments =
      const XdrContractCostType._internal(39);

  // Cost of instantiating a known number of wasm imports.
  static const InstantiateWasmImports = const XdrContractCostType._internal(40);

  // Cost of instantiating a known number of wasm exports.
  static const InstantiateWasmExports = const XdrContractCostType._internal(41);

  // Cost of instantiating a known number of data segment bytes.
  static const InstantiateWasmDataSegmentBytes =
      const XdrContractCostType._internal(42);

  // Cost of decoding a bytes array representing an uncompressed SEC-1 encoded point on a 256-bit elliptic curve
  static const Sec1DecodePointUncompressed =
      const XdrContractCostType._internal(43);

  // Cost of verifying an ECDSA Secp256r1 signature
  static const VerifyEcdsaSecp256r1Sig =
      const XdrContractCostType._internal(44);

  // Cost of encoding a BLS12-381 Fp (base field element)
  static const Bls12381EncodeFp = const XdrContractCostType._internal(45);

  // Cost of decoding a BLS12-381 Fp (base field element)
  static const Bls12381DecodeFp = const XdrContractCostType._internal(46);

  // Cost of checking a G1 point lies on the curve
  static const Bls12381G1CheckPointOnCurve =
      const XdrContractCostType._internal(47);

  // Cost of checking a G1 point belongs to the correct subgroup
  static const Bls12381G1CheckPointInSubgroup =
      const XdrContractCostType._internal(48);

  // Cost of checking a G2 point lies on the curve
  static const Bls12381G2CheckPointOnCurve =
      const XdrContractCostType._internal(49);

  // Cost of checking a G2 point belongs to the correct subgroup
  static const Bls12381G2CheckPointInSubgroup =
      const XdrContractCostType._internal(50);

  // Cost of converting a BLS12-381 G1 point from projective to affine coordinates
  static const Bls12381G1ProjectiveToAffine =
      const XdrContractCostType._internal(51);

  // Cost of converting a BLS12-381 G2 point from projective to affine coordinates
  static const Bls12381G2ProjectiveToAffine =
      const XdrContractCostType._internal(52);

  // Cost of performing BLS12-381 G1 point addition
  static const Bls12381G1Add = const XdrContractCostType._internal(53);

  // Cost of performing BLS12-381 G1 scalar multiplication
  static const Bls12381G1Mul = const XdrContractCostType._internal(54);

  // Cost of performing BLS12-381 G1 multi-scalar multiplication (MSM)
  static const Bls12381G1Msm = const XdrContractCostType._internal(55);

  // Cost of mapping a BLS12-381 Fp field element to a G1 point
  static const Bls12381MapFpToG1 = const XdrContractCostType._internal(56);

  // Cost of hashing to a BLS12-381 G1 point
  static const Bls12381HashToG1 = const XdrContractCostType._internal(57);

  // Cost of performing BLS12-381 G2 point addition
  static const Bls12381G2Add = const XdrContractCostType._internal(58);

  // Cost of performing BLS12-381 G2 scalar multiplication
  static const Bls12381G2Mul = const XdrContractCostType._internal(59);

  // Cost of performing BLS12-381 G2 multi-scalar multiplication (MSM)
  static const Bls12381G2Msm = const XdrContractCostType._internal(60);

  // Cost of mapping a BLS12-381 Fp2 field element to a G2 point
  static const Bls12381MapFp2ToG2 = const XdrContractCostType._internal(61);

  // Cost of hashing to a BLS12-381 G2 point
  static const Bls12381HashToG2 = const XdrContractCostType._internal(62);

  // Cost of performing BLS12-381 pairing operation
  static const Bls12381Pairing = const XdrContractCostType._internal(63);

  // Cost of converting a BLS12-381 scalar element from U256
  static const Bls12381FrFromU256 = const XdrContractCostType._internal(64);

  // Cost of converting a BLS12-381 scalar element to U256
  static const Bls12381FrToU256 = const XdrContractCostType._internal(65);

  // Cost of performing BLS12-381 scalar element addition/subtraction
  static const Bls12381FrAddSub = const XdrContractCostType._internal(66);

  // Cost of performing BLS12-381 scalar element multiplication
  static const Bls12381FrMul = const XdrContractCostType._internal(67);

  // Cost of performing BLS12-381 scalar element exponentiation
  static const Bls12381FrPow = const XdrContractCostType._internal(68);

  // Cost of performing BLS12-381 scalar element inversion
  static const Bls12381FrInv = const XdrContractCostType._internal(69);

  static XdrContractCostType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return WasmInsnExec;
      case 1:
        return MemAlloc;
      case 2:
        return MemCpy;
      case 3:
        return MemCmp;
      case 4:
        return DispatchHostFunction;
      case 5:
        return VisitObject;
      case 6:
        return ValSer;
      case 7:
        return ValDeser;
      case 8:
        return ComputeSha256Hash;
      case 9:
        return ComputeEd25519PubKey;
      case 10:
        return VerifyEd25519Sig;
      case 11:
        return VmInstantiation;
      case 12:
        return VmCachedInstantiation;
      case 13:
        return InvokeVmFunction;
      case 14:
        return ComputeKeccak256Hash;
      case 15:
        return DecodeEcdsaCurve256Sig;
      case 16:
        return RecoverEcdsaSecp256k1Key;
      case 17:
        return Int256AddSub;
      case 18:
        return Int256Mul;
      case 19:
        return Int256Div;
      case 20:
        return Int256Pow;
      case 21:
        return Int256Shift;
      case 22:
        return ChaCha20DrawBytes;
      case 23:
        return ParseWasmInstructions;
      case 24:
        return ParseWasmFunctions;
      case 25:
        return ParseWasmGlobals;
      case 26:
        return ParseWasmTableEntries;
      case 27:
        return ParseWasmTypes;
      case 28:
        return ParseWasmDataSegments;
      case 29:
        return ParseWasmElemSegments;
      case 30:
        return ParseWasmImports;
      case 31:
        return ParseWasmExports;
      case 32:
        return ParseWasmDataSegmentBytes;
      case 33:
        return InstantiateWasmInstructions;
      case 34:
        return InstantiateWasmFunctions;
      case 35:
        return InstantiateWasmGlobals;
      case 36:
        return InstantiateWasmTableEntries;
      case 37:
        return InstantiateWasmTypes;
      case 38:
        return InstantiateWasmDataSegments;
      case 39:
        return InstantiateWasmElemSegments;
      case 40:
        return InstantiateWasmImports;
      case 41:
        return InstantiateWasmExports;
      case 42:
        return InstantiateWasmDataSegmentBytes;
      case 43:
        return Sec1DecodePointUncompressed;
      case 44:
        return VerifyEcdsaSecp256r1Sig;
      case 45:
        return Bls12381EncodeFp;
      case 46:
        return Bls12381DecodeFp;
      case 47:
        return Bls12381G1CheckPointOnCurve;
      case 48:
        return Bls12381G1CheckPointInSubgroup;
      case 49:
        return Bls12381G2CheckPointOnCurve;
      case 50:
        return Bls12381G2CheckPointInSubgroup;
      case 51:
        return Bls12381G1ProjectiveToAffine;
      case 52:
        return Bls12381G2ProjectiveToAffine;
      case 53:
        return Bls12381G1Add;
      case 54:
        return Bls12381G1Mul;
      case 55:
        return Bls12381G1Msm;
      case 56:
        return Bls12381MapFpToG1;
      case 57:
        return Bls12381HashToG1;
      case 58:
        return Bls12381G2Add;
      case 59:
        return Bls12381G2Mul;
      case 60:
        return Bls12381G2Msm;
      case 61:
        return Bls12381MapFp2ToG2;
      case 62:
        return Bls12381HashToG2;
      case 63:
        return Bls12381Pairing;
      case 64:
        return Bls12381FrFromU256;
      case 65:
        return Bls12381FrToU256;
      case 66:
        return Bls12381FrAddSub;
      case 67:
        return Bls12381FrMul;
      case 68:
        return Bls12381FrPow;
      case 69:
        return Bls12381FrInv;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrContractCostType value) {
    stream.writeInt(value.value);
  }
}
