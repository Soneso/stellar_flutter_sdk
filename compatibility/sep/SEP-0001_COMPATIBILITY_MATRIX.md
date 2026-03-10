# SEP-0001 (Stellar Info File) Compatibility Matrix

**Generated:** 2026-03-10 19:47:44  
**SDK Version:** 3.0.4  
**SEP Version:** 2.7.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md

## SEP Summary

The `stellar.toml` file is used to provide a common place where the Internet
can find information about your organization’s Stellar integration. By setting
the home_domain of your Stellar account to the domain that hosts your
`stellar.toml`, you can create a definitive link between this information and
that account. Any website can publish Stellar network information, and the
`stellar.toml` is designed to be readable by both humans and machines.

If you are an anchor or issuer, the `stellar.toml` file serves a very important
purpose: it allows you to publish information about your organization and
token(s) that help to legitimize your offerings. Clients and exchanges can use
this information to decide whether a token should be listed. Fully and
truthfully disclosing contact and business information is an essential step in
responsible token issuance.

If you are a validator, the `stellar.toml` file allows you to declare your
node(s) to other network participants, which improves discoverability, and
contributes to the health and decentralization of the network as a whole.

## Overall Coverage

**Total Coverage:** 100.0% (70/70 fields)

- ✅ **Implemented:** 70/70
- ❌ **Not Implemented:** 0/70

**Required Fields:** 100.0% (3/3)

