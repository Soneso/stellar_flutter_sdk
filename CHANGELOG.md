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
