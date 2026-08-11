# SEP-51: XDR-JSON

**Purpose:** Render any XDR value as a canonical JSON document and read it back to the same bytes.
**Prerequisites:** None
**SDK Class:** every generated `Xdr*` type, over the shared runtime `XdrJsonHelper`
**Specification:** SEP-0051 v2.0.1, Draft

## Overview

Every generated XDR type in the SDK carries four members:

| Member | Direction | Returns |
|--------|-----------|---------|
| `String toXdrJson()` | out | the canonical document as text |
| `Object? toXdrJsonValue()` | out | the same document as a Dart tree |
| `static T fromXdrJson(String json)` | in | the value, parsed from text |
| `static T fromXdrJsonValue(Object? value)` | in | the value, read from a tree |

The tree form is what `dart:convert` produces and consumes: `Map<String, dynamic>`, `List<dynamic>`, `String`, `num`, `bool` and `null`. Use it to inspect or edit a document without a second parse.

There is no service class and no separate import. The methods come with the XDR types, which the SDK already exports.

`toXdrJson()` emits one line with no whitespace, and keys follow the order the XDR definition declares the fields in. Two runs on the same value produce the same bytes on every platform the SDK supports.

## Quick Start

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String envelopeBase64 = 'AAAAAgAAAADmmSZkwY3163TMouB2TY8MljqXw2IxVYTGyvDrR6Yt...';

XdrTransactionEnvelope envelope =
    XdrTransactionEnvelope.fromBase64EncodedXdrString(envelopeBase64);

String json = envelope.toXdrJson();
// {"tx":{"tx":{"source_account":"GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA",
//  "fee":2792036,"seq_num":"29059748724737","cond":"none","memo":"none", ... }}

XdrTransactionEnvelope parsed = XdrTransactionEnvelope.fromXdrJson(json);
print(parsed.toBase64EncodedXdrString() == envelopeBase64); // true
```

The same four members work on every XDR type, not only on the envelope:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrMemo memo = XdrMemo.fromBase64EncodedXdrString('AAAAAQAAAAVoZWxsbwAAAA==');

String document = memo.toXdrJson();      // {"text":"hello"}
Object? tree = memo.toXdrJsonValue();    // {'text': 'hello'}

XdrMemo fromDocument = XdrMemo.fromXdrJson(document);
XdrMemo fromTree = XdrMemo.fromXdrJsonValue(tree);
print(fromDocument.text); // hello
print(fromTree.text);     // hello
```

## Integers

32-bit fields are JSON numbers. 64-bit fields are base-10 strings, so the full range survives a JavaScript runtime, whose number type stops being exact at 2^53.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 32-bit: numbers on both sides
XdrLedgerBounds bounds =
    XdrLedgerBounds.fromXdrJson('{"min_ledger":1,"max_ledger":2}');
print(bounds.minLedger.uint32);  // 1
print(bounds.toXdrJson());       // {"min_ledger":1,"max_ledger":2}

// 64-bit: base-10 strings, carried as BigInt in Dart
XdrTimeBounds times =
    XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1735689600"}');
print(times.maxTime.uint64);  // 1735689600
print(times.toXdrJson());     // {"min_time":"0","max_time":"1735689600"}

XdrUint64 max = XdrUint64.fromXdrJson('"18446744073709551615"');
print(max.uint64);       // 18446744073709551615
print(max.toXdrJson());  // "18446744073709551615"
```

A 64-bit value never passes through `int`, `num` or `jsonEncode`'s numeric path, so nothing rounds on dart2js.

The 128-bit and 256-bit parts types render as one decimal string rather than as an object of limbs: `XdrInt128Parts`, `XdrUInt128Parts`, `XdrInt256Parts` and `XdrUInt256Parts` each read and write a single base-10 string.

An older producer may render a 64-bit field as a JSON number. That form is accepted up to 2^53, where a JSON number is still exact, and re-emitted as a string:

```dart
XdrTimeBounds v1 =
    XdrTimeBounds.fromXdrJson('{"min_time":9007199254740992,"max_time":0}');
print(v1.toXdrJson());  // {"min_time":"9007199254740992","max_time":"0"}

