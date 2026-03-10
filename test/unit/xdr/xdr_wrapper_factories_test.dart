// Tests for hand-written wrapper factory methods and helpers.
// These methods are not auto-generated and need dedicated test coverage.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// A valid ED25519 account ID for testing.
final _testAccountId =
    KeyPair.random().accountId;

void main() {
  // =========================================================================
  // XdrSCVal factory methods
  // =========================================================================
  group('XdrSCVal factories', () {
    test('forBool true/false', () {
      var t = XdrSCVal.forBool(true);
      expect(t.discriminant, XdrSCValType.SCV_BOOL);
      expect(t.b, true);
      _roundtrip(t);

      var f = XdrSCVal.forBool(false);
      expect(f.b, false);
      _roundtrip(f);
    });

    test('forVoid', () {
      var v = XdrSCVal.forVoid();
      expect(v.discriminant, XdrSCValType.SCV_VOID);
      _roundtrip(v);
    });

    test('forError', () {
      var err = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      err.contractCode = XdrUint32(42);
      var e = XdrSCVal.forError(err);
      expect(e.discriminant, XdrSCValType.SCV_ERROR);
      expect(e.error!.type, XdrSCErrorType.SCE_CONTRACT);
      _roundtrip(e);
    });

    test('forU32', () {
      var v = XdrSCVal.forU32(42);
      expect(v.discriminant, XdrSCValType.SCV_U32);
      expect(v.u32!.uint32, 42);
      _roundtrip(v);
    });

    test('forI32', () {
      var v = XdrSCVal.forI32(-7);
      expect(v.discriminant, XdrSCValType.SCV_I32);
      expect(v.i32!.int32, -7);
      _roundtrip(v);
    });

    test('forU64', () {
      var v = XdrSCVal.forU64(BigInt.from(999999));
      expect(v.discriminant, XdrSCValType.SCV_U64);
      expect(v.u64!.uint64, BigInt.from(999999));
      _roundtrip(v);
    });

    test('forI64', () {
      var v = XdrSCVal.forI64(BigInt.from(-12345));
      expect(v.discriminant, XdrSCValType.SCV_I64);
      expect(v.i64!.int64, BigInt.from(-12345));
      _roundtrip(v);
    });

    test('forTimepoint', () {
      var v = XdrSCVal.forTimepoint(BigInt.from(1700000000));
      expect(v.discriminant, XdrSCValType.SCV_TIMEPOINT);
      expect(v.timepoint!.uint64, BigInt.from(1700000000));
      _roundtrip(v);
    });

    test('forDuration', () {
      var v = XdrSCVal.forDuration(BigInt.from(3600));
      expect(v.discriminant, XdrSCValType.SCV_DURATION);
      expect(v.duration!.uint64, BigInt.from(3600));
      _roundtrip(v);
    });

    test('forU128', () {
      var parts = XdrUInt128Parts.forHiLo(BigInt.from(1), BigInt.from(2));
      var v = XdrSCVal.forU128(parts);
      expect(v.discriminant, XdrSCValType.SCV_U128);
      expect(v.u128!.hi.uint64, BigInt.from(1));
      expect(v.u128!.lo.uint64, BigInt.from(2));
      _roundtrip(v);
    });

    test('forU128Parts', () {
      var v = XdrSCVal.forU128Parts(BigInt.from(10), BigInt.from(20));
      expect(v.discriminant, XdrSCValType.SCV_U128);
      _roundtrip(v);
    });

    test('forI128', () {
      var parts = XdrInt128Parts.forHiLo(BigInt.from(-1), BigInt.from(0));
      var v = XdrSCVal.forI128(parts);
      expect(v.discriminant, XdrSCValType.SCV_I128);
      _roundtrip(v);
    });

    test('forI128Parts', () {
      var v = XdrSCVal.forI128Parts(BigInt.from(-5), BigInt.from(100));
      expect(v.discriminant, XdrSCValType.SCV_I128);
      _roundtrip(v);
    });

    test('forU256', () {
      var parts = XdrUInt256Parts.forHiHiHiLoLoHiLoLo(
        BigInt.from(1), BigInt.from(2), BigInt.from(3), BigInt.from(4));
      var v = XdrSCVal.forU256(parts);
      expect(v.discriminant, XdrSCValType.SCV_U256);
      _roundtrip(v);
    });

    test('forU256Parts', () {
      var v = XdrSCVal.forU256Parts(
        BigInt.from(1), BigInt.from(2), BigInt.from(3), BigInt.from(4));
      expect(v.discriminant, XdrSCValType.SCV_U256);
      _roundtrip(v);
    });

    test('forI256', () {
      var parts = XdrInt256Parts.forHiHiHiLoLoHiLoLo(
        BigInt.from(-1), BigInt.from(0), BigInt.from(0), BigInt.from(0));
      var v = XdrSCVal.forI256(parts);
      expect(v.discriminant, XdrSCValType.SCV_I256);
      _roundtrip(v);
    });

    test('forI256Parts', () {
      var v = XdrSCVal.forI256Parts(
        BigInt.from(-1), BigInt.from(0), BigInt.from(0), BigInt.from(0));
      expect(v.discriminant, XdrSCValType.SCV_I256);
      _roundtrip(v);
    });

    test('forBytes', () {
      var v = XdrSCVal.forBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(v.discriminant, XdrSCValType.SCV_BYTES);
      expect(v.bytes!.sCBytes, Uint8List.fromList([1, 2, 3, 4]));
      _roundtrip(v);
    });

    test('forString', () {
      var v = XdrSCVal.forString('hello');
      expect(v.discriminant, XdrSCValType.SCV_STRING);
      expect(v.str, 'hello');
      _roundtrip(v);
    });

    test('forSymbol', () {
      var v = XdrSCVal.forSymbol('transfer');
      expect(v.discriminant, XdrSCValType.SCV_SYMBOL);
      expect(v.sym, 'transfer');
      _roundtrip(v);
    });

    test('forVec', () {
      var v = XdrSCVal.forVec([XdrSCVal.forU32(1), XdrSCVal.forU32(2)]);
      expect(v.discriminant, XdrSCValType.SCV_VEC);
      expect(v.vec!.length, 2);
      _roundtrip(v);
    });

    test('forMap', () {
      var entry = XdrSCMapEntry(XdrSCVal.forSymbol('key'), XdrSCVal.forU32(42));
      var v = XdrSCVal.forMap([entry]);
      expect(v.discriminant, XdrSCValType.SCV_MAP);
      expect(v.map!.length, 1);
      _roundtrip(v);
    });

    test('forAddress with XdrSCAddress', () {
      var addr = XdrSCAddress.forAccountId(_testAccountId);
      var v = XdrSCVal.forAddress(addr);
      expect(v.discriminant, XdrSCValType.SCV_ADDRESS);
      _roundtrip(v);
    });

    test('forAccountAddress', () {
      var v = XdrSCVal.forAccountAddress(_testAccountId);
      expect(v.discriminant, XdrSCValType.SCV_ADDRESS);
      _roundtrip(v);
    });

    test('forContractAddress', () {
      var contractId = StrKey.encodeContractId(
          Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var v = XdrSCVal.forContractAddress(contractId);
      expect(v.discriminant, XdrSCValType.SCV_ADDRESS);
      _roundtrip(v);
    });

    test('forAddressStrKey with account', () {
      var v = XdrSCVal.forAddressStrKey(_testAccountId);
      expect(v.discriminant, XdrSCValType.SCV_ADDRESS);
      _roundtrip(v);
    });

    test('forAddressStrKey with contract', () {
      var contractId = StrKey.encodeContractId(
          Uint8List.fromList(List<int>.filled(32, 0xCD)));
      var v = XdrSCVal.forAddressStrKey(contractId);
      expect(v.discriminant, XdrSCValType.SCV_ADDRESS);
      _roundtrip(v);
    });

    test('forNonceKey', () {
      var v = XdrSCVal.forNonceKey(XdrSCNonceKey(XdrInt64(BigInt.from(42))));
      expect(v.discriminant, XdrSCValType.SCV_LEDGER_KEY_NONCE);
      _roundtrip(v);
    });

    test('forLedgerKeyNonce', () {
      var v = XdrSCVal.forLedgerKeyNonce(99);
      expect(v.discriminant, XdrSCValType.SCV_LEDGER_KEY_NONCE);
      _roundtrip(v);
    });

    test('forContractInstance', () {
      var instance = XdrSCContractInstance(
          XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET),
          null);
      var v = XdrSCVal.forContractInstance(instance);
      expect(v.discriminant, XdrSCValType.SCV_CONTRACT_INSTANCE);
      _roundtrip(v);
    });

    test('forLedgerKeyContractInstance', () {
      var v = XdrSCVal.forLedgerKeyContractInstance();
      expect(v.discriminant, XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE);
      _roundtrip(v);
    });

    test('forU128BigInt', () {
      var v = XdrSCVal.forU128BigInt(BigInt.from(1000000));
      expect(v.discriminant, XdrSCValType.SCV_U128);
      _roundtrip(v);
    });

    test('forI128BigInt positive', () {
      var v = XdrSCVal.forI128BigInt(BigInt.from(500));
      expect(v.discriminant, XdrSCValType.SCV_I128);
      _roundtrip(v);
    });

    test('forI128BigInt negative', () {
      var v = XdrSCVal.forI128BigInt(BigInt.from(-999));
      expect(v.discriminant, XdrSCValType.SCV_I128);
      _roundtrip(v);
    });

    test('forU256BigInt', () {
      var v = XdrSCVal.forU256BigInt(BigInt.from(123456789));
      expect(v.discriminant, XdrSCValType.SCV_U256);
      _roundtrip(v);
    });

    test('forI256BigInt negative', () {
      var v = XdrSCVal.forI256BigInt(BigInt.from(-42));
      expect(v.discriminant, XdrSCValType.SCV_I256);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrSCVal BigInt helpers
  // =========================================================================
  group('XdrSCVal BigInt helpers', () {
    test('bigInt128Parts zero', () {
      var parts = XdrSCVal.bigInt128Parts(BigInt.zero);
      expect(parts[0], BigInt.zero);
      expect(parts[1], BigInt.zero);
    });

    test('bigInt128Parts positive', () {
      var parts = XdrSCVal.bigInt128Parts(BigInt.from(1000000));
      // lo should contain 1000000, hi should be 0
      expect(parts[0], BigInt.zero);
      expect(parts[1], BigInt.from(1000000));
    });

    test('bigInt128Parts negative', () {
      var parts = XdrSCVal.bigInt128Parts(BigInt.from(-1));
      expect(parts[0], BigInt.from(-1)); // hi = -1 (sign extended)
      // lo = max uint64
    });

    test('bigInt256Parts zero', () {
      var parts = XdrSCVal.bigInt256Parts(BigInt.zero);
      expect(parts.length, 4);
      for (var p in parts) {
        expect(p, BigInt.zero);
      }
    });

    test('bigInt256Parts positive', () {
      var parts = XdrSCVal.bigInt256Parts(BigInt.from(42));
      expect(parts[0], BigInt.zero); // hiHi
      expect(parts[1], BigInt.zero); // hiLo
      expect(parts[2], BigInt.zero); // loHi
      expect(parts[3], BigInt.from(42)); // loLo
    });

    test('bigInt256Parts negative', () {
      var parts = XdrSCVal.bigInt256Parts(BigInt.from(-1));
      expect(parts[0], BigInt.from(-1)); // hiHi sign extended
    });

    test('toBigInt U128 roundtrip', () {
      var original = BigInt.from(1000000);
      var scVal = XdrSCVal.forU128BigInt(original);
      expect(scVal.toBigInt(), original);
    });

    test('toBigInt I128 positive roundtrip', () {
      var original = BigInt.from(500);
      var scVal = XdrSCVal.forI128BigInt(original);
      expect(scVal.toBigInt(), original);
    });

    test('toBigInt I128 negative roundtrip', () {
      var original = BigInt.from(-999);
      var scVal = XdrSCVal.forI128BigInt(original);
      expect(scVal.toBigInt(), original);
    });

    test('toBigInt U256 roundtrip', () {
      var original = BigInt.from(123456789);
      var scVal = XdrSCVal.forU256BigInt(original);
      expect(scVal.toBigInt(), original);
    });

    test('toBigInt I256 negative roundtrip', () {
      var original = BigInt.from(-42);
      var scVal = XdrSCVal.forI256BigInt(original);
      expect(scVal.toBigInt(), original);
    });

    test('toBigInt unsupported type returns null', () {
      var v = XdrSCVal.forU32(42);
      expect(v.toBigInt(), isNull);
    });
  });

  // =========================================================================
  // XdrSCSpecTypeDef factory methods
  // =========================================================================
  group('XdrSCSpecTypeDef factories', () {
    test('forVal', () {
      var v = XdrSCSpecTypeDef.forVal();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_VAL);
      _roundtrip(v);
    });

    test('forBool', () {
      var v = XdrSCSpecTypeDef.forBool();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_BOOL);
      _roundtrip(v);
    });

    test('forVoid', () {
      var v = XdrSCSpecTypeDef.forVoid();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_VOID);
      _roundtrip(v);
    });

    test('forError', () {
      var v = XdrSCSpecTypeDef.forError();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_ERROR);
      _roundtrip(v);
    });

    test('forU32', () {
      var v = XdrSCSpecTypeDef.forU32();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_U32);
      _roundtrip(v);
    });

    test('forI32', () {
      var v = XdrSCSpecTypeDef.forI32();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_I32);
      _roundtrip(v);
    });

    test('forU64', () {
      var v = XdrSCSpecTypeDef.forU64();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_U64);
      _roundtrip(v);
    });

    test('forI64', () {
      var v = XdrSCSpecTypeDef.forI64();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_I64);
      _roundtrip(v);
    });

    test('forTimepoint', () {
      var v = XdrSCSpecTypeDef.forTimepoint();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT);
      _roundtrip(v);
    });

    test('forDuration', () {
      var v = XdrSCSpecTypeDef.forDuration();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_DURATION);
      _roundtrip(v);
    });

    test('forU128', () {
      var v = XdrSCSpecTypeDef.forU128();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_U128);
      _roundtrip(v);
    });

    test('forI128', () {
      var v = XdrSCSpecTypeDef.forI128();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_I128);
      _roundtrip(v);
    });

    test('forU256', () {
      var v = XdrSCSpecTypeDef.forU256();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_U256);
      _roundtrip(v);
    });

    test('forI256', () {
      var v = XdrSCSpecTypeDef.forI256();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_I256);
      _roundtrip(v);
    });

    test('forBytes', () {
      var v = XdrSCSpecTypeDef.forBytes();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_BYTES);
      _roundtrip(v);
    });

    test('forString', () {
      var v = XdrSCSpecTypeDef.forString();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_STRING);
      _roundtrip(v);
    });

    test('forSymbol', () {
      var v = XdrSCSpecTypeDef.forSymbol();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_SYMBOL);
      _roundtrip(v);
    });

    test('forAddress', () {
      var v = XdrSCSpecTypeDef.forAddress();
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);
      _roundtrip(v);
    });

    test('forOption', () {
      var option = XdrSCSpecTypeOption(XdrSCSpecTypeDef.forU32());
      var v = XdrSCSpecTypeDef.forOption(option);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_OPTION);
      _roundtrip(v);
    });

    test('forResult', () {
      var result = XdrSCSpecTypeResult(
          XdrSCSpecTypeDef.forU32(), XdrSCSpecTypeDef.forError());
      var v = XdrSCSpecTypeDef.forResult(result);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_RESULT);
      _roundtrip(v);
    });

    test('forVec', () {
      var vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef.forU32());
      var v = XdrSCSpecTypeDef.forVec(vec);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_VEC);
      _roundtrip(v);
    });

    test('forMap', () {
      var map = XdrSCSpecTypeMap(
          XdrSCSpecTypeDef.forSymbol(), XdrSCSpecTypeDef.forU32());
      var v = XdrSCSpecTypeDef.forMap(map);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_MAP);
      _roundtrip(v);
    });

    test('forTuple', () {
      var tuple = XdrSCSpecTypeTuple(
          [XdrSCSpecTypeDef.forU32(), XdrSCSpecTypeDef.forBool()]);
      var v = XdrSCSpecTypeDef.forTuple(tuple);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_TUPLE);
      _roundtrip(v);
    });

    test('forBytesN', () {
      var bytesN = XdrSCSpecTypeBytesN(XdrUint32(32));
      var v = XdrSCSpecTypeDef.forBytesN(bytesN);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      _roundtrip(v);
    });

    test('forUdt', () {
      var udt = XdrSCSpecTypeUDT('MyStruct');
      var v = XdrSCSpecTypeDef.forUdt(udt);
      expect(v.discriminant, XdrSCSpecType.SC_SPEC_TYPE_UDT);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrHostFunction factory methods
  // =========================================================================
  group('XdrHostFunction factories', () {
    test('forUploadContractWasm', () {
      var wasm = Uint8List.fromList([0, 97, 115, 109]); // WASM magic
      var v = XdrHostFunction.forUploadContractWasm(wasm);
      expect(v.discriminant, XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM);
      _roundtrip(v);
    });

    test('forCreatingContract', () {
      var addr = XdrSCAddress.forAccountId(_testAccountId);
      var salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var wasmId = '0000000000000000000000000000000000000000000000000000000000000000';
      var v = XdrHostFunction.forCreatingContract(addr, salt, wasmId);
      expect(v.discriminant, XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
      _roundtrip(v);
    });

    test('forCreatingContractV2', () {
      var addr = XdrSCAddress.forAccountId(_testAccountId);
      var salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var wasmId = '0000000000000000000000000000000000000000000000000000000000000000';
      var v = XdrHostFunction.forCreatingContractV2(
          addr, salt, wasmId, [XdrSCVal.forU32(1)]);
      expect(v.discriminant, XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2);
      _roundtrip(v);
    });

    test('forDeploySACWithAsset', () {
      var v = XdrHostFunction.forDeploySACWithAsset(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      expect(v.discriminant, XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
      _roundtrip(v);
    });

    test('forInvokingContractWithArgs', () {
      var args = XdrInvokeContractArgs(
          XdrSCAddress.forAccountId(_testAccountId), 'transfer', []);
      var v = XdrHostFunction.forInvokingContractWithArgs(args);
      expect(v.discriminant, XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrLedgerKey factory methods
  // =========================================================================
  group('XdrLedgerKey factories', () {
    test('forAccountId', () {
      var v = XdrLedgerKey.forAccountId(_testAccountId);
      expect(v.discriminant, XdrLedgerEntryType.ACCOUNT);
      expect(v.getAccountAccountId(), _testAccountId);
      _roundtrip(v);
    });

    test('forTrustLine', () {
      var v = XdrLedgerKey.forTrustLine(
          _testAccountId, XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      expect(v.discriminant, XdrLedgerEntryType.TRUSTLINE);
      expect(v.getTrustlineAccountId(), _testAccountId);
      _roundtrip(v);
    });

    test('forOffer', () {
      var v = XdrLedgerKey.forOffer(_testAccountId, 12345);
      expect(v.discriminant, XdrLedgerEntryType.OFFER);
      expect(v.getOfferSellerId(), _testAccountId);
      expect(v.getOfferOfferId(), 12345);
      _roundtrip(v);
    });

    test('forData', () {
      var v = XdrLedgerKey.forData(_testAccountId, 'mydata');
      expect(v.discriminant, XdrLedgerEntryType.DATA);
      expect(v.getDataAccountId(), _testAccountId);
      _roundtrip(v);
    });

    test('forClaimableBalance', () {
      var hash = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var hexId = '00000000' + hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      var v = XdrLedgerKey.forClaimableBalance(hexId);
      expect(v.discriminant, XdrLedgerEntryType.CLAIMABLE_BALANCE);
      expect(v.getClaimableBalanceId(), isNotNull);
      _roundtrip(v);
    });

    test('forContractData', () {
      var addr = XdrSCAddress.forAccountId(_testAccountId);
      var key = XdrSCVal.forSymbol('counter');
      var v = XdrLedgerKey.forContractData(
          addr, key, XdrContractDataDurability.PERSISTENT);
      expect(v.discriminant, XdrLedgerEntryType.CONTRACT_DATA);
      _roundtrip(v);
    });

    test('forContractCode', () {
      var code = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var v = XdrLedgerKey.forContractCode(code);
      expect(v.discriminant, XdrLedgerEntryType.CONTRACT_CODE);
      _roundtrip(v);
    });

    test('forConfigSetting', () {
      var v = XdrLedgerKey.forConfigSetting(
          XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES);
      expect(v.discriminant, XdrLedgerEntryType.CONFIG_SETTING);
      _roundtrip(v);
    });

    test('forTTL', () {
      var hash = Uint8List.fromList(List<int>.filled(32, 0xCD));
      var v = XdrLedgerKey.forTTL(hash);
      expect(v.discriminant, XdrLedgerEntryType.TTL);
      _roundtrip(v);
    });

    test('fromBase64EncodedXdrString', () {
      var original = XdrLedgerKey.forAccountId(_testAccountId);
      var base64 = original.toBase64EncodedXdrString();
      var decoded = XdrLedgerKey.fromBase64EncodedXdrString(base64);
      expect(decoded.discriminant, XdrLedgerEntryType.ACCOUNT);
    });

    test('balanceID compatibility getter/setter', () {
      var hash = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var hexId = '00000000' + hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      var key = XdrLedgerKey.forClaimableBalance(hexId);
      expect(key.balanceID, isNotNull);
    });
  });

  // =========================================================================
  // XdrSCAddress factory methods
  // =========================================================================
  group('XdrSCAddress factories', () {
    test('forAccountId', () {
      var v = XdrSCAddress.forAccountId(_testAccountId);
      expect(v.discriminant, XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      expect(v.toStrKey(), _testAccountId);
      _roundtrip(v);
    });

    test('forContractId', () {
      var contractId = StrKey.encodeContractId(
          Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var v = XdrSCAddress.forContractId(contractId);
      expect(v.discriminant, XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      expect(v.toStrKey(), contractId);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrContractIDPreimage factory methods
  // =========================================================================
  group('XdrContractIDPreimage factories', () {
    test('forAddress', () {
      var addr = XdrSCAddress.forAccountId(_testAccountId);
      var salt = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var v = XdrContractIDPreimage.forAddress(addr, salt);
      expect(v.discriminant,
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      expect(v.address, isNotNull);
      expect(v.salt, isNotNull);
      _roundtrip(v);
    });

    test('forAsset', () {
      var v = XdrContractIDPreimage.forAsset(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      expect(v.discriminant,
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
      _roundtrip(v);
    });

    test('address getter/setter', () {
      var addr = XdrSCAddress.forAccountId(_testAccountId);
      var preimage = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = addr;
      expect(preimage.address, isNotNull);
    });

    test('salt getter/setter', () {
      var salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var preimage = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.salt = salt;
      expect(preimage.salt, isNotNull);
    });
  });

  // =========================================================================
  // XdrClaimableBalanceID factory methods
  // =========================================================================
  group('XdrClaimableBalanceID factories', () {
    test('forId and claimableBalanceIdString', () {
      var hash = Uint8List.fromList(List<int>.filled(32, 0xAB));
      // claimableBalanceIdString uses 1-byte discriminant prefix (matching StrKey payload format)
      var hashHex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      var expectedHex = '00' + hashHex; // 1-byte V0 discriminant (0) + 32-byte hash
      // forId accepts Horizon format (4-byte prefix) — stringIdToXdrHash takes last 32 bytes
      var horizonHex = '00000000' + hashHex;
      var v = XdrClaimableBalanceID.forId(horizonHex);
      expect(v.discriminant,
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      expect(v.claimableBalanceIdString, expectedHex);
      _roundtrip(v);
    });

    test('forId with StrKey format', () {
      var hash = Uint8List.fromList(List<int>.filled(32, 0xCD));
      var strKey = StrKey.encodeClaimableBalanceId(hash);
      var v = XdrClaimableBalanceID.forId(strKey);
      expect(v.discriminant,
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      // v0 hash should contain the original hash bytes
      expect(v.v0!.hash, hash);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrChangeTrustAsset / XdrTrustlineAsset factory methods
  // =========================================================================
  group('XdrChangeTrustAsset factories', () {
    test('fromXdrAsset native', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var v = XdrChangeTrustAsset.fromXdrAsset(asset);
      expect(v.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
      _roundtrip(v);
    });

    test('fromXdrAsset credit4', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
          Uint8List.fromList([85, 83, 68, 0]),
          XdrAccountID.forAccountId(_testAccountId));
      var v = XdrChangeTrustAsset.fromXdrAsset(asset);
      expect(v.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      _roundtrip(v);
    });
  });

  group('XdrTrustlineAsset factories', () {
    test('fromXdrAsset native', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var v = XdrTrustlineAsset.fromXdrAsset(asset);
      expect(v.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrContractExecutable factory methods
  // =========================================================================
  group('XdrContractExecutable factories', () {
    test('forWasm', () {
      var hash = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var v = XdrContractExecutable.forWasm(hash);
      expect(v.discriminant,
          XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      _roundtrip(v);
    });

    test('forAsset', () {
      var v = XdrContractExecutable.forAsset();
      expect(v.discriminant,
          XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrSorobanAuthorizedFunction factory methods
  // =========================================================================
  group('XdrSorobanAuthorizedFunction factories', () {
    test('forInvokeContractArgs', () {
      var args = XdrInvokeContractArgs(
          XdrSCAddress.forAccountId(_testAccountId), 'transfer', []);
      var v = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);
      expect(v.discriminant,
          XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrSorobanCredentials factory methods
  // =========================================================================
  group('XdrSorobanCredentials factories', () {
    test('forSourceAccount', () {
      var v = XdrSorobanCredentials.forSourceAccount();
      expect(v.discriminant,
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
      _roundtrip(v);
    });

    test('forAddressCredentials', () {
      var creds = XdrSorobanAddressCredentials(
          XdrSCAddress.forAccountId(_testAccountId),
          XdrInt64(BigInt.from(1)),
          XdrUint32(100),
          XdrSCVal.forVoid());
      var v = XdrSorobanCredentials.forAddressCredentials(creds);
      expect(v.discriminant,
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      _roundtrip(v);
    });
  });

  // =========================================================================
  // XdrAccountID / XdrPublicKey factory methods
  // =========================================================================
  group('XdrAccountID factories', () {
    test('forAccountId', () {
      var v = XdrAccountID.forAccountId(_testAccountId);
      expect(v.accountID.discriminant,
          XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      _roundtrip(v);
    });
  });

  group('XdrPublicKey factories', () {
    test('forAccountId', () {
      var v = XdrPublicKey.forAccountId(_testAccountId);
      expect(v.discriminant, XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      expect(v.getEd25519(), isNotNull);
      _roundtrip(v);
    });

    test('getEd25519/setEd25519', () {
      var v = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      v.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))));
      expect(v.getEd25519(), isNotNull);
    });
  });

  // =========================================================================
  // XdrTransactionEnvelope
  // =========================================================================
  group('XdrTransactionEnvelope', () {
    test('toEnvelopeXdrBase64 legacy alias', () {
      // Build a minimal V0 envelope
      var kp = KeyPair.random();
      var account = Account(kp.accountId, BigInt.from(100));
      var builder = TransactionBuilder(account);
      builder.addOperation(
          BumpSequenceOperationBuilder(BigInt.from(200)).build());
      var tx = builder.build();
      tx.sign(kp, Network.TESTNET);
      var envelope = tx.toEnvelopeXdr();

      var base64 = envelope.toBase64EncodedXdrString();
      var legacy = envelope.toEnvelopeXdrBase64();
      expect(legacy, base64);

      var decoded = XdrTransactionEnvelope.fromBase64EncodedXdrString(base64);
      expect(decoded.discriminant, envelope.discriminant);

      var decodedLegacy = XdrTransactionEnvelope.fromEnvelopeXdrString(base64);
      expect(decodedLegacy.discriminant, envelope.discriminant);
    });
  });

  // =========================================================================
  // XdrMuxedAccountMed25519
  // =========================================================================
  group('XdrMuxedAccountMed25519', () {
    test('encodeInverted/decodeInverted roundtrip', () {
      var id = XdrUint64(BigInt.from(12345));
      var ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var original = XdrMuxedAccountMed25519(id, ed25519);

      var output = XdrDataOutputStream();
      XdrMuxedAccountMed25519.encodeInverted(output, original);
      var encoded = Uint8List.fromList(output.bytes);

      var input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccountMed25519.decodeInverted(input);

      expect(decoded.id.uint64, BigInt.from(12345));
      expect(decoded.ed25519.uint256, original.ed25519.uint256);
    });

    test('accountId getter', () {
      var kp = KeyPair.random();
      var id = XdrUint64(BigInt.from(42));
      var ed25519 = XdrUint256(
          Uint8List.fromList(kp.publicKey));
      var med = XdrMuxedAccountMed25519(id, ed25519);
      var accountId = med.accountId;
      expect(accountId, isNotEmpty);
      expect(accountId.startsWith('M'), true);
    });
  });
  // =========================================================================
  // Setter coverage tests — exercise setters on large-field structs
  // =========================================================================
  group('ConfigSettingContractLedgerCostV0 setters', () {
    test('all setters update fields', () {
      var v = XdrConfigSettingContractLedgerCostV0(
        XdrUint32(1), XdrUint32(2), XdrUint32(3), XdrUint32(4),
        XdrUint32(5), XdrUint32(6), XdrUint32(7), XdrUint32(8),
        XdrInt64(BigInt.from(9)), XdrInt64(BigInt.from(10)),
        XdrInt64(BigInt.from(11)), XdrInt64(BigInt.from(12)),
        XdrInt64(BigInt.from(13)), XdrInt64(BigInt.from(14)),
        XdrUint32(15),
      );
      // Exercise every setter
      v.ledgerMaxDiskReadEntries = XdrUint32(100);
      v.ledgerMaxDiskReadBytes = XdrUint32(200);
      v.ledgerMaxWriteLedgerEntries = XdrUint32(300);
      v.ledgerMaxWriteBytes = XdrUint32(400);
      v.txMaxDiskReadEntries = XdrUint32(500);
      v.txMaxDiskReadBytes = XdrUint32(600);
      v.txMaxWriteLedgerEntries = XdrUint32(700);
      v.txMaxWriteBytes = XdrUint32(800);
      v.feeDiskReadLedgerEntry = XdrInt64(BigInt.from(900));
      v.feeWriteLedgerEntry = XdrInt64(BigInt.from(1000));
      v.feeDiskRead1KB = XdrInt64(BigInt.from(1100));
      v.sorobanStateTargetSizeBytes = XdrInt64(BigInt.from(1200));
      v.rentFee1KBSorobanStateSizeLow = XdrInt64(BigInt.from(1300));
      v.rentFee1KBSorobanStateSizeHigh = XdrInt64(BigInt.from(1400));
      v.sorobanStateRentFeeGrowthFactor = XdrUint32(1500);
      expect(v.ledgerMaxDiskReadEntries.uint32, 100);
      expect(v.sorobanStateRentFeeGrowthFactor.uint32, 1500);
      _roundtrip(v);
    });
  });

  group('PeerStats setters', () {
    test('all setters update fields', () {
      var nodeId = XdrNodeID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)
        ..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))));
      var v = XdrPeerStats(
        nodeId, 'v20',
        XdrUint64(BigInt.zero), XdrUint64(BigInt.zero),
        XdrUint64(BigInt.zero), XdrUint64(BigInt.zero),
        XdrUint64(BigInt.zero), XdrUint64(BigInt.zero),
        XdrUint64(BigInt.zero), XdrUint64(BigInt.zero),
        XdrUint64(BigInt.zero), XdrUint64(BigInt.zero),
        XdrUint64(BigInt.zero), XdrUint64(BigInt.zero),
        XdrUint64(BigInt.zero),
      );
      v.id = XdrNodeID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)
        ..ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCD))));
      v.versionStr = 'v21';
      v.messagesRead = XdrUint64(BigInt.from(1));
      v.messagesWritten = XdrUint64(BigInt.from(2));
      v.bytesRead = XdrUint64(BigInt.from(3));
      v.bytesWritten = XdrUint64(BigInt.from(4));
      v.secondsConnected = XdrUint64(BigInt.from(5));
      v.uniqueFloodBytesRecv = XdrUint64(BigInt.from(6));
      v.duplicateFloodBytesRecv = XdrUint64(BigInt.from(7));
      v.uniqueFetchBytesRecv = XdrUint64(BigInt.from(8));
      v.duplicateFetchBytesRecv = XdrUint64(BigInt.from(9));
      v.uniqueFloodMessageRecv = XdrUint64(BigInt.from(10));
      v.duplicateFloodMessageRecv = XdrUint64(BigInt.from(11));
      v.uniqueFetchMessageRecv = XdrUint64(BigInt.from(12));
      v.duplicateFetchMessageRecv = XdrUint64(BigInt.from(13));
      expect(v.messagesRead.uint64, BigInt.from(1));
      _roundtrip(v);
    });
  });

  group('TimeSlicedNodeData setters', () {
    test('all setters update fields', () {
      var v = XdrTimeSlicedNodeData(
        XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrUint32(0),
        XdrUint32(0), XdrUint32(0), XdrUint32(0), false,
        XdrUint32(0), XdrUint32(0),
      );
      v.addedAuthenticatedPeers = XdrUint32(1);
      v.droppedAuthenticatedPeers = XdrUint32(2);
      v.totalInboundPeerCount = XdrUint32(3);
      v.totalOutboundPeerCount = XdrUint32(4);
      v.p75SCPFirstToSelfLatencyMs = XdrUint32(5);
      v.p75SCPSelfToOtherLatencyMs = XdrUint32(6);
      v.lostSyncCount = XdrUint32(7);
      v.isValidator = true;
      v.maxInboundPeerCount = XdrUint32(8);
      v.maxOutboundPeerCount = XdrUint32(9);
      expect(v.addedAuthenticatedPeers.uint32, 1);
      expect(v.isValidator, true);
      _roundtrip(v);
    });
  });

  group('StateArchivalSettings setters', () {
    test('all setters update fields', () {
      var v = XdrStateArchivalSettings(
        XdrUint32(0), XdrUint32(0), XdrUint32(0), XdrInt64(BigInt.zero),
        XdrInt64(BigInt.zero), XdrUint32(0), XdrUint32(0), XdrUint32(0),
        XdrUint32(0), XdrUint32(0),
      );
      v.maxEntryTTL = XdrUint32(100);
      v.minTemporaryTTL = XdrUint32(200);
      v.minPersistentTTL = XdrUint32(300);
      v.persistentRentRateDenominator = XdrInt64(BigInt.from(400));
      v.tempRentRateDenominator = XdrInt64(BigInt.from(500));
      v.maxEntriesToArchive = XdrUint32(600);
      v.liveSorobanStateSizeWindowSampleSize = XdrUint32(700);
      v.liveSorobanStateSizeWindowSamplePeriod = XdrUint32(800);
      v.evictionScanSize = XdrUint32(900);
      v.startingEvictionScanLevel = XdrUint32(1000);
      expect(v.maxEntryTTL.uint32, 100);
      _roundtrip(v);
    });
  });
}

/// Helper: encode to base64 and decode back — verifies roundtrip works.
void _roundtrip(dynamic val) {
  var base64 = val.toBase64EncodedXdrString();
  expect(base64, isNotEmpty);
}
