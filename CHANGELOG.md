## [Unreleased]
- Breaking change: strkey decoding and keypair construction reject a number of inputs they used to accept. Every case is listed below; code that decodes addresses coming from users or from the network is worth checking against it.
- `StrKey.decodeCheck`, and every `decode*` method built on it, measures the encoded string before decoding it and the decoded payload after the checksum, and throws a `FormatException` when either falls outside the widths its type admits. A strkey with a valid checksum but the wrong number of characters or bytes previously decoded cleanly and reached the caller. `documentation/sep/sep-23.md` lists the encoded length and payload width of every type, together with the framing rules below.
- An empty or one-character input to a `decode*` method throws `FormatException` instead of `RangeError`, because the length check runs ahead of the base32 step. Code catching `RangeError` around a decode call has to catch `FormatException`.
- `StrKey.decodeCheck` throws a `FormatException` for a `VersionByte` value it does not recognize, rather than decoding against it.
- `StrKey.decodeSignedPayload` and `StrKey.decodeXdrSignedPayload` enforce the SEP-23 framing of a `P...` address: a declared payload length of 1 to 64 bytes, a total width of exactly 32 + 4 + the payload padded to a multiple of four, and NUL padding.
- `StrKey.decodeClaimableBalanceId` rejects a `B...` id whose discriminant is not `CLAIMABLE_BALANCE_ID_TYPE_V0`. `StrKey.encodeClaimableBalanceId` rejects a 33-byte input whose first byte is not zero, and an input of any width other than 32, 33 or 36. A wrong-width input previously passed straight through. Both encode-side rejections raise a plain `Exception`, not a `FormatException`.
- `StrKey.encodeClaimableBalanceId` reads the 36-byte XDR encoding of a balance id, the shape Horizon reports as 72 hex characters, verifying its four-byte union discriminant and stripping it down to the strkey body. It previously ran that form through unchanged and emitted a 63-character string, which the decoder also read back; the same input now yields the 58-character strkey, and a stored 63-character string no longer decodes.
- `StrKey.encodeCheck` verifies that the payload is a width its version byte admits, so every encoder rejects a wrong-width payload with a plain `Exception`. A wrong-width payload previously encoded to a strkey the decoder in this release refuses.
- `StrKey.encodeCheck` also applies the structural checks `StrKey.decodeCheck` applies: the SEP-23 framing of a `P...` payload, and the `CLAIMABLE_BALANCE_ID_TYPE_V0` discriminant of a `B...` payload. Both raise a `FormatException`, unlike the width check beside them. Either input previously encoded to an address the decoder in this release refuses.
- `OperationsRequestBuilder.forClaimableBalance`, `TransactionsRequestBuilder.forClaimableBalance` and `ClaimableBalancesRequestBuilder.forBalanceId` accept every spelling of a balance id (`B...`, the bare hash, or the hash behind the one- or four-byte discriminant) and send the 72-character hex of its XDR encoding, the form Horizon accepts; an id matching no spelling throws `ArgumentError`, naming the reason, before any request. All three previously sent a `B...` id as a 66-character form Horizon rejects, and passed hex spellings through unvalidated.
- `XdrClaimableBalanceID.forId` rejects a discriminant other than V0 instead of rewriting it to V0, and reports a failed `B...` decode instead of swallowing it and reading the string as hex. A hex id of a width matching none of the accepted shapes is refused instead of being zero-padded or truncated to 32 bytes. This rejection reaches every API that reads an id through `forId`: `ClaimClaimableBalanceOperation`, `ClawbackClaimableBalanceOperation`, `RevokeSponsorshipOperation`, `XdrSCAddress.forClaimableBalanceId`, `Address.forClaimableBalanceId` and `XdrSCVal.forClaimableBalanceAddress`.
- `XdrClaimableBalanceID` gains `paddedBalanceIdHex`, the id in the spelling Horizon reports: the four-byte discriminant ahead of the hash.
- `ClaimClaimableBalanceOperation.balanceId` and `ClawbackClaimableBalanceOperation.balanceId` report the 72-character form Horizon serves when the operation is read from XDR; both previously reported the bare 64-character hash. The spellings the two operations accept as input are unchanged.
- `SubmitTransactionResponse.getClaimableBalanceIdIdFromResult(position)` returns the balance id created by the operation at `position`. It previously answered position 0's id whenever both positions held a CreateClaimableBalance, and raised a `TypeError` when position 0 held another operation type. A fee-bumped transaction's inner operations are now read (previously a `TypeError`), and an out-of-range position answers null.
- `SubmitTransactionResponse.getOfferIdFromResult(position)` likewise reads a fee-bumped transaction's inner operations (previously a `TypeError`) and answers null for an out-of-range position or an operation result its position does not carry.
- `SubmitTransactionResponse.success` answers false for a result XDR it cannot read. It previously let the decode failure reach the caller, as a `FormatException` for malformed base64 or a `RangeError` for a body too short to hold a transaction result. A `RangeError` is an `Error`, not an `Exception`, so an `on Exception catch` around the call did not catch it. The getters that branch on `success` follow: `envelopeXdr`, `resultXdr`, `resultMetaXdr` and `feeMetaXdr` answer from `extras`, and `getOfferIdFromResult` and `getClaimableBalanceIdIdFromResult` answer null.
- `SignedPayloadSigner` rejects an empty payload. Its upper-bound message reads "must be at most 64"; the guard accepts 64 bytes, which the old "less than 64" wording contradicted.
- Breaking change: `SignedPayloadSigner.fromAccountId` throws `ArgumentError` for a muxed account id (`M...`). It previously read the muxed id as the ed25519 key it multiplexes, so the signer silently named a key the caller did not pass. `KeyPair.fromAccountId` is unchanged and still accepts both spellings. `ArgumentError` is an `Error`, not an `Exception`, so an `on Exception catch` around that call does not catch it.
- Breaking change: `KeyPair.fromPublicKey` and `KeyPair.fromSecretSeedList` throw `ArgumentError` for a key that is not 32 bytes. For `fromPublicKey` this replaces silent acceptance of a mis-sized key. For `fromSecretSeedList` it replaces an `Exception` raised by the crypto library ("SigningKey must be created from a 32 byte seed"). `ArgumentError` is an `Error`, not an `Exception`, so an `on Exception catch` around that call stops catching it.
- `XdrSCAddress.forLiquidityPoolId` and `XdrLedgerKey.forLiquidityPool` report why an `L...` id failed to decode. The exception type is unchanged; the message names the strkey failure instead of a hexadecimal parse error.
- `XdrSCAddress.forContractId`, `XdrSCAddress.forLiquidityPoolId` and `XdrLedgerKey.forLiquidityPool` refuse a hex id that does not render exactly 32 bytes, with a `FormatException` naming the id kind and the byte count given. A hex id of another width previously built an address or key over a hash of whatever width it spelled, so `'00ff'` produced a 2-byte hash where the protocol fixes 32.
- `LiquidityPoolDepositOperation` and `LiquidityPoolWithdrawOperation` refuse a `liquidityPoolId` that is neither an `L...` strkey nor the hex of a 32-byte hash, throwing `ArgumentError` and naming the reason. A hex id of another width was zero-padded or truncated to 32 bytes before, so the operation was built against a pool the caller never named.
- Breaking change: `Util.stringIdToXdrHash` is removed. It padded or truncated its input to 32 bytes, so it answered for an id other than the one it was given. `Util.hexIdToXdrHash(String hexId, String idKind)` replaces it and rejects any width other than 32; `Util.liquidityPoolIdToXdrHash(String)` takes a pool id in either the `L...` or the hex spelling.
- `Address.fromXdr` reports a claimable balance address's id in the 72-character form Horizon serves, the four-byte discriminant ahead of the hash; it previously reported the 66-character form carrying a single discriminant byte. `XdrClaimableBalanceID.claimableBalanceIdString` still renders that 66-character form, and `Address` accepts every spelling `XdrClaimableBalanceID.forId` accepts.
- `XdrClaimableBalanceID.forId` names the case rule when it refuses a 58-character id that is not a strkey, so a lower-case `b...` id is refused with a message that says why.
- SEP-51 (XDR-JSON): a `B...` strkey carrying a non-zero discriminant is reported by the strkey codec and restated by the reader as `... holds a malformed strkey: "B..." (Decoded claimable balance id carries the discriminant N, which names no claimable balance id type)`. The exception type and the `XDR-JSON <type>` framing are unchanged.
- SEP-51 (XDR-JSON): a `P...` strkey with broken framing is likewise reported by the strkey codec and restated by the reader, so `XdrSignedPayload is 72 bytes, but a 32-byte payload occupies 68` now reads `XdrSignedPayload holds a malformed strkey: "P..." (Decoded signed payload is 72 bytes, but a 32-byte payload occupies 68)`. A `P...` declaring an empty payload is shorter than the encoded length its type admits, so it is now reported as `Encoded string must be 69 to 165 characters, got 63` rather than as an empty payload. The exception type and the `XDR-JSON <type>` framing are unchanged.
- `XdrJsonHelper.readStrKey` no longer converts an `ArgumentError` raised by the strkey codec it is given into an `XDR-JSON ...` failure; it propagates. Only a `FormatException` is restated under the XDR-JSON contract. Every codec the SDK itself passes reports through `FormatException`, so this is visible only to a caller supplying its own.
- `StrKey.isValidContractIdHex` delegates to `StrKey.isValidContractId`, so it now refuses the widths the decoder refuses. It carried no width check of its own, and returned true for a `C...` strkey of any length that passed the checksum. Its input has always been a `C...` strkey rather than hex, and its parameter is renamed from `contractIdHex` to `strKeyContractId` to say so. The parameter is positional, so existing calls compile unchanged.
- `StrKey` gains `signedPayloadLengthViolation(int)` and `signedPayloadFramingViolation(Uint8List)`, which describe how a signed payload breaks the rules above or return `null` when it does not. `StellarProtocolConstants` gains `SIGNED_PAYLOAD_MIN_LENGTH_BYTES`, `SIGNED_PAYLOAD_MIN_PADDED_LENGTH_BYTES`, `SIGNED_PAYLOAD_LENGTH_PREFIX_BYTES`, `CLAIMABLE_BALANCE_DISCRIMINANT_BYTES` and `XDR_UNION_DISCRIMINANT_BYTES`. `VersionByte`'s constructor parameter and `VersionByte.getValue()` are now declared `int` rather than `dynamic`.
- TxRep parsing holds a fixed-width opaque value to the width its type declares. `XdrHash.fromTxRep`, `XdrUint256.fromTxRep` and `XdrSignatureHint.fromTxRep` throw an `Exception` naming the key, the declared byte width and the width given. A line spelling too few or too many hex digits, `...v0: 00` for instance, previously decoded to a value of that literal width and encoded back to XDR of the wrong length. `XdrHash` carries every `Hash` field, so this covers a claimable balance id's `.v0` as well as transaction and wasm hashes.
- `SorobanServer.loadContractCodeForContractId` and `loadContractInfoForContractId` resolve a contract created from a CAP-85 external reference (Protocol 28): the instance names an owner contract and a tag, and the loader reads the wasm hash from the owner's persistent tag entry before loading the code. `SorobanClient.forClientOptions` inherits the resolution. A Stellar Asset Contract instance still yields null.
- The new `SorobanServer.getExternalRefWasmHash` resolves an external reference to its 32-byte wasm hash directly. It returns null when the owner is not a contract address, when no entry exists under the tag, or when the entry does not hold a 32-byte `SCV_BYTES` value; the owner contract is read, never invoked.
- Create-contract host functions carry the external reference executable arm through the new `CreateContractFromExternalRefHostFunction` and `CreateContractFromExternalRefWithConstructorHostFunction` classes and the `XdrHostFunction.forCreatingContractWithExternalRef` and `forCreatingContractV2WithExternalRef` factories. `InvokeHostFunctionOperation.fromXdr` previously threw `UnimplementedError` for a transaction envelope containing such an operation.
- The new `SorobanClient.deployFromExternalRef` deploys a contract instance from a CAP-85 external reference; the new `DeployFromExternalRefRequest` names the owner contract and the tag instead of a wasm hash. The reference is resolved before the transaction is built, so an unresolvable reference throws an `Exception` naming the owner and the tag rather than failing on-chain; one message covers every miss, because `getExternalRefWasmHash` reports each of them as null. The contract spec is loaded from the resolved wasm before submission and the returned client is ready to invoke, the same flow `deploy` uses. Nothing is installed as part of the deployment. Without constructor arguments the operation carries the `CREATE_CONTRACT` arm, with them `CREATE_CONTRACT_V2`, unlike `deploy`, which always uses `CREATE_CONTRACT_V2`.
- Breaking change: the CAP-85 executable tag is carried as raw bytes. `XdrContractExecutableExternalRef.tag` and `XdrSCVal.executableTag` are `Uint8List`. The new getters `tagString` and `executableTagString` read those bytes as UTF-8 and throw a `FormatException` when they spell no text. An executable tag is an XDR `string`, which carries arbitrary bytes, so a tag whose bytes are not valid UTF-8 is legal on the ledger; such a tag previously failed the whole ledger-entry decode, and there was no way to build one. `XdrSCVal.forExecutableTag(String)` and `XdrContractExecutable.forExternalRef(XdrSCAddress, String)` keep their signatures and encode the text as UTF-8; `XdrSCVal.forExecutableTagBytes` and `XdrContractExecutable.forExternalRefBytes` take the bytes. The wire, SEP-0051 and TxRep renderings of a tag that spells text are unchanged byte for byte.
- `CreateContractFromExternalRefHostFunction.tag` and `CreateContractFromExternalRefWithConstructorHostFunction.tag` are `Uint8List` and both classes gain a `tagString` getter and a `forTagString` constructor that takes the tag as text. `XdrHostFunction.forCreatingContractWithExternalRef` and `forCreatingContractV2WithExternalRef` take the tag as `Uint8List`. `DeployFromExternalRefRequest.tag` stays a `String`. A tag decoded from the ledger reaches `SorobanServer.getExternalRefWasmHash` and the resolution inside `SorobanClient.deployFromExternalRef` as bytes, so the entry it resolves is the entry the reference names.
- `XdrDataOutputStream.writeString` no longer refuses a string longer than 65535 bytes. An XDR `string` declares its length in four bytes and the reader has never applied a limit, so a legal value that decoded could not be encoded again. `XdrDataOutputStream.writeStringBytes` and `XdrDataInputStream.readStringBytes` write and read an XDR `string` as raw bytes. `DataOutput.writeUTF` keeps its limit; its two-byte length prefix cannot declare more.
- The new `Address.deriveContractId` returns the contract id ("C...") a deployment by a given deployer with a given salt creates on a given network. The id derives from the deployer, the salt and the network only; the executable does not enter the derivation. A salt that is not exactly 32 bytes throws `ArgumentError`; `ArgumentError` is an `Error`, not an `Exception`, so an `on Exception catch` around the call does not catch it.

