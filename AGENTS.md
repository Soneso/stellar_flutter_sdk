# AGENTS.md

This file is for everyone who changes the Flutter Stellar SDK, people and agents alike. It holds what the tree does not show: the commands, what "done" means, which files are generated, the conventions that differ from Dart defaults, and the limits of a change. When this file and a file it names disagree, the named file wins, and the pull request that changes the fact updates this file. Users of the SDK read `README.md` and `documentation/`; agents that build on the SDK read the skill under `skills/`.

## Commands

Setup is described in `CONTRIBUTING.md`. The Dart and Flutter floors are in `pubspec.yaml`; the CI matrix in the tests workflow names the tested Flutter versions.

```sh
flutter pub get
dart analyze lib/ --fatal-warnings
dart format --output=none --set-exit-if-changed lib test example/lib tool
flutter test test/unit/
flutter test test/unit/core/key_pair_test.dart --plain-name 'KeyPair fromSecretSeed creates keypair from known seed'
```

- `flutter pub get` and `flutter test` rewrite the tracked `analysis_options.yaml`, `example/analysis_options.yaml` and the two files under `example/ios/Flutter/`; restore them with `git checkout --` before every commit and never stage them.
- The unit suite (about 12,000 tests) takes 40 to 70 seconds. It needs loopback sockets, because three Soroban test files bind a local server, and one test resolves a `.invalid` host and expects the failure.
- The tree is `dart format` clean. Format the files you change, never the whole tree: the generated paths are formatted by their Make targets, and `example/lib` follows the style of the example package's own Dart floor.
- CI analyzes `lib/` only. `test/` carries a few analyzer findings; a change does not add to them.
- Browser suites run with `flutter test --platform chrome <paths>`; CI runs the list in the tests workflow (about 3,000 tests) and the WasmGC smoke test `bash tool/sep51_wasm_smoke/run.sh` (needs Node with WasmGC). The smart-account browser tests under `test/unit/smartaccount/core/web/` and `test/unit/smartaccount/oz/web/` are not in CI (75 tests, 10 to 20 seconds). The VM and the browser differ in integer width, JSON number typing, and stack depth, so a change to a `@TestOn('browser')` area runs both.
- The integration tests (`flutter test test/integration/`) and the documentation tests (`flutter test test/docsTest/`) run against testnet with Friendbot funding and are not part of CI; under load, rerun the integration tests with `--concurrency=1 --timeout 5x`.
- The native plugin tests under `android/src/test/` and `ios/stellar_flutter_sdk/Tests/` have no command in the repository; they run through the example app.
- The API documentation builds with `dart doc` in 20 to 30 seconds into the gitignored `doc/api/`; CI publishes it from `master`.

## Definition of done

Before reporting a change as done:

1. `dart analyze lib/ --fatal-warnings`, the format check and the unit suite pass.
2. Area gates. After a generator, override, or XDR definition change: `make xdr-generate`, `make xdr-generate-tests` and `make sep51-generate-tests` leave a clean tree, and `make xdr-generator-test` passes. After a change that touches XDR-JSON names or either SEP-51 pin: `ruby tools/sep-51-oracle/name_map.rb --offline`, `ruby tools/sep-51-oracle/emitted_names.rb` and the corpus comparison the SEP-51 workflow runs. After a change under `test/unit/sep/web/`, `test/unit/smartaccount/core/web/` or `test/unit/smartaccount/oz/web/`, or to code those tests cover: the browser suites of that area. After a matrix generator change: `python3 -m unittest discover -s tools/matrix-generator/tests`. After a change to an example in `documentation/`: the page's test under `test/docsTest/`, changed in the same pull request.
3. A test that would fail without the change exists. A bug fix starts with the failing test.
4. `CHANGELOG.md` has an entry under `[Unreleased]` in the Keep a Changelog section the change belongs to (Added, Changed, Deprecated, Removed, Fixed, Security), in present tense, one entry per user-visible change.
5. No generated file was edited by hand. The user documentation under `documentation/` and the authored text of the skill under `skills/` describe the released SDK; they change on the `release-docs` branch with the release. The skill's generated API reference, its version fields, and its zip change in the release preparation. `documentation/documentation-strategy.md` is a process document and changes in the pull request that changes a fact it states.

