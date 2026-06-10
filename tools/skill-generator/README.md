# Skill Generator

Python script that generates the agent-skill API reference file
(`skills/stellar-flutter-sdk/references/api_reference.md`) from the SDK's Dart
source.

## What it does

Extracts the public API of the package into a compact signature-only markdown
reference. The output is consumed by the `stellar-flutter-sdk` agent skill and
lets AI coding agents look up method/property/field signatures without reading
the raw Dart source.

Handled declaration kinds include classes (with all modifier combinations),
mixins, mixin classes, enums (including enhanced-enum fields, constants, and
constructors), extensions, and typedefs. Member extraction covers fields (typed
and inferred), const/factory/plain constructors, getters, setters, methods
(including generic methods), and operators.

## Prerequisites

- Python 3.9+ (standard library only, no external dependencies)

## Usage

Run from the repository root:

```bash
python3 tools/skill-generator/generate_api_reference.py
```

Output is written to
`skills/stellar-flutter-sdk/references/api_reference.md` (overwriting the
previous generation).

Before a release, rebuild the skill zip so the bundled archive matches the new
reference content:

```bash
cd skills
rm -f stellar-flutter-sdk.zip
cd stellar-flutter-sdk && zip -r ../stellar-flutter-sdk.zip . -x "*.DS_Store"
```

## When to regenerate

Regenerate whenever the SDK's public API surface changes:

- New SEP implementation added
- New public class, method, field, getter, or setter in any non-XDR source area
- Type moved between directories
- Field renamed, type changed, or signature otherwise modified
- Type deprecated or removed

Stale generation will not break the SDK build, but the agent skill will offer
out-of-date guidance to consumers.

## What gets scanned

- **Public-API allowlist (the load-bearing filter)**: a declaration is emitted
  only when its declaring file is reachable from the public barrel
  (`lib/stellar_flutter_sdk.dart`) via the transitive `export` graph. This is
  the authority for what counts as public API. Conditional exports select the
  platform implementation target.
- **Scanned source**: a recursive walk of `lib/src/`, filtered by the allowlist
  above.
- **Excluded directories**: `xdr/`.
- **Excluded files**: the conditional HTTP / Soroban-HTTP implementation and
  stub files (`http_client_io.dart`, `http_client_stub.dart`,
  `soroban_http_io.dart`, `soroban_http_stub.dart`).
- **Excluded declarations**: private, underscore-prefixed (`_`) classes,
  methods, fields, getters, and setters. Only public declarations are emitted.
- **Captured member kinds**: typed and inferred fields, const/factory/plain
  constructors, getters, setters, methods (including generic methods such as
  `name<T>(...)`), operators (`operator ==`, `operator []`, etc.), enhanced-enum
  fields and constructors, extensions, and typedefs.

## Output format

Each type produces a section like:

```
## class TypeName extends ParentType implements SomeInterface
static const int kDefault
final String publicField
TypeName(this.publicField)
SomeType get publicProperty
Future<ReturnType> publicMethod(Type arg) async
```

Types are grouped into buckets driven by the source-file path (core, requests,
responses, soroban, sep, constants).

## Handled declaration kinds

The parser recognizes these top-level declaration shapes:

- `class`, including any combination of the modifiers `abstract`, `final`,
  `sealed`, `base`, `interface` (in any order), with optional type parameters
  and `extends` / `with` / `implements` clauses
- `mixin class`
- `mixin`
- `enum` (values plus any methods/getters after the values block)
- `extension Name on Type` (named; members extracted like class members).
  Anonymous extensions are emitted only when they have an `on Type` and at
  least one member
- `typedef`, both the modern `typedef Name = ...;` form and the legacy
  `typedef ReturnType Name(args);` form (the aliased signature is shown as the
  section content)

Public filter: a declaration is emitted only when its declaring file is
reachable from the public barrel (`lib/stellar_flutter_sdk.dart`) via the
transitive `export` graph, and the declared name is public (no leading
underscore). Conditional exports select the platform implementation target.

## Coverage sanity scan

After parsing, two diagnostic scans run:

- **Name-level**: a broad secondary regex scans every barrel-allowlisted file
  for all public top-level declaration names across all kinds, then diffs that
  set against the names actually emitted.
- **Member-level**: for each emitted type, a broad member-shaped scan counts the
  public, non-underscore member-like lines (methods, constructors, operators,
  getters, setters, fields, enum values) in the type body and diffs that count
  against the number of members actually emitted. Intentionally suppressed
  Object overrides (`toString`, `hashCode`, etc.) are excluded.

Anything the scans find but the parser did not emit is printed to stderr as a
`WARNING:` list. The scans are diagnostic only — they do not change output. The
script exits with a non-zero status when either scan reports unemitted symbols
or when any file fails to parse, so a regression fails any pipeline that runs
the generator.

## Limitations

This is a regex-based parser, not a Dart analyzer frontend. `show` / `hide`
combinators on `export` statements are not yet honored (currently unused by the
barrel). If a future SDK change uses a declaration shape the script does not yet
recognize, the coverage sanity scan above will surface it on stderr; extend the
declaration matching and regenerate. After any large API change, also
sanity-check the regenerated `api_reference.md` against the actual source (counts
and a few spot-checked sections).