## [3.5.0] - 11.Aug.2026.
- Add SEP-0051 (XDR-JSON) support. Every generated XDR type gains `toXdrJson()` and `toXdrJsonValue()` for writing and the statics `fromXdrJson(String)` and `fromXdrJsonValue(Object?)` for reading, so the whole XDR type system converts to the canonical JSON rendering and back. Output is compact and ordered by XDR field declaration, malformed input is reported as a `FormatException` naming the type and the offending key, and the four members are additions that remove nothing. Documented in `documentation/sep/sep-51.md`.
- Breaking change: `XdrAccountEntryV2.signerSponsoringIDs` is now `List<XdrAccountID?>` instead of `List<XdrAccountID>`. `SponsorshipDescriptor` is declared `AccountID*`, so every element of the array carries its own four-byte presence flag on the wire; the binary codec now writes and reads that flag, and an absent element keeps its position in the list rather than being dropped. Code reading the list has to accept `null` elements. In XDR-JSON an absent element renders as `null` inside `signer_sponsoring_i_ds`.
- XDR definitions updated to stellar-xdr commit `911c935`, adding the CAP-0085 external contract executable references (`XdrContractExecutableExternalRef`, the `CONTRACT_EXECUTABLE_EXTERNAL_REF` executable arm, the `SCV_EXECUTABLE_TAG` SCVal arm with `XdrSCVal.forExecutableTag` and `XdrContractExecutable.forExternalRef` factories) and the CAP-0083 `STELLAR_VALUE_EMPTY_TX_SET` consensus value arm (`XdrStellarValueProposedValue`). Smart-account ScMap key ordering compares `SCV_EXECUTABLE_TAG` values content-wise like strings and symbols.
- Soroban transaction submission: `AssembledTransaction.send()` and the smart account wallet deployment now poll `PENDING` and `DUPLICATE` submissions to their true outcome and fail fast on any other status, with the error result XDR and diagnostic events in the failure message. A `DUPLICATE` answer names a transaction already in the network's queue (for example a byte-identical deploy retry still in flight), so polling reports its actual result; a `TRY_AGAIN_LATER` submission was never queued, so the previous poll on its hash could only end in a misleading timeout.
- `SorobanClient.deploy()` loads the returned client's contract spec from the wasm code entry before submitting the deployment, so a successful deployment no longer surfaces as a load failure when the RPC's ledger-entry ingestion runs behind transaction status. Loading by contract id remains the fallback for code without a parseable spec.
- Soroban transactions set no lower time bound. The previous lower bound, backdated 10 seconds from the client clock, is rejected with `tx_too_early` by a submission node whose clock or ledger state lags the client by more than the buffer. `NetworkConstants.TRANSACTION_TIME_BUFFER_SECONDS` is now unused and deprecated.
- `SorobanClient.forClientOptions` now honors `ClientOptions.enableServerLogging` when it constructs its own `SorobanServer` from `rpcUrl`; an injected server is used as configured.
- Integration tests: account funding polls until every endpoint a test reads from (Soroban RPC and/or Horizon) serves the account in three consecutive rounds, replacing the single-lookup wait that raced load-balanced testnet replicas.

