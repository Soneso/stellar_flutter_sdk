# SEP-51: XDR-JSON

XDR-JSON is a JSON rendering of Stellar's XDR structures. It gives every XDR value one canonical JSON document, and every such document reads back to the bytes it came from.

**When to use:** inspecting a transaction envelope or a ledger entry while debugging, diffing two values field by field, showing an operation to a user before they sign it, storing a readable copy alongside the base64, or building tooling that edits XDR through a tree rather than through a binary codec.

See the [SEP-51 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md) for the mapping rules.

## Overview

> **Note:** SEP-51 is in Draft status (v2.0.1). The document shape follows the Stellar XDR definitions, so a protocol upgrade can change key names and structure. See [Limitations](#limitations).

Every generated XDR type in `lib/src/xdr/` carries four members:

| Member | Direction | Returns |
|--------|-----------|---------|
| `String toXdrJson()` | out | the canonical document as text |
| `Object? toXdrJsonValue()` | out | the same document as a Dart tree |
| `static T fromXdrJson(String json)` | in | the value, parsed from text |
| `static T fromXdrJsonValue(Object? value)` | in | the value, read from a tree |

The tree form is what `dart:convert` produces and consumes: `Map<String, dynamic>`, `List<dynamic>`, `String`, `num`, `bool` and `null`. Use it when you want to inspect or edit the document without a second parse.

There is no service class and no separate import. The methods come with the XDR types, which the SDK already exports.

## Quick example

Render a transaction envelope as XDR-JSON, then read it back:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String envelopeBase64 =
    'AAAAAgAAAADmmSZkwY3163TMouB2TY8MljqXw2IxVYTGyvDrR6YtAAAqmmQAABpuAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAABgAAAAHXkotywnA8z+r365/0701QSlWouXn8m0UOoshCtNHOYQAAABQAAAABAAI9fQAAAAAAAAD4AAAAAAAqmgAAAAABR6YtAAAAAEArDtxbqUI+CsdkRmV0lFhVt0wyB7fyrmmkM6Fr35wpPcK8WKcXeKTl4BQ+akE14MZtpaea9LMdhXopaW3pJA0E';

XdrTransactionEnvelope envelope =
    XdrTransactionEnvelope.fromBase64EncodedXdrString(envelopeBase64);

String json = envelope.toXdrJson();
print(json);

// Read the document back and confirm the binary is unchanged
XdrTransactionEnvelope parsed = XdrTransactionEnvelope.fromXdrJson(json);
print(parsed.toBase64EncodedXdrString() == envelopeBase64); // true
```

`toXdrJson()` emits one line with no whitespace. Indented for reading, the document above is:

```json
{
  "tx": {
    "tx": {
      "source_account": "GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA",
      "fee": 2792036,
      "seq_num": "29059748724737",
      "cond": "none",
      "memo": "none",
      "operations": [
        {
          "source_account": null,
          "body": {
            "invoke_host_function": {
              "host_function": {
                "create_contract": {
                  "contract_id_preimage": { "asset": "native" },
                  "executable": "stellar_asset"
                }
              },
              "auth": []
            }
          }
        }
      ],
      "ext": {
        "v1": {
          "ext": "v0",
          "resources": {
            "footprint": {
              "read_only": [],
              "read_write": [
                {
                  "contract_data": {
                    "contract": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
                    "key": "ledger_key_contract_instance",
                    "durability": "persistent"
                  }
                }
              ]
            },
            "instructions": 146813,
            "disk_read_bytes": 0,
            "write_bytes": 248
          },
          "resource_fee": "2791936"
        }
      }
    },
    "signatures": [
      {
        "hint": "47a62d00",
        "signature": "2b0edc5ba9423e0ac764466574945855b74c3207b7f2ae69a433a16bdf9c293dc2bc58a71778a4e5e0143e6a4135e0c66da5a79af4b31d857a29696de9240d04"
      }
    ]
  }
}
```

Both directions are available on every XDR type, not only on the envelope.

## Detailed usage

### The four members

`toXdrJson()` and `fromXdrJson()` work in text. `toXdrJsonValue()` and `fromXdrJsonValue()` work in the tree, which is what you want when a caller hands you a decoded map or when you plan to walk the document:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrMemo memo = XdrMemo.fromBase64EncodedXdrString('AAAAAQAAAAVoZWxsbwAAAA==');

String document = memo.toXdrJson();      // {"text":"hello"}
Object? tree = memo.toXdrJsonValue();    // {'text': 'hello'}

XdrMemo fromDocument = XdrMemo.fromXdrJson(document);
XdrMemo fromTree = XdrMemo.fromXdrJsonValue(tree);

print(fromDocument.text);  // hello
print(fromTree.text);      // hello
```

Key order in the emitted document follows the order the XDR definition declares the fields in, and the output is compact. Two runs on the same value produce the same bytes, on every platform the SDK supports.

### Booleans

An XDR `bool` maps to a JSON boolean, both as a union arm and as a struct member:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCVal flag = XdrSCVal.fromXdrJson('{"bool":true}');
print(flag.b);            // true
print(flag.toXdrJson());  // {"bool":true}

print(XdrSCVal.forBool(false).toXdrJson()); // {"bool":false}

// A boolean member of a struct renders the same way
XdrDiagnosticEvent event = XdrDiagnosticEvent.fromBase64EncodedXdrString(
    'AAAAAQAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAQ==');
print(event.toXdrJson());
// {"in_successful_contract_call":true,"event":{...}}
```

Nothing else counts as a boolean. `"true"`, `"false"`, `1` and `0` are refused:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrSCVal.fromXdrJson('{"bool":"true"}');
} on FormatException catch (e) {
  print(e.message); // ... expects a boolean but found "true"
}
```

### Integers

32-bit fields are JSON numbers. 64-bit fields are base-10 strings. The specification explains why in its Number Representation for 64-bit Integers section: a JSON number loses precision past 2^53 in a JavaScript runtime.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 32-bit: numbers
XdrLedgerBounds bounds =
    XdrLedgerBounds.fromXdrJson('{"min_ledger":1,"max_ledger":2}');
print(bounds.minLedger.uint32);  // 1
print(bounds.toXdrJson());       // {"min_ledger":1,"max_ledger":2}

// A 32-bit field takes a JSON number, not a string
try {
  XdrLedgerBounds.fromXdrJson('{"min_ledger":"1","max_ledger":2}');
} on FormatException catch (e) {
  print(e.message); // ... expects a JSON number but found "1"
}
```

64-bit values are carried as `BigInt` in Dart and never pass through `int`, `num` or `jsonEncode`'s numeric path, so the full range survives on every target:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrTimeBounds bounds =
    XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1735689600"}');
print(bounds.maxTime.uint64);  // 1735689600
print(bounds.toXdrJson());     // {"min_time":"0","max_time":"1735689600"}

XdrUint64 max = XdrUint64.fromXdrJson('"18446744073709551615"');
print(max.uint64);        // 18446744073709551615
print(max.toXdrJson());   // "18446744073709551615"
```

The four 128-bit and 256-bit parts types render as one base-10 string rather than as an object of limbs, so `XdrInt128Parts`, `XdrUInt128Parts`, `XdrInt256Parts` and `XdrUInt256Parts` all read and write a single decimal.

### Opaque data and text

Opaque fields, fixed and variable, render as lowercase hexadecimal. An empty variable-length field is `""`, never `"0"`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSignatureHint hint = XdrSignatureHint.fromBase64EncodedXdrString('YWJjZA==');
print(hint.toXdrJson());  // "61626364"

print(XdrDataValue.fromXdrJson('"deadbeef"').toXdrJson());  // "deadbeef"
print(XdrDataValue.fromXdrJson('""').toBase64EncodedXdrString()); // AAAAAA==
```

Text fields take the escape ladder of the specification's String section: `\0`, `\t`, `\n`, `\r` and `\\` have short forms, printable ASCII passes through, and every other byte becomes `\xNN` with two lowercase hexadecimal digits. The ladder runs over bytes, so one multi-byte character produces one escape per byte. The result is then a JSON string, which is where the second backslash comes from:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrMemo tab = XdrMemo.fromBase64EncodedXdrString('AAAAAQAAAAh0YWIJaGVyZQ==');
print(tab.toXdrJson());  // {"text":"tab\\there"}

XdrManageDataOp op = XdrManageDataOp.fromXdrJson(
    r'{"data_name":"caf\\xc3\\xa9","data_value":null}');
print(op.dataName.string64);  // café
print(op.toXdrJson());        // {"data_name":"caf\\xc3\\xa9","data_value":null}
```

Asset codes are opaque, so they take the ladder too. A four-byte code drops its trailing NUL padding. A twelve-byte code drops trailing NULs down to five bytes and no further, which is what keeps the two widths distinguishable.

Address-shaped types render as strkeys: `AccountID`, `NodeID` and `PublicKey` as `G...`, `MuxedAccount` as `G...` or `M...`, contract identifiers as `C...`, liquidity pool identifiers as `L...`, claimable balance identifiers as `B...`, and signer keys as `G...`, `T...`, `X...` or `P...` by arm.

### Unions: a void arm is not an absent value

This is the distinction that costs the most time. A void arm renders as a bare string. An arm that carries a value renders as a single-key object. An arm whose declared value is optional keeps the object shape and puts `null` inside it. Three documents that look alike mean different things:

| Document | Meaning | Bytes |
|----------|---------|-------|
| `"void"` | the `SCV_VOID` arm, which carries nothing | `AAAAAQ==` |
| `{"vec":null}` | the `SCV_VEC` arm, its optional vector absent | `AAAAEAAAAAA=` |
| `{"vec":[]}` | the `SCV_VEC` arm, holding an empty vector | `AAAAEAAAAAEAAAAA` |

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCVal voidArm = XdrSCVal.fromXdrJson('"void"');        // SCV_VOID
XdrSCVal absentVec = XdrSCVal.fromXdrJson('{"vec":null}'); // SCV_VEC, no vector
XdrSCVal emptyVec = XdrSCVal.fromXdrJson('{"vec":[]}');    // SCV_VEC, empty vector

print(voidArm.toBase64EncodedXdrString());    // AAAAAQ==
print(absentVec.toBase64EncodedXdrString());  // AAAAEAAAAAA=
print(emptyVec.toBase64EncodedXdrString());   // AAAAEAAAAAEAAAAA

print(absentVec.vec);  // null
print(emptyVec.vec);   // []
```

Three documents, three different sets of bytes. If you build XDR-JSON by hand, pick the one you mean. Writing the bare string for an arm that is not void is refused rather than read as an absent value:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrSCVal.fromXdrJson('"vec"');
} on FormatException catch (e) {
  print(e.message); // XDR-JSON XdrSCVal has no arm named "vec"
}
```

Unions whose discriminant is a plain integer key on the letter `v` plus the number: `"v0"` for a void arm, `{"v1": ...}` otherwise. That covers `XdrExtensionPoint` and every `...Ext` union.

### Structs

A struct renders as an object whose keys are the snake_case forms of the XDR field names. The names come from the XDR definitions, not from the Dart member names, so a field the SDK renames still keys on its declared name:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrContractEvent event = XdrContractEvent.fromBase64EncodedXdrString(
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB');

print(event.toXdrJson());
// {"ext":"v0","contract_id":null,"type":"system","body":{"v0":{"topics":[],"data":"void"}}}
```

Every declared key has to be present on input, including the key of an optional field whose value is `null`. A missing key and a null value are different documents:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrContractEvent.fromXdrJson(
      '{"ext":"v0","type":"system","body":{"v0":{"topics":[],"data":"void"}}}');
} on FormatException catch (e) {
  print(e.message); // ... is missing the required key "contract_id"
}
```

Seven types declare an XDR field named `type`. They emit the key `type` and also accept `type_` on input, which is a spelling older producers emit. `type_` is never emitted, and supplying both spellings is refused rather than resolved to either one:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String declared = '{"ext":"v0","contract_id":null,"type":"system",'
    '"body":{"v0":{"topics":[],"data":"void"}}}';
String aliased = '{"ext":"v0","contract_id":null,"type_":"system",'
    '"body":{"v0":{"topics":[],"data":"void"}}}';

// Both read to the same value, and both emit "type"
print(XdrContractEvent.fromXdrJson(aliased).toXdrJson() == declared); // true

try {
  XdrContractEvent.fromXdrJson('{"ext":"v0","contract_id":null,'
      '"type":"system","type_":"system",'
      '"body":{"v0":{"topics":[],"data":"void"}}}');
} on FormatException catch (e) {
  print(e.message); // ... carries both "type" and its accepted alias "type_"
}
```

The seven are `XdrContractEvent`, `XdrDontHave`, `XdrSCSpecEventParamV0`, `XdrSCSpecFunctionInputV0`, `XdrSCSpecUDTStructFieldV0`, `XdrSCSpecUDTUnionCaseTupleV0` and `XdrSerializedBinaryFuseFilter`.

### Optional values

An optional field renders as `null` when unset and as the value itself when set. The key stays in the object either way.

One array in the Stellar definitions holds an optional element type: `AccountEntryExtensionV2.signerSponsoringIDs`. Each element is either a strkey or `null`, and a `null` element occupies a position rather than being dropped, because the binary encoding writes a presence flag per element. `XdrAccountEntryV2.signerSponsoringIDs` is therefore a `List<XdrAccountID?>`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrAccountEntryV2 sponsors = XdrAccountEntryV2.fromXdrJson(
    '{"num_sponsored":0,"num_sponsoring":1,'
    '"signer_sponsoring_i_ds":[null],"ext":"v0"}');

print(sponsors.signerSponsoringIDs.length);   // 1
print(sponsors.signerSponsoringIDs.first);    // null
print(sponsors.toBase64EncodedXdrString());   // AAAAAAAAAAEAAAABAAAAAAAAAAA=

// Present and absent elements interleave without shifting position
XdrAccountEntryV2 mixed = XdrAccountEntryV2.fromXdrJson(
    '{"num_sponsored":2,"num_sponsoring":3,"signer_sponsoring_i_ds":'
    '["GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQDZ7H",null,'
    '"GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"],'
    '"ext":"v0"}');
print(mixed.signerSponsoringIDs.length);  // 3
print(mixed.signerSponsoringIDs[1]);      // null
```

### The `$schema` property

The specification's JSON Schema section says objects should allow, but not require, a `$schema` property. This SDK accepts it wherever an object is accepted, at any depth, removes it before anything else reads the object, and never emits it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String document =
    r'{"$schema":"https://stellar.org/schema/xdr-json/main/Asset.json",'
    '"credit_alphanum4":{"asset_code":"ABCD","issuer":'
    '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';

XdrAsset asset = XdrAsset.fromXdrJson(document);
print(asset.toXdrJson());
// {"credit_alphanum4":{"asset_code":"ABCD",
//  "issuer":"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}
```

The property carries no further privilege. An object holding nothing but `$schema` is an object holding nothing, so a struct still requires its fields and a union arm still requires its one key. The SDK publishes no schema documents, which is why it never emits the property.

### Comparing documents

The emitted form is canonical, so two values that are equal produce identical bytes and you can compare `toXdrJson()` results directly.

The reverse does not hold for documents you did not emit. No normalizer ships with the SDK, and a document from another producer may differ byte for byte while describing the same value: it may be indented, order its struct keys differently, carry a `$schema` property, or render a 64-bit field as a JSON number. All of those are accepted on input, and none of them survives into the output.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String canonical = '{"text":"hello"}';
String spaced = '{ "text" : "hello" }';

print(canonical == spaced); // false, the texts differ

// Read both into the XDR type and re-emit to get one text
XdrMemo fromCanonical = XdrMemo.fromXdrJson(canonical);
XdrMemo fromSpaced = XdrMemo.fromXdrJson(spaced);
print(fromCanonical.toXdrJson() == fromSpaced.toXdrJson()); // true
print(fromSpaced.toXdrJson() == canonical);                 // true
```

To decide whether two foreign documents mean the same thing, parse both into the XDR type and compare either the re-emitted text or the base64 encoding. Comparing the incoming texts answers a different question.

### Input strictness

The specification fixes one rendering per value, and that is the only rendering this SDK emits. On input it accepts a few documented variations, listed further down, and refuses everything else. These are SDK rules, chosen so that a byte-for-byte comparison of two emitted documents stays meaningful:

- hexadecimal is lowercase and of even length;
- a `\x` escape carries exactly two lowercase hexadecimal digits, and an escape the ladder does not define is refused rather than passed through;
- a decimal integer carries no leading `+`, no leading zero, no exponent and no fraction;
- a repeated object key is refused rather than resolved in favor of the last occurrence;
- an enum takes its wire name, not the XDR identifier and not the numeric value;
- a fixed-length field is held to its declared length, and a variable-length field to its declared maximum;
- nesting is bounded at 128 containers, the same bound the binary decoder applies.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void report(String label, void Function() read) {
  try {
    read();
    print('$label: accepted');
  } on FormatException catch (e) {
    print('$label: ${e.message}');
  }
}

report('uppercase hex', () => XdrDataValue.fromXdrJson('"DEADBEEF"'));
report('odd-length hex', () => XdrDataValue.fromXdrJson('"deadbee"'));
report('leading zero',
    () => XdrTimeBounds.fromXdrJson('{"min_time":"007","max_time":"0"}'));
// Dart's own parser would keep the last occurrence of a repeated key silently
report(
    'repeated key',
    () => XdrTimeBounds.fromXdrJson(
        '{"min_time":"1","min_time":"2","max_time":"3"}'));
```

The nesting bound is checked before the document reaches the JSON encoder or parser, so a deeply nested document is reported rather than exhausting the stack. `XdrJsonHelper` is the shared runtime the generated types delegate to, and it carries the bound as a constant:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

print(XdrJsonHelper.maxDepth); // 128

String tooDeep = '${'{"not":' * 129}"unconditional"${'}' * 129}';

try {
  XdrClaimPredicate.fromXdrJson(tooDeep);
} on FormatException catch (e) {
  print(e.message);
  // XDR-JSON XdrClaimPredicate nests JSON containers more than 128 deep, ...
}
```

#### Undeclared keys are refused

The specification does not say what to do with a key a type does not declare. This SDK refuses it. A type has one set of field names, so a document carrying anything else is describing something other than that type, and accepting the extra key silently would let a field renamed by a future protocol version decode as though it were simply absent.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1","foo":2}');
} on FormatException catch (e) {
  print(e.message); // XDR-JSON XdrTimeBounds has the unknown key "foo"
}

// Several are reported together, in sorted order
try {
  XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1","zeta":2,"alpha":3}');
} on FormatException catch (e) {
  print(e.message);
  // XDR-JSON XdrTimeBounds has the unknown keys "alpha", "zeta"
}
```

`$schema` is the one key accepted here that the reference implementation refuses. Everything the reference refuses beyond that, this SDK refuses too. "The reference implementation" throughout this page means the XDR-JSON implementation that produced the fixtures this SDK's output is pinned against; the version is recorded in the SDK's conformance corpus.

### When not to use XDR-JSON

- Not as a network format. Horizon and the RPC take base64 XDR. XDR-JSON is for reading and for tooling.
- Not as long-lived storage. The specification's Changed with Protocols section is explicit that XDR-JSON changes from one protocol to the next, because the Stellar XDR does. Keep the base64 as the record and treat the JSON as a view of it.
- Not as an application API. Key names come from the XDR field names, so a protocol upgrade that renames or restructures a field changes your consumers' documents. A schema of your own is a better contract.
- Not as a compact encoding. A document runs several times the size of the equivalent base64 and costs a parse on top.
- Not for non-XDR SDK types. `Transaction`, `Asset`, `KeyPair` and the Horizon and RPC response classes are not XDR structures and carry no XDR-JSON. `Transaction.toEnvelopeXdr()` gets you to an XDR type that does.

## Limitations

### Text members carry UTF-8 only

An XDR `string<>` is a Dart `String`, so its bytes are text. A document whose escapes resolve to bytes that are not valid UTF-8 is refused:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 0xc3 alone is not valid UTF-8
try {
  XdrManageDataOp.fromXdrJson(r'{"data_name":"\\xc3","data_value":null}');
} on FormatException catch (e) {
  print(e.message); // ... resolves to bytes that are not valid UTF-8
}

// The same bytes in an opaque member are just bytes and round-trip
print(XdrDataValue.fromXdrJson('"c3"').toXdrJson()); // "c3"
```

This limitation is exactly the one the binary path already has. The XDR decoder throws on a non-UTF-8 `string<>` too, so such a value cannot reach the JSON path from a real envelope. The JSON path accepts what the binary path accepts, no more and no less. Opaque-backed members, including asset codes and every fixed opaque field, hold raw bytes and are unaffected.

### Divergences from the reference implementation

This SDK's behaviour differs from the reference implementation in four places, and each difference is deliberate. In the first three the reference departs from SEP-51 and this SDK follows the specification. The fourth is a value the specification leaves unresolved, where the reference is asymmetric and this SDK makes a choice of its own. If you check this SDK against the reference, these are the four differences you will see.

#### A standalone 64-bit value renders as a string

Addressed on its own, `XdrInt64` and `XdrUint64` emit a base-10 string, the same rendering they take as a struct field. The reference emits a bare JSON number for the standalone case. The specification's Hyper Integer (64-bit) section is unambiguous, and the named typedefs (`SequenceNumber`, `TimePoint`, `Duration`) already agree with it.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

print(XdrInt64.fromXdrJson('"-1"').toXdrJson());  // "-1"
print(XdrInt64.fromXdrJson('"-1"').toBase64EncodedXdrString()); // //////////8=
```

#### Inline fixed-length opaque renders as hexadecimal

Where the XDR definition declares an opaque field inline rather than through a named typedef, the reference emits an array of byte numbers. The specification's Opaque Data (Fixed Length) section requires a hexadecimal string, which is what this SDK emits. Seven types are affected. Five declare the opaque field themselves: `XdrCurve25519Secret`, `XdrCurve25519Public`, `XdrHmacSha256Key`, `XdrHmacSha256Mac` and `XdrShortHashSeed`. The other two inherit it: `XdrSerializedBinaryFuseFilter` through the `XdrShortHashSeed` members it carries, and `XdrPeerAddress` through the inline `ipv4` and `ipv6` declarations of its `ip` arm.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrPeerAddress peer =
    XdrPeerAddress.fromBase64EncodedXdrString('AAAAAH8AAAEAAC1pAAAAAw==');
print(peer.toXdrJson());
// {"ip":{"i_pv4":"7f000001"},"port":11625,"num_failures":3}
// The reference emits {"ip":{"i_pv4":[127,0,0,1]}, ...}

XdrShortHashSeed seed =
    XdrShortHashSeed.fromBase64EncodedXdrString('AQIDBAUGBwgJCgsMDQ4PEA==');
print(seed.toXdrJson()); // {"seed":"0102030405060708090a0b0c0d0e0f10"}
```

#### `$schema` is accepted

The reference rejects the property as an unknown field. The specification requires objects to allow it, so this SDK accepts and strips it. It is the only key this decoder accepts that the reference refuses.

#### A zero-length signed payload is refused

`SignerKeyEd25519SignedPayload` with an empty `payload<64>` is valid XDR, but no strkey form of it exists that the ecosystem reads back. The reference is asymmetric here: it renders such a value as a P-strkey and then refuses to read that same strkey back. The specification does not settle the case, so this SDK chooses to refuse it in both directions rather than emit a document nothing can decode:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrSignerKey.fromXdrJson(
      '"PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAED2A"');
} on FormatException catch (e) {
  print(e.message);
  // XDR-JSON XdrSignedPayload holds a malformed strkey:
  // "PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA..." (Encoded string must be
  // 69 to 165 characters, got 63)
}
```

An empty payload leaves the P-address 63 characters wide, short of the 69 the shortest signed payload occupies, so the strkey codec turns it away on length and the reader restates that. The encoding direction reports the bound directly, as `carries an empty payload, which has no strkey rendering`.

Payloads of 1 to 64 bytes render and read back normally. Only the empty one has no rendering.

### The number path

Two limits apply to documents that render a 64-bit integer, or a 32-bit one, as a JSON number. Neither reaches a document in the canonical form, where a 64-bit integer is a string.

#### A JSON number is accepted for a 64-bit field only below 2^53

The specification asks implementations to keep reading the XDR-JSON v1 number form where they can, and this SDK does, up to the largest magnitude a JSON number carries exactly. Past that the parser has already rounded, and the rounded value is itself a whole number, so nothing about it can recover what the document meant. Such input is refused rather than returned wrong:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrTimeBounds v1 =
    XdrTimeBounds.fromXdrJson('{"min_time":9007199254740992,"max_time":0}');
print(v1.minTime.uint64);   // 9007199254740992
print(v1.toXdrJson());      // {"min_time":"9007199254740992","max_time":"0"}

try {
  XdrTimeBounds.fromXdrJson('{"min_time":9007199254740994,"max_time":0}');
} on FormatException catch (e) {
  print(e.message); // ... which a JSON number cannot carry exactly
}
```

