# Contributing to the Flutter Stellar SDK

Thank you for helping to improve the SDK. This guide covers bug reports, feature proposals, setup and the pull request process. The commands, the definition of done and the repository rules are in `AGENTS.md`.

## Reporting a bug

Open a bug report issue; the template asks for what you did, what happened, what you expected, the SDK version, the Flutter version, and the platform (VM, web, mobile). A failing test or a short snippet that reproduces the behavior shortens the fix.

## Proposing a feature

Open a feature request issue and describe the use case and the proposed behavior. For a SEP or a protocol feature, name the specification. Discuss before writing a large change, so the design is settled before the code.

## Setting up

- Flutter at or above the floor in `pubspec.yaml`; the CI matrix in `.github/workflows/tests.yml` names the tested versions. The Commands section of `AGENTS.md` has the dependency, analysis, format, and test commands.
- Chrome for the browser suites, and Node with WasmGC support for the smoke test.
- For the XDR generator: Docker, or Ruby with Bundler for the setup without Docker. For the SEP-51 tools: Python 3 and Rust's cargo for the pinned reference CLI. For the compatibility matrices: Python 3, network, and the sibling clones the generator README names; a GitHub token raises the API rate limit. Each tool's README under `tools/` names its requirements.

Run the unit suite as `AGENTS.md` describes before you change anything, so you know the baseline is green on your machine. The toolchain rewrites a few tracked files on every run; `AGENTS.md` names them and how to restore them.

## Submitting a change

1. Fork the repository and branch from `master` with a short kebab-case name that names the change.
2. Make the change with its tests. A bug fix starts with a test that fails before the fix. Format the files you change, never the whole tree.
3. Add an entry under `[Unreleased]` in `CHANGELOG.md`, in the section the change belongs to.
4. Run the gates listed under "Definition of done" in `AGENTS.md`.
5. Commit with an imperative subject and a body that states the motivation and what the change does. Open the pull request against `master` and describe what you verified.

The user documentation under `documentation/` and the skill under `skills/` describe the released SDK and are updated on the `release-docs` branch with the release; a pull request does not change them. Describe the needed documentation change in the pull request, and the maintainer adds it on that branch. `documentation/documentation-strategy.md`, `AGENTS.md` and this file are process documents: change them in the pull request that changes a fact they state. A documentation example that your change affects has a test under `test/docsTest/`; change that test in the same pull request.

## What the review checks

- The change does what the pull request says, and nothing else.
- The tests fail without the change and pass with it; unit tests mock HTTP.
- The conventions in `AGENTS.md`: typed API, DartDoc on public declarations, the wrapper rules for XDR types, browser and VM behavior where they differ.
- The CHANGELOG entry; no hand edits to generated files; no change to the user documentation or the skill.

CI runs analysis and the unit suite on every Flutter version of the matrix, the format check and coverage on the newest, and the browser suites; the Codecov project status must pass.

## Questions

Use GitHub Discussions for questions about using the SDK or about a change you plan.