**Optional Fields:** 100.0% (67/67)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0001/stellar_toml.dart`

### Key Classes

- **`StellarToml`**: Main class for fetching and parsing stellar.toml files from Stellar domains
- **`GeneralInformation`**: Represents the general information section (VERSION, NETWORK_PASSPHRASE, etc.)
- **`Documentation`**: Represents organization documentation (ORG_NAME, ORG_URL, ORG_LOGO, etc.)
- **`PointOfContact`**: Represents point of contact information (name, email, keybase, etc.)
- **`Currency`**: Represents currency/asset documentation (code, issuer, status, etc.)
- **`Validator`**: Represents validator node information (ALIAS, DISPLAY_NAME, PUBLIC_KEY, etc.)

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Currency Documentation | 100.0% | 100.0% | 24 | 0 | 24 |
| General Information | 100.0% | 100% | 16 | 0 | 16 |
| Organization Documentation | 100.0% | 100% | 17 | 0 | 17 |
| Point of Contact Documentation | 100.0% | 100% | 8 | 0 | 8 |
| Validator Information | 100.0% | 100% | 5 | 0 | 5 |

## Detailed Field Comparison

### Currency Documentation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `anchor_asset` |  | ✅ | `anchorAsset` | If anchored token, code / symbol for asset that token is anchored to. E.g. USD, BTC, SBUX, Address of real-estate investment property. |
| `anchor_asset_type` |  | ✅ | `anchorAssetType` | Type of asset anchored. Can be `fiat`, `crypto`, `nft`, `stock`, `bond`, `commodity`, `realestate`, or `other`. |
| `approval_criteria` |  | ✅ | `approvalCriteria` | a human readable string that explains the issuer's requirements for approving transactions. |
| `approval_server` |  | ✅ | `approvalServer` | url of a [sep0008](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md) compliant approval service that signs validated transactions. |
| `attestation_of_reserve` |  | ✅ | `attestationOfReserve` | URL to attestation or other proof, evidence, or verification of reserves, such as third-party audits. |
| `code` | ✓ | ✅ | `code` | Token code. Required. |
| `code_template` |  | ✅ | `codeTemplate` | A pattern with `?` as a single character wildcard. Allows a `[[CURRENCIES]]` entry to apply to multiple assets that share the same info. An example is futures, where the only difference between issues... |
| `collateral_address_messages` |  | ✅ | `collateralAddressMessages` | Messages stating that funds in the `collateral_addresses` list are reserved to back the issued asset. See below for details. |
| `collateral_address_signatures` |  | ✅ | `collateralAddressSignatures` | These prove you control the `collateral_addresses`. For each address you list, sign the entry in `collateral_address_messages` with the address's private key and add the resulting string to this list ... |
| `collateral_addresses` |  | ✅ | `collateralAddresses` | If this is an anchored crypto token, list of one or more public addresses that hold the assets for which you are issuing tokens. |
| `conditions` |  | ✅ | `conditions` | Conditions on token |
| `contract` | ✓ | ✅ | `contract` | Contract ID of the token contract. The token must be compatible with the [SEP-41 Token Interface](sep-0041.md) to be defined here. Required for tokens that are not Stellar Assets. Omitted if the token... |
| `desc` |  | ✅ | `desc` | Description of token and what it represents |
| `display_decimals` |  | ✅ | `displayDecimals` | Preference for number of decimals to show when a client displays currency balance |
| `fixed_number` |  | ✅ | `fixedNumber` | Fixed number of tokens, if the number of tokens issued will never change |
| `image` |  | ✅ | `image` | URL to a PNG image on a transparent background representing token |
| `is_asset_anchored` |  | ✅ | `isAssetAnchored` | `true` if token can be redeemed for underlying asset, otherwise `false` |
| `is_unlimited` |  | ✅ | `isUnlimited` | The number of tokens is dilutable at the issuer's discretion |
| `issuer` | ✓ | ✅ | `issuer` | Stellar public key of the issuing account. Required for tokens that are Stellar Assets. Omitted if the token is not a Stellar asset. |
| `max_number` |  | ✅ | `maxNumber` | Max number of tokens, if there will never be more than `max_number` tokens |
| `name` |  | ✅ | `name` | A short name for the token |
| `redemption_instructions` |  | ✅ | `redemptionInstructions` | If anchored token, these are instructions to redeem the underlying asset from tokens. |
| `regulated` |  | ✅ | `regulated` | indicates whether or not this is a [sep0008](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md) regulated asset. If missing, `false` is assumed. |
| `status` |  | ✅ | `status` | Status of token. One of `live`, `dead`, `test`, or `private`. Allows issuer to mark whether token is dead/for testing/for private use or is live and should be listed in live exchanges. |

### General Information

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `ACCOUNTS` |  | ✅ | `accounts` | A list of Stellar accounts that are controlled by this domain |
| `ANCHOR_QUOTE_SERVER` |  | ✅ | `anchorQuoteServer` | The server used for receiving [SEP-38](sep-0038.md) requests. |
| `AUTH_SERVER` |  | ✅ | `authServer` | (deprecated) The endpoint used for [SEP-3](sep-0003.md) Compliance Protocol |
| `DIRECT_PAYMENT_SERVER` |  | ✅ | `directPaymentServer` | The server used for receiving [SEP-31](sep-0031.md) direct fiat-to-fiat payments. Requires [SEP-12](sep-0012.md) and hence a `KYC_SERVER` TOML attribute. |
| `FEDERATION_SERVER` |  | ✅ | `federationServer` | The endpoint for clients to resolve stellar addresses for users on your domain via [SEP-2](sep-0002.md) Federation Protocol |
| `HORIZON_URL` |  | ✅ | `horizonUrl` | Location of public-facing Horizon instance (if you offer one) |
| `KYC_SERVER` |  | ✅ | `kYCServer` | The server used for [SEP-12](sep-0012.md) Anchor/Client customer info transfer |
| `NETWORK_PASSPHRASE` |  | ✅ | `networkPassphrase` | The passphrase for the specific [Stellar network](https://developers.stellar.org/docs/networks) this infrastructure operates on |
| `SIGNING_KEY` |  | ✅ | `signingKey` | The signing key is used for [SEP-3](sep-0003.md) Compliance Protocol (deprecated) and [SEP-10](sep-0010.md)/[SEP-45](sep-0045.md) Authentication Protocols |
| `TRANSFER_SERVER` |  | ✅ | `transferServer` | The server used for [SEP-6](sep-0006.md) Anchor/Client interoperability |
| `TRANSFER_SERVER_SEP0024` |  | ✅ | `transferServerSep24` | The server used for [SEP-24](sep-0024.md) Anchor/Client interoperability |
| `URI_REQUEST_SIGNING_KEY` |  | ✅ | `uriRequestSigningKey` | The signing key is used for [SEP-7](sep-0007.md) delegated signing |
| `VERSION` |  | ✅ | `version` | The version of SEP-1 your `stellar.toml` adheres to. This helps parsers know which fields to expect. |
| `WEB_AUTH_CONTRACT_ID` |  | ✅ | `webAuthContractId` | The web authentication contract ID for [SEP-45 Web Authentication](sep-0045.md) |
| `WEB_AUTH_ENDPOINT` |  | ✅ | `webAuthEndpoint` | The endpoint used for [SEP-10 Web Authentication](sep-0010.md) |
| `WEB_AUTH_FOR_CONTRACTS_ENDPOINT` |  | ✅ | `webAuthForContractsEndpoint` | The endpoint used for [SEP-45 Web Authentication](sep-0045.md) |

### Organization Documentation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `ORG_DBA` |  | ✅ | `orgDBA` | (may not apply) [DBA](https://www.entrepreneur.com/encyclopedia/doing-business-as-dba) of your organization |
| `ORG_DESCRIPTION` |  | ✅ | `orgDescription` | Short description of your organization |
| `ORG_GITHUB` |  | ✅ | `orgGithub` | Your organization's Github account |
| `ORG_KEYBASE` |  | ✅ | `orgKeybase` | A [Keybase](https://keybase.io/) account name for your organization. Should contain proof of ownership of any public online accounts you list here, including your organization's domain. |
| `ORG_LICENSE_NUMBER` |  | ✅ | `orgLicenseNumber` | Official license, registration, or authorization number of your organization, if applicable |
| `ORG_LICENSE_TYPE` |  | ✅ | `orgLicenseType` | Type of financial or other license, registration, or authorization your organization holds, if applicable |
| `ORG_LICENSING_AUTHORITY` |  | ✅ | `orgLicensingAuthority` | Name of the authority or agency that issued a license, registration, or authorization to your organization, if applicable |
| `ORG_LOGO` |  | ✅ | `orgLogo` | A PNG image of your organization's logo on a transparent background |
| `ORG_NAME` |  | ✅ | `orgName` | Legal name of your organization |
| `ORG_OFFICIAL_EMAIL` |  | ✅ | `orgOfficialEmail` | An email that business partners such as wallets, exchanges, or anchors can use to contact your organization. Must be hosted at your `ORG_URL` domain. |
| `ORG_PHONE_NUMBER` |  | ✅ | `orgPhoneNumber` | Your organization's phone number in [E.164 format](https://en.wikipedia.org/wiki/E.164), e.g. `+14155552671`. See also [this guide](https://support.twilio.com/hc/en-us/articles/223183008-Formatting-International-Phone-Numbers). |
| `ORG_PHONE_NUMBER_ATTESTATION` |  | ✅ | `orgPhoneNumberAttestation` | URL on the same domain as your `ORG_URL` that contains an image or pdf of a phone bill showing both the phone number and your organization's name. |
| `ORG_PHYSICAL_ADDRESS` |  | ✅ | `orgPhysicalAddress` | Physical address for your organization |
| `ORG_PHYSICAL_ADDRESS_ATTESTATION` |  | ✅ | `orgPhysicalAddressAttestation` | URL on the same domain as your `ORG_URL` that contains an image or pdf official document attesting to your physical address. It must list your `ORG_NAME` or `ORG_DBA` as the party at the address. Only... |
| `ORG_SUPPORT_EMAIL` |  | ✅ | `orgSupportEmail` | An email that users can use to request support regarding your Stellar assets or applications. |
| `ORG_TWITTER` |  | ✅ | `orgTwitter` | Your organization's Twitter account |
| `ORG_URL` |  | ✅ | `orgUrl` | Your organization's official URL. Your `stellar.toml` must be hosted on the same domain. |

### Point of Contact Documentation

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `email` |  | ✅ | `email` | Business email address for the principal |
| `github` |  | ✅ | `github` | Personal Github account |
| `id_photo_hash` |  | ✅ | `idPhotoHash` | SHA-256 hash of a photo of the principal's government-issued photo ID |
| `keybase` |  | ✅ | `keybase` | Personal Keybase account. Should include proof of ownership for other online accounts, as well as the organization's domain. |
| `name` |  | ✅ | `name` | Full legal name |
| `telegram` |  | ✅ | `telegram` | Personal Telegram account |
| `twitter` |  | ✅ | `twitter` | Personal Twitter account |
| `verification_photo_hash` |  | ✅ | `verificationPhotoHash` | SHA-256 hash of a verification photo of principal. Should be well-lit and contain: principal holding ID card and signed, dated, hand-written message stating `I, $NAME, am a principal of $ORG_NAME, a S... |

### Validator Information

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `ALIAS` |  | ✅ | `alias` | A name for display in stellar-core configs that conforms to `^[a-z0-9-]{2,16}$` |
| `DISPLAY_NAME` |  | ✅ | `displayName` | A human-readable name for display in quorum explorers and other interfaces |
| `HISTORY` |  | ✅ | `history` | The location of the history archive published by this validator |
| `HOST` |  | ✅ | `host` | The IP:port or domain:port peers can use to connect to the node |
| `PUBLIC_KEY` |  | ✅ | `publicKey` | The Stellar account associated with the node |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0001!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
