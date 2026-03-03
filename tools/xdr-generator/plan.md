# Plan: XDR Code Generator for Stellar Flutter SDK

## Context

The Flutter SDK has 376 hand-written XDR type files (+ 32 base files for wrapper types). When the Stellar protocol changes (new XDR types in `.x` files), these must be updated manually. The iOS SDK solved this with a Ruby-based generator using the `xdrgen` gem. We need the same for Dart.

The generator reads `.x` files via xdrgen's AST, produces Dart files matching existing code patterns exactly. For the 32 types with custom SDK helpers, it generates `*_base.dart` files; for all others, regular `*.dart` files.

## Architecture

```
tools/xdr-generator/
├── generate.rb                    # Entry point (like iOS SDK)
├── Gemfile                        # xdrgen dependency
├── generator/
│   ├── generator.rb              # Core Dart renderer (~1000 lines)
│   ├── name_overrides.rb         # XDR name → Dart class name
│   ├── field_overrides.rb        # XDR field name → Dart field name
│   └── type_overrides.rb         # Typedef resolution + BASE_WRAPPER_TYPES + SKIP_TYPES
├── plan.md                        # This file
├── fixes.md                       # Bug fixes in hand-written XDR (breaking changes)
├── learnings.md                   # Agent learnings across batches
└── progress.md                    # Batch progress tracking
xdr/                               # .x source files (copy from stellar-xdr)
```

Reference: iOS SDK generator at `/Users/chris/projects/Stellar/stellar-ios-mac-sdk/tools/xdr-generator/`

## Guiding Principles

1. **No breaking changes to user-facing SDK API** unless fixing a genuine bug.
   - Generated field types must match existing hand-written types (e.g., if original uses `int` for a uint32 field, generator must too).
   - Generated method signatures must match existing ones.
2. **Bug fixes are allowed** even if they cause breaking changes.
   - Missing switch cases, wrong field counts, incorrect types where the XDR definition is clearly different from the hand-written code.
   - All bug fixes must be documented in `fixes.md`.
3. **Format before comparing** — run `dart format` on both generated and original before diffing to eliminate cosmetic noise (blank lines, line wrapping).

## XDR → Dart Type Mapping

| XDR Type | Dart Type | Stream Method |
|----------|-----------|---------------|
| int | int | readInt/writeInt |
| unsigned int | int | readInt/writeInt |
| hyper | BigInt | readBigInt64Signed/writeBigInt64 |
| unsigned hyper | BigInt | readBigInt64/writeBigInt64 |
| bool | bool | readBoolean/writeBoolean |
| string | String | readString/writeString |
| opaque[N] | Uint8List | readBytes(N)/write |
| opaque<> | Uint8List (via XdrDataValue) | XdrDataValue.encode/decode |

## Dart Code Patterns

### Enum
```dart
class XdrFooType {
  final _value;
  const XdrFooType._internal(this._value);
  toString() => 'FooType.$_value';
  XdrFooType(this._value);
  get value => this._value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrFooType && _value == other._value;
  @override
  int get hashCode => _value.hashCode;

  static const CASE_A = const XdrFooType._internal(0);
  static const CASE_B = const XdrFooType._internal(1);

  static XdrFooType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0: return CASE_A;
      case 1: return CASE_B;
      default: throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrFooType value) {
    stream.writeInt(value.value);
  }
}
```

### Struct
Constructor takes all fields. Private fields with getters/setters. Static encode/decode methods.

### Union (enum discriminant)
Constructor takes only discriminant. Nullable fields for each arm. encode() writes discriminant then switches. decode() constructs with decoded discriminant then switches to populate.

### Union (int discriminant)
Same pattern but `int _v` discriminant, read via `stream.readInt()`.

### Union Base (32 wrapper types)
Same as union but class name `XdrFooBase`, adds `decodeAs<T>` generic factory.

### Special patterns
- **Optional fields**: `stream.readInt()` presence flag (1/0), then decode if != 0
- **Variable arrays**: `stream.readInt()` count, then loop decode into `List<T>.empty(growable: true)`
- **Fixed arrays**: hardcoded count in decode loop (e.g., `for (int i = 0; i < 4; i++)`)

## Naming Convention

- XDR `FooBar` → Dart class `XdrFooBar` → file `xdr_foo_bar.dart`
- Dart SDK uses `Xdr` prefix (not `XDR` suffix like iOS)
- Enum members preserved as-is from XDR (e.g., `ASSET_TYPE_NATIVE`)
- Discriminant field getter: `get discriminant` (not `get type`)

## Configuration Files

### name_overrides.rb
Maps XDR canonical names → Dart class names where default `Xdr{CamelCase}` doesn't match. Built by auditing existing 376 files against xdrgen AST names.

### field_overrides.rb
Maps XDR field names → Dart property names where they differ.

### type_overrides.rb
- `TYPE_OVERRIDES`: Typedef resolution (e.g., `XdrTimePoint` → `XdrUint64`)
- `BASE_WRAPPER_TYPES`: 32 types generating `*_base.dart`
- `SKIP_TYPES`: Initially all types; shrink per batch

## SKIP_TYPES Strategy

Start with ALL types in SKIP_TYPES. Remove batches at a time. After each batch:
1. Generate the types
2. `dart format` both generated and original, then diff
3. Fix generator issues
4. Run `dart analyze lib/src/xdr/`
5. Verify no breaking changes to SDK API
6. Document any bug fixes in `fixes.md`
7. Update `learnings.md` and `progress.md`

## Verification

After each batch:
```bash
# Format and diff
dart format <generated>
dart format <(git show HEAD:<original>)
diff <formatted_generated> <formatted_original>

# Analyze
dart analyze lib/src/xdr/

# Full SDK analyze (check cross-boundary compatibility)
dart analyze lib/
```

Final:
```bash
dart analyze
flutter test test/unit/  # 5602+ tests
```

## Key Files

- iOS reference generator: `/Users/chris/projects/Stellar/stellar-ios-mac-sdk/tools/xdr-generator/generator/generator.rb`
- iOS override files: `.../generator/{name,field,type}_overrides.rb`
- Existing Dart XDR: `lib/src/xdr/` (376 type files + 32 base + barrel + xdr_data_io)
- Base wrapper pattern: `lib/src/xdr/BASE_WRAPPER_PATTERN.md`
