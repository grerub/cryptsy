require 'hashie'
require 'json'
require 'openssl'
require 'uri'

module Cryptsy
  class Client
    DEFAULT_OPTIONS = {
      url: 'https://api.cryptsy.com',
      ssl: {
        verify: false
      }
    }

    ORDER_TYPE_BUY = 'Buy'
    ORDER_TYPE_SELL = 'Sell'

    # @param [String] public_key
    # @param [String] private_key
    # @param [Hash] options
    def initialize(public_key, private_key, options = {})
      @public_key = public_key
      @private_key = private_key
      @digest = OpenSSL::Digest::SHA512.new
      @connection = Faraday.new(DEFAULT_OPTIONS.merge(options))
    end

    def info
      call(:getinfo)
    end

    def markets
      call(:getmarkets)
    end

    def market_by_pair(primary_code, secondary_code)
      markets.find do |market|
        market.primary_currency_code == normalize_currency_code(primary_code) &&
          market.secondary_currency_code == normalize_currency_code(secondary_code)
      end
    end

    def orders(market_id)
      call(:myorders, marketid: market_id)
    end

    def all_orders
      call(:allmyorders)
    end

    def trades(market_id, limit = 200)
      call(:mytrades, marketid: market_id, limit: limit)
    end

    def all_trades
      call(:allmytrades)
    end

    def transactions
      call(:mytransactions)
    end

    def transfers
      call(:mytransfers)
    end

    def market_depth(market_id)
      call(:depth, marketid: market_id)
    end

    def market_orders(market_id)
      call(:marketorders, marketid: market_id)
    end

    def market_trades(market_id)
      call(:markettrades, marketid: market_id)
    end

    def create_buy_order(market_id, quantity, price)
      create_order(market_id, ORDER_TYPE_BUY, quantity, price)
    end

    def create_sell_order(market_id, quantity, price)
      create_order(market_id, ORDER_TYPE_SELL, quantity, price)
    end

    def create_order(market_id, order_type, quantity, price)
      call(:createorder, marketid: market_id, ordertype: order_type, quantity: quantity, price: price)
    end

    def cancel_order(order_id)
      call(:cancelorder, orderid: order_id)
    end

    def cancel_orders(market_id)
      call(:cancelmarketorders, marketid: market_id)
    end

    def cancel_all_orders
      call(:cancelallorders)
    end

    def calculate_buy_fees(quantity, price)
      calculate_fees(ORDER_TYPE_BUY, quantity, price)
    end

    def calculate_sell_fees(quantity, price)
      calculate_fees(ORDER_TYPE_SELL, quantity, price)
    end

    def calculate_fees(order_type, quantity, price)
      call(:calculatefees, ordertype: order_type, quantity: quantity, price: price)
    end

    def generate_new_address(currency)
      if currency.is_a?(Integer)
        call(:generatenewaddress, currencyid: currency).address
      else
        call(:generatenewaddress, currencycode: normalize_currency_code(currency)).address
      end
    end

    def make_withdrawal(address, amount)
      call(:makewithdrawal, address: address, amount: amount)
    end

    # @raise [CryptsyError]
    # @param [Symbol] method_name
    # @param [Hash] params
    # @return [Object]
    def call(method_name, params = {})
      request = {
        method: method_name,
        nonce: (Time.now.to_f * 1000).to_i
      }.merge(params)

      body = URI.encode_www_form(request)
      signature = OpenSSL::HMAC.hexdigest(@digest, @private_key, body)

      response = @connection.post do |req|
        req.url 'api'
        req.body = body

        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.headers['Key'] = @public_key
        req.headers['Sign'] = signature
      end

      process_response(response)
    end

    # @raise [CryptsyError]
    # @param [Faraday::Response] response
    # @return [Object]
    def process_response(response)
      body = Hashie::Mash.new(JSON.parse(response.body))

      unless body.success.to_i == 1
        raise ClientError, body.error
      end

      body.return
    end

    # @param [Object] code
    # @return [String]
    def normalize_currency_code(code)
      code.to_s.upcase
    end
  end
end