#### A whole double for a 32-bit field is target-dependent

`1.0` supplied where an `int32` or `uint32` is expected is refused on the Dart VM and accepted when compiled with dart2js. On dart2js the value is an integer and carries no signal that distinguishes it from `1`. Write `1`.

## Error handling

Every rejection is a `FormatException`, whatever the cause. Strkey failures and UTF-8 failures are caught at their boundary and reported under the same contract, so one `catch` covers the whole decoder:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrTimeBounds.fromXdrJson('{"min_time":"0"}');
} on FormatException catch (e) {
  print(e.message);
  // XDR-JSON XdrTimeBounds is missing the required key "max_time"
}
```

Messages name the type and, where the failure is at a field, the key. Values quoted back into a message are truncated and control bytes are escaped, so a hostile document cannot inject line breaks into a log through an exception.

Text that is not JSON at all arrives as the same exception type, but its wording comes from Dart's parser and differs between compilation targets. Match on the type, not on the message, for that case:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrTimeBounds.fromXdrJson('{');
} on FormatException catch (e) {
  print('not valid XDR-JSON: ${e.message}');
}
```

Encoding raises the same type. A value outside its declared range, a field longer than its declared maximum or a tree nested past the limit comes back from `toXdrJson()` as a `FormatException` rather than as malformed output.

## Related SEPs

- [SEP-11](sep-11.md) - Txrep, the other human-readable rendering of a transaction. Txrep covers transaction envelopes; XDR-JSON covers every XDR type.
- [SEP-23](sep-23.md) - StrKey encoding, which is how addresses and identifiers appear in XDR-JSON documents.

## Reference

- [SEP-51 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md)
- [XDR-JSON runtime source](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/xdr/xdr_json_helper.dart)

---

[Back to SEP Overview](README.md)
