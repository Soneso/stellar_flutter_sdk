import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {

  String contractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_token_contract.wasm";

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

    var byteCode = await Util.readFile(contractPath);
    var contractInfo = SorobanContractParser.parseContractByteCode(byteCode);
    assert(contractInfo.specEntries.length == 17);
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

}