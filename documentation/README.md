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

More examples and use cases can be found in the [test classes](../test).

An additional [example App](../example) is in progress.