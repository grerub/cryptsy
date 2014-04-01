# Cryptsy

Provides an idiomatic Ruby client for the authenticated Cryptsy API

[![Gem Release](http://img.shields.io/gem/v/cryptsy.svg)](http://rubygems.org/gems/cryptsy)

## JSON client

Grab your API keys from the Crypsty website

```ruby
client = Cryptsy::Client.new('YOUR PUBLIC KEY', 'YOUR PRIVATE KEY')
```

### Check your account details

```ruby
# Get account blances
client.info.balances_available

# Get transfers, transactions, open orders
client.transfers
client.transactions
client.orders
```

### Query markets

```ruby
client.markets
client.market_by_pair('DOGE', 'BTC')
```

### Generate new receive addresses

```ruby
client.generate_deposit_address('DOGE') # => 'DTP2Na7P4JpwhUuPTdJWjGzAK9P5VXF5Zd'
client.generate_deposit_address('BTC')  # => '156q4WMvWmCSmTdZSVVn8zdnDFJWZsb6XW'
```

### Make withdrawals

```ruby
client.make_withdrawal('DKkNNCF2DRcHtSgbKeDTVd2T8qjng1Z8hV', 1250.0)
```

Note that this method only works for addresses that have been pre-approved. Use the web client
if you wish to automate the pre-approval process.

## Web client

This package provides a web client for doing unsafe operations on Cryptsy. The official JSON
API does not allow you to withdraw funds to addresses that have not been pre-approved. Nor does
it let you pre-approval addresses. Therefore, you would be forced to login to the HTML web interface,
and input your password and TFA token to do withdrawals and add trusted addresses.

This client is rough around the edges, but the basic functionality is there. It has many extra dependencies,
so you have to explicitly require it and install the dependencies.

```sh
gem install faraday-cookie_jar nokogiri rotp
```

```ruby
require 'cryptsy/web_client'

web_client = Cryptsy::WebClient.new('YOUR CRYPTSY USERNAME', 'YOUR CRYPTSY PASSWORD', 'YOUR TFA SECRET')
web_client.login
web_client.pincode
```

Now that you have a session on Cryptsy, you can perform privileged operations.

### Withdrawals

If you wish to make a withdrawal to an address that has not been pre-approved, use the following:

```ruby
web_client.make_withdrawal(94, 'DKkNNCF2DRcHtSgbKeDTVd2T8qjng1Z8hV', 1250.0)
```

You will receive a confirmation email after a short period. The link in this email must be visited
for the withdrawal to continue.

Note that you **will not** be able to use this for trusted addresses. Instead, use the respective method
on the regular JSON client.

### Trusted addresses

If you wish to make an address trusted, use the following:

```ruby
web_client.add_trusted_address('DQRhettwhyR6xeK6xFQ2nbhjhSTgZzdgMR')
```

You will receive a confirmatin email after a short period. The link in this email must be visited
for the address to become trusted.

Note that you **will not** be able to use the web client to make withdrawals to this address now. Instead,
use the respective method on the regular JSON client.

### Caching sessions

The web client uses Faraday with middleware for [HTTP::CookieJar](https://github.com/sparklemotion/http-cookie).

The cookie jar is accessible, so you can save and load cookies to a file between uses.

```ruby
jar = web_client.cookie_jar

jar.load('path/to/cookies.txt')
jar.cleanup

jar.save('path/to/cookies.txt', session: true)
```

## Confirmation email polling

Take automation to the next level! Using `ConfirmationPoller`, you can scan the email account associated with your
Cryptsy account. Combining this with the web client allows you to automatically confirm:

- Trusted addresses
- Withdrawals to untrusted addresses

Refer to `examples/gmail_poller.rb` to see basic integration with Gmail. Combine it with the web client like so:

```ruby
adapter = GmailAdapter.new('GMAIL USERNAME', 'GMAIL PASSWORD')
web_client = Cryptsy::WebClient.new('CRYPTSY USERNAME', 'CRYPTSY PASSWORD', 'TFA SECRET')
poller = Cryptsy::ConfirmationPoller.new(adapter, CONFIRM_TRUSTED_ADDRESS_PATTERN)

poller.run_until_found.each do |link|
  web_client.get(link)
end

adapter.logout
```

It's recommended to setup an application-specific password instead of using your primary Gmail password.

## Security concerns

### SSL verification

The certificate for `https://api.cryptsy.com` is invalid. Therefore, any clients that connect to it
must disable SSL verification. **This opens up the possibility for a MITM attack.**

Until this is fixed, avoid experimenting with the JSON client on untrusted networks until this
is corrected. The web client does not have this vulnerability, the `https://www.cryptsy.com` certificate
is correct.

### Plaintext credentials

Using both clients will result in a large number of credentials needing to be stored in plaintext.

This includes the following:

- Cryptsy username & password
- Cryptsy API key pair
- Cryptsy two-factor authentication (TFA) secret

Therefore, you should isolate the use of this client away from a public-facing service. On a separate VM,
you can use a background worker process, like Sidekiq or Resque.
