require "open-uri"
require "json"
require "base64"
require "addressable/uri"
require "retryable"
require "faraday"
require "net/protocol"
require "ubea"
require "ubea/log"
require "ubea/money"
require "ubea/offer"
require "ubea/order_book"

module Ubea
  module Exchange
    class Base
      attr_reader :order_book, :updated_at, :last_rtt

      def id
        @id ||= begin
          self.class.to_s.gsub(/.*::/, "").gsub(/([A-Z])/, "_\\1").gsub(/\A_/, "").downcase
        end
      end

      alias_method :to_param, :id

      def short_name
        @short_name ||= self.class.to_s.gsub(/.*::/, "")
      end

      alias_method :to_s, :short_name

      def name
        raise NotImplementedError, to_s
      end

      def trade_fee
        raise NotImplementedError, to_s
      end

      def balance
        raise NotImplementedError, to_s
      end

    protected

      def retryable_http_request
        exceptions = [
          Faraday::ConnectionFailed,
          Faraday::TimeoutError,
          Faraday::SSLError,
          Net::ReadTimeout,
        ].freeze

        retryable(tries: 5, sleep: 1, on: exceptions) do
          yield
        end
      end

    private

      def http_adapter(base_uri)
        @http ||= Faraday.new(url: base_uri) do |faraday|
          faraday.request :url_encoded
          faraday.adapter :net_http
          # faraday.response :logger                  # log requests to STDOUT
        end
      end

      def get_html(url)
        retryable(tries: 5, sleep: 1) do
          open(url).read
        end
      end

      def get_json(url)
        html = get_html(url) or return

        begin
          JSON.parse(html)
        rescue JSON::ParserError
          nil
        end
      end

      def mark_as_refreshed
        now = Time.now.utc
        @last_rtt = now - updated_at if updated_at
        @updated_at = now

        Log.debug "Order book for #{self} has been refreshed"
      end
    end
  end
end