// Past 2^53 the parser has already rounded, so the value is refused
try {
  XdrTimeBounds.fromXdrJson('{"min_time":9007199254740994,"max_time":0}');
} on FormatException catch (e) {
  print(e.message); // ... which a JSON number cannot carry exactly
}
```

## Booleans

An XDR `bool` is a JSON boolean, as a union arm and as a struct member alike. Nothing else counts: `"true"`, `"false"`, `1` and `0` are refused.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCVal flag = XdrSCVal.fromXdrJson('{"bool":true}');
print(flag.b);            // true
print(flag.toXdrJson());  // {"bool":true}
print(XdrSCVal.forBool(false).toXdrJson()); // {"bool":false}

try {
  XdrSCVal.fromXdrJson('{"bool":"true"}');
} on FormatException catch (e) {
  print(e.message); // ... expects a boolean but found "true"
}
```

## Opaque Data and Text

Opaque fields, fixed and variable, render as lowercase hexadecimal. An empty variable-length field is `""`, never `"0"`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSignatureHint hint = XdrSignatureHint.fromBase64EncodedXdrString('YWJjZA==');
print(hint.toXdrJson());  // "61626364"

print(XdrDataValue.fromXdrJson('"deadbeef"').toXdrJson());        // "deadbeef"
print(XdrDataValue.fromXdrJson('""').toBase64EncodedXdrString()); // AAAAAA==
```

Text fields take the escape ladder of SEP-51: `\0`, `\t`, `\n`, `\r` and `\\` have short forms, printable ASCII passes through, and every other byte becomes `\xNN` with two lowercase hexadecimal digits. The ladder runs over bytes, so one multi-byte character produces one escape per byte. The result is then a JSON string, which is where the second backslash comes from.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrMemo tab = XdrMemo.fromBase64EncodedXdrString('AAAAAQAAAAh0YWIJaGVyZQ==');
print(tab.toXdrJson());  // {"text":"tab\\there"}

XdrManageDataOp op = XdrManageDataOp.fromXdrJson(
    r'{"data_name":"caf\\xc3\\xa9","data_value":null}');
print(op.dataName.string64);  // café
print(op.toXdrJson());        // {"data_name":"caf\\xc3\\xa9","data_value":null}
```

## Addresses and Asset Codes

Address-shaped types render as strkeys, by arm:

| Type | Rendering |
|------|-----------|
| `XdrAccountID`, `XdrNodeID`, `XdrPublicKey` | `G...` |
| `XdrMuxedAccount` | `G...` or `M...` |
| `XdrMuxedAccountMed25519` | `M...` |
| `XdrSCAddress` | `G...`, `C...`, `M...`, `B...` or `L...` |
| `XdrSignerKey` | `G...`, `T...`, `X...` or `P...` |
| `XdrSignedPayload` | `P...` |
| contract identifiers | `C...` |
| liquidity pool identifiers | `L...` |
| claimable balance identifiers | `B...` |

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String muxed =
    '"MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFNZG"';
print(XdrSCAddress.fromXdrJson(muxed).toXdrJson() == muxed); // true

// The key name comes from the XDR field name, not from the Dart member name
XdrContractEvent event =
    XdrContractEvent.fromBase64EncodedXdrString('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB');
print(event.toXdrJson());
// {"ext":"v0","contract_id":null,"type":"system","body":{"v0":{"topics":[],"data":"void"}}}
```

Asset codes are opaque, so they take the escape ladder too. A four-byte code drops its trailing NUL padding; a twelve-byte code drops trailing NULs down to five bytes and no further, which is what keeps the two widths distinguishable.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// AssetCode4 holding three bytes
print(XdrAllowTrustOpAsset.fromBase64EncodedXdrString('AAAAAUFCQwA=').toXdrJson());
// "ABC"

// AssetCode12 holding three bytes, padded back to five
print(XdrAllowTrustOpAsset.fromBase64EncodedXdrString('AAAAAkFCQwAAAAAAAAAAAA==')
    .toXdrJson());
// "ABC\\0\\0"
```

## Unions: a void arm is not an absent value

This is the distinction that costs the most time. A void arm renders as a bare string. An arm that carries a value renders as a single-key object. An arm whose declared value is optional keeps the object shape and puts `null` inside it. Three documents that look alike carry different bytes:

| Document | Meaning | Bytes |
|----------|---------|-------|
| `"void"` | the `SCV_VOID` arm, which carries nothing | `AAAAAQ==` |
| `{"vec":null}` | the `SCV_VEC` arm, its optional vector absent | `AAAAEAAAAAA=` |
| `{"vec":[]}` | the `SCV_VEC` arm, holding an empty vector | `AAAAEAAAAAEAAAAA` |

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCVal voidArm = XdrSCVal.fromXdrJson('"void"');
XdrSCVal absentVec = XdrSCVal.fromXdrJson('{"vec":null}');
XdrSCVal emptyVec = XdrSCVal.fromXdrJson('{"vec":[]}');

