# XDR Code Generator

Generates Dart XDR types from Stellar's `.x` definition files using the [xdrgen](https://github.com/stellar/xdrgen) Ruby gem.

## Prerequisites

- Docker (for Makefile targets)
- Ruby 3.x and Bundler (only if running without Docker)

## Usage

### Generate XDR files

From the repo root using the Makefile:

```bash
make xdr-generate         # fetch .x files and generate Dart types
make xdr-update           # re-download .x files and regenerate
make xdr-clean-generated  # remove only generated Dart files
make xdr-clean-all        # remove generated Dart files and .x definitions
```

Or run the generator directly:

```bash
cd tools/xdr-generator
bundle config set --local path vendor/bundle
bundle install
bundle exec ruby generate.rb
```

Output goes to `lib/src/xdr/`. The `xdr.dart` barrel file must be updated manually to export any newly added types.

### Update to a new XDR spec version

1. Update `XDR_COMMIT` in the repo-root `Makefile` to the new [stellar/stellar-xdr](https://github.com/stellar/stellar-xdr) commit
2. Run `make xdr-update`
3. Run `make xdr-generate-tests` to re-emit the XDR unit tests
4. Run `make xdr-generator-test`. When the snapshot diffs show only the intended upstream change, run `make xdr-generator-update-snapshots` and re-run the test
5. Update `sdk_xdr_commit` in `tools/sep-51-oracle/oracle-pin.json` to the same commit. The SEP-0051 corpus generator refuses to run while that field disagrees with the `Makefile`
6. Install the pinned XDR-JSON reference CLI with the command recorded under `install` in `tools/sep-51-oracle/oracle-pin.json`
7. Run `ruby tools/sep-51-oracle/name_map.rb --diff` to rebuild the SEP-0051 name table and check every derived JSON name against the reference (see `tools/sep-51-oracle/README.md`)
8. Run `python3 tools/sep-51-corpus/generate_corpus.py` to regenerate the SEP-0051 conformance corpus against the same build
9. Run `make sep51-generate-tests` to re-emit the SEP-0051 tests and the embedded corpus
10. If new XDR types were added, update `lib/src/xdr/xdr.dart` to export the new files
11. Run `dart format lib/src/xdr/` if not done automatically
12. Build and test: `dart analyze lib/ && flutter test test/unit/`
13. If new types introduce naming conflicts, update the override files (see below)

### Run tests

```bash
make xdr-generator-test                # run snapshot tests via Docker
make xdr-generator-update-snapshots    # update snapshots after intentional changes
make xdr-generator-validate            # validate generated types against XDR definitions
make xdr-generate-tests                # regenerate XDR unit tests
```

Or directly (requires `bundle install` first):

```bash
cd tools/xdr-generator
bundle exec ruby test/generator_snapshot_test.rb
bundle exec ruby test/update_snapshots.rb
bundle exec ruby test/validate_generated_types.rb
bundle exec ruby test/generate_tests.rb
```

Generated test output goes to `test/unit/xdr/generated/`.

## Generator architecture

| File | Purpose |
|---|---|
| `generate.rb` | Entry point |
| `generator/generator.rb` | Core Dart renderer (structs, enums, unions, typedefs) |
| `generator/name_overrides.rb` | Maps XDR type names to Dart class names |
| `generator/field_overrides.rb` | Maps struct field names and per-field type overrides |
| `generator/type_overrides.rb` | Typedef resolution (`TYPE_OVERRIDES`) and base/wrapper type list (`BASE_WRAPPER_TYPES`) |
| `test/generator_snapshot_test.rb` | Snapshot tests comparing generated output to expected files |
| `test/update_snapshots.rb` | Regenerates snapshot files after intentional generator changes |
| `test/validate_generated_types.rb` | Validates generated files against XDR definitions |
| `test/generate_tests.rb` | Generates roundtrip encode/decode unit tests for all XDR types |

## Base/wrapper pattern

23 types generate a `*_base.dart` file instead of a plain `*.dart` file. These are types where the SDK has hand-maintained helper methods, such as factory constructors, convenience getters, and BigInt conversions, that cannot be derived from the XDR spec alone.

The hand-maintained wrapper file extends the generated base class:

```
lib/src/xdr/xdr_sc_val_base.dart   ← generated (encode/decode/fields)
lib/src/xdr/xdr_sc_val.dart        ← hand-maintained (helpers such as forBool, forU32, and toBigInt)
```

The full list of wrapper types is in `generator/type_overrides.rb` (`BASE_WRAPPER_TYPES`).

All other XDR types are generated directly. No types are skipped.

## Override files

The override files preserve the existing SDK API where hand-written Dart code diverged from the canonical XDR names:

- **`type_overrides.rb`**: `TYPE_OVERRIDES` maps XDR typedefs to the Dart types the SDK uses (for example, `XdrTimePoint` → `XdrUint64`, `XdrSCVec` → `List<XdrSCVal>`).
- **`field_overrides.rb`**: `FIELD_OVERRIDES` remaps field names (for example, `buyAmount` → `amount`). `FIELD_TYPE_OVERRIDES` overrides the type of specific fields (for example, forcing `XdrUint64` instead of `XdrInt64`).
- **`name_overrides.rb`**: Maps XDR type names to Dart class names where the SDK convention differs from the spec.