## [3.4.0] - 20.Jul.2026.
- OpenZeppelin smart accounts: policies can now be installed on the default context rule at wallet creation, through `OZSmartAccountConfig.defaultPolicies` and a new per-call `policies` parameter on `createWallet` and `deployPendingCredential`, where the per-call value overrides the config default. It takes the same typed `Map<String, OZPolicyInstallParams>` that `addContextRule` uses, and is validated and encoded before the passkey ceremony starts, so an invalid configuration fails without creating an orphaned credential. Constructor arguments are not part of the contract-address preimage, so the derived wallet address is unchanged by the policies. Note that constructor policies land on the default rule, and a spending-limit policy, which the contract installs only on call-contract rules, therefore cannot be installed at deploy time.
- OpenZeppelin smart accounts: fix map-key ordering. Map keys in auth payloads and policy install parameters are now sorted in the Soroban host's content-wise key order. The previous length-major sort over XDR-encoded bytes produced orderings the host rejects, which failed authentication, rule creation, and policy installation for affected key sets. `OZPolicyManager.sortMapByKeyXdr` returns entries in the corrected order, so consumer-built install-param maps sorted with it pick it up automatically.
- OpenZeppelin smart accounts: indexer requests no longer send client-identification headers (the relayer still sends them). Custom headers force a CORS preflight in browsers, and indexer providers only allowlist standard headers, which blocked every indexer request from the web target.
- OpenZeppelin smart accounts: context-rule names (20 UTF-8 bytes) and external-signer key data (256 bytes) are now validated client-side before submission, and the per-rule policy limit (5) is enforced for constructor policies as well, so violations fail fast instead of on-chain. `addContextRule`'s policy validation now shares the constructor-policy path's error surface: the over-limit message text changed, and the invalid-address error reports field `policyAddress` instead of `contractAddress`.
- OpenZeppelin smart accounts: `OZContractErrorCodes` now decodes all five error enums of the OpenZeppelin smart-account contracts (account, WebAuthn verification, simple threshold, weighted threshold, spending limit), and exposes named constants for the smart-account contract's own 16 codes. `decode` resolves a raw code, and `decodeFromMessage` the first known code inside a failure message, to an `OZContractError` carrying the defining contract name and variant name.
- OpenZeppelin smart accounts: the default indexer endpoints for testnet and mainnet now point at the Mercury smart-account indexer, previously the SDF ecosystem workers endpoints. Consumers that set a custom indexer URL are unaffected.
- Soroban: `SorobanServer` accepts a preconfigured Dio instance through the new `httpClient` constructor parameter, matching the Horizon `StellarSDK` pattern, for proxies, interceptors, timeouts and certificate pinning. A preconfigured `SorobanServer` can also be supplied to `OZSmartAccountConfig` and to SEP-45 `WebAuthForContracts`. The `@visibleForTesting` `SorobanServer.withDio` constructor is removed, superseded by it, and `SorobanServer.httpOverrides` now configures the Dio instance in use instead of replacing it.
- Soroban: `SimulateTransactionResponse.diagnosticEvents` decodes the base64 `events` of simulateTransaction into `XdrDiagnosticEvent`, aligning it with `SendTransactionResponse`.
- Invalid `B...` and `L...` strkey ids passed to request-builder methods or to the liquidity pool deposit and withdraw operations now throw `ArgumentError` instead of being silently sent to Horizon. `LiquidityPoolTradesRequestBuilder.forPoolId` builds the URL from the decoded hex id rather than the raw strkey.
- `ContractSpec` integer conversion rejects non-integral and non-finite doubles instead of silently truncating them.
- `TimeBounds` accepts `minTime == maxTime` and `LedgerBounds` accepts `minLedger == maxLedger`, a valid single-point window, and the inverted error messages are corrected. This also fixes `TimeBounds.fromXdr` throwing on valid on-chain transactions with a single-point window.
- `setSourceAccount` with an invalid account id now throws in `SetOptionsOperationBuilder`, `SetTrustLineFlagsOperationBuilder` and `RevokeSponsorshipOperationBuilder`, matching the other 23 builders. Previously these three silently dropped the source account.
- Internal deduplication with additive public API and no removals: the Horizon request builders share the new `RequestBuilder.requestExecute` and `streamEvents`, the 26 operation builders share a new `OperationBuilder` base class, and `soroban_server.dart` is split into cohesive request and response files with the 12 RPC method bodies sharing a helper. All existing import paths and response types are unchanged. The dead SSE encoder is removed, and with it the `archive` dependency.
- Update XDR definitions to upstream `df0c200`: declaration reordering in `Stellar-contract.x`, with the regenerated Dart XDR types identical.
- Consume the XDR generator from the Soneso xdrgen fork so concurrent-ruby resolves to 1.3.7. The upstream gemspec caps it at 1.3.4, which is affected by GHSA-h8w8-99g7-qmvj, GHSA-wv3x-4vxv-whpp and GHSA-6wx8-w4f5-wwcr. Build tooling only, generated output is unchanged.
- Compatibility matrices: repair and complete the Soroban RPC matrix's response field coverage.

