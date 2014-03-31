require 'spec_helper'
require 'cryptsy/web_client'

describe Cryptsy::WebClient do
  before(:all) do
    @username = ENV['CRYPTSY_USERNAME']
    @password = ENV['CRYPTSY_PASSWORD']
    @tfa_secret = ENV['CRYPTSY_TFA_SECRET']

    unless @username && @password && @tfa_secret
      fail 'Cryptsy login details are required to run this spec'
    end
  end

  subject { Cryptsy::WebClient.new(@username, @password, @tfa_secret) }

  describe '#login' do
    it 'logs into Cryptsy' do
      response = subject.login
      # Should respond with 302
      # Location header should be /users/dashboard or /users/pincode
    end

    context 'with bad credentials' do
      subject { Cryptsy::WebClient.new('herp', 'derp', 'lolz') }
      it 'fails to login' do
        response = subject.login
        # Should respond with 200
        # Look for div#flashMessages
      end
    end
  end
end
