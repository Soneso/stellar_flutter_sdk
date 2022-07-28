# [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk)

## Documentation

### General
The Soneso open source Stellar SDK for Flutter is build with Dart and provides APIs to build and sign transactions, connect and query [Horizon](https://github.com/stellar/horizon). To learn about the general concepts of Stellar you can read the [Stellar Development Guides](https://www.stellar.org/developers/guides/).

### Resources

##### * [Installation Guide](installation.md)
##### * [Quick Start Guide](quick_start.md)
##### * [Source code](../lib/src)
##### * [Download API documentation](sdk_api_doc.zip)
##### * [Main page](https://github.com/Soneso/stellar_flutter_sdk)
##### * [SDK Examples](sdk_examples/):

| Example | Description | Documentation |
| :--- | :--- | :--- |
| [Create a new account](sdk_examples/create_account.md)| A new account is created by another account. In the testnet we can also use Freindbot.|[Create account](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#create-account) |
| [Send native payment](sdk_examples/send_native_payment.md)| A sender sends 100 XLM (Stellar Lumens) native payment to a receiver. |[Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment) |
| [Crerate trustline](sdk_examples/trustline.md) | An trustor account trusts an issuer account for a specific custom token. The issuer account can now send tokens to the trustor account. |[Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust)|
| [Send tokens - non native payment](sdk_examples/send_non_native_payment.md) | Two accounts trust the same issuer account and custom token. They can now send this custom tokens to each other. | [Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust) and [Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment)|
| [Path payments](sdk_examples/path_payments.md) | Two accounts trust different custom tokens. The sender wants to send token "IOM" but the receiver wants to receive token "ECO".| [Path payment strict send](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-send) and [Path payment strict receive](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-receive)|
| [Merge accounts](sdk_examples/merge_account.md) | Merge one account into another. The first account is removed, the second receives the funds. | [Account merge](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#account-merge) |
| [Bump sequence number](sdk_examples/bump_sequence.md) | In this example we will bump the sequence number of an account to a higher number. | [Bump sequence number](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#bump-sequence) |
| [Manage data](sdk_examples/manage_data.md) | Sets, modifies, or deletes a data entry (name/value pair) that is attached to a particular account. | [Manage data](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-data) |
| [Manage buy offer](sdk_examples/manage_buy_offer.md) | Creates, updates, or deletes an offer to buy one asset for another, otherwise known as a "bid" order on a traditional orderbook. | [Manage buy offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-buy-offer) |
| [Manage sell offer](sdk_examples/manage_buy_offer.md) | Creates, updates, or deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook. | [Manage sell offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-sell-offer) |
| [Create passive sell offer](sdk_examples/create_passive_sell_offer.md) | Creates, updates and deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook, _without taking a reverse offer of equal price_. | [Create passive sell offer](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-sell-offer) |
| [Change trust](sdk_examples/change_trust.md) | Creates, updates, and deletes a trustline. | [Change trust](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#change-trust) and [Assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html) |
| [Allow trust](sdk_examples/allow_trust.md) | Updates the authorized flag of an existing trustline. | [Allow trust](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#allow-trust) and [Assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html) |
| [Stream payments](sdk_examples/stream_payments.md) | Listens for payments received by a given account.| [Streaming](https://developers.stellar.org/api/introduction/streaming/) |
| [Fee bump transaction](sdk_examples/fee_bump.md) | Fee bump transactions allow an arbitrary account to pay the fee for a transaction.| [Fee bump transactions](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md)|
| [Muxed accounts](sdk_examples/muxed_account_payment.md) | In this example we will see how to use a muxed account in a payment operation.| [First-class multiplexed accounts](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0027.md)|
| [SEP-0001: stellar.toml](sdk_examples/sep-0001-toml.md) | In this example you can find out how to obtain data about an organization’s Stellar integration.| [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)|
| [SEP-0002: Federation](sdk_examples/sep-0002-federation.md) | This examples shows how to resolve a stellar address, a stellar account id, a transaction id and a forward by using the federation protocol. | [SEP-0002](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md)|
| [SEP-0005: Key derivation](sdk_examples/sep-0005-key-derivation.md) | In this examples you can see how to generate 12 or 24 words mnemonics for different languages using the Flutter SDK, how to generate key pairs from a mnemonic (with and without BIP 39 passphrase) and how to generate key pairs from a BIP 39 seed. |
[SEP-0005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)|
| [SEP-0006: Deposit and Withdrawal API](sdk_examples/sep-0006-transfer.md) | In this examples you can see how to use the sdk to communicate with anchors.| [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)|
| [SEP-0007: URI Scheme to facilitate delegated signing](sdk_examples/sep-0007-urischeme.md) | In this examples you can see how to use the sdk to support SEP-0007 in your wallet.| [SEP-0007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md)|
| [SEP-0010: Stellar Web Authentication](sdk_examples/sep-0010-webauth.md) | This example shows how to authenticate with any web service which requires a Stellar account ownership verification. | [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)|
| [SEP-0011: Txrep](sdk_examples/sep-0011-txrep.md) | This example shows how to  to generate Txrep (human-readable low-level representation of Stellar transactions) from a transaction and how to create a transaction object from a Txrep string. | [SEP-0011](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md)|
| [SEP-0012: KYC API](sdk_examples/sep-0012-kyc.md) | In this examples you can see how to use the sdk to send KYC data to anchors and other services. | [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)|


More examples and use cases can be found in the [test classes](../test).

An additional [example App](../example) is in progress.