## [3.3.0] - 13.Jul.2026.
- Soroban: add the optional `useUpgradedAuth` flag to transaction simulation, on `SimulateTransactionRequest` and on the contract-client path via `MethodOptions`. When set, recording-mode simulation on a supporting RPC (stellar-rpc v27.1.0+) returns `ADDRESS_V2` credential entries (Protocol 27, CAP-71) instead of legacy `ADDRESS` entries. The key is omitted from the JSON-RPC params when `false` (the default); servers without support silently ignore it — detect support by inspecting the credential arm of the returned entries.
- Soroban: `GetHealthResponse` gains `latestLedgerCloseTime` and `oldestLedgerCloseTime`, the unix timestamps (seconds, as strings) at which the latest and oldest ledgers closed, returned by stellar-rpc v27.1.0+. On older servers the fields are `null`.
- SEP-10: `validateChallenge` now verifies the first operation's data value as required by the spec: it must be present, 64 bytes long, and base64-decode to a 48-byte nonce. A missing value on the first operation or on a `web_auth_domain` operation now fails with a `ChallengeValidationError` or `ChallengeValidationErrorInvalidWebAuthDomain` respectively, instead of an unhandled `TypeError`.
- Fix `FeeBumpTransactionBuilder.setBaseFee` for Soroban transactions: the inner transaction's resource fee is now excluded from the per-operation fee rate check and added once to the total fee (`baseFee * (operations + 1) + resourceFee`). Previously the base fee had to cover the entire resource fee and the resource fee was effectively doubled. The minimum base fee for inner fees not divisible by the operation count is now rounded up instead of to the nearest integer, equivalent to the JS SDK's exact comparison and matching the Python SDK.
- Fix automatic state restore in `AssembledTransaction.simulate` (`restore: true`): a successful restore no longer throws "Automatic restore failed". The transaction is now rebuilt with the bumped sequence number and actually re-simulated, keeping its original operation (relevant for `buildWithOp`) and configured fee. The restore transaction's own simulation is now awaited before signing and sending.
- Add an optional `server` parameter to `ClientOptions`, `InstallRequest` and `DeployRequest` to supply a preconfigured `SorobanServer` instead of constructing one from `rpcUrl`. This allows reusing a single RPC connection across operations and injecting custom HTTP client configurations.
- Fix XDR decoding of `unsigned int` (uint32) values: values of 2^31 or greater decoded as negative numbers. Decoding now uses an unsigned 32-bit read, correct across native and web (dart2js) platforms.
- Regenerate the contract-bindings test fixtures (hello, auth, token, atomic swap) with the updated community bindings generator: convenience methods now forward their options into MethodOptions and 64-bit types map to BigInt. The convenience methods no longer accept signer or submitTimeout parameters, and restore defaults to false.
- Add a full-surface fixture (BindingsSpecTestContract) and a gated testnet integration test covering u64, i64, i32, u128, i128, u256, i256, timepoint, duration, bytes, string, map, vec, tuple, option, struct, union (including a payload arm and the RoyalCard integer-discriminant enum), and address round-trips.
- Add an option-shapes fixture (OptionShapesContract) and a gated testnet integration test covering Option nested as a tuple element, a struct field, map values, and a union payload, plus the Dart-keyword-escaped `default` method.
- Give the atomic swap integration tests the same two-minute timeout as their contract-binding variant.
- Compatibility matrices: refresh the Soroban RPC baseline to v27.1.1.