print(voidArm.toBase64EncodedXdrString());    // AAAAAQ==
print(absentVec.toBase64EncodedXdrString());  // AAAAEAAAAAA=
print(emptyVec.toBase64EncodedXdrString());   // AAAAEAAAAAEAAAAA

print(absentVec.vec);  // null
print(emptyVec.vec);   // []
```

Writing the bare string for an arm that is not void is refused rather than read as an absent value:

```dart
// WRONG: "vec" is not a void arm
try {
  XdrSCVal.fromXdrJson('"vec"');
} on FormatException catch (e) {
  print(e.message); // XDR-JSON XdrSCVal has no arm named "vec"
}

// CORRECT: name the state you mean
XdrSCVal.fromXdrJson('{"vec":null}');  // arm present, vector absent
XdrSCVal.fromXdrJson('{"vec":[]}');    // arm present, vector empty
```

A union whose discriminant is a plain integer keys on the letter `v` plus the number: `"v0"` for a void arm, `{"v1": ...}` otherwise. That covers `XdrExtensionPoint` and every `...Ext` union.

## Structs

A struct renders as an object whose keys are the snake_case forms of the XDR field names. Every declared key has to be present on input, including the key of an optional field whose value is `null`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// WRONG: contract_id dropped because its value would be null
try {
  XdrContractEvent.fromXdrJson(
      '{"ext":"v0","type":"system","body":{"v0":{"topics":[],"data":"void"}}}');
} on FormatException catch (e) {
  print(e.message); // ... is missing the required key "contract_id"
}

// CORRECT: the key stays, the value is null
XdrContractEvent.fromXdrJson('{"ext":"v0","contract_id":null,"type":"system",'
    '"body":{"v0":{"topics":[],"data":"void"}}}');
```

Seven types declare an XDR field named `type`. They emit the key `type` and also accept `type_` on input, a spelling older producers emit. `type_` is never emitted, and supplying both spellings is refused rather than resolved to either one. The seven are `XdrContractEvent`, `XdrDontHave`, `XdrSCSpecEventParamV0`, `XdrSCSpecFunctionInputV0`, `XdrSCSpecUDTStructFieldV0`, `XdrSCSpecUDTUnionCaseTupleV0` and `XdrSerializedBinaryFuseFilter`.

## Optional Values

An optional field renders as `null` when unset and as the value itself when set. The key stays in the object either way.

One array in the Stellar definitions holds an optional element type. `XdrAccountEntryV2.signerSponsoringIDs` is a `List<XdrAccountID?>`, and a `null` element occupies a position rather than being dropped, because the binary encoding writes a presence flag per element:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrAccountEntryV2 sponsors = XdrAccountEntryV2.fromXdrJson(
    '{"num_sponsored":0,"num_sponsoring":1,'
    '"signer_sponsoring_i_ds":[null],"ext":"v0"}');

print(sponsors.signerSponsoringIDs.length);  // 1
print(sponsors.signerSponsoringIDs.first);   // null
print(sponsors.toBase64EncodedXdrString());  // AAAAAAAAAAEAAAABAAAAAAAAAAA=
```

## The `$schema` Property

SEP-51 says JSON objects should allow, but not require, a `$schema` property. The SDK accepts it wherever an object is accepted, at any depth, removes it before anything else reads the object, and never emits it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String document =
    r'{"$schema":"https://stellar.org/schema/xdr-json/main/Asset.json",'
    '"credit_alphanum4":{"asset_code":"ABCD","issuer":'
    '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';

print(XdrAsset.fromXdrJson(document).toXdrJson());
// {"credit_alphanum4":{"asset_code":"ABCD",
//  "issuer":"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}
```

The property carries no further privilege. An object holding nothing but `$schema` is an object holding nothing, so a struct still requires its fields and a union arm still requires its one key.

## Input Strictness

SEP-51 fixes one rendering per value, and that is the only rendering this SDK emits. On input it accepts a few documented variations, listed below, and refuses everything else. These are SDK rules, chosen so that a byte-for-byte comparison of two emitted documents stays meaningful:

- hexadecimal is lowercase and of even length;
- a `\x` escape carries exactly two lowercase hexadecimal digits, and an escape the ladder does not define is refused rather than passed through;
- a decimal integer carries no leading `+`, no leading zero, no exponent and no fraction;
- a repeated object key is refused; Dart's own parser would silently keep the last occurrence;
- an enum takes its wire name, not the XDR identifier and not the numeric value;
- a fixed-length field is held to its declared length, and a variable-length field to its declared maximum;
- nesting is bounded at `XdrJsonHelper.maxDepth`, which is 128, the same bound the binary decoder applies. The bound is checked before the document reaches the JSON encoder or parser.

