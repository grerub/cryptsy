# Cryptsy

Provides an idiomatic Ruby client for the authenticated Cryptsy API

## Examples

Grab your API keys from the Crypsty website

```ruby
client = Cryptsy::Client.new('YOUR PUBLIC KEY', 'YOUR PRIVATE KEY')
```

Check your account details

```ruby
# Get account blances
client.info.balances_available

# Get transfers, transactions, open orders
client.transfers
client.transactions
client.orders
```

Query markets

```ruby
client.markets
client.market_by_pair('DOGE', 'BTC')
```

Generate new receive addresses

```ruby
client.generate_deposit_address('DOGE') # => 'DTP2Na7P4JpwhUuPTdJWjGzAK9P5VXF5Zd'
client.generate_deposit_address('BTC')  # => '156q4WMvWmCSmTdZSVVn8zdnDFJWZsb6XW'
```
