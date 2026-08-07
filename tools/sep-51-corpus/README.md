# SEP-0051 conformance corpus

`corpus.json` pins, for a set of hand-chosen XDR values, the exact JSON text the
SDK must emit and the base64 XDR that value encodes to. The Dart unit test
`test/unit/sep/sep51_corpus_test.dart` walks it in both directions: JSON to XDR
and XDR to JSON.

The corpus targets the renderings that are not mechanical — strkey-valued union
arms, integers that become strings, the escape ladder over bytes-typed and
string-typed fields, empty and populated variable-length data, optionals in both
states, and the name rules a pin bump could disturb. It is not an enumeration of
every type; the generated per-type suites cover that.

## Files

| File | Role |
|---|---|
| `seeds.py` | Hand-authored seed values, each written in XDR-JSON form. |
| `generate_corpus.py` | Encodes and decodes every seed with the reference CLI and writes `corpus.json`. |
| `corpus.json` | Generated and committed. Consumed by the emitter, never edited by hand. |
| `refresh_corpus.sh` | Regenerates into `.tmp/` and diffs against the committed file. |
| `emit_dart_corpus.py` | Renders the committed `corpus.json` as `test/unit/sep/sep51_corpus_data.dart`. |

`emit_dart_corpus.py` reads only committed artefacts and never invokes the
reference CLI, so a per-PR job can check the emitted Dart against the committed
corpus without building the reference. The corpus is compiled into the test
sources rather than read from disk at test time because the suite has to run on
the web platform, which has no file to read.

## Installing the reference

```bash
cargo install stellar-xdr --features cli --version 28.0.0 --locked
```

The exact build is pinned in `../sep-51-oracle/oracle-pin.json` by version and by
the XDR commit it vendors. Every tool here verifies that pin before it does
anything else and refuses a different build, because key spellings differ between
reference releases: anything before 28.0.0 emits `type_` where SEP-0051 requires
`type`. The Homebrew `stellar` CLI and the stellar-xdr MCP server are pre-v28 and
must not be used to generate fixtures.

Set `STELLAR_XDR` to address a build that is not on `PATH` as `stellar-xdr`.

## Ground truth

Every seed is encoded to XDR and decoded straight back through the reference, so
a seed that is not valid XDR-JSON for its type fails the run rather than reaching
the corpus. The decoded document — not the authored one — is what the corpus
records, which is why authoring a value in a non-canonical form is harmless.

Fixtures come from the reference, never from this SDK's own output. A corpus
generated from the implementation it tests detects drift but never error.

Each seed names both the reference type and the SDK class. The SDK class is
checked against the committed artefacts rather than taken on trust:
`../sep-51-oracle/type_map.json` for enums, structs and unions, and the `.x`
typedef list run through the generator's `NAME_OVERRIDES` and `TYPE_OVERRIDES`
for typedefs. The named class must also exist under `lib/src/xdr/` and declare
`fromXdrJsonValue`, so a seed can never name a type the corpus cannot be driven
through.

## Comparable and incomparable entries

Most entries are **comparable**: the reference's own output is exactly what the
SDK must emit, and the entry records it verbatim under `oracle: "reference"`.

Some entries are **incomparable**: SEP-0051 specifies one form and the reference
emits another. Those entries carry `oracle: "incomparable"`, the specified text
under `json`, the reference's text under `oracle_json`, and a `reason`. At the
current pins there are 19 such entries across 9 types, under two transformations
that derive the specified form from the reference's:

- `integer_string` — SEP-0051 §Hyper Integer (64-bit) requires a 64-bit integer
  to be a base-10 string. The reference emits a bare JSON number for a
  standalone `Int64` or `Uint64`.
- `opaque_hex` — SEP-0051 §Opaque Data (Fixed Length) requires fixed-length
  opaque data to be a lowercase hex string. Where the `.x` declares such a field inline
  rather than through a named typedef, the reference emits an array of byte
  numbers. That covers struct fields (`Curve25519Secret`, `Curve25519Public`,
  `HmacSha256Key`, `HmacSha256Mac`, `ShortHashSeed`, and `SerializedBinaryFuseFilter`
  transitively) and union arms alike (`PeerAddressIp`, through `PeerAddress`).
  The transformation walks the whole document, so nested occurrences are
  rewritten too.

