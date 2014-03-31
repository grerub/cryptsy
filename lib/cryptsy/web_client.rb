require 'faraday-cookie_jar'
require 'nokogiri'
require 'rotp'

module Cryptsy
  # Unsafe client that allows you to do things that the Cryptsy API does not permit,
  # including withdrawals to untrusted addresses, as well as pre-approving addresses
  # for withdrawals
  class WebClient
    DEFAULT_OPTIONS = {
      url: 'https://www.cryptsy.com'
    }

    # @param [HTTP::CookieJar]
    attr_reader :cookie_jar

    # @param [String] username
    # @param [String] password
    # @param [String] tfa_secret
    # @param [Hash] options
    def initialize(username, password, tfa_secret, options = {})
      @username = username
      @password = password
      @tfa = ROTP::TOTP.new(tfa_secret)

      @cookie_jar = HTTP::CookieJar.new

      @connection = Faraday.new(DEFAULT_OPTIONS.merge(options)) do |builder|
        builder.use :cookie_jar, jar: @cookie_jar
        builder.request :url_encoded
        builder.adapter Faraday.default_adapter
      end
    end

    # Performs login operation using the configured username and password
    # @return [Faraday::Response]
    def login
      request = {
        'data[User][username]' => @username,
        'data[User][password]' => @password,
      }

      post_with_csrf('/users/login', request)
    end

    # Finishes login operation using TOTP and TFA secret
    # @return [Faraday::Response]
    def pincode
      request = {
        'data[User][pincode]' => @tfa.now
      }

      post_with_csrf('/users/pincode', request)
    end

    # Submits a trusted address for pre-approved withdrawals
    #
    # @param [Integer] currency_id
    # @param [String] address
    # @return [Faraday::Response]
    def add_trusted_address(currency_id, address)
      request = {
        'data[Withdrawal][currency_id]' => currency_id,
        'data[Withdrawal][address]' => address,
        'data[Withdrawal][existing_password]' => @password,
        'data[Withdrawal][pincode]' => @tfa.now,
      }

      post_with_csrf('/users/addtrustedaddress', request)
    end

    # Submits a request for withdrawal to an untrusted address
    #
    # @param [Integer] currency_id
    # @param [String] address
    # @param [Float] amount
    # @return [Faraday::Response]
    def make_withdrawal(currency_id, address, amount)
      request = {
        'data[Withdrawal][fee]' => '1.00000000',
        'data[Withdrawal][wdamount]' => amount,
        'data[Withdrawal][address]' => address,
        'data[Withdrawal][approvedaddress]' => '',
        'data[Withdrawal][existing_password]' => @password,
        'data[Withdrawal][pincode]' => @tfa.now,
      }

      post_with_csrf("/users/makewithdrawal/#{currency_id}", request)
    end

    # @param [String] url
    # @return [Faraday::Response]
    def get(url)
      @connection.get(url)
    end

    # @param [String] url
    # @param [Hash] body
    # @return [Faraday::Response]
    def post(url, body)
      @connection.post(url, body)
    end

    # Performs an initial GET request to the given URL to obtain any CSRF tokens,
    # injects them into the given request, then performs a POST request to the given URL
    #
    # @param [String] url
    # @param [Hash] request
    # @return [Faraday::Request]
    def post_with_csrf(url, request)
      prepare_request(get(url), request)
      post(url, request)
    end

    private

    # @param [Faraday::Response] initial_response
    # @param [Hash] new_request
    # @return [void]
    def prepare_request(initial_response, new_request)
      doc = Nokogiri::HTML(initial_response.body)

      # Inject CSRF token into new request
      doc.xpath('//input').each do |input|
        if input[:name] =~ /_Token/
          new_request[input[:name]] = input[:value]
        end
      end

      # Set the request method
      new_request['_method'] = 'POST'
    end
  end
end
