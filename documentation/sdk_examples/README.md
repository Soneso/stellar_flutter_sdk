# [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk)

The [Soneso open source Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk) is build with Dart and provides APIs to build and sign transactions, connect and query [Horizon](https://github.com/stellar/horizon). To learn about the general concepts of Stellar you can read the [Stellar Development Guides](https://www.stellar.org/developers/guides/).


## SDK usage examples

| Example | Description | Documentation |
| :--- | :--- | :--- |
| [Create a new account](create_account.md)| A new account is created by another account. In the testnet we can also use Freindbot.|[Create account](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#create-account) |
| [Send native payment](send_native_payment.md)| A sender sends 100 XLM (Stellar Lumens) native payment to a receiver. |[Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment) |
| [Crerate trustline](trustline.md) | An trustor account trusts an issuer account for a specific custom token. The issuer account can now send tokens to the trustor account. |[Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust)|
| [Send tokens - non native payment](send_non_native_payment.md) | Two accounts trust the same issuer account and custom token. They can now send this custom tokens to each other. | [Assets & Trustlines](https://www.stellar.org/developers/guides/concepts/assets.html) and [Change trust](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#change-trust) and [Payments](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#payment)|
| [Path payments](path_payments.md) | Two accounts trust different custom tokens. The sender wants to send token "IOM" but the receiver wants to receive token "ECO".| [Path payment strict send](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-send) and [Path payment strict receive](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#path-payment-strict-receive)|
| [Merge accounts](merge_account.md) | Merge one account into another. The first account is removed, the second receives the funds. | [Account merge](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#account-merge) |
| [Bump sequence number](bump_sequence.md) | In this example we will bump the sequence number of an account to a higher number. | [Bump sequence number](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#bump-sequence) |
| [Manage data](manage_data.md) | Sets, modifies, or deletes a data entry (name/value pair) that is attached to a particular account. | [Manage data](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-data) |
| [Manage buy offer](manage_buy_offer.md) | Creates, updates, or deletes an offer to buy one asset for another, otherwise known as a "bid" order on a traditional orderbook. | [Manage buy offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-buy-offer) |
| [Manage sell offer](manage_buy_offer.md) | Creates, updates, or deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook. | [Manage sell offer](https://www.stellar.org/developers/guides/concepts/list-of-operations.html#manage-sell-offer) |
| [Create passive sell offer](create_passive_sell_offer.md) | Creates, updates and deletes an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook, _without taking a reverse offer of equal price_. | [Create passive sell offer](https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-sell-offer) |

