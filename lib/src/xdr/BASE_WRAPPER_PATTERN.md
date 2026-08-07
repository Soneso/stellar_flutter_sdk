# XDR Base+Wrapper Pattern

## Why

22 XDR classes have hand-written helper methods (factories, base64 encoding,
BigInt helpers, etc.) that must survive xdrgen regeneration. The solution:
split each into a **base file** (replaceable by xdrgen) and a **wrapper file**
(hand-maintained).

## Structure

```
xdr_foo_base.dart   ← xdrgen output: fields, encode(), decode(), decodeAs()
xdr_foo.dart        ← hand-maintained: extends base, custom methods only
```

No code outside `lib/src/xdr/` imports base files directly. The wrapper
preserves the original public API.

## Patterns

### Union types (`decodeAs<T>`)

The base provides a generic factory that accepts a constructor parameter:

```dart
class XdrFooBase {
  static T decodeAs<T extends XdrFooBase>(
    XdrDataInputStream stream, T Function(DiscType) constructor,
  ) {
    T decoded = constructor(DiscType.decode(stream));
    switch (decoded.discriminant) { /* populate fields */ }
    return decoded;
  }
}
```

The wrapper calls it with its own constructor:

```dart
class XdrFoo extends XdrFooBase {
  static XdrFoo decode(XdrDataInputStream stream) {
    return XdrFooBase.decodeAs(stream, XdrFoo.new);
  }
}
```

### Sequential types

Wrapper uses Dart super parameters and decode-reconstruct:

```dart
class XdrFoo extends XdrFooBase {
  XdrFoo(super.field1, super.field2);

  static XdrFoo decode(XdrDataInputStream stream) {
    var b = XdrFooBase.decode(stream);
    return XdrFoo(b.field1, b.field2);
  }
}
```

### Static members (`fromBase64EncodedXdrString`, `fromXdrJson`, `fromXdrJsonValue`)

Dart does not inherit static members. A static declared only on the base is not
reachable through the wrapper, so `XdrFoo.fromXdrJson(json)` does not compile
unless `XdrFoo` declares it. Instance members (`toBase64EncodedXdrString`,
`toXdrJson`, `toXdrJsonValue`) are inherited and need nothing.

Every wrapper therefore redeclares the SEP-0051 entry points, returning its own
type so callers keep the wrapper's API. `fromXdrJson` is the same everywhere;
`fromXdrJsonValue` follows the type's own pattern, exactly as `decode` does.

Union types go through the base's generic factory, so the arms stay in one
place:

```dart
class XdrFoo extends XdrFooBase {
  static XdrFoo fromXdrJson(String json) =>
      fromXdrJsonValue(XdrJsonHelper.decodeDocument(json, type: 'XdrFoo'));

  static XdrFoo fromXdrJsonValue(Object? value) =>
      XdrFooBase.fromXdrJsonValueAs(value, XdrFoo.new);
}
```

Sequential types reconstruct through their constructor, which is what makes a
new field a compile error rather than a silent omission:

```dart
class XdrFoo extends XdrFooBase {
  static XdrFoo fromXdrJson(String json) =>
      fromXdrJsonValue(XdrJsonHelper.decodeDocument(json, type: 'XdrFoo'));

  static XdrFoo fromXdrJsonValue(Object? value) {
    var b = XdrFooBase.fromXdrJsonValue(value);
    return XdrFoo(b.field1, b.field2);
  }
}
```

The split is not a style choice. A union has no constructor carrying its arms,
so reconstructing one by hand means copying every arm across and gaining a
place to forget one; a sequential type has no generic factory to go through.
Each shape is the only safe one for its pattern.

Returning the base type instead compiles but is wrong: the caller loses the
wrapper's own members, so `XdrTransactionEnvelope.fromXdrJson(...).toEnvelopeXdrBase64()`
would not resolve.

### Three-level inheritance

For types extending `XdrAsset`:
`XdrAsset` → `XdrChangeTrustAssetBase extends XdrAsset` → `XdrChangeTrustAsset extends XdrChangeTrustAssetBase`

## Rules for xdrgen

- Regenerate only `*_base.dart` files.
- Never modify wrapper files.
- Base files must keep the same class name, field names, and `decodeAs` signature.
- When a base union gains an arm, every wrapper whose `fromTxRep` copies base
  fields one by one (`result.x = b.x`) must gain a copy line for the new arm's
  field. The analyzer cannot detect the omission; the missed field silently
  stays null and `encode` throws at runtime. Wrappers that reconstruct through
  their constructor are immune.
- Every static the base declares must be redeclared on the wrapper, returning
  the wrapper type. This covers `fromBase64EncodedXdrString`, `fromXdrJson` and
  `fromXdrJsonValue`. Nothing detects the omission until a caller tries to use
  the member, so a base gaining a static is a change to every wrapper.
- A base union declares `fromXdrJsonValueAs<T>` beside `decodeAs<T>`, so a
  wrapper reads its arms back through its own constructor rather than by
  copying them across. That is what keeps arm completeness structural: an arm
  added upstream reaches every wrapper without an edit.
- `XdrSCValBase` has a circular import to `xdr_sc_val.dart` — this is required
  for self-referencing `List<XdrSCVal>` fields.

## Files

- 22 base files (`*_base.dart`)
- 22 wrapper files, each extending its base and carrying the public type name
- The set is `BASE_WRAPPER_TYPES` in
  `tools/xdr-generator/generator/type_overrides.rb`, which is what decides
  whether a type is emitted to `xdr_foo_base.dart` or to `xdr_foo.dart`.
- Barrel: `xdr.dart` exports both base and wrapper files
