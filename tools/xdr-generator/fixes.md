# XDR Generator Fixes

Bug fixes in hand-written XDR files discovered by the generator.
These are cases where the hand-written code doesn't match the XDR definition
and the generator produces the correct output. These may cause breaking changes
in the SDK API but are necessary for correctness.

## Format

Each fix lists:
- **File**: The affected Dart file
- **Issue**: What's wrong in the hand-written version
- **Fix**: What the generator produces instead
- **Breaking**: Whether this changes the public API
- **SDK impact**: Files outside `lib/src/xdr/` that need updating

---

## Fixes

(To be populated as batches are verified and genuine bugs are identified)
