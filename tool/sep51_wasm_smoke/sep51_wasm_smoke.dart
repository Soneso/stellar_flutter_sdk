// SEP-0051 nesting guard, executed on the WasmGC target.
//
// This target is the reason the guard is a pre-scan rather than a `try/catch`.
// A stack overflow inside the host's JSON encoder propagates out of Wasm as a
// host error that Dart cannot catch, and it terminates the process. The guard
// has to refuse an over-nested document before the encoder ever sees it,
// because once the encoder is reached there is nothing left to recover with.
//
// So this harness asserts two things and reports them by exit code: a document
// nested to exactly the cap is encoded and parsed normally, and one nested a
// single level deeper is refused with a `FormatException`. If the guard ever
// regresses to catching, the second case does not fail here — it kills the
// process, and the non-zero exit is the signal.
//
// Run it with `tool/sep51_wasm_smoke/run.sh`. It is deliberately outside
// `flutter test`, which has no WasmGC platform.

import 'package:stellar_flutter_sdk/src/xdr/xdr_json_helper.dart';

const String type = 'Sep51WasmSmoke';

int failures = 0;

void check(String what, bool ok) {
  if (ok) {
    print('ok   $what');
    return;
  }
  print('FAIL $what');
  failures++;
}

/// A tree of [containers] nested single-element lists.
Object? nestedValue(int containers) {
  Object? value = 0;
  for (int i = 0; i < containers; i++) {
    value = <Object?>[value];
  }
  return value;
}

/// The JSON text [nestedValue] renders to, built directly so the text form can
/// be pushed past the depth the value form refuses to render.
String nestedText(int containers) =>
    '${'[' * containers}0${']' * containers}';

void main() {
  final int cap = XdrJsonHelper.maxDepth;
  check('the cap is the number the guard is specified at', cap == 128);

  // At the cap, both directions work. A guard that refused here would be a
  // margin taken out of the usable range rather than the stated bound.
  final String encoded = XdrJsonHelper.encodeDocument(
    nestedValue(cap),
    type: type,
  );
  check('a document at the cap encodes', encoded == nestedText(cap));

  final Object? decoded = XdrJsonHelper.decodeDocument(
    nestedText(cap),
    type: type,
  );
  check('a document at the cap parses', decoded is List);

  // One level deeper, the guard refuses. Reaching the line after this call at
  // all is half of what the harness establishes: on this target an encoder
  // failure is not catchable, so a guard that let the value through would end
  // the process here instead of throwing.
  bool refusedOnEncode = false;
  try {
    XdrJsonHelper.encodeDocument(nestedValue(cap + 1), type: type);
  } on FormatException {
    refusedOnEncode = true;
  }
  check('a document past the cap is refused before the encoder',
      refusedOnEncode);

  bool refusedOnDecode = false;
  try {
    XdrJsonHelper.decodeDocument(nestedText(cap + 1), type: type);
  } on FormatException {
    refusedOnDecode = true;
  }
  check('a document past the cap is refused before the parser',
      refusedOnDecode);

  // Depth well past anything the host stack survives. The guard counts the
  // text without recursing, so this is refused the same way as the first level
  // past the cap rather than by running out of stack.
  bool refusedDeep = false;
  try {
    XdrJsonHelper.decodeDocument(nestedText(50000), type: type);
  } on FormatException {
    refusedDeep = true;
  }
  check('a deeply nested document is refused without recursion', refusedDeep);

  if (failures > 0) {
    print('$failures check(s) failed');
    throw StateError('SEP-0051 WasmGC nesting guard smoke test failed');
  }
  print('all checks passed');
}
