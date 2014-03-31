require 'spec_helper'

describe Cryptsy::Client do
  before(:all) do
    @public_key = ENV['CRYPTSY_PUBKEY']
    @private_key = ENV['CRYPTSY_PRIVKEY']

    unless @public_key && @private_key
      fail 'API keys are required to run this spec'
    end
  end

  subject { Cryptsy::Client.new(@public_key, @private_key) }

  describe '#info' do
    it 'displays current user info' do
      result = subject.info
      expect(result.balances_available).to be_a(Hash)
      expect(result.servertimestamp).to be_an(Integer)
    end
  end

  describe '#calculate_fees' do
    it 'calculates the fee for a buy order' do
      quantity = 1000
      price = 10

      result = subject.calculate_buy_fees(quantity, price)

      expect(result.net.to_f).to eql((quantity * price) + result.fee.to_f)
    end

    it 'calculates the fee for a sell order' do
      quantity = 1000
      price = 10

      result = subject.calculate_sell_fees(quantity, price)

      expect(result.net.to_f).to eql((quantity * price) - result.fee.to_f)
    end
  end

  describe '#generate_new_address' do
    it 'raises an error when using an invalid currency' do
      expect {
        subject.generate_new_address('HERP')
      }.to raise_error(Cryptsy::ClientError)
    end

    it 'returns a newly generated receive address' do
      result = subject.generate_new_address('DOGE')
      expect(result.size).to eql(34)
    end
  end

  describe '#transactions' do
    it 'returns all deposits and withdrawals' do
      expect(subject.transactions).to be_an(Enumerable)
    end
  end

  describe '#market_by_pair' do
    it 'returns market by its currency code pair' do
      expect(subject.market_by_pair('DOGE', 'BTC')).to be_a(Hash)
    end

    it 'returns nil for non-existant markets' do
      expect(subject.market_by_pair('DOGE', 'HERP')).to be_nil
    end
  end
end