Every pull request runs `.github/workflows/tests.yml`: analysis and the unit suite on every Flutter version of the matrix; the format check, coverage, and the Codecov upload on the newest; the browser job; and the `agents-md-paths` job. That job runs `.github/scripts/check_agents_md_paths.py`. It fails when a path in a code span outside the fenced block is missing and not ignored by git, or when a glob matches nothing. Spans with whitespace, such as commands, are not checked. A change that moves a file also changes the line here. Two workflows run when their path filters match. `.github/workflows/xdr-generator.yml` regenerates the XDR types and tests and fails on a difference from the committed files. The committed-artefacts job of `.github/workflows/sep-51-conformance.yml` checks the name table against the XDR sources, the emitted names against the table and the embedded corpus against the committed corpus. The branch rules require the Codecov project status; `codecov.yml` holds the targets and the ignore list.

## Generated code and data

Generated files are never edited by hand. Change the generator or its override files and regenerate.

- **XDR types.** The files in `lib/src/xdr/` whose header says they were generated by xdrgen, the test trees `test/unit/xdr/generated/` and `test/unit/xdr/json_generated/`, the corpus embed `test/unit/sep/sep51_corpus_data.dart` and the generator snapshots under `tools/xdr-generator/test/snapshots/`. Hand-written in `lib/src/xdr/`: the wrappers that extend the generated `lib/src/xdr/*_base.dart` types, the export barrel `lib/src/xdr/xdr.dart`, `lib/src/xdr/txrep_helper.dart`, `lib/src/xdr/xdr_data_io.dart` and `lib/src/xdr/xdr_json_helper.dart`. A new XDR type needs an export in the barrel. Before editing a wrapper or adding a type to the wrapper list, read `lib/src/xdr/BASE_WRAPPER_PATTERN.md`; it holds the copy and redeclaration rules. A union arm added upstream needs a copy line in every wrapper that copies fields, and every base static is redeclared on the wrapper. The analyzer detects neither. The stellar-xdr commit is pinned as `XDR_COMMIT` in `Makefile` and repeated as `sdk_xdr_commit` in `tools/sep-51-oracle/oracle-pin.json`; the corpus generator refuses to run while the two differ. The definitions in `xdr/` are tracked downloads of that commit and are never edited; `make xdr-update` re-downloads them (network), `make xdr-generate` regenerates from the tracked files. The Make targets run Ruby in Docker and format what they emit; with the image and the gems cached they need no network. The override files are the `tools/xdr-generator/generator/*_overrides.rb` files and `tools/xdr-generator/generator/txrep_types.rb`. Run `make xdr-generator-update-snapshots` only after an intended output change, and read the snapshot diff. Before changing the generator, an override file, or the pin, read `tools/xdr-generator/README.md`; it holds the update procedure and the override files.
- **SEP-51 conformance.** `tools/sep-51-oracle/oracle-pin.json` pins the reference CLI, the reference commits, and the SEP-51 version; `documentation/sep/sep-51.md` and the skill quote that version. `tools/sep-51-oracle/name-map.json` and `tools/sep-51-oracle/type_map.json` are generated by `ruby tools/sep-51-oracle/name_map.rb --diff`. The corpus `tools/sep-51-corpus/corpus.json` is generated from `tools/sep-51-corpus/seeds.py` by `python3 tools/sep-51-corpus/generate_corpus.py` and embedded into the Dart corpus, because browser tests cannot read a file fixture. `tools/sep-51-oracle/name_map.rb` loads the generator's gems (`bundle install` in `tools/xdr-generator/`); `tools/sep-51-oracle/emitted_names.rb` needs only Ruby. The pinned CLI installs with the Cargo command in the corpus README, or `STELLAR_XDR` points at a binary. Never generate fixtures with the Homebrew `stellar` CLI or another XDR-JSON implementation; only the pinned reference build is authoritative. A struct or union arm the reference cannot resolve gets a hand-written round-trip test derived from the specification. Before moving a pin or touching XDR-JSON names, read `tools/sep-51-oracle/README.md`; it holds the modes and exit codes of the name scripts. Before adding a seed or regenerating the corpus, read `tools/sep-51-corpus/README.md`; it holds the seed rules.
- **Compatibility matrices.** The files under `compatibility/` describe the released SDK. `python3 tools/matrix-generator/run_analysis.py` runs every pipeline; it needs network and the sibling clones `stellar-horizon` and `stellar-rpc` next to this repository, and a GitHub token in `GITHUB_TOKEN` raises the API rate limit. The SEP-23 matrix reads its vectors from `test/unit/strkey_test.dart`. The matrices change in four cases. An SDK behavior change ships them with its release. A generator fix commits them in its pull request, after the maintainer has read every changed cell. A new protocol version adds its rows when it is live. A mixed diff is the maintainer's decision. A run that only verifies a change restores `compatibility/` before the commit. Before changing a generator or an analyzer, read `tools/matrix-generator/README.md`; it holds the pipelines and their inputs.
- **Agent skill.** `skills/stellar-flutter-sdk/references/api_reference.md` is generated by `python3 tools/skill-generator/generate_api_reference.py` from the export graph of `lib/stellar_flutter_sdk.dart`. Its output on `master` includes unreleased API, so it is regenerated at release only, together with the skill version and the zip; a verification run restores the committed file. Before changing the reference generator, read `tools/skill-generator/README.md`; it holds the scan rules.
- **Test fixtures.** The six files under `test/contract_bindings/` were generated by the external contract bindings generator and are not edited. `test/wasm/p28_owner_fixture.wasm` is built from `tools/p28-owner-fixture/` and replicated in four SDK repositories; before changing it, read `tools/p28-owner-fixture/README.md`; it holds the build and the replication rule. The other wasm files under `test/wasm/` are test inputs without a source in this repository.

