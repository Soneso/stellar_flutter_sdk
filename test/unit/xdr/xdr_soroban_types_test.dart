// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Final Coverage - Uncovered Lines', () {

    // xdr_contract.dart line 100 - toString for enum unknown value
    test('XdrSCValType toString method', () {
      var type = XdrSCValType.SCV_BOOL;
      expect(type.toString(), contains('SCValType'));
    });

    // xdr_contract.dart lines 214-215, 231, 244 - toString methods
    test('XdrSorobanCredentialsType toString', () {
      var type = XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT;
      expect(type.toString(), contains('SorobanCredentialsType'));
    });

    test('XdrSorobanCredentials type setter', () {
      var creds = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
      creds.type = XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS;
      expect(creds.type,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
    });

    test('XdrSorobanCredentials address setter', () {
      var creds = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      var addressCreds = XdrSorobanAddressCredentials(
          XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT),
          XdrInt64(BigInt.from(12345)),
          XdrUint32(100),
          XdrSCVal(XdrSCValType.SCV_VOID));
      creds.address = addressCreds;
      expect(creds.address, equals(addressCreds));
    });

    // xdr_contract.dart line 475 - Exception path in forAccountId
    test('XdrSCAddress forAccountId with invalid account throws', () {
      expect(() => XdrSCAddress.forAccountId('invalid'),
          throwsA(isA<Exception>()));
    });

    test('XdrSCAddress forClaimableBalanceId', () {
      var balanceId = '000000006d6f6e657900000000000000000000000000000000000000000000000000000000';
      var addr = XdrSCAddress.forClaimableBalanceId(balanceId);
      expect(addr.discriminant, equals(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE));
      expect(addr.claimableBalanceId, isNotNull);
    });

    // xdr_contract.dart lines 631-644 - XdrInt256Parts setters
    test('XdrInt256Parts setters', () {
      var parts = XdrInt256Parts(
          XdrInt64(BigInt.one),
          XdrUint64(BigInt.two),
          XdrUint64(BigInt.from(3)),
          XdrUint64(BigInt.from(4)));

      parts.hiHi = XdrInt64(BigInt.from(10));
      parts.hiLo = XdrUint64(BigInt.from(20));
      parts.loHi = XdrUint64(BigInt.from(30));
      parts.loLo = XdrUint64(BigInt.from(40));

      expect(parts.hiHi.int64, equals(BigInt.from(10)));
      expect(parts.hiLo.uint64, equals(BigInt.from(20)));
      expect(parts.loHi.uint64, equals(BigInt.from(30)));
      expect(parts.loLo.uint64, equals(BigInt.from(40)));
    });

    // xdr_contract.dart lines 674-686 - XdrUInt256Parts setters
    test('XdrUInt256Parts setters', () {
      var parts = XdrUInt256Parts(
          XdrUint64(BigInt.one),
          XdrUint64(BigInt.two),
          XdrUint64(BigInt.from(3)),
          XdrUint64(BigInt.from(4)));

      parts.hiHi = XdrUint64(BigInt.from(10));
      parts.hiLo = XdrUint64(BigInt.from(20));
      parts.loHi = XdrUint64(BigInt.from(30));
      parts.loLo = XdrUint64(BigInt.from(40));

      expect(parts.hiHi.uint64, equals(BigInt.from(10)));
      expect(parts.hiLo.uint64, equals(BigInt.from(20)));
      expect(parts.loHi.uint64, equals(BigInt.from(30)));
      expect(parts.loLo.uint64, equals(BigInt.from(40)));
    });

    // xdr_contract.dart lines 1242-1247 - forMuxedAccountAddress
    test('XdrSCVal forMuxedAccountAddress', () {
      var muxedId = 'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6';
      var scVal = XdrSCVal.forMuxedAccountAddress(muxedId);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
      expect(scVal.address, isNotNull);
    });

    test('XdrSCVal forClaimableBalanceAddress', () {
      var balanceId = '000000006d6f6e657900000000000000000000000000000000000000000000000000000000';
      var scVal = XdrSCVal.forClaimableBalanceAddress(balanceId);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
      expect(scVal.address, isNotNull);
    });

    // xdr_contract.dart lines 1256-1261 - forLiquidityPoolAddress
    test('XdrSCVal forLiquidityPoolAddress', () {
      var poolId = '67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9';
      var scVal = XdrSCVal.forLiquidityPoolAddress(poolId);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
      expect(scVal.address, isNotNull);
    });

    // xdr_contract.dart lines 1263-1275 - forAddressStrKey with different types
    test('XdrSCVal forAddressStrKey with stellar account', () {
      var accountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
      var scVal = XdrSCVal.forAddressStrKey(accountId);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
    });

    test('XdrSCVal forAddressStrKey with contract id', () {
      var contractId = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
      var scVal = XdrSCVal.forAddressStrKey(contractId);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
    });

    test('XdrSCVal forAddressStrKey with muxed account', () {
      var muxedId = 'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6';
      var scVal = XdrSCVal.forAddressStrKey(muxedId);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
    });

    test('XdrSCVal forAddressStrKey with invalid throws', () {
      expect(() => XdrSCVal.forAddressStrKey('invalid_address'),
          throwsA(isA<Exception>()));
    });

    // xdr_contract.dart lines 1278-1282 - forNonceKey
    test('XdrSCVal forNonceKey', () {
      var nonceKey = XdrSCNonceKey(XdrInt64(BigInt.from(12345)));
      var scVal = XdrSCVal.forNonceKey(nonceKey);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_LEDGER_KEY_NONCE));
      expect(scVal.nonce_key, equals(nonceKey));
    });

    // xdr_contract.dart lines 1284-1286 - forLedgerKeyNonce
    test('XdrSCVal forLedgerKeyNonce', () {
      var scVal = XdrSCVal.forLedgerKeyNonce(9999);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_LEDGER_KEY_NONCE));
      expect(scVal.nonce_key?.nonce?.int64, equals(BigInt.from(9999)));
    });

    // xdr_contract.dart lines 1288-1292 - forContractInstance
    test('XdrSCVal forContractInstance', () {
      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List(32));
      var instance = XdrSCContractInstance(executable, null);
      var scVal = XdrSCVal.forContractInstance(instance);
      expect(scVal.discriminant, equals(XdrSCValType.SCV_CONTRACT_INSTANCE));
      expect(scVal.instance, equals(instance));
    });

    // xdr_contract.dart lines 1294-1296 - forLedgerKeyContractInstance
    test('XdrSCVal forLedgerKeyContractInstance', () {
      var scVal = XdrSCVal.forLedgerKeyContractInstance();
      expect(scVal.discriminant,
          equals(XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE));
    });

    // xdr_ledger.dart line 181 - XdrClaimPredicate discriminant setter
    test('XdrClaimPredicate discriminant setter', () {
      var predicate = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      predicate.discriminant =
          XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME;
      expect(predicate.discriminant,
          equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
    });

    // xdr_ledger.dart line 333 - XdrClaimant discriminant setter
    test('XdrClaimant discriminant setter', () {
      var claimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      expect(claimant.discriminant, equals(XdrClaimantType.CLAIMANT_TYPE_V0));
    });

    // xdr_ledger.dart line 845 - XdrLedgerHeaderExt discriminant setter
    test('XdrLedgerHeaderExt discriminant setter', () {
      var ext = XdrLedgerHeaderExt(0);
      ext.discriminant = 0;
      expect(ext.discriminant, equals(0));
    });

    // xdr_ledger.dart lines 871, 875, 879 - XdrLedgerKeyContractData setters
    test('XdrLedgerKeyContractData setters', () {
      var contract = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      var key = XdrSCVal(XdrSCValType.SCV_U32);
      var durability = XdrContractDataDurability.TEMPORARY;

      var ledgerKey = XdrLedgerKeyContractData(contract, key, durability);

      var newContract = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      var newKey = XdrSCVal(XdrSCValType.SCV_STRING);
      var newDurability = XdrContractDataDurability.PERSISTENT;

      ledgerKey.contract = newContract;
      ledgerKey.key = newKey;
      ledgerKey.durability = newDurability;

      expect(ledgerKey.contract, equals(newContract));
      expect(ledgerKey.key, equals(newKey));
      expect(ledgerKey.durability, equals(newDurability));
    });

    // xdr_ledger.dart lines 1434-1435, 1441, 1447 - XdrLedgerEntry setters
    test('XdrLedgerEntry setters', () {
      var ledgerSeq = XdrUint32(100);
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var ext = XdrLedgerEntryExt(0);

      var entry = XdrLedgerEntry(ledgerSeq, data, ext);

      var newSeq = XdrUint32(200);
      var newData = XdrLedgerEntryData(XdrLedgerEntryType.TRUSTLINE);
      var newExt = XdrLedgerEntryExt(1);

      entry.lastModifiedLedgerSeq = newSeq;
      entry.data = newData;
      entry.ext = newExt;

      expect(entry.lastModifiedLedgerSeq, equals(newSeq));
      expect(entry.data.discriminant, equals(XdrLedgerEntryType.TRUSTLINE));
      expect(entry.ext.discriminant, equals(1));
    });

    // xdr_ledger.dart lines 1463-1472 - toBase64/fromBase64
    test('XdrLedgerEntry toBase64EncodedXdrString and fromBase64EncodedXdrString', () {
      var ledgerSeq = XdrUint32(12345);
      var accountId = XdrAccountID(KeyPair.random().xdrPublicKey);
      var account = XdrAccountEntry(
          accountId,
          XdrInt64(BigInt.from(1000000)),
          XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
          XdrUint32(0),
          null,
          XdrUint32(0),
          XdrString32('test'),
          XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
          [],
          XdrAccountEntryExt(0));

      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      data.account = account;
      var ext = XdrLedgerEntryExt(0);

      var entry = XdrLedgerEntry(ledgerSeq, data, ext);

      var base64 = entry.toBase64EncodedXdrString();
      expect(base64, isNotEmpty);

      var decoded = XdrLedgerEntry.fromBase64EncodedXdrString(base64);
      expect(decoded.lastModifiedLedgerSeq.uint32, equals(12345));
    });

    // xdr_ledger.dart line 1480 - XdrLedgerEntryData discriminant setter
    test('XdrLedgerEntryData discriminant setter', () {
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      data.discriminant = XdrLedgerEntryType.TRUSTLINE;
      expect(data.discriminant, equals(XdrLedgerEntryType.TRUSTLINE));
    });

    // xdr_ledger.dart line 1629 - XdrLedgerEntryExt discriminant setter
    test('XdrLedgerEntryExt discriminant setter', () {
      var ext = XdrLedgerEntryExt(0);
      ext.discriminant = 1;
      expect(ext.discriminant, equals(1));
    });

    // xdr_ledger.dart lines 1677 - XdrLedgerEntryV1 ext setter
    test('XdrLedgerEntryV1 ext setter', () {
      var ext = XdrLedgerEntryV1Ext(0);
      var v1 = XdrLedgerEntryV1(ext);

      var newExt = XdrLedgerEntryV1Ext(0);
      v1.ext = newExt;

      expect(v1.ext, equals(newExt));
    });

    // xdr_ledger.dart lines 1809-1810 - XdrLedgerEntryChanges setter
    test('XdrLedgerEntryChanges setter', () {
      var change1 = XdrLedgerEntryChange(
          XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      var changes = XdrLedgerEntryChanges([change1]);

      var change2 = XdrLedgerEntryChange(
          XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED);
      changes.ledgerEntryChanges = [change2];

      expect(changes.ledgerEntryChanges.length, equals(1));
      expect(changes.ledgerEntryChanges[0].discriminant,
          equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED));
    });

    // xdr_ledger.dart lines 1835, 1838-1842 - Base64 methods
    test('XdrLedgerEntryChanges toBase64 and fromBase64', () {
      var change = XdrLedgerEntryChange(
          XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED);
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(
          XdrAccountID(KeyPair.random().xdrPublicKey));
      change.removed = ledgerKey;

      var changes = XdrLedgerEntryChanges([change]);

      var base64 = changes.toBase64EncodedXdrString();
      expect(base64, isNotEmpty);

      var decoded = XdrLedgerEntryChanges.fromBase64EncodedXdrString(base64);
      expect(decoded.ledgerEntryChanges.length, equals(1));
    });

    // xdr_ledger.dart lines 1852, 1858, 1864 - XdrLedgerHeaderHistoryEntry setters
    test('XdrLedgerHeaderHistoryEntry setters', () {
      var hash = XdrHash(Uint8List(32));
      var skipList = List<XdrHash>.filled(4, XdrHash(Uint8List(32)));
      var stellarValue = XdrStellarValue(XdrHash(Uint8List(32)), XdrUint64(BigInt.zero), [], XdrStellarValueExt(0));
      var header = XdrLedgerHeader(
          XdrUint32(0),
          XdrHash(Uint8List(32)),
          stellarValue,
          XdrHash(Uint8List(32)),
          XdrHash(Uint8List(32)),
          XdrUint32(0),
          XdrInt64(BigInt.zero),
          XdrInt64(BigInt.zero),
          XdrUint32(0),
          XdrUint64(BigInt.zero),
          XdrUint32(0),
          XdrUint32(0),
          XdrUint32(0),
          skipList,
          XdrLedgerHeaderExt(0));
      var ext = XdrLedgerHeaderHistoryEntryExt(0);

      var entry = XdrLedgerHeaderHistoryEntry(hash, header, ext);

      var newHash = XdrHash(Uint8List(32));
      var newSkipList = List<XdrHash>.filled(4, XdrHash(Uint8List(32)));
      var newStellarValue = XdrStellarValue(XdrHash(Uint8List(32)), XdrUint64(BigInt.one), [], XdrStellarValueExt(0));
      var newHeader = XdrLedgerHeader(
          XdrUint32(1),
          XdrHash(Uint8List(32)),
          newStellarValue,
          XdrHash(Uint8List(32)),
          XdrHash(Uint8List(32)),
          XdrUint32(1),
          XdrInt64(BigInt.one),
          XdrInt64(BigInt.one),
          XdrUint32(1),
          XdrUint64(BigInt.one),
          XdrUint32(1),
          XdrUint32(1),
          XdrUint32(1),
          newSkipList,
          XdrLedgerHeaderExt(0));
      var newExt = XdrLedgerHeaderHistoryEntryExt(0);

      entry.hash = newHash;
      entry.header = newHeader;
      entry.ext = newExt;

      expect(entry.hash, equals(newHash));
      expect(entry.header.ledgerVersion.uint32, equals(1));
      expect(entry.ext, equals(newExt));
    });

    // Additional setter coverage tests
    test('XdrClaimPredicate andPredicates setter', () {
      var predicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      var pred1 = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      predicate.andPredicates = [pred1];
      expect(predicate.andPredicates?.length, equals(1));
    });

    test('XdrClaimPredicate orPredicates setter', () {
      var predicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
      var pred1 = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      predicate.orPredicates = [pred1];
      expect(predicate.orPredicates?.length, equals(1));
    });

    test('XdrClaimPredicate notPredicate setter', () {
      var predicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
      var notPred = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      predicate.notPredicate = notPred;
      expect(predicate.notPredicate, equals(notPred));
    });

    test('XdrClaimPredicate absBefore setter', () {
      var predicate = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      predicate.absBefore = XdrInt64(BigInt.from(123456789));
      expect(predicate.absBefore?.int64, equals(BigInt.from(123456789)));
    });

    test('XdrClaimPredicate relBefore setter', () {
      var predicate = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
      predicate.relBefore = XdrInt64(BigInt.from(3600));
      expect(predicate.relBefore?.int64, equals(BigInt.from(3600)));
    });

    test('XdrClaimant v0 setter', () {
      var claimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      var destination = XdrAccountID(KeyPair.random().xdrPublicKey);
      var predicate = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var v0 = XdrClaimantV0(destination, predicate);
      claimant.v0 = v0;
      expect(claimant.v0, equals(v0));
    });

    test('XdrLedgerEntryV1 sponsoringID setter', () {
      var ext = XdrLedgerEntryV1Ext(0);
      var v1 = XdrLedgerEntryV1(ext);
      var sponsorId = XdrAccountID(KeyPair.random().xdrPublicKey);
      v1.sponsoringID = sponsorId;
      expect(v1.sponsoringID, equals(sponsorId));
    });

    test('XdrLedgerEntryExt with v1 extension', () {
      var v1Ext = XdrLedgerEntryV1Ext(0);
      var v1 = XdrLedgerEntryV1(v1Ext);
      var ext = XdrLedgerEntryExt(1);
      ext.ledgerEntryExtensionV1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryExt.encode(output, ext);

      XdrDataInputStream input = XdrDataInputStream(
          Uint8List.fromList(output.bytes));
      var decoded = XdrLedgerEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.ledgerEntryExtensionV1, isNotNull);
    });

    // Test Int128Parts and UInt128Parts setters
    test('XdrInt128Parts setters', () {
      var parts = XdrInt128Parts(XdrInt64(BigInt.one), XdrUint64(BigInt.two));
      parts.hi = XdrInt64(BigInt.from(100));
      parts.lo = XdrUint64(BigInt.from(200));
      expect(parts.hi.int64, equals(BigInt.from(100)));
      expect(parts.lo.uint64, equals(BigInt.from(200)));
    });

    test('XdrUInt128Parts setters', () {
      var parts = XdrUInt128Parts(XdrUint64(BigInt.one), XdrUint64(BigInt.two));
      parts.hi = XdrUint64(BigInt.from(100));
      parts.lo = XdrUint64(BigInt.from(200));
      expect(parts.hi.uint64, equals(BigInt.from(100)));
      expect(parts.lo.uint64, equals(BigInt.from(200)));
    });

    // Test SCError type toString
    test('XdrSCErrorType toString', () {
      var errorType = XdrSCErrorType.SCE_CONTRACT;
      expect(errorType.toString(), contains('SCErrorType'));
    });

    // Test SCErrorCode toString
    test('XdrSCErrorCode toString', () {
      var errorCode = XdrSCErrorCode.SCEC_ARITH_DOMAIN;
      expect(errorCode.toString(), contains('SCErrorCod'));
    });
  });

  group('XdrSCValType', () {
    test('constructor and toString', () {
      final type = XdrSCValType(5);
      expect(type.value, 5);
      expect(type.toString(), 'SCValType.5');
    });
  });

  group('XdrSCErrorType', () {
    test('constructor and toString', () {
      final type = XdrSCErrorType(3);
      expect(type.value, 3);
      expect(type.toString(), 'SCErrorType.3');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrSCErrorType.decode(stream), throwsException);
    });
  });

  group('XdrSCErrorCode', () {
    test('constructor and toString', () {
      final type = XdrSCErrorCode(5);
      expect(type.value, 5);
      expect(type.toString(), 'SCErrorCod.5');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrSCErrorCode.decode(stream), throwsException);
    });
  });

  group('XdrSorobanCredentials', () {
    test('forSourceAccount', () {
      final cred = XdrSorobanCredentials.forSourceAccount();
      expect(cred.type,
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
      expect(cred.address, isNull);
    });

    test('forAddressCredentials', () {
      final address = XdrSCAddress.forAccountId(KeyPair.random().accountId);
      final signature = XdrSCVal.forVoid();
      final signatureExpirationLedger = XdrUint32(1000);
      final addressCred = XdrSorobanAddressCredentials(
          address, XdrInt64(BigInt.from(100)), signatureExpirationLedger, signature);

      final cred = XdrSorobanCredentials.forAddressCredentials(addressCred);
      expect(cred.type, XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      expect(cred.address, addressCred);

      final output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, cred);

      final decoded =
          XdrSorobanCredentials.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      expect(decoded.address, isNotNull);
    });

    test('encode/decode source account type', () {
      final cred = XdrSorobanCredentials.forSourceAccount();

      final output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, cred);

      final decoded =
          XdrSorobanCredentials.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type,
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
    });
  });

  group('XdrSCError', () {
    test('encode/decode CONTRACT type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      error.contractCode = XdrUint32(42);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_CONTRACT);
      expect(decoded.contractCode!.uint32, 42);
    });

    test('encode/decode WASM_VM type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_WASM_VM);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_WASM_VM);
    });

    test('encode/decode CONTEXT type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_CONTEXT);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_CONTEXT);
    });

    test('encode/decode STORAGE type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_STORAGE);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_STORAGE);
    });

    test('encode/decode OBJECT type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_OBJECT);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_OBJECT);
    });

    test('encode/decode CRYPTO type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_CRYPTO);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_CRYPTO);
    });

    test('encode/decode EVENTS type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_EVENTS);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_EVENTS);
    });

    test('encode/decode BUDGET type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_BUDGET);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_BUDGET);
    });

    test('encode/decode VALUE type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_VALUE);

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_VALUE);
    });

    test('encode/decode AUTH type', () {
      final error = XdrSCError(XdrSCErrorType.SCE_AUTH);
      error.code = XdrSCErrorCode.SCEC_INVALID_INPUT;

      final output = XdrDataOutputStream();
      XdrSCError.encode(output, error);

      final decoded = XdrSCError.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.type, XdrSCErrorType.SCE_AUTH);
      expect(decoded.code, isNotNull);
    });
  });

  group('XdrSCAddressType', () {
    test('constructor and toString', () {
      final type = XdrSCAddressType(2);
      expect(type.value, 2);
      expect(type.toString(), 'SCAddressType.2');
    });
  });

  group('XdrSCAddress', () {
    test('manual claimable balance construction', () {
      final balanceId =
          '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
      final address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE);
      address.claimableBalanceId = XdrClaimableBalanceID.forId(balanceId);
      expect(address.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE);
      expect(address.claimableBalanceId, isNotNull);
    });

    test('forLiquidityPoolId with hex', () {
      final poolId =
          'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
      final address = XdrSCAddress.forLiquidityPoolId(poolId);
      expect(address.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL);
      expect(address.liquidityPoolId, isNotNull);
    });

    test('forLiquidityPoolId with L prefix', () {
      final poolId =
          'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
      final lId = StrKey.encodeLiquidityPoolId(Util.hexToBytes(poolId));
      final address = XdrSCAddress.forLiquidityPoolId(lId);
      expect(address.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL);
      expect(address.liquidityPoolId, isNotNull);
    });

    test('toStrKey for account', () {
      final kp = KeyPair.random();
      final address = XdrSCAddress.forAccountId(kp.accountId);
      final strKey = address.toStrKey();
      expect(strKey, kp.accountId);
    });

    test('toStrKey for contract', () {
      final contractId = Util.hexToBytes(
          'c5b72e9a00bf93dd6e54538e3ab40b9d5265b0634e228862de66cd7b4052a1d0');
      final address =
          XdrSCAddress.forContractId(StrKey.encodeContractId(contractId));
      final strKey = address.toStrKey();
      expect(strKey, startsWith('C'));
    });

    test('toStrKey for muxed account', () {
      final muxedId = XdrUint64(BigInt.from(999));
      final ed25519 = KeyPair.random().xdrPublicKey.getEd25519()!.uint256;
      final med25519 = XdrMuxedAccountMed25519(muxedId, XdrUint256(ed25519));
      final address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT);
      address.muxedAccount = med25519;
      final strKey = address.toStrKey();
      expect(strKey, startsWith('M'));
    });

    test('toStrKey for claimable balance manual', () {
      final balanceId =
          '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
      final address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE);
      address.claimableBalanceId = XdrClaimableBalanceID.forId(balanceId);
      final strKey = address.toStrKey();
      expect(strKey, isNotEmpty);
    });

    test('toStrKey for liquidity pool', () {
      final poolId =
          'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
      final address = XdrSCAddress.forLiquidityPoolId(poolId);
      final strKey = address.toStrKey();
      expect(strKey, startsWith('L'));
    });
  });

  group('XdrSCNonceKey', () {
    test('encode/decode', () {
      final nonce = XdrSCNonceKey(XdrInt64(BigInt.from(12345)));

      final output = XdrDataOutputStream();
      XdrSCNonceKey.encode(output, nonce);

      final decoded = XdrSCNonceKey.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.nonce.int64, BigInt.from(12345));
    });

    test('setters', () {
      final nonce = XdrSCNonceKey(XdrInt64(BigInt.from(100)));
      nonce.nonce = XdrInt64(BigInt.from(200));
      expect(nonce.nonce.int64, BigInt.from(200));
    });
  });

  group('XdrSCMapEntry', () {
    test('encode/decode', () {
      final key = XdrSCVal.forU32(1);
      final val = XdrSCVal.forU32(2);
      final entry = XdrSCMapEntry(key, val);

      final output = XdrDataOutputStream();
      XdrSCMapEntry.encode(output, entry);

      final decoded = XdrSCMapEntry.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.key.u32, isNotNull);
      expect(decoded.val.u32, isNotNull);
    });

    test('setters', () {
      final key = XdrSCVal.forU32(1);
      final val = XdrSCVal.forU32(2);
      final entry = XdrSCMapEntry(key, val);

      entry.key = XdrSCVal.forU32(3);
      entry.val = XdrSCVal.forU32(4);

      expect(entry.key.u32!.uint32, 3);
      expect(entry.val.u32!.uint32, 4);
    });
  });

  group('XdrInt128Parts', () {
    test('encode/decode', () {
      final parts = XdrInt128Parts.forHiLo(BigInt.from(123), BigInt.from(456));

      final output = XdrDataOutputStream();
      XdrInt128Parts.encode(output, parts);

      final decoded = XdrInt128Parts.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.hi.int64, BigInt.from(123));
      expect(decoded.lo.uint64, BigInt.from(456));
    });

    test('setters', () {
      final parts = XdrInt128Parts.forHiLo(BigInt.from(1), BigInt.from(2));
      parts.hi = XdrInt64(BigInt.from(3));
      parts.lo = XdrUint64(BigInt.from(4));

      expect(parts.hi.int64, BigInt.from(3));
      expect(parts.lo.uint64, BigInt.from(4));
    });
  });

  group('XdrUInt128Parts', () {
    test('encode/decode', () {
      final parts = XdrUInt128Parts.forHiLo(BigInt.from(789), BigInt.from(101112));

      final output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, parts);

      final decoded = XdrUInt128Parts.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.hi.uint64, BigInt.from(789));
      expect(decoded.lo.uint64, BigInt.from(101112));
    });

    test('setters', () {
      final parts = XdrUInt128Parts.forHiLo(BigInt.from(5), BigInt.from(6));
      parts.hi = XdrUint64(BigInt.from(7));
      parts.lo = XdrUint64(BigInt.from(8));

      expect(parts.hi.uint64, BigInt.from(7));
      expect(parts.lo.uint64, BigInt.from(8));
    });
  });

  group('XdrTransaction', () {
    test('all setters', () {
      final sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = KeyPair.random().xdrPublicKey.getEd25519();

      final tx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1000))),
        XdrPreconditions(XdrPreconditionType.NONE),
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionExt(0),
      );

      tx.sourceAccount = sourceAccount;
      tx.fee = XdrUint32(200);
      tx.seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(2000)));
      tx.preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      tx.memo = XdrMemo(XdrMemoType.MEMO_TEXT);
      tx.operations = [];
      tx.ext = XdrTransactionExt(0);

      expect(tx.fee.uint32, 200);
      expect(tx.seqNum.sequenceNumber.bigInt, BigInt.from(2000));
    });
  });

  group('XdrFeeBumpTransactionInnerTx', () {
    test('encode/decode ENVELOPE_TYPE_TX', () {
      final sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = KeyPair.random().xdrPublicKey.getEd25519();

      final tx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1000))),
        XdrPreconditions(XdrPreconditionType.NONE),
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionExt(0),
      );

      final envelope = XdrTransactionV1Envelope(tx, []);
      final innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.v1 = envelope;

      final output = XdrDataOutputStream();
      XdrFeeBumpTransactionInnerTx.encode(output, innerTx);

      final decoded =
          XdrFeeBumpTransactionInnerTx.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.discriminant, XdrEnvelopeType.ENVELOPE_TYPE_TX);
      expect(decoded.v1, isNotNull);
    });
  });

  group('XdrFeeBumpTransactionExt', () {
    test('encode/decode v0', () {
      final ext = XdrFeeBumpTransactionExt(0);

      final output = XdrDataOutputStream();
      XdrFeeBumpTransactionExt.encode(output, ext);

      final decoded =
          XdrFeeBumpTransactionExt.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.discriminant, 0);
    });
  });

  group('XdrPreconditionType', () {
    test('decode NONE', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 0);
      final stream = XdrDataInputStream(bytes);
      final type = XdrPreconditionType.decode(stream);
      expect(type, XdrPreconditionType.NONE);
    });

    test('decode TIME', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 1);
      final stream = XdrDataInputStream(bytes);
      final type = XdrPreconditionType.decode(stream);
      expect(type, XdrPreconditionType.TIME);
    });

    test('decode V2', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 2);
      final stream = XdrDataInputStream(bytes);
      final type = XdrPreconditionType.decode(stream);
      expect(type, XdrPreconditionType.V2);
    });
  });

  group('XdrPreconditions', () {
    test('encode/decode TIME with timeBounds', () {
      final timeBounds =
          XdrTimeBounds(XdrUint64(BigInt.from(1000)), XdrUint64(BigInt.from(2000)));
      final precond = XdrPreconditions(XdrPreconditionType.TIME);
      precond.timeBounds = timeBounds;

      final output = XdrDataOutputStream();
      XdrPreconditions.encode(output, precond);

      final decoded = XdrPreconditions.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.discriminant, XdrPreconditionType.TIME);
      expect(decoded.timeBounds, isNotNull);
    });

    test('encode/decode V2', () {
      final precondV2 = XdrPreconditionsV2(
        XdrUint64(BigInt.from(100)),
        XdrUint32(10),
        [],
      );
      precondV2.ledgerBounds = XdrLedgerBounds(XdrUint32(100), XdrUint32(200));
      final precond = XdrPreconditions(XdrPreconditionType.V2);
      precond.v2 = precondV2;

      final output = XdrDataOutputStream();
      XdrPreconditions.encode(output, precond);

      final decoded = XdrPreconditions.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.discriminant, XdrPreconditionType.V2);
      expect(decoded.v2, isNotNull);
    });
  });

  group('XdrLedgerBounds', () {
    test('encode/decode', () {
      final bounds = XdrLedgerBounds(XdrUint32(100), XdrUint32(500));

      final output = XdrDataOutputStream();
      XdrLedgerBounds.encode(output, bounds);

      final decoded = XdrLedgerBounds.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.minLedger.uint32, 100);
      expect(decoded.maxLedger.uint32, 500);
    });

    test('setters', () {
      final bounds = XdrLedgerBounds(XdrUint32(1), XdrUint32(2));
      bounds.minLedger = XdrUint32(10);
      bounds.maxLedger = XdrUint32(20);

      expect(bounds.minLedger.uint32, 10);
      expect(bounds.maxLedger.uint32, 20);
    });
  });

  group('XdrPreconditionsV2', () {
    test('encode/decode with sequenceNumber', () {
      final precondV2 = XdrPreconditionsV2(
        XdrUint64(BigInt.from(100)),
        XdrUint32(10),
        [],
      );
      precondV2.sequenceNumber = XdrBigInt64(BigInt.from(5000));

      final output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, precondV2);

      final decoded =
          XdrPreconditionsV2.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.minSeqAge.uint64, BigInt.from(100));
      expect(decoded.sequenceNumber, isNotNull);
    });

    test('encode/decode with extra signers', () {
      final signer = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signer.ed25519 = KeyPair.random().xdrPublicKey.getEd25519();

      final precondV2 = XdrPreconditionsV2(
        XdrUint64(BigInt.from(0)),
        XdrUint32(0),
        [signer],
      );

      final output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, precondV2);

      final decoded =
          XdrPreconditionsV2.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.extraSigners.length, 1);
    });
  });

  group('XdrMuxedAccount', () {
    test('setters', () {
      final account = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      account.ed25519 = KeyPair.random().xdrPublicKey.getEd25519();

      final newKey = KeyPair.random().xdrPublicKey.getEd25519();
      account.discriminant = XdrCryptoKeyType.KEY_TYPE_ED25519;
      account.ed25519 = XdrUint256(newKey!.uint256);

      expect(account.ed25519!.uint256, newKey.uint256);
    });
  });

  group('XdrAccountEntry', () {
    test('all setters', () {
      final accountId = XdrAccountID(KeyPair.random().xdrPublicKey);
      final balance = XdrInt64(BigInt.from(10000000));
      final seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(1000)));
      final numSubEntries = XdrUint32(5);
      final inflationDest = XdrAccountID(KeyPair.random().xdrPublicKey);
      final flags = XdrUint32(1);
      final homeDomain = XdrString32('test');
      final thresholds = XdrThresholds(Uint8List(4));
      final signers = <XdrSigner>[];
      final ext = XdrAccountEntryExt(0);

      final entry = XdrAccountEntry(
        accountId,
        balance,
        seqNum,
        numSubEntries,
        inflationDest,
        flags,
        homeDomain,
        thresholds,
        signers,
        ext,
      );

      entry.accountID = accountId;
      entry.balance = XdrInt64(BigInt.from(20000000));
      entry.seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(2000)));
      entry.numSubEntries = XdrUint32(6);
      entry.inflationDest = inflationDest;
      entry.flags = XdrUint32(2);
      entry.homeDomain = XdrString32('prod');
      entry.thresholds = thresholds;
      entry.signers = signers;
      entry.ext = ext;

      expect(entry.balance.int64, BigInt.from(20000000));
      expect(entry.seqNum.sequenceNumber.bigInt, BigInt.from(2000));
      expect(entry.numSubEntries.uint32, 6);
      expect(entry.flags.uint32, 2);
      expect(entry.homeDomain.string32, 'prod');
    });
  });

  group('XdrAccountEntryExt', () {
    test('encode/decode v0', () {
      final ext = XdrAccountEntryExt(0);

      final output = XdrDataOutputStream();
      XdrAccountEntryExt.encode(output, ext);

      final decoded =
          XdrAccountEntryExt.decode(XdrDataInputStream(Uint8List.fromList(output.bytes)));
      expect(decoded.discriminant, 0);
    });

    test('discriminant setter', () {
      final ext = XdrAccountEntryExt(0);
      ext.discriminant = 0;
      expect(ext.discriminant, 0);
    });
  });
}
