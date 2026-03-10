# XDR Base+Wrapper Pattern

## Why

32 XDR classes have hand-written helper methods (factories, base64 encoding,
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

### Three-level inheritance

For types extending `XdrAsset`:
`XdrAsset` → `XdrChangeTrustAssetBase extends XdrAsset` → `XdrChangeTrustAsset extends XdrChangeTrustAssetBase`

## Rules for xdrgen

- Regenerate only `*_base.dart` files.
- Never modify wrapper files.
- Base files must keep the same class name, field names, and `decodeAs` signature.
- `XdrSCValBase` has a circular import to `xdr_sc_val.dart` — this is required
  for self-referencing `List<XdrSCVal>` fields.

## Files

- 32 base files (`*_base.dart`)
- 32 wrapper files (original names, now extending base)
- Barrel: `xdr.dart` exports both base and wrapper files
- Automation: `tools/split_xdr_wrappers.py`