Each of these throws a `FormatException` carrying the message shown:

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
// ... expects lowercase hexadecimal digits
report('odd-length hex', () => XdrDataValue.fromXdrJson('"deadbee"'));
// ... has an odd number of hexadecimal digits
report('leading zero',
    () => XdrTimeBounds.fromXdrJson('{"min_time":"007","max_time":"0"}'));
// ... expects a base-10 uint64 string but found "007"
report('repeated key',
    () => XdrTimeBounds.fromXdrJson(
        '{"min_time":"1","min_time":"2","max_time":"3"}'));
// ... repeats the object key "min_time"
```

A key a type does not declare is refused as well. A type has one set of field names, so a document carrying anything else is describing something other than that type:

```dart
try {
  XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1","foo":2}');
} on FormatException catch (e) {
  print(e.message); // XDR-JSON XdrTimeBounds has the unknown key "foo"
}

// Several are reported together, in sorted order
try {
  XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1","zeta":2,"alpha":3}');
} on FormatException catch (e) {
  print(e.message); // XDR-JSON XdrTimeBounds has the unknown keys "alpha", "zeta"
}
```

## Comparing Documents

The emitted form is canonical, so two equal values produce identical bytes and you can compare `toXdrJson()` results directly.

The reverse does not hold for documents you did not emit. No normalizer ships with the SDK, and a document from another producer may differ byte for byte while describing the same value: it may be indented, order its struct keys differently, carry a `$schema` property, or render a 64-bit field as a JSON number. All of those are accepted on input, and none survives into the output.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String canonical = '{"text":"hello"}';
String spaced = '{ "text" : "hello" }';

// WRONG: comparing two foreign texts answers a different question
print(canonical == spaced); // false

// CORRECT: parse both, then compare the re-emitted text or the base64
XdrMemo a = XdrMemo.fromXdrJson(canonical);
XdrMemo b = XdrMemo.fromXdrJson(spaced);
print(a.toXdrJson() == b.toXdrJson()); // true
print(b.toXdrJson() == canonical);     // true

// A producer that orders the struct keys differently is accepted too, and the
// output carries the declared order either way
print(XdrTimeBounds.fromXdrJson('{"max_time":"1","min_time":"0"}').toXdrJson());
// {"min_time":"0","max_time":"1"}
```

## Error Handling

Every rejection is a `FormatException`, whatever the cause. Strkey failures and UTF-8 failures are caught at their boundary and reported under the same contract, so one `catch` covers the decoder:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  XdrTimeBounds.fromXdrJson('{"min_time":"0"}');
} on FormatException catch (e) {
  print(e.message);
  // XDR-JSON XdrTimeBounds is missing the required key "max_time"
}
```

Messages name the type and, where the failure is at a field, the key. Quoted values are truncated and control bytes escaped, so a hostile document cannot inject line breaks into a log through an exception message.

Text that is not JSON at all arrives as the same exception type, but its wording comes from Dart's parser and differs between compilation targets. Match on the type, not the message, for that case:

```dart
// WRONG: the message for malformed JSON differs between the VM and dart2js
try {
  XdrTimeBounds.fromXdrJson('{');
} on FormatException catch (e) {
  if (e.message.contains('Unexpected end of input')) { /* ... */ }
}

// CORRECT: match the type
try {
  XdrTimeBounds.fromXdrJson('{');
} on FormatException {
  print('not valid XDR-JSON');
}
```

Encoding raises the same type. A value outside its declared range, a field longer than its declared maximum, or a tree nested past the limit comes back from `toXdrJson()` as a `FormatException` rather than as malformed output.

## Limitations

**Text members carry UTF-8 only.** An XDR `string<>` is a Dart `String`, so its bytes are text, and a document whose escapes resolve to bytes that are not valid UTF-8 is refused. The binary decoder refuses the same bytes, so such a value cannot reach the JSON path from a real envelope. Opaque-backed members, including asset codes and every fixed opaque field, hold raw bytes and are unaffected.

```dart
// 0xc3 alone is not valid UTF-8
try {
  XdrManageDataOp.fromXdrJson(r'{"data_name":"\\xc3","data_value":null}');
} on FormatException catch (e) {
  print(e.message); // ... resolves to bytes that are not valid UTF-8
}

