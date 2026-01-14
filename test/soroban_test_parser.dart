import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'tests_util.dart';

void main() {

  String contractPath = "test/wasm/soroban_token_contract.wasm";

  String _getSpecTypeInfo(XdrSCSpecTypeDef specType) {
    switch(specType.discriminant) {
      case XdrSCSpecType.SC_SPEC_TYPE_VAL:
        return "val";
      case XdrSCSpecType.SC_SPEC_TYPE_BOOL:
        return "bool";
      case XdrSCSpecType.SC_SPEC_TYPE_VOID:
        return "void";
      case XdrSCSpecType.SC_SPEC_TYPE_ERROR:
        return "error";
      case XdrSCSpecType.SC_SPEC_TYPE_U32:
        return "u32";
      case XdrSCSpecType.SC_SPEC_TYPE_I32:
        return "i32";
      case XdrSCSpecType.SC_SPEC_TYPE_U64:
        return "u64";
      case XdrSCSpecType.SC_SPEC_TYPE_I64:
        return "i64";
      case XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT:
        return "timepoint";
      case XdrSCSpecType.SC_SPEC_TYPE_DURATION:
        return "duration";
      case XdrSCSpecType.SC_SPEC_TYPE_U128:
        return "u128";
      case XdrSCSpecType.SC_SPEC_TYPE_I128:
        return "i128";
      case XdrSCSpecType.SC_SPEC_TYPE_U256:
        return "u256";
      case XdrSCSpecType.SC_SPEC_TYPE_I256:
        return "i256";
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES:
        return "bytes";
      case XdrSCSpecType.SC_SPEC_TYPE_STRING:
        return "string";
      case XdrSCSpecType.SC_SPEC_TYPE_SYMBOL:
        return "symbol";
      case XdrSCSpecType.SC_SPEC_TYPE_ADDRESS:
        return "address";
      case XdrSCSpecType.SC_SPEC_TYPE_MUXED_ADDRESS:
        return "muxed address";
      case XdrSCSpecType.SC_SPEC_TYPE_OPTION:
        var valueType = _getSpecTypeInfo(specType.option!.valueType);
        return "option (value type: $valueType)";
      case XdrSCSpecType.SC_SPEC_TYPE_RESULT:
        var okType = _getSpecTypeInfo(specType.result!.okType);
        var errorType = _getSpecTypeInfo(specType.result!.errorType);
        return "result (ok type: $okType , error type: $errorType)";
      case XdrSCSpecType.SC_SPEC_TYPE_VEC:
        var elementType = _getSpecTypeInfo(specType.vec!.elementType);
        return "vec (element type: $elementType)";
      case XdrSCSpecType.SC_SPEC_TYPE_MAP:
        var keyType = _getSpecTypeInfo(specType.map!.keyType);
        var valueType = _getSpecTypeInfo(specType.map!.valueType);
        return "map (key type: $keyType , value type: $valueType)";
      case XdrSCSpecType.SC_SPEC_TYPE_TUPLE:
        var valueTypesStr = "[";
        for (var valueType in specType.tuple!.valueTypes) {
          valueTypesStr += "${_getSpecTypeInfo(valueType)},";
        }
        valueTypesStr += "]";
        return "tuple (value types: $valueTypesStr)";
      case XdrSCSpecType.SC_SPEC_TYPE_BYTES_N:
        return "bytesN (n: ${specType.bytesN!.n.uint32})";
      case XdrSCSpecType.SC_SPEC_TYPE_UDT:
        return "udt (name: ${specType.udt!.name})";
      default:
        return "unknown";
    }
  }

  _printFunction(XdrSCSpecFunctionV0 function) {
    print("Function: ${function.name}");
    var index = 0;
    for (var input in function.inputs) {
      print("input[$index] name: ${input.name}");
      print("input[$index] type: ${_getSpecTypeInfo(input.type)}");
      if (input.doc.length > 0) {
        print("input[$index] doc: ${input.doc}");
      }
      index ++;
    }
    index = 0;
    for (var output in function.outputs) {
      print("output[$index] type: ${_getSpecTypeInfo(output)}");
      index ++;
    }
    if (function.doc.length > 0) {
      print("doc : ${function.doc}");
    }
  }

  _printUdtStruct(XdrSCSpecUDTStructV0 udtStruct) {
    print("UDT Struct: ${udtStruct.name}");
    if (udtStruct.lib.length > 0) {
      print("lib : ${udtStruct.lib}");
    }
    var index = 0;
    for (var field in udtStruct.fields) {
      print("field[$index] name: ${field.name}");
      print("field[$index] type: ${_getSpecTypeInfo(field.type)}");
      if (field.doc.length > 0) {
        print("field[$index] doc: ${field.doc}");
      }
      index ++;
    }
    if (udtStruct.doc.length > 0) {
      print("doc : ${udtStruct.doc})");
    }
  }

  _printUdtUnion(XdrSCSpecUDTUnionV0 udtUnion) {
    print("UDT Union: ${udtUnion.name}");
    if (udtUnion.lib.length > 0) {
      print("lib : ${udtUnion.lib}");
    }
    var index = 0;
    for (var uCase in udtUnion.cases) {
      switch(uCase.discriminant) {
        case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0:
          print("case[$index] is voidV0");
          print("case[$index] name: ${uCase.voidCase!.name}");
          if (uCase.voidCase!.doc.length > 0) {
            print("case[$index] doc: ${uCase.voidCase!.doc}");
          }
          break;
        case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
          print("case[$index] is tupleV0");
          print("case[$index] name: ${uCase.tupleCase!.name}");
          var valueTypesStr = "[";
          for (var valueType in uCase.tupleCase!.type) {
            valueTypesStr += "${_getSpecTypeInfo(valueType)},";
          }
          valueTypesStr += "]";
          print("case[$index] types: $valueTypesStr");
          if (uCase.tupleCase!.doc.length > 0) {
            print("case[$index] doc: ${uCase.tupleCase!.doc}");
          }
          break;
      }
      index ++;
    }
    if (udtUnion.doc.length > 0) {
      print("doc : ${udtUnion.doc})");
    }
  }

  _printUdtEnum(XdrSCSpecUDTEnumV0 udtEnum) {
    print("UDT Enum : ${udtEnum.name}");
    if (udtEnum.lib.length > 0) {
      print("lib : ${udtEnum.lib}");
    }
    var index = 0;
    for (var uCase in udtEnum.cases) {
      print("case[$index] name: ${uCase.name}");
      print("case[$index] value: ${uCase.value}");
      if (uCase.doc.length > 0) {
        print("case[$index] doc: ${uCase.doc}");
      }
      index ++;
    }
    if (udtEnum.doc.length > 0) {
      print("doc : ${udtEnum.doc}");
    }
  }

  _printUdtErrorEnum(XdrSCSpecUDTErrorEnumV0 udtErrorEnum) {
    print("UDT Error Enum : ${udtErrorEnum.name}");
    if (udtErrorEnum.lib.length > 0) {
      print("lib : ${udtErrorEnum.lib}");
    }
    var index = 0;
    for (var uCase in udtErrorEnum.cases) {
      print("case[$index] name: ${uCase.name}");
      print("case[$index] value: ${uCase.value}");
      if (uCase.doc.length > 0) {
        print("case[$index] doc: ${uCase.doc}");
      }
      index ++;
    }
    if (udtErrorEnum.doc.length > 0) {
      print("doc : ${udtErrorEnum.doc}");
    }
  }

  _printEvent(XdrSCSpecEventV0 event) {
    print("Event: ${event.name}");
    print("lib: ${event.lib}");

    var index = 0;
    for (var prefixTopic in event.prefixTopics) {
      print("prefixTopic[$index] name: ${prefixTopic}");
      index ++;
    }

    index = 0;
    for (var param in event.params) {
      print("param[$index] name: ${param.name}");
      if (param.doc.length > 0) {
        print("param[$index] doc : ${param.doc}");
      }
      print("param[$index] type: ${_getSpecTypeInfo(param.type)}");
      if (param.location.value == XdrSCSpecEventParamLocationV0.SC_SPEC_EVENT_PARAM_LOCATION_DATA.value) {
        print("param[$index] location: data");
      } else if (param.location.value == XdrSCSpecEventParamLocationV0.SC_SPEC_EVENT_PARAM_LOCATION_TOPIC_LIST.value) {
        print("param[$index] location: topic list");
      } else {
        print("param[$index] location: unknown");
      }
      index ++;
    }

    if (event.dataFormat.value == XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_SINGLE_VALUE.value) {
      print("data format: single value");
    } else if (event.dataFormat.value == XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_MAP.value) {
      print("data format: map");
    } else if (event.dataFormat.value == XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_VEC.value) {
      print("data format: vec");
    } else {
      print("data format: unknown");
    }

    if (event.doc.length > 0) {
      print("doc : ${event.doc}");
    }
  }

  test('test token contract parsing', () async {

    var byteCode = await loadContractCode(contractPath);
    var contractInfo = SorobanContractParser.parseContractByteCode(byteCode);
    assert(contractInfo.specEntries.length == 25);
    assert(contractInfo.metaEntries.length == 2);
    print("--------------------------------");
    print("Env Meta:");
    print("");
    print("Interface version: ${contractInfo.envInterfaceVersion}");
    print("--------------------------------");
    print("Contract Meta:");
    print("");
    for (var metaEntry in contractInfo.metaEntries.entries) {
      print("${metaEntry.key}: ${metaEntry.value}");
    }
    print("--------------------------------");

    print("Contract Spec:");
    print("");
    var specEntries = contractInfo.specEntries;
    var index = 0;
    for (var specEntry in specEntries) {
      switch (specEntry.discriminant) {
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0:
          _printFunction(specEntry.functionV0!);
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0:
          _printUdtStruct(specEntry.udtStructV0!);
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0:
          _printUdtUnion(specEntry.udtUnionV0!);
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0:
          _printUdtEnum(specEntry.udtEnumV0!);
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0:
          _printUdtErrorEnum(specEntry.udtErrorEnumV0!);
          break;
        case XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0:
          _printEvent(specEntry.eventV0!);
          break;
        default:
          print('specEntry [$index] -> kind(${specEntry.discriminant.value}): unknown');
      }
      print("");
      index++;
    }
    print("--------------------------------");
  });

  test('test SorobanContractInfo supportedSeps parsing', () {
    // Test with multiple SEPs
    var metaWithMultipleSeps = {
      'sep': '1, 10, 24',
      'other': 'value'
    };
    var info1 = SorobanContractInfo(1, [], metaWithMultipleSeps);
    expect(info1.supportedSeps, ['1', '10', '24']);

    // Test with single SEP
    var metaWithSingleSep = {'sep': '47'};
    var info2 = SorobanContractInfo(1, [], metaWithSingleSep);
    expect(info2.supportedSeps, ['47']);

    // Test with no SEP meta entry
    var metaWithoutSep = {'other': 'value'};
    var info3 = SorobanContractInfo(1, [], metaWithoutSep);
    expect(info3.supportedSeps, isEmpty);

    // Test with empty SEP value
    var metaWithEmptySep = {'sep': ''};
    var info4 = SorobanContractInfo(1, [], metaWithEmptySep);
    expect(info4.supportedSeps, isEmpty);

    // Test with SEPs containing extra spaces
    var metaWithSpaces = {'sep': '  1  ,  2  ,  3  '};
    var info5 = SorobanContractInfo(1, [], metaWithSpaces);
    expect(info5.supportedSeps, ['1', '2', '3']);

    // Test with trailing/leading commas
    var metaWithCommas = {'sep': ',1,2,'};
    var info6 = SorobanContractInfo(1, [], metaWithCommas);
    expect(info6.supportedSeps, ['1', '2']);

    // Test with duplicate SEPs (should be deduplicated)
    var metaWithDuplicates = {'sep': '1, 10, 1, 24, 10'};
    var info7 = SorobanContractInfo(1, [], metaWithDuplicates);
    expect(info7.supportedSeps, ['1', '10', '24']);
  });

  test('test token contract validation', () async {
    // Load and parse the token contract
    var contractCode = await loadContractCode(contractPath);
    var contractInfo = SorobanContractParser.parseContractByteCode(contractCode);

    // Validate environment interface version
    expect(contractInfo.envInterfaceVersion, greaterThan(0),
        reason: 'Environment interface version should be greater than 0');

    // Validate meta entries
    expect(contractInfo.metaEntries.length, 2,
        reason: 'Contract should have exactly 2 meta entries');
    expect(contractInfo.metaEntries.containsKey('rsver'), true,
        reason: 'Meta entries should contain rsver key');
    expect(contractInfo.metaEntries.containsKey('rssdkver'), true,
        reason: 'Meta entries should contain rssdkver key');

    // Validate total spec entries count
    expect(contractInfo.specEntries.length, 25,
        reason: 'Contract should have exactly 25 spec entries');

    // Validate functions count and specific function names
    expect(contractInfo.funcs.length, 13,
        reason: 'Contract should have exactly 13 functions');

    var functionNames = contractInfo.funcs.map((func) => func.name).toList();

    // Validate critical token functions exist
    expect(functionNames, contains('__constructor'),
        reason: 'Contract should have __constructor function');
    expect(functionNames, contains('mint'),
        reason: 'Contract should have mint function');
    expect(functionNames, contains('burn'),
        reason: 'Contract should have burn function');
    expect(functionNames, contains('transfer'),
        reason: 'Contract should have transfer function');
    expect(functionNames, contains('transfer_from'),
        reason: 'Contract should have transfer_from function');
    expect(functionNames, contains('balance'),
        reason: 'Contract should have balance function');
    expect(functionNames, contains('approve'),
        reason: 'Contract should have approve function');
    expect(functionNames, contains('allowance'),
        reason: 'Contract should have allowance function');
    expect(functionNames, contains('decimals'),
        reason: 'Contract should have decimals function');
    expect(functionNames, contains('name'),
        reason: 'Contract should have name function');
    expect(functionNames, contains('symbol'),
        reason: 'Contract should have symbol function');
    expect(functionNames, contains('set_admin'),
        reason: 'Contract should have set_admin function');
    expect(functionNames, contains('burn_from'),
        reason: 'Contract should have burn_from function');

    // Validate UDT structs count and specific struct names
    expect(contractInfo.udtStructs.length, 3,
        reason: 'Contract should have exactly 3 UDT structs');

    var structNames = contractInfo.udtStructs.map((struct) => struct.name).toList();
    expect(structNames, contains('AllowanceDataKey'),
        reason: 'Contract should have AllowanceDataKey struct');
    expect(structNames, contains('AllowanceValue'),
        reason: 'Contract should have AllowanceValue struct');
    expect(structNames, contains('TokenMetadata'),
        reason: 'Contract should have TokenMetadata struct');

    // Validate AllowanceDataKey struct fields
    XdrSCSpecUDTStructV0? allowanceDataKey;
    for (var struct in contractInfo.udtStructs) {
      if (struct.name == 'AllowanceDataKey') {
        allowanceDataKey = struct;
        break;
      }
    }
    expect(allowanceDataKey, isNotNull,
        reason: 'AllowanceDataKey struct should be found');
    expect(allowanceDataKey!.fields.length, 2,
        reason: 'AllowanceDataKey should have 2 fields');
    expect(allowanceDataKey.fields[0].name, 'from',
        reason: 'First field of AllowanceDataKey should be named "from"');
    expect(allowanceDataKey.fields[1].name, 'spender',
        reason: 'Second field of AllowanceDataKey should be named "spender"');

    // Validate TokenMetadata struct fields
    XdrSCSpecUDTStructV0? tokenMetadata;
    for (var struct in contractInfo.udtStructs) {
      if (struct.name == 'TokenMetadata') {
        tokenMetadata = struct;
        break;
      }
    }
    expect(tokenMetadata, isNotNull,
        reason: 'TokenMetadata struct should be found');
    expect(tokenMetadata!.fields.length, 3,
        reason: 'TokenMetadata should have 3 fields');
    expect(tokenMetadata.fields[0].name, 'decimal',
        reason: 'First field of TokenMetadata should be named "decimal"');
    expect(tokenMetadata.fields[1].name, 'name',
        reason: 'Second field of TokenMetadata should be named "name"');
    expect(tokenMetadata.fields[2].name, 'symbol',
        reason: 'Third field of TokenMetadata should be named "symbol"');

    // Validate UDT unions count and specific union names
    expect(contractInfo.udtUnions.length, 1,
        reason: 'Contract should have exactly 1 UDT union');

    var unionNames = contractInfo.udtUnions.map((union) => union.name).toList();
    expect(unionNames, contains('DataKey'),
        reason: 'Contract should have DataKey union');

    // Validate DataKey union cases
    var dataKey = contractInfo.udtUnions[0];
    expect(dataKey.name, 'DataKey',
        reason: 'Union should be named DataKey');
    expect(dataKey.cases.length, 4,
        reason: 'DataKey union should have 4 cases');

    // Validate UDT enums count (should be zero for this contract)
    expect(contractInfo.udtEnums.length, 0,
        reason: 'Contract should have 0 UDT enums');

    // Validate UDT error enums count (should be zero for this contract)
    expect(contractInfo.udtErrorEnums.length, 0,
        reason: 'Contract should have 0 UDT error enums');

    // Validate events count and specific event names
    expect(contractInfo.events.length, 8,
        reason: 'Contract should have exactly 8 events');

    var eventNames = contractInfo.events.map((event) => event.name).toList();
    expect(eventNames, contains('SetAdmin'),
        reason: 'Contract should have SetAdmin event');
    expect(eventNames, contains('Approve'),
        reason: 'Contract should have Approve event');
    expect(eventNames, contains('Transfer'),
        reason: 'Contract should have Transfer event');
    expect(eventNames, contains('TransferWithAmountOnly'),
        reason: 'Contract should have TransferWithAmountOnly event');
    expect(eventNames, contains('Burn'),
        reason: 'Contract should have Burn event');
    expect(eventNames, contains('Mint'),
        reason: 'Contract should have Mint event');
    expect(eventNames, contains('MintWithAmountOnly'),
        reason: 'Contract should have MintWithAmountOnly event');
    expect(eventNames, contains('Clawback'),
        reason: 'Contract should have Clawback event');

    // Validate Transfer event structure
    XdrSCSpecEventV0? transferEvent;
    for (var event in contractInfo.events) {
      if (event.name == 'Transfer') {
        transferEvent = event;
        break;
      }
    }
    expect(transferEvent, isNotNull,
        reason: 'Transfer event should be found');
    expect(transferEvent!.prefixTopics.length, 1,
        reason: 'Transfer event should have 1 prefix topic');
    expect(transferEvent.prefixTopics[0], 'transfer',
        reason: 'Transfer event prefix topic should be "transfer"');
    expect(transferEvent.params.length, 4,
        reason: 'Transfer event should have 4 parameters');

    // Validate Approve event structure
    XdrSCSpecEventV0? approveEvent;
    for (var event in contractInfo.events) {
      if (event.name == 'Approve') {
        approveEvent = event;
        break;
      }
    }
    expect(approveEvent, isNotNull,
        reason: 'Approve event should be found');
    expect(approveEvent!.prefixTopics.length, 1,
        reason: 'Approve event should have 1 prefix topic');
    expect(approveEvent.prefixTopics[0], 'approve',
        reason: 'Approve event prefix topic should be "approve"');
    expect(approveEvent.params.length, 4,
        reason: 'Approve event should have 4 parameters');

    // Validate balance function signature
    XdrSCSpecFunctionV0? balanceFunc;
    for (var func in contractInfo.funcs) {
      if (func.name == 'balance') {
        balanceFunc = func;
        break;
      }
    }
    expect(balanceFunc, isNotNull,
        reason: 'balance function should be found');
    expect(balanceFunc!.inputs.length, 1,
        reason: 'balance function should have 1 input parameter');
    expect(balanceFunc.inputs[0].name, 'id',
        reason: 'balance function input should be named "id"');
    expect(balanceFunc.outputs.length, 1,
        reason: 'balance function should have 1 output');

    // Validate mint function signature
    XdrSCSpecFunctionV0? mintFunc;
    for (var func in contractInfo.funcs) {
      if (func.name == 'mint') {
        mintFunc = func;
        break;
      }
    }
    expect(mintFunc, isNotNull,
        reason: 'mint function should be found');
    expect(mintFunc!.inputs.length, 2,
        reason: 'mint function should have 2 input parameters');
    expect(mintFunc.inputs[0].name, 'to',
        reason: 'First parameter of mint function should be named "to"');
    expect(mintFunc.inputs[1].name, 'amount',
        reason: 'Second parameter of mint function should be named "amount"');
    expect(mintFunc.outputs.length, 0,
        reason: 'mint function should have no outputs (void return)');
  });

  test('test contract spec methods', () async {
    // Load and parse the token contract
    var contractCode = await loadContractCode(contractPath);
    var contractInfo = SorobanContractParser.parseContractByteCode(contractCode);

    // Create a ContractSpec instance from the parsed spec entries
    var contractSpec = ContractSpec(contractInfo.specEntries);

    // Test funcs() method - should return 13 functions
    var functions = contractSpec.funcs();
    expect(functions.length, 13,
        reason: 'ContractSpec funcs() should return exactly 13 functions');

    // Validate that all returned items are XdrSCSpecFunctionV0 instances
    for (var func in functions) {
      expect(func is XdrSCSpecFunctionV0, true,
          reason: 'Each function should be an instance of XdrSCSpecFunctionV0');
    }

    // Validate specific function names exist
    var functionNames = functions.map((func) => func.name).toList();
    expect(functionNames, contains('__constructor'),
        reason: 'Functions should include __constructor');
    expect(functionNames, contains('mint'),
        reason: 'Functions should include mint');
    expect(functionNames, contains('burn'),
        reason: 'Functions should include burn');
    expect(functionNames, contains('transfer'),
        reason: 'Functions should include transfer');
    expect(functionNames, contains('transfer_from'),
        reason: 'Functions should include transfer_from');
    expect(functionNames, contains('balance'),
        reason: 'Functions should include balance');
    expect(functionNames, contains('approve'),
        reason: 'Functions should include approve');
    expect(functionNames, contains('allowance'),
        reason: 'Functions should include allowance');
    expect(functionNames, contains('decimals'),
        reason: 'Functions should include decimals');
    expect(functionNames, contains('name'),
        reason: 'Functions should include name');
    expect(functionNames, contains('symbol'),
        reason: 'Functions should include symbol');
    expect(functionNames, contains('set_admin'),
        reason: 'Functions should include set_admin');
    expect(functionNames, contains('burn_from'),
        reason: 'Functions should include burn_from');

    // Test udtStructs() method - should return 3 structs
    var structs = contractSpec.udtStructs();
    expect(structs.length, 3,
        reason: 'ContractSpec udtStructs() should return exactly 3 structs');

    // Validate that all returned items are XdrSCSpecUDTStructV0 instances
    for (var struct in structs) {
      expect(struct is XdrSCSpecUDTStructV0, true,
          reason: 'Each struct should be an instance of XdrSCSpecUDTStructV0');
    }

    // Validate specific struct names exist
    var structNames = structs.map((struct) => struct.name).toList();
    expect(structNames, contains('AllowanceDataKey'),
        reason: 'Structs should include AllowanceDataKey');
    expect(structNames, contains('AllowanceValue'),
        reason: 'Structs should include AllowanceValue');
    expect(structNames, contains('TokenMetadata'),
        reason: 'Structs should include TokenMetadata');

    // Validate AllowanceDataKey struct has expected fields
    XdrSCSpecUDTStructV0? allowanceDataKey;
    for (var struct in structs) {
      if (struct.name == 'AllowanceDataKey') {
        allowanceDataKey = struct;
        break;
      }
    }
    expect(allowanceDataKey, isNotNull,
        reason: 'AllowanceDataKey struct should be found');
    expect(allowanceDataKey!.fields.length, 2,
        reason: 'AllowanceDataKey should have 2 fields');
    expect(allowanceDataKey.fields[0].name, 'from',
        reason: 'First field should be named "from"');
    expect(allowanceDataKey.fields[1].name, 'spender',
        reason: 'Second field should be named "spender"');

    // Test udtUnions() method - should return 1 union
    var unions = contractSpec.udtUnions();
    expect(unions.length, 1,
        reason: 'ContractSpec udtUnions() should return exactly 1 union');

    // Validate that all returned items are XdrSCSpecUDTUnionV0 instances
    for (var union in unions) {
      expect(union is XdrSCSpecUDTUnionV0, true,
          reason: 'Each union should be an instance of XdrSCSpecUDTUnionV0');
    }

    // Validate specific union names exist
    var unionNames = unions.map((union) => union.name).toList();
    expect(unionNames, contains('DataKey'),
        reason: 'Unions should include DataKey');

    // Validate DataKey union has expected cases
    var dataKey = unions[0];
    expect(dataKey.name, 'DataKey',
        reason: 'Union should be named DataKey');
    expect(dataKey.cases.length, 4,
        reason: 'DataKey union should have 4 cases');

    // Test udtEnums() method - should return 0 enums
    var enums = contractSpec.udtEnums();
    expect(enums.length, 0,
        reason: 'ContractSpec udtEnums() should return 0 enums for this contract');

    // Validate that all returned items are XdrSCSpecUDTEnumV0 instances (even if empty)
    for (var enumItem in enums) {
      expect(enumItem is XdrSCSpecUDTEnumV0, true,
          reason: 'Each enum should be an instance of XdrSCSpecUDTEnumV0');
    }

    // Test udtErrorEnums() method - should return 0 error enums
    var errorEnums = contractSpec.udtErrorEnums();
    expect(errorEnums.length, 0,
        reason: 'ContractSpec udtErrorEnums() should return 0 error enums for this contract');

    // Validate that all returned items are XdrSCSpecUDTErrorEnumV0 instances (even if empty)
    for (var errorEnum in errorEnums) {
      expect(errorEnum is XdrSCSpecUDTErrorEnumV0, true,
          reason: 'Each error enum should be an instance of XdrSCSpecUDTErrorEnumV0');
    }

    // Test events() method - should return 8 events
    var events = contractSpec.events();
    expect(events.length, 8,
        reason: 'ContractSpec events() should return exactly 8 events');

    // Validate that all returned items are XdrSCSpecEventV0 instances
    for (var event in events) {
      expect(event is XdrSCSpecEventV0, true,
          reason: 'Each event should be an instance of XdrSCSpecEventV0');
    }

    // Validate specific event names exist
    var eventNames = events.map((event) => event.name).toList();
    expect(eventNames, contains('SetAdmin'),
        reason: 'Events should include SetAdmin');
    expect(eventNames, contains('Approve'),
        reason: 'Events should include Approve');
    expect(eventNames, contains('Transfer'),
        reason: 'Events should include Transfer');
    expect(eventNames, contains('TransferWithAmountOnly'),
        reason: 'Events should include TransferWithAmountOnly');
    expect(eventNames, contains('Burn'),
        reason: 'Events should include Burn');
    expect(eventNames, contains('Mint'),
        reason: 'Events should include Mint');
    expect(eventNames, contains('MintWithAmountOnly'),
        reason: 'Events should include MintWithAmountOnly');
    expect(eventNames, contains('Clawback'),
        reason: 'Events should include Clawback');

    // Validate Transfer event structure from ContractSpec
    XdrSCSpecEventV0? transferEvent;
    for (var event in events) {
      if (event.name == 'Transfer') {
        transferEvent = event;
        break;
      }
    }
    expect(transferEvent, isNotNull,
        reason: 'Transfer event should be found');
    expect(transferEvent!.prefixTopics.length, 1,
        reason: 'Transfer event should have 1 prefix topic');
    expect(transferEvent.prefixTopics[0], 'transfer',
        reason: 'Transfer event prefix topic should be "transfer"');
    expect(transferEvent.params.length, 4,
        reason: 'Transfer event should have 4 parameters');

    // Validate that ContractSpec can find specific functions by name using getFunc()
    var balanceFunc = contractSpec.getFunc('balance');
    expect(balanceFunc, isNotNull,
        reason: 'ContractSpec getFunc() should find balance function');
    expect(balanceFunc is XdrSCSpecFunctionV0, true,
        reason: 'getFunc() should return XdrSCSpecFunctionV0 instance');
    expect(balanceFunc!.name, 'balance',
        reason: 'Found function should have correct name');
    expect(balanceFunc.inputs.length, 1,
        reason: 'balance function should have 1 input parameter');

    // Validate that getFunc() returns null for non-existent function
    var nonExistentFunc = contractSpec.getFunc('non_existent_function');
    expect(nonExistentFunc, isNull,
        reason: 'ContractSpec getFunc() should return null for non-existent function');

    // Validate that findEntry() can locate entries by name
    var mintEntry = contractSpec.findEntry('mint');
    expect(mintEntry, isNotNull,
        reason: 'ContractSpec findEntry() should find mint entry');
    expect(mintEntry!.discriminant, XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
        reason: 'mint entry should be a function type');

    var dataKeyEntry = contractSpec.findEntry('DataKey');
    expect(dataKeyEntry, isNotNull,
        reason: 'ContractSpec findEntry() should find DataKey entry');
    expect(dataKeyEntry!.discriminant, XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0,
        reason: 'DataKey entry should be a union type');

    var transferEventEntry = contractSpec.findEntry('Transfer');
    expect(transferEventEntry, isNotNull,
        reason: 'ContractSpec findEntry() should find Transfer entry');
    expect(transferEventEntry!.discriminant, XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0,
        reason: 'Transfer entry should be an event type');

    // Validate that findEntry() returns null for non-existent entry
    var nonExistentEntry = contractSpec.findEntry('NonExistentEntry');
    expect(nonExistentEntry, isNull,
        reason: 'ContractSpec findEntry() should return null for non-existent entry');
  });

}