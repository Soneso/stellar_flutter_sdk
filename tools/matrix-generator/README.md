# Compatibility Matrix Generator

Automated tool that generates compatibility matrices comparing the Flutter Stellar SDK against the official Stellar APIs and protocol specifications.

It analyzes three areas:

- **Horizon API** -- all REST endpoints defined in `stellar-horizon`
- **Soroban RPC** -- all JSON-RPC methods defined in `stellar-rpc`, with the response structs from `go-stellar-sdk`
- **SEPs** -- 21 Stellar Ecosystem Proposals (SEP-01 through SEP-53)

## Requirements

- Python 3.8+
- No external dependencies (stdlib only)
- Internet access (fetches specs from GitHub and stellar.org)
- Local clones of `stellar-horizon` and `stellar-rpc` as siblings of the SDK root

Horizon sources are fetched from GitHub at the tag of the latest release. RPC sources are fetched at the tag of the newest stable release: the highest `vX.Y.Z` tag with `draft` and `prerelease` false, across every page of the release list. `--rpc-version` must name a non-draft `v*` server release. The local clones back the `--local` modes below, and `run_analysis.py` checks for them up front: `stellar-horizon` must carry `internal/httpx/router.go`.

A pipeline exits non-zero and writes no matrix when `pubspec.yaml` has no readable version or no RPC release qualifies. The RPC pipeline does the same when the response struct of a method cannot be fetched, yields no fields, or embeds a struct that no fetched go-stellar-sdk protocol file declares. The SEP-23 pipeline does the same when the specification lacks its Specification or Tests section, or when the version byte table or a test case list is missing or empty. It also stops when a file it reads is missing or unreadable, or when a key type has no entry in its name table. A class, `VersionByte` member, constant, or `StrKey` function it maps that is absent stops it too, and so does a version byte value in a form it cannot evaluate. `run_analysis.py` stops at the first failed step.

The response fields of a method include the fields of the structs its response struct embeds. Fields ending in `Json` are the JSON-format variants of XDR fields and are not counted, because the SDK decodes XDR.

Optional: set `GITHUB_TOKEN` for higher API rate limits (5,000 vs 60 requests/hour).

## Quick Start

Run all 65 analysis steps at once:

```bash
python3 tools/matrix-generator/run_analysis.py
```

This generates Markdown reports in `compatibility/`:

```
compatibility/
  horizon/HORIZON_COMPATIBILITY_MATRIX.md
  rpc/RPC_COMPATIBILITY_MATRIX.md
  sep/SEP-0001_COMPATIBILITY_MATRIX.md
  sep/SEP-0002_COMPATIBILITY_MATRIX.md
  ...
  sep/SEP-0053_COMPATIBILITY_MATRIX.md
```

## Running Individual Pipelines

Each subsystem can be run independently.

### Horizon

```bash
python3 tools/matrix-generator/horizon/run_horizon_analysis.py

# Use a specific Horizon version
python3 tools/matrix-generator/horizon/run_horizon_analysis.py --horizon-version v28.0.1

# Use a local router.go file
python3 tools/matrix-generator/horizon/run_horizon_analysis.py --local /path/to/router.go
```

### Soroban RPC

```bash
python3 tools/matrix-generator/rpc/run_rpc_analysis.py

# Cite a specific RPC release
python3 tools/matrix-generator/rpc/run_rpc_analysis.py --rpc-version v28.0.1

# Use a local jsonrpc.go file
python3 tools/matrix-generator/rpc/run_rpc_analysis.py --local /path/to/jsonrpc.go
```

### SEPs

SEP analysis runs as three stages per SEP: parse, analyze, compare.

```bash
# Parse a single SEP specification from stellar.org
python3 tools/matrix-generator/sep/sep_parser.py 0010

# Analyze SDK implementation for that SEP
python3 tools/matrix-generator/sep/sep_analyzer.py 0010

# Generate the comparison report
python3 tools/matrix-generator/sep/generate_sep_comparison.py 0010
```

## Project Structure

```
tools/matrix-generator/
├── run_analysis.py              # Master orchestrator (runs all 65 steps)
├── common.py                    # Shared utilities (colors, paths, version)
├── github_fetcher.py            # GitHub API client (release + source fetching)
├── sdk_analyzer.py              # Pipeline module: analyzes the SDK request builders for Horizon
├── horizon/
│   ├── run_horizon_analysis.py  # Horizon pipeline orchestrator
│   ├── horizon_parser.py        # Pipeline module: parses router.go for endpoint definitions
│   └── generate_horizon_comparison.py  # Pipeline module: compares and writes the matrix
├── rpc/
│   ├── run_rpc_analysis.py      # RPC pipeline orchestrator
│   ├── rpc_parser.py            # Pipeline module: parses jsonrpc.go for RPC method definitions
│   └── generate_rpc_comparison.py  # Pipeline module: compares and writes the matrix
├── sep/
│   ├── sep_parser.py            # Fetches and parses SEP specs from stellar.org
│   ├── sep_analyzer.py          # Analyzes SDK source for SEP implementation
│   └── generate_sep_comparison.py
├── tests/                       # unittest suite (offline, network calls patched)
└── data/                        # Intermediate JSON (gitignored)
    ├── horizon/
    ├── rpc/
    └── sep/
```

## How It Works

Each pipeline follows the same pattern:

1. **Parse** the reference source (Go source code or SEP HTML) to extract the official API surface
2. **Analyze** the Flutter SDK source to find which parts are implemented
3. **Compare** the two and generate a Markdown compatibility matrix with coverage percentages

Intermediate JSON files are written to `data/` for debugging. Only the final Markdown reports in `compatibility/` are committed.

## Tests

Run from the repository root:

```bash
python3 -m unittest discover -s tools/matrix-generator/tests
```

The tests patch every network call. The SEP fixtures in `tests/fixtures/` are copies of the upstream SEP markdown.

## Adding a New SEP

Each stage finds the code for a SEP by its number and stops for a number it has no code for.

1. Add a `parse_sep_NN()` to `sep/sep_parser.py`
2. Add an `analyze_sep_NN()` and a `map_sep_NN_features()` to `sep/sep_analyzer.py`. A SEP with no `lib/src/sep/<n>/` directory bypasses `find_sep_files()` and names its own paths, as SEP-23, SEP-29, SEP-46, SEP-51 and SEP-53 do. SEP-23 also reads its test vectors from `test/unit/strkey_test.dart`
3. Add the titles of its analysis categories to `SECTION_TITLES` in `sep/generate_sep_comparison.py`
4. Add the SEP to `SEPS` in `run_analysis.py`
5. Run `python3 tools/matrix-generator/run_analysis.py` to verify
