# XDR Split Learnings

## Plan vs Reality
- Plan per-file class counts were estimates from reviewers, not actual counts. Always verify with `grep -c '^class ' lib/src/xdr/*.dart`. Actual total: 376 (plan said ~378).

## Patterns Discovered

### Filename collisions after split
- 7 of 20 old domain-grouped filenames collided with new individual type files (e.g., old `xdr_asset.dart` contained 7 classes, new `xdr_asset.dart` contains only `XdrAsset`). This caused imports to partially resolve but miss most classes. Solution: always update consumer imports to use barrel file, never rely on individual type file imports from consumers.

### Mixed import styles in consumer files
- Some files mixed relative (`import 'xdr/xdr_foo.dart'`) and package (`import 'package:stellar_flutter_sdk/src/xdr/xdr_foo.dart'`) imports. When replacing with barrel, this creates duplicate imports. The import update script should normalize to a single style per file — prefer relative within the same package.

### Files affected: 5 files had dual barrel imports (claimant.dart, create_claimable_balance_operation.dart, extend_footprint_ttl_operation.dart, soroban_server.dart, test/unit/xdr/xdr_ledger_uncovered_test.dart).

### Barrel file approach
- Replacing ~155 individual imports across 53 consumer files with a single barrel import (`xdr.dart`) is clean and avoids future breakage when adding/removing XDR types.
- The main SDK barrel (`stellar_flutter_sdk.dart`) went from 21 XDR exports to 1.
- XDR type files should NOT import the barrel (to avoid cycles); they import specific sibling files.

### Python script design
- Brace-depth tracking for class extraction works reliably for all 376 classes.
- `find_xdr_refs()` scanning all class names as regex against body text is O(n²) but fast enough for 376 classes.
- External import detection via regex pattern matching (e.g., `\bUint8List\b` → `dart:typed_data`) covers all cases.
- Unused import detection (xdr_invoke_host_function_success_pre_image in xdr_invoke_host_function_result) — the reference was in a comment, not code. The `find_xdr_refs` regex matched it anyway. Could filter comment lines in future.

### Atomic swap strategy
- Generate to staging dir first, then delete+copy in one step. This avoids partial states.
- Preserving `xdr_data_io.dart` during the swap requires explicit exclusion from the delete step.