The generator asserts that each derived value actually differs from the
reference's. A divergence that quietly disappears in a future reference release
fails the run instead of passing unnoticed.

## `spec_form_paths`

The `opaque_hex` transformation is addressed by value, not by type: it rewrites
any non-empty array whose every element is an integer in 0..255. The document
carries no type information, so there is nothing else for it to key on — and the
same rule would rewrite a variable-length `uint32` array whose values all
happened to stay under 256, pinning an expected value the SDK could then never
match.

So every incomparable seed declares `spec_form_paths`: the exact locations the
transformation is expected to rewrite, as dotted object keys with `[n]` for an
array index and `""` for the whole value. The generator records what it actually
rewrote and **fails when the two sets differ in either direction**. A rewrite
that reaches a location nobody declared is a failure, and so is a declared
location the walk never reached.

The rule is total: it applies to every incomparable seed, including one carrying
no transformation, which declares the empty list. An exemption for those would
leave unchecked exactly the case where a future transformation reaches an entry
that was never meant to be rewritten.

## Divergences that are not entries

Two divergences have no emitted text for an entry to pin, because the SDK emits
nothing at all for them. Both are asserted live against the pinned reference on
every run and recorded in the corpus metadata, so one that quietly disappears
fails the run:

- A `SignerKeyEd25519SignedPayload` with a zero-length payload is valid XDR that
  the reference decodes to a strkey it then refuses to encode. The SDK refuses it
  in both directions.
- A document carrying `$schema`, which SEP-0051 requires objects to accept and
  the reference rejects outright. The SDK accepts it, strips it and never emits
  it, so no emitted text differs.

Both are pinned by hand-written tests under `test/unit/sep/` instead.

## Regenerating

```bash
# Check the committed corpus against a fresh generation
bash tools/sep-51-corpus/refresh_corpus.sh

# Ask whether a newer reference build would render the corpus differently.
# Reports only; the committed corpus is never written.
STELLAR_XDR=/path/to/newer/stellar-xdr bash tools/sep-51-corpus/refresh_corpus.sh --advisory

# Rewrite it
python3 tools/sep-51-corpus/generate_corpus.py

# Re-emit the copy embedded in the SDK test sources
make sep51-generate-tests
```

`corpus.json` has no timestamp and a fixed entry and key order, so an unchanged
input produces a byte-identical file and any diff is real drift. The whole
document is compared raw; there is nothing to exclude.

Re-run after either pin moves: the SDK's XDR pin (`XDR_COMMIT` in the repository
`Makefile`), or the reference pin in `../sep-51-oracle/oracle-pin.json`. The
generator refuses to run when the two records of the SDK's XDR commit disagree.

## Exit codes

`generate_corpus.py`

| Code | Meaning |
|---|---|
| 0 | Corpus written. |
| 1 | A seed failed, a declared divergence no longer holds, or the seed set is incomplete. |
| 2 | The reference CLI is missing or does not match the pin, or a committed artefact is absent or malformed. |

`--check-prerequisites` runs the code-2 checks alone, writes nothing, and exits 0
or 2. `refresh_corpus.sh` runs it before it creates or writes anything, so a
missing CLI can never be mistaken for a clean diff and can never leave a
half-written artefact.

`refresh_corpus.sh`

| Code | Meaning |
|---|---|
| 0 | No drift. |
| 1 | Drift; the diff is printed. |
| 2 | A prerequisite is missing. |

`emit_dart_corpus.py`

| Code | Meaning |
|---|---|
| 0 | The Dart source was written. |
| 2 | The committed corpus is missing or malformed. |

In `--advisory` mode the same codes mean the same things, measured against
whatever build `STELLAR_XDR` names rather than the pinned one: 0 that the build
renders the corpus identically, 1 that it does not, with the diff and any
per-seed findings both printed. A seed the build cannot process is recorded as a
finding and its entry omitted, so one run enumerates every affected seed instead
of stopping at the first, and the omission shows up in the diff as a smaller
`entry_count`.

The advisory comparison ignores `reference_version` and `reference_xdr_commit`.
The generated document records the build that actually produced it, but those two
fields differ on every real release and would otherwise mask the only question
being asked: does anything the SDK emits change? `entry_count` stays in the
comparison, because a dropped seed is a real difference.
