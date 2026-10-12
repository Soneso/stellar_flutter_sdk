# SEP-0051 name derivation and reference probing

These tools hold the ground truth for the SDK's XDR-JSON (SEP-0051) names.
`name_map.rb` derives the JSON name of every enum member, struct field and
union arm from the `.x` sources and checks the derivation against a pinned
build of the XDR-JSON reference CLI. `emitted_names.rb` checks that the
generated Dart emits those names.

No build and no unit test runs these tools or the reference CLI. They run when
the XDR pin or the reference pin moves, and in the SEP-51 conformance workflow.

## Pins

`oracle-pin.json` records both pins:

| Field | Holds |
|---|---|
| `tool`, `version`, `tool_commit` | The reference CLI build. |
| `xdr_commit` | The stellar-xdr commit that build vendors. |
| `install` | The command that installs the pinned build. |
| `sdk_xdr_commit` | The stellar-xdr commit this SDK generates from. It repeats `XDR_COMMIT` in the repository `Makefile`, and the corpus generator refuses to run while the two differ. |
| `sep_spec` | The SEP-0051 revision this implementation follows. `documentation/sep/sep-51.md` and the agent skill quote the same version. |

`oracle-pin.json` pins the reference build by version because XDR-JSON key
spellings differ between its releases. `probe.sh` and `name_map.rb` verify the installed CLI
against `version` and `xdr_commit` on every run that uses it, except
`name_map.rb --advisory`, which accepts a build with a different pin. The reference
cannot resolve types and enum members added after the commit it vendors; the
tools report those as unresolvable, not as mismatches.

## Prerequisites

- The pinned reference CLI, installed with the command under `install` in
  `oracle-pin.json`. Cargo installs it into `~/.cargo/bin`; set `STELLAR_XDR`
  to use a binary from another location. `name_map.rb --offline` and
  `emitted_names.rb` run without it.
- The generator's Ruby gems. `name_map.rb` reads the `.x` sources with the
  generator's parser and derives names with the generator's own naming module,
  `tools/xdr-generator/generator/json_names.rb`:

```sh
cd tools/xdr-generator
bundle config set --local path vendor/bundle
bundle install
```

## Files

| File | Role |
|---|---|
| `oracle-pin.json` | The reference pin, the SDK's XDR pin and the SEP-0051 revision. |
| `probe.sh` | Prints the reference rendering of one value, the JSON schema of one type, or the type list. |
| `name_map.rb` | Derives every JSON name from the `.x` sources and checks the derivation against the reference. |
| `name-map.json` | Generated name table, with the verification summary of the last `--diff` run. |
| `type_map.json` | Generated map from each `.x` type name to the reference CLI's spelling and this SDK's Dart class, with the types the reference does not resolve. |
| `emitted_names.rb` | Reads the generated Dart in `lib/src/xdr/` and compares the names it emits with `name-map.json`. Writes nothing. |

`name-map.json` and `type_map.json` are never edited by hand.

## Usage

Run from the repository root:

```sh
# Verify the installed CLI against the pin
bash tools/sep-51-oracle/probe.sh --check

# Render one value. The type is the reference CLI's spelling (ScVal), not the Dart class (XdrSCVal).
bash tools/sep-51-oracle/probe.sh ScVal AAAAAwAAAAU=
bash tools/sep-51-oracle/probe.sh --schema AccountEntryExtensionV2
bash tools/sep-51-oracle/probe.sh --types

# Rebuild name-map.json and type_map.json and check every name against the reference
ruby tools/sep-51-oracle/name_map.rb --diff

# Run the same comparison without writing, and fail when a committed file is stale
ruby tools/sep-51-oracle/name_map.rb --check

# Check the committed name table against the .x sources, without the reference CLI
ruby tools/sep-51-oracle/name_map.rb --offline

# Check the names the generated Dart emits against the name table
ruby tools/sep-51-oracle/emitted_names.rb
```

- `--diff` compares the derived names with the pinned build, writes both
  generated files, and records the comparison in the verification block of
  `name-map.json`; a pull request commits the output of this form. `--quiet`
  limits the output to the summary.
- `--check` runs the same comparison with the pinned build and writes nothing.
  It is the form the weekly workflow runs.
- Without a comparison flag, `name_map.rb` generates: it requires the pinned
  build, writes both files with `type_map.json` resolved against it, and skips
  the name comparison. The verification block of `name-map.json` then records
  that the run verified nothing.
- `--offline` writes nothing and consults no reference build. It compares the
  derived names and the recorded pins with the committed table, and leaves the
  verification block and `type_map.json` to the runs that have the reference.
- `--advisory` compares the derived names with the build `STELLAR_XDR` names and
  accepts a build whose version or vendored XDR commit differs from the pin. It
  writes nothing and answers whether a pin bump would change the SDK's output.

## Exit codes

`name_map.rb`:

| Code | Meaning |
|---|---|
| 0 | The run succeeded. The list after this table says what exit 0 establishes in each mode. |
| 1 | A name disagrees with the reference build the run uses, a committed file is stale under `--check`, or the run stops with a message that names its cause. |
| 2 | The reference CLI is missing or fails to report its version, or, in a run other than `--advisory`, it does not match the pin. |

Exit 0 per mode:

- `--diff`: every derived name the pinned build resolves agrees with it, and the
  run wrote both files.
- `--check`: every derived name the pinned build resolves agrees with it, and
  both committed files are current.
- No comparison flag: the run wrote both files. It compares no names, so its
  exit 0 says nothing about them.
- `--offline`: the committed table matches the names and pins derived from the
  `.x` sources. Exit 1 means it does not or is missing; exit 2 does not occur.
- `--advisory`: every derived name the build `STELLAR_XDR` names resolves
  matches it. Exit 1 lists the names that differ.

`emitted_names.rb` exits 0 when the emitted names match the table, and 1 on a
mismatch, a missing or extra name, a missing file, or a run that compares no
names at all.

`probe.sh` exits 2 when the reference CLI is missing or does not match the pin,
or when its arguments are wrong. A value the CLI cannot decode ends the script
with the CLI's exit status.

The SEP-51 conformance workflow treats exit 2 as a broken job, never as drift.

## When to rerun

- After the XDR pin moves (`XDR_COMMIT` in the `Makefile` and `sdk_xdr_commit`
  in `oracle-pin.json`, set to the same commit): `name_map.rb --diff`, then
  `emitted_names.rb` after `make xdr-generate`, then the corpus steps in
  `tools/sep-51-corpus/README.md`.
- After the reference pin moves: install the new build with the updated
  `install` command, then `name_map.rb --diff` and the corpus steps.
- After a change to the naming module
  `tools/xdr-generator/generator/json_names.rb` or to `name_overrides.rb`
  beside it: `name_map.rb --diff`, then `emitted_names.rb` after
  `make xdr-generate`.

The workflow `.github/workflows/sep-51-conformance.yml` runs
`name_map.rb --offline` and `emitted_names.rb` when its path filter matches a
push or a pull request. Every Monday it runs `name_map.rb --check` with the
pinned build, compares the name table with the newest reference release
through `--advisory`, and compares `sep_spec` with the published
specification. It reports drift in an issue and never writes a committed file.
