# SAC spec generator

`generate_sac_spec.py` writes `lib/src/soroban/sac_spec.dart`, which embeds the XDR
`SCSpecEntry` list of the Stellar Asset Contract (SAC) spec. The spec is the built-in token
interface of every classic asset. The SDK decodes it to describe SAC methods and events without
a wasm contract.

The generated file holds the upstream file's bytes as one base64 literal, its sha256 digest, and
the pinned commit. The upstream file is `stellar-asset-spec.xdr` in
`stellar/stellar-asset-contract-spec`.

## Files

- `pin.json`: the upstream repository, commit, file name, and sha256 digest, plus the template and
  output paths. Paths resolve against the repository root.
- `sac_spec.dart.template`: the Dart layout of the output. The generator fills `{{REPOSITORY}}`,
  `{{FILE}}`, `{{COMMIT}}`, `{{SHA256}}`, `{{SIZE}}` (bytes), and `{{BASE64}}`.
- `generate_sac_spec.py`: the generator. It uses only the Python standard library and needs
  Python 3.9 or later.
- `tests/test_generate_sac_spec.py`: unit tests of the generator. They run offline.

## Generate

```sh
python3 tools/sac-spec/generate_sac_spec.py
```

The script downloads the pinned raw URL with a 60-second timeout and checks its sha256 digest.
Pass `--source FILE` to read a local copy instead of downloading it. Pass `--pin PATH` or
`--root DIR` to use another pin or root, for example in tests.

Exit status is 0 on success, 1 on a failure of the run, and 2 for a usage error.
A failure writes no file, and the message on stderr
names the URL or path and the cause. A digest mismatch prints both the expected and the actual
digest.

The output has no timestamp, so a run at the same pin reproduces the committed file byte for
byte. The template holds the layout that `dart format` produces for the output, so the output
passes the format check without a further step.

## Test

```sh
python3 -m unittest discover -s tools/sac-spec/tests
dart format --output=none --set-exit-if-changed lib/src/soroban/sac_spec.dart
```

## Bump the pin

1. Find the new commit of `stellar/stellar-asset-contract-spec` that changes the spec. Download
   `stellar-asset-spec.xdr` at that commit and compute its sha256 digest, for example with
   `sha256sum`.
2. Set `commit` and `sha256` in `pin.json`.
3. Regenerate with the command above. The script verifies the digest of the download against the
   new pin.
4. Run the format check on the output. If it reports a difference, apply the layout change to the
   template, then regenerate and check again. A second run must leave the tree unchanged.
5. Run the unit suite of the generator, then the SAC spec unit tests of the SDK. A changed function
   or event set, or a new pin, fails `sac_spec_test.dart` until the same commit updates its
   expectations.