// The same bytes in an opaque member round-trip
print(XdrDataValue.fromXdrJson('"c3"').toXdrJson()); // "c3"
```

**A whole double for a 32-bit field is target-dependent.** `1.0` supplied where an `int32` or `uint32` is expected is refused on the Dart VM and accepted when compiled with dart2js, where the value is an integer and carries no signal that distinguishes it from `1`. Write `1`.

### Divergences from the reference implementation

This SDK's behaviour differs from the reference implementation in four places, and each difference is deliberate. In the first three the reference departs from SEP-51 and this SDK follows the specification. The fourth is a value the specification leaves unresolved, where the reference is asymmetric and this SDK makes a choice of its own.

- **A standalone 64-bit value renders as a string.** Addressed on its own, `XdrInt64` and `XdrUint64` emit a base-10 string, the same rendering they take as a struct field. The reference emits a bare number for the standalone case.
- **Inline fixed-length opaque renders as hexadecimal.** Where the XDR definition declares an opaque field inline rather than through a named typedef, the reference emits an array of byte numbers. Seven types are affected: `XdrCurve25519Secret`, `XdrCurve25519Public`, `XdrHmacSha256Key`, `XdrHmacSha256Mac`, `XdrShortHashSeed`, `XdrSerializedBinaryFuseFilter`, and `XdrPeerAddress` through its `ip` arm.
- **`$schema` is accepted.** The reference rejects it as an unknown field. It is the only key this decoder accepts that the reference refuses.
- **A zero-length signed payload is refused.** `SignerKeyEd25519SignedPayload` with an empty `payload<64>` is valid XDR, but no strkey form of it exists that the ecosystem reads back. The reference renders it as a P-strkey and then refuses to read that same strkey back; the specification does not settle the case, so this SDK refuses it in both directions. Payloads of 1 to 64 bytes render and read back normally.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

print(XdrInt64.fromXdrJson('"-1"').toXdrJson()); // "-1"

XdrPeerAddress peer =
    XdrPeerAddress.fromBase64EncodedXdrString('AAAAAH8AAAEAAC1pAAAAAw==');
print(peer.toXdrJson());
// {"ip":{"i_pv4":"7f000001"},"port":11625,"num_failures":3}
```

## When Not to Use XDR-JSON

- Not as a network format. Horizon and the RPC take base64 XDR.
- Not as long-lived storage. XDR-JSON changes from one protocol to the next, because the Stellar XDR does. Keep the base64 as the record and treat the JSON as a view of it.
- Not as an application API. Key names come from the XDR field names, so a protocol upgrade that renames or restructures a field changes your consumers' documents.
- Not as a compact encoding. A document runs several times the size of the equivalent base64 and costs a parse on top.
- Not for non-XDR SDK types. `Transaction`, `Asset`, `KeyPair` and the Horizon and RPC response classes are not XDR structures and carry no XDR-JSON. `Transaction.toEnvelopeXdr()` gets you to an XDR type that does.

## Common Pitfalls

```dart
// WRONG: no XDR type declares toJson(), so jsonEncode throws
// JsonUnsupportedObjectError rather than producing XDR-JSON
String bad = jsonEncode(memo);

// CORRECT: the methods carry the Xdr infix
String good = memo.toXdrJson();
```

```dart
// WRONG: toXdrJsonValue returns the tree, not the text
String bad = memo.toXdrJsonValue() as String;

// CORRECT: toXdrJson for text, toXdrJsonValue for the tree
String text = memo.toXdrJson();
Object? tree = memo.toXdrJsonValue();
```

```dart
// WRONG: when you write a document by hand, a 64-bit field is a string.
// The number form is read for compatibility, but only below 2^53, and it is
// never emitted.
XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":1735689600}');

// CORRECT: the canonical form
XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1735689600"}');
```

```dart
// WRONG: dropping an optional key because its value is null
XdrContractEvent.fromXdrJson('{"ext":"v0","type":"system",'
    '"body":{"v0":{"topics":[],"data":"void"}}}');

// CORRECT: every declared key is present, null included
XdrContractEvent.fromXdrJson('{"ext":"v0","contract_id":null,"type":"system",'
    '"body":{"v0":{"topics":[],"data":"void"}}}');
```

```dart
// WRONG: uppercase hexadecimal
XdrDataValue.fromXdrJson('"DEADBEEF"');

// CORRECT: lowercase, even length
XdrDataValue.fromXdrJson('"deadbeef"');
```
