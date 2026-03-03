# XDR Split Progress

## Baseline
- Branch: xdr-gen2
- Total classes across 20 source files (excluding xdr_data_io.dart): **376**
- Actual class counts per file (from `grep -c '^class '`):
  - xdr_error.dart: 2
  - xdr_memo.dart: 2
  - xdr_bucket.dart: 2
  - xdr_data_entry.dart: 3
  - xdr_network.dart: 4
  - xdr_auth.dart: 4
  - xdr_scp.dart: 10
  - xdr_history.dart: 6
  - xdr_other.dart: 13
  - xdr_payment.dart: 11
  - xdr_signing.dart: 7
  - xdr_offer.dart: 11
  - xdr_trustline.dart: 20
  - xdr_type.dart: 19
  - xdr_asset.dart: 7
  - xdr_operation.dart: 8
  - xdr_account.dart: 56
  - xdr_transaction.dart: 59
  - xdr_ledger.dart: 64
  - xdr_contract.dart: 68

**Note:** Plan estimates differed significantly for some files (e.g., plan said xdr_auth=9 but actual=4, xdr_signing=18 but actual=7). The plan's per-file counts in §1.1 were reviewer estimates; the grep counts above are authoritative.

## Phase 0: Build Python Script
- [x] 0.1 Parser (class extraction)
- [x] 0.2 Dependency graph
- [x] 0.3 Classification (wrapper/plain/version-union)
- [x] 0.4 File generation
- [x] 0.5 Barrel file generation
- [x] 0.6 Import update commands

## Phase 1: Execute the Split
- [x] 1.1 Generate individual type files (376 type files + 1 barrel)
- [x] 1.2 Atomic swap: deleted 20 old multi-class files, copied 377 new files
- [x] 1.3 XDR-only verification: `dart analyze lib/src/xdr/` — 0 errors (1 unused import fixed)
- [x] 1.4 Update consumer imports (53 consumer files updated to use barrel import)
- [x] 1.5 Fix duplicate barrel imports (5 files had mixed relative+package imports)
- [x] 1.6 Update main SDK barrel: `stellar_flutter_sdk.dart` now exports single `src/xdr/xdr.dart`
- [x] 1.7 Full project compilation: `dart analyze` — 0 errors, 0 warnings, 246 pre-existing infos
- [x] 1.8 Run tests: `flutter test test/unit/` — **5602 tests pass, 0 failures**

## Phase 2: Delete Old Files
- [x] Old files already deleted during the atomic swap in Phase 1.2
- [x] Final dart analyze — clean
- [x] Final tests — all pass

## Final File Count
- 378 files in `lib/src/xdr/`:
  - 376 individual type files
  - 1 barrel file (`xdr.dart`)
  - 1 infrastructure file (`xdr_data_io.dart`, unchanged)
