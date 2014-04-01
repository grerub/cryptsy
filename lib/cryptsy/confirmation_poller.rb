require 'nokogiri'

module Cryptsy
  class ConfirmationPoller
    # @param [Object] adapter
    # @param [Regexp] pattern
    def initialize(adapter, pattern)
      @adapter = adapter
      @pattern = pattern
    end

    # @return [Enumerable]
    def run_once
      links = []

      @adapter.call do |email|
        scan_links(links, email)
      end

      links
    end

    # @param [Integer] sleep_interval
    # @return [void]
    def run_until_found(sleep_interval = 3)
      loop do
        links = run_once
        return links unless links.empty?
        sleep sleep_interval
      end
    end

    private

    # @param [Array] links
    # @param [String] email
    # @return [void]
    def scan_links(links, email)
      doc = Nokogiri::HTML(email.to_s)
      doc.xpath('//a').each do |link|
        if link[:href] =~ @pattern
          links.push($1)
        end
      end
    end
  end # ConfirmationPoller
end
