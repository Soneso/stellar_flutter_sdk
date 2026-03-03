# Potential Improvements

## XdrChangeTrustAsset encode/decode asymmetry

- **Files:** `lib/src/xdr/xdr_asset.dart`, `lib/src/xdr/xdr_trustline.dart`
- **Issue:** Encode and decode take different paths for `XdrChangeTrustAsset`:
  - **Decode** (`xdr_trustline.dart:468`): calls `XdrChangeTrustAsset.decode` directly, which reads the discriminant itself.
  - **Encode** (`xdr_trustline.dart:463`): calls `XdrAsset.encode` (the parent), which writes the discriminant at `xdr_asset.dart:60`, then hits the `ASSET_TYPE_POOL_SHARE` case at line 70, checks `if (encodedAsset is XdrChangeTrustAsset)`, and delegates to `XdrChangeTrustAsset.encode` which only writes the body.
- **Problem:** `XdrChangeTrustAsset.encode` is not self-contained (missing discriminant write), the parent `XdrAsset.encode` has special knowledge of its subclass, and encode/decode are asymmetric.
- **Proposed fix:**
  1. Add `stream.writeInt(encodedAsset.discriminant.value)` to `XdrChangeTrustAsset.encode`
  2. Change `XdrChangeTrustOp.encode` to call `XdrChangeTrustAsset.encode` directly (matching how decode works)
  3. Remove the `ASSET_TYPE_POOL_SHARE` case from `XdrAsset.encode`
- **Reference:** The Java SDK (`ChangeTrustAsset.java`) writes the discriminant in its own encode method and is called directly.
