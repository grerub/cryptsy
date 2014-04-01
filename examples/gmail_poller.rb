$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'cryptsy'
require 'gmail'

CONFIRM_TRUSTED_ADDRESS_PATTERN = /^https:\/\/www.cryptsy.com(\/users\/confirmtrustedaddress\/.*)/
CONFIRM_WITHDRAWAL_PATTERN      = /^https:\/\/www.cryptsy.com(\/users\/confirmwithdrawal\/.*)/

class GmailAdapter
  def initialize(username, password)
    @client = Gmail.connect!(username, password)
  end

  def call
    @client.inbox.find(:unread, from: 'support@cryptsy.com').each do |email|
      yield email.message.body
    end
  end

  def logout
    @client.logout
  end
end

adapter = GmailAdapter.new(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'])

poller = Cryptsy::ConfirmationPoller.new(adapter, CONFIRM_TRUSTED_ADDRESS_PATTERN)
links = poller.run_once

links.each do |link|
  puts "Found link #{link}"
end

adapter.logout