## [3.2.1] - 28.Jun.2026.
- OpenZeppelin smart accounts: add headless `connectToContract` to connect by contract address alone, with no passkey credential. Adds `OZConnectToContractResult`, the `OZSmartAccountEventHeadlessConnected` event, and `isHeadless` on `OZSmartAccountKit` and `OZConnectedState`.
- OpenZeppelin smart accounts: `OZConnectedState.credentialId` is now nullable (`String?`); `null` indicates a headless connection. Minor breaking change for code that reads it as a non-null `String`.
- OpenZeppelin smart accounts: poll the Soroban RPC for account and contract visibility during wallet creation and connection, instead of a fixed delay, for more reliable setup.
- SEP-10: reject challenge transactions with no time bounds or an infinite maximum time, as required by the spec.

## [3.2.0] - 19.Jun.2026.
- Add Protocol 27 (CAP-71) Soroban authorization support: the ADDRESS_V2 and ADDRESS_WITH_DELEGATES credential arms with delegated account authorization
- Update compatibility matrices to Horizon v27.0.0 and Soroban RPC v27.0.0 (coverage unchanged at 100%)

## [3.1.0] - 10.Jun.2026.
- Add OpenZeppelin smart account support
- Package the SDK as a Flutter plugin with native iOS code, distributed for both CocoaPods and Swift Package Manager; minimum iOS deployment target 15.0 (passkey features require iOS 16 at runtime)
- Declare web as a supported plugin platform
- Add Util.constantTimeEquals, Util.bigIntToI128ScVal, Util.decimalStringToStroops, and Util.stroopsToDecimalString
- toXdrInt64Amount and fromXdrInt64Amount now also handle negative amounts; both are deprecated in favor of the new decimal/stroops helpers
- Add SorobanServer.close for resource cleanup
- Deprecate the pre-OZ PasskeyUtils and AuthenticatorAttestationResponse in favor of the smart account API