## Conventions and gotchas

- `flutter test <directory>` runs only the files whose names end in `_test.dart`; a test file named otherwise never runs.
- Unit tests mock HTTP with `MockClient` from the testing library of the `http` package, assigned to `httpClient`; the smart-account tests use the hand-written fakes under `test/unit/smartaccount/`. No unit test reaches a Stellar network.
- XDR enum types are classes of constants, so a `switch` over them gets no exhaustiveness diagnostic; a new member needs a search for every `switch` on the type.
- Public declarations carry `///` DartDoc comments with symbol links that describe current behavior and its reason, never history; the API documentation is generated from them.
- New code uses the typed API; raw XDR appears only where no typed path exists, because the typed layer carries the validation and the documentation users read.
- `.pubignore` lists what stays out of the pub.dev package; a new top-level directory ships unless it is listed.

## Boundaries

- Releases are the maintainer's. Outside a release preparation the maintainer directs, an agent never changes a version place: `version` in `pubspec.yaml`, `versionNumber` in `lib/src/stellar_sdk.dart`, the install snippets in `README.md`, `documentation/getting-started.md`, `documentation/quick-start.md` and `skills/stellar-flutter-sdk/references/smart_accounts.md`, and the `compatibility:` caret, `sdk_version` and install snippet of `skills/stellar-flutter-sdk/SKILL.md`. The same holds for the skill version fields in `skills/stellar-flutter-sdk/SKILL.md`, `skills/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, the zip `skills/stellar-flutter-sdk.zip`, a tag or a GitHub release. An agent runs `flutter pub publish` only on the maintainer's word after the tag; the release preparation runs `flutter pub publish --dry-run`.
- No credential lives in the repository. CI uses OIDC for the Codecov, Pages, and SBOM uploads. Ask before adding a dependency, a workflow, or a new generated artifact; each is a maintenance commitment the maintainer carries after the pull request.

## Changes

- Branch from `master` with a short kebab-case name that names the change; open the pull request against `master`.
- The commit subject is one imperative sentence of at most 72 characters without a type prefix; the body states the motivation and what the change does, so the log reads without the diff. The pull request body follows the same form and names what was verified.
- A pull request carries code, tests, and the CHANGELOG entry.

## Where details live

- Before your first change, read `CONTRIBUTING.md`; it holds setup, how to report a bug or propose a feature, how a change is submitted and what the review checks.
- Before writing or changing a page under `documentation/` or a documentation test, read `documentation/documentation-strategy.md`; it holds the page template, the example rules, and the release policy for documentation.
- Before touching the skill under `skills/`, read `tools/skill-generator/README.md`; it holds the skill's structure and the reference generator.
- Before changing a tool under `tools/`, read its README; every tool directory has one.

## Locations

- `tool/` (singular) holds the WasmGC smoke test; the generators live under `tools/`.
