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