## [3.0.5] - 28.Mar.2026.
- Rewrite SEP-0011 TxRep to use generated XDR-based toTxRep/fromTxRep methods
- Improve TxRep input validation and test coverage
- Fix TxRep bool interpolation bug
- Restrict TxRep generation to transaction-reachable types
- Update XDR definitions to upstream stellar-xdr cff714a (Protocol 26)
- Update XDR definitions to upstream stellar-xdr 61657d9
- Fix xdr-update Makefile target to re-download .x files when XDR_COMMIT changes
- Fix CI issue template to reference the correct update procedure
- Update Horizon compatibility matrix for Horizon v25.1.0
- Update RPC compatibility matrix for RPC v25.1.1
- Add workflow to auto-detect upstream XDR definition changes
- Add Claude Code automated PR review workflow
- Pin all GitHub Actions to commit SHAs to prevent tag reassignment attacks
- Add least-privilege permissions to all workflows
- Add Dependabot config for monthly GitHub Actions update checks
- Skip web-incompatible mock server test on Chrome platform

## [3.0.4] - 10.Mar.2026.
- Fix published package referencing test/wasm/ asset directory that was excluded via .pubignore

## [3.0.3] - 10.Mar.2026.
- Auto-generate XDR types from canonical Stellar `.x` definition files using a Ruby-based code generator
- New comprehensive documentation with tested code examples covering the full SDK surface
- Add agent skill for AI coding agents (agentskills.io)
- Add SBOM submission workflow for PG Atlas
- See [PR #131](https://github.com/Soneso/stellar_flutter_sdk/pull/131) for breaking changes and migration details

## [3.0.2] - 21.Feb.2026.
- Fix SEP-08 constructor network resolution and fromDomain parameter forwarding
- Fix SEP-10 fromDomain not forwarding httpRequestHeaders; add clientDomain validation
- Fix SEP-09 date fields serialized as full ISO 8601 instead of date-only format
- Fix SEP-24 moreInfoUrl not nullable
- Fix SEP-30 identity role not nullable
- Fix Soroban needsNonInvokerSigningBy for non-invoke operations
- Remove DeploySACWithSourceAccountHostFunction (invalid XDR combination)
- Fix AccountResponse swapped num_sponsoring/num_sponsored, contract_spec type inference, TxRep memo.retHash, offer ID precision loss on web, removeTailZero for "0" on web
- Fix XDR enum operator==/hashCode for web compatibility
- Fix KYC GET request builders not passing custom headers
- Fix incorrect API references and test paths in documentation
- Update RPC compatibility matrix for RPC v25.0.1

## [3.0.1] - 03.Feb.2026.
- SEP-53: message signing and verification support

## [3.0.0] - 14.Jan.2026.

### Added
- Full Flutter web platform support

### Breaking Changes
- 64-bit integer types migrated from `int` to `BigInt` for web compatibility
- See [v3_migration_guide.md](v3_migration_guide.md) for detailed migration instructions

### Fixed
- Web: All 64-bit values now encode/decode correctly
- Web: Soroban I128/U128/I256/U256 work for all values including negatives
- Web: No more silent data corruption for large values exceeding 2^53

## [2.2.2] - 07.Jan.2026.
- RPC: add RPC v25.0.0 response fields to getLatestLedger: closeTime, headerXdr, metadataXdr

## [2.2.1] - 18.Dec.2025.
- SEP-45: add client-side web authentication for contract accounts (C... addresses)

## [2.2.0] - 21.Nov.2025.
- Update Dart SDK requirement from >=3.0.0 to >=3.8.0 (requires Flutter 3.32+)
- Update toml dependency to ^0.17.0 to resolve petitparser version conflicts with melos >=7.2.0
- Update compatibility matrices for version 2.2.0

## [2.1.8] - 16.Nov.2025.
- Replace magic numbers with named constants for improved code maintainability
- Update Dart SDK constraint from >=2.17.0 to >=3.0.0
- Add documentation for 510 classes (100% coverage)
- Add documentation for constructors, methods, and properties (95%+ coverage)
- Add 100+ code examples across SDK features
- Fix signed payload strkey validation (minimum length corrected from 56 to 69 characters)
- Fix SEP-7 URI message parameter mapping (message was incorrectly assigned to publicKey parameter)
- Fix SEP-6 transaction query language parameter (lang was incorrectly using kind value)
- Fix TrustLine effect field name typo in authorizedToMaintainLiabilities
- Fix Address utility claimable balance type handling (was returning forContractId instead of forClaimableBalanceId)
- Fix Soroban address XDR muxed account serialization (was using accountId instead of muxedAccountId)

## [2.1.7] - 16.Oct.2025.
- SEP-01: add `WEB_AUTH_FOR_CONTRACTS_ENDPOINT` and `WEB_AUTH_CONTRACT_ID` fields.
- SEP-47: expose the supported SEPs of soroban contracts (parsed from the meta entries)
- SEP-48: extend the soroban contract parser and related classes for full SEP-48 support (including events)

## [2.1.6] - 09.Oct.2025.
- Horizon: add support for health check endpoint
- Horizon: add support for the /accounts/{account_id}/data/{key} endpoint
- Horizon: add account query parameter for the liquidity_pools endpoint that lists all available liquidity pools.
- RPC: add support for getLedgers endpoint

## [2.1.5] - 29.Sep.2025.
- Soroban: add endLedger param to getEvents RPC method

## [2.1.4] - 12.Sep.2025.
- SEP-6: fix fee details parsing in history transactions

## [2.1.3] - 30.Aug.2025.
- Official support for contract bindings
- Update dependencies

## [2.1.2] - 11.Aug.2025.
- BigInt support in ContractSpec
- Eix StrKey encoding for claimable balances
- Extend InvokeHostFunction to accept any kind of address
- Prepare for contract bindings

## [2.1.1] - 04.Aug.2025.
- add ContractSpec class for easy preparation of XdrSCVal args for invoking contract functions
- update and improve soroban doc

## [2.1.0] - 19.Jul.2025.
- protocol 23 support

## [2.0.1-beta] - 07.Jul.2025.
- first release candidate for protocol 23 support

## [2.0.0] - 15.May.2025.
- improve soroban usability by adding SorobanClient and AssembledTransaction

## [1.9.4] - 08.May.2025.
- update eventsource implementation for newer Dart/Flutter environments

## [1.9.3] - 04.Mar.2025.
- extend SEP-09 support by adding multiple new kyc fields
- link passkey kit for working with soroban smart wallets

## [1.9.2] - 04.Dec.2024.
- support for the SEP-12 endpoints get and post customer files
- experimental soroban passkey support 

## [1.9.1] - 25.Nov.2024.
- include the changes from 1.9.1-beta
- fix contractID setter in XdrHashIDPreimage

## [1.9.1-beta] - 31.Oct.2024.
- Improved Protocol 22 support backwards compatibility:
- revert createdAt to int in soroban TransactionInfo (getTransactions)
- make pagingToken in soroban EventInfo not nullable so it can still be used.
- Improve ErrorResponse object to contain the http response

## [1.9.0-beta] - 24.Oct.2024.
- Protocol 22 support

## [1.8.9] - 21.Oct.2024.
- allow null values in account response for lastModifiedTime

## [1.8.8] - 05.Oct.2024.
- Improve and extend SEP-07 (UriScheme) support
- Updated toml to ^0.16.0
- Forwarded http client to EventSource
- minor fixes

## [1.8.7] - 05.Sep.2024.
- Add Soroban Contract Parser
- contract spec xdr fixes

## [1.8.6] - 19.Aug.2024.
- SEP-06: allow extra fields in deposit and withdraw request
- SEP-06: add userActionRequired by field in transaction response
- SEP-12: null safety improvements
- SEP-24: add userActionRequired by field in transaction response

## [1.8.5] - 09.Aug.2024.
- Update for Horizon API historical data changes

## [1.8.4] - 25.Jul.2024.
- add: submit async transactions (Horizon v2.31.0)
- soroban: add getTransactions, getFeeStats, getVersionInfo (RPC v21.4.0)
- sep12: add transaction_id to get and put customer
- sep: allow custom request headers
- improve submit tx timeout response handling

## [1.8.3] - 16.Jul.2024.
- improve request headers handling
- change sequence number from int to BigInt (web issue)

## [1.8.2] - 1.Jul.2024.
- null safety improvements
- add support for large amounts on web

## [1.8.1] - 6.Jun.2024.
- soroban improvements
- add soroban support to txRep (sep-11)

## [1.8.0] - 13.May.2024.
- add protocol 21 support

## [1.7.8] - 29.Apr.2024.
- update Soroban RPC args for sendTransaction and getTransaction
- add optional httpClient Parameter for StellarSDK 

## [1.7.7] - 24.Apr.2024.
- add SEP-08 support
- improve SEP-06 support

## [1.7.6] - 08.Apr.2024.
- update SEP-01 currency fields: add contract field
- improve streams in the request builders
- update the request builder to maintain the original path and query

## [1.7.5] - 23.Feb.2024.
- update SEP-12 financial account fields
- update SEP-06 to reflect current SEP doc version

## [1.7.4] - 01.Feb.2024.
- add SEP-38 support

## [1.7.3] - 18.Jan.2024.
- update and extend SEP-09 KYC fields

## [1.7.2] - 18.Jan.2024.
- extend soroban send transaction response
- improve SEP-006 support

## [1.7.1] - 18.Dec.2023.
- update for new soroban version 20.0.2

## [1.7.0] - 23.Nov.2023.
- improve status code 429 handling
- fix soroban simulate tx response parsing
- fix a soroban test case

## [1.6.9] - 30.Oct.2023.
- improve sep-24 support

## [1.6.8] - 26.Oct.2023.
- add sep-30 support
- rename expirationLedgerSeq from rpc response

## [1.6.7] - 26.Oct.2023.
- add sep-30 support
- rename expirationLedgerSeq from rpc response

## [1.6.6] - 24.Oct.2023.
- update stable version of p20

## [1.6.5] - 03.Oct.2023.
- update horizon responses for p20
- remove soroban experimental flag

## [1.6.4] - 18.Sep.2023.
- multisigning for soroban prev 11.

## [1.6.3] - 17.Sep.2023.
- support for soroban prev 11

## [1.6.2] - 24.Aug.2023.
- anchor handling improvements
- preparations for web support
- 
## [1.6.1] - 27.Jul.2023.
- xdr fixes: XdrSCNoceKey, data_io
- soroban contract source code loading
- 18 words mnemonic added

## [1.6.0] - 19.Jul.2023.
- add soroban prev. 10 support

## [1.5.8] - 11.Jul.2023.
- add SEP-24 support
- 
## [1.5.7] - 10.Jul.2023.
- make streaming indefinite
- fix names in XdrSCSpec classes
- 
## [1.5.6] - 22.Jun.2023.
- fix soroban events request
- extend soroban server (latest ledger, nonce for address)
- SEP 0006 improvements
- extend test cases

## [1.5.5] - 31.Mai.2023.
- add support for soroban prev 9
- improve soroban tests & docs
- add contract_id - strkey encoding
- add httpOverrides
- add SEP 0006 improvements

## [1.5.4] - 03.Mai.2023.
- update txrep for soroban prev 8

## [1.5.3] - 08.Apr.2023.
- add support for soroban prev 8
- improve soroban tests & docs
- add missing proof_of_liveness kyc field

## [1.5.2] - 03.Mar.2023.
- add support for soroban prev 7
- add support for soroban auth next
- extend txrep for soroban

## [1.5.1] - 30.Jan.2023.
- improve submit transaction response
- add fee meta xdr
- improve tx result xdr
- improve and bugfix tx result meta

## [1.5.0] - 22.Jan.2023.
- add soroban support

## [1.4.1] - 20.Dec.2022.
- add client domain signing delegate to webauth (sep-0010)
- extend and improve webauth test
- extend an improve webauth documentation
- 
## [1.4.0] - 11.Dec.2022.
- improve null safety 
- update api doc
- performance, test and docs improvements
- 
## [1.3.7] - 01.Oct.2022.
- update dependency packages to newest versions
- update sdk to work with the newest packages
- fix example app build

## [1.3.6] - 30.Sep.2022.
- update sep-005 - add support for malay language
- update sep-001 - add new fields

## [1.3.5] - 02.Aug.2022.
- extend txrep to support protocol 19

## [1.3.4] - 28.July.2022.
- add SEP-0007 implementation

## [1.3.3] - 09.Mai.2022.
- protocol 19 support

## [1.3.2] - 26.Apr.2022.
- bugfix stack overflow error

## [1.3.1] - 06.Apr.2022.
- extend example app - add Stellar Quest Series 1 & 2
- bugfixes xdr transaction result parsing

## [1.3.0] - 03.Feb.2022.
- update end extend sep-011 support
- bugfixes in xdr parsing

## [1.2.9] - 25.Jan.2022.
- Muxed accounts are now supported by default
- fix sep-0012 headers
- improve documentation

## [1.2.8] - 11.Jan.2022.
- fix sep-10 transaction post
- fix revoke sponsorship operation
- improve documentation

## [1.2.7] - 27.Nov.2021.
- fix sep-10 transaction post

## [1.2.6] - 27.Nov.2021.
- fix sep-10 timebounds validation

## [1.2.5] - 25.Nov.2021.
- fix xdr parsing - claim predicate error

## [1.2.4] - 07.Nov.2021.
- P18: Fix for Unknown Enum Value in XdrClaimAtomType
- P18: Improve AMM Test Cases

## [1.2.3] - 27.Sep.2021.
- muxed accounts and memo support for SEP-10
- grace period for timebounds validation in SEP-10

## [1.2.2] - 26.Sep.2021.
- protocol 18 support

## [1.2.1] - 01.Sep.2021.
- null-safety support

## [1.2.0] - 22.Aug.2021.
- update http package version
- update eventsource package version

## [1.1.9] - 27.July.2021.
- extend sep-0010 support: add client attribution support 
- extend sep-0010 support: accept multiple signers

## [1.1.8] - 23.July.2021.
- add sep-0006 support 
- add sep-0009 support
- add sep-0012 support

## [1.1.7] - 29.Jun.2021.
- update support for horizon > 2.5.1 (representation of "..._muxed_id" field values changed to string)

## [1.1.6] - 06.Jun.2021.
- extend asset response for horizon 2.2.0
- add new endpont to fetch operations for claimable balances
- add new endpont to fetch transactions for claimable balances
- add 3 missing operations responses 
- add access to _muxed and _muxed_id optional fields from horizon 2.4.0

## [1.1.5] - 05.May.2021.
- Add OPT-IN support for SEP0023 (Muxed Accounts M-strkeys)
- look-a-like G and M addresses
- add docs

## [1.1.4] - 01.May.2021.
- Add OPT-IN support for SEP0023 (Muxed Accounts M-strkeys)
- look-a-like G and M addresses

## [1.1.3] - 01.May.2021.
- add protocol 17 support
- bugfix claim claimable balance

## [1.1.2] - 03.Mar.2021.
- add support for sep-0010
- bugfixes & improvements

## [1.1.1] - 03.Mar.2021.
- add support for sep-0010

## [1.1.0] - 09.Oct.2020.
- add protocol 14 support

## [1.0.7] - 23.Aug.2020.
- make sep-0005 functions async
- minor improvements

## [1.0.6] - 06.Aug.2020.
- add fee bump support for TxRep
- add muxed accounts support for TxRep
- TxRep bugfixes and more tests

## [1.0.5] - 31.Jul.2020.
- add SEP-0011 implementation (txrep)
- add SEP-0011 examples and test

## [1.0.4] - 28.Jul.2020.
- refactor transaction, move network passphrase to signing
- improve examples
- add SEP-0011 MVP (experimental)

## [1.0.3] - 16.Jul.2020.
- SEP-0005 implementation:
- Key Derivation Methods for Stellar Keys
- Update documentation
- Add tests and examples

## [1.0.2] - 14.Jul.2020.
- SEP-0002 implementation - Federation
- update documentation
- add tests and examples

## [1.0.1] - 12.Jul.2020.
- SEP-0001 implementation
- loading and parsing stellar.toml data
- update documentation
- improve tests and examples

## [1.0.0] - 06.Jul.2020.
- update documentation
- improve tests and examples
- add tx_set_operation_count to ledger response
- finish beta testing phase

## [0.8.6] - 04.Jul.2020.
- improve path finding
- improve trades query
- fix and improve order book query
- change offer ids from int to String
- imporve tests and examples

## [0.8.5] - 02.Jul.2020.
- Handle muxed accounts on fee bump transactions (feeSource)
- Handle muxed accounts as transaction source
- Add fee bump example
- Add muxed account example

## [0.8.4] - 02.Jul.2020.
- Add support for muxed accounts
- Use XdrMuxedAccount in all supported operations

## [0.8.3] - 01.Jul.2020.
- Add fee stats implementation
- Add max operation fee
- Fix fee bump transaction

## [0.8.2] - 28.Jun.2020.
- Add query tests for accounts, efffects, ledgers.
- Fix ledger response parsing.
- Extend EffectsRequestBuilder for order, limit, cursor.
- remove many warnings/hints

## [0.8.1] - 27.Jun.2020.
- Add examples, app and more documentation.
- Restructuring of the project.
- Improve tests.

## [0.8.0] - 26.Jun.2020.
- Extend documentation and tests, extend orders result.

## [0.7.9] - 25.Jun.2020.
- Added examples, documentation, tests and bugfixes.

## [0.7.8] - 24.Jun.2020.
- Added tests and bugfixes.
