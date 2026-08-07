# Compatibility Matrix Generator

Automated tool that generates compatibility matrices comparing the Flutter Stellar SDK against the official Stellar APIs and protocol specifications.

It analyzes three areas:

- **Horizon API** -- all REST endpoints defined in `stellar-go/services/horizon`
- **Soroban RPC** -- all JSON-RPC methods defined in `stellar-rpc`
- **SEPs** -- 19 Stellar Ecosystem Proposals (SEP-01 through SEP-53)

## Requirements

- Python 3.8+
- No external dependencies (stdlib only)
- Internet access (fetches specs from GitHub and stellar.org)
- Local clones of `stellar-go` and `stellar-rpc` as siblings of the SDK root (for Horizon analysis)

Optional: set `GITHUB_TOKEN` for higher API rate limits (5,000 vs 60 requests/hour).

## Quick Start

Run all 59 analysis steps at once:

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
python3 tools/matrix-generator/horizon/run_horizon_analysis.py --horizon-version v2.30.0

# Use a local router.go file
python3 tools/matrix-generator/horizon/run_horizon_analysis.py --local /path/to/router.go
```

### Soroban RPC

```bash
python3 tools/matrix-generator/rpc/run_rpc_analysis.py

# Use a specific RPC version
python3 tools/matrix-generator/rpc/run_rpc_analysis.py --rpc-version v22.0.0

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
├── run_analysis.py              # Master orchestrator (runs all 59 steps)
├── common.py                    # Shared utilities (colors, paths, version)
├── github_fetcher.py            # GitHub API client (release + source fetching)
├── sdk_analyzer.py              # Dart source file analyzer (used by Horizon)
├── horizon/
│   ├── run_horizon_analysis.py  # Horizon pipeline orchestrator
│   ├── horizon_parser.py        # Parses router.go for endpoint definitions
│   └── generate_horizon_comparison.py
├── rpc/
│   ├── run_rpc_analysis.py      # RPC pipeline orchestrator
│   ├── rpc_parser.py            # Parses jsonrpc.go for RPC method definitions
│   └── generate_rpc_comparison.py
├── sep/
│   ├── sep_parser.py            # Fetches and parses SEP specs from stellar.org
│   ├── sep_analyzer.py          # Analyzes SDK source for SEP implementation
│   └── generate_sep_comparison.py
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

## Adding a New SEP

Each stage carries a dispatch table as well as the code it dispatches to, so a new SEP needs both halves in all three of them.

1. Add the SEP number to `KNOWN_SEPS` in `sep/sep_parser.py`
2. Add a `parse_sep_NN()` in `sep/sep_parser.py` if the spec has non-standard structure, plus its branch in `SEPParser.parse()`
3. Add an `analyze_sep_NN()` and a `map_sep_NN_features()` in `sep/sep_analyzer.py`, plus the branch in `SEPAnalyzer.analyze()`. A SEP with no `lib/src/sep/<n>/` directory bypasses `find_sep_files()` and names its own paths, as SEP-46, SEP-51 and SEP-53 do
4. Add a `_compare_sep_NN_features()` in `sep/generate_sep_comparison.py`, plus its branch in `compare_fields()`. That dispatch keys on the shape of `implemented_features`, not on the SEP number, so the branch must test a key combination no other SEP produces
5. Add the three script entries to `self.scripts` in `run_analysis.py`
6. Run `python3 tools/matrix-generator/run_analysis.py` to verify
