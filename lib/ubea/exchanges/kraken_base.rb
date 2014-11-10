require "ubea/exchanges/base"

module Ubea
  module Exchange
    class KrakenBase < Base
      RateError = Class.new(Exception)

      def name
        "Kraken (#{fiat_currency})"
      end

      def fiat_currency
        raise NotImplementedError
      end

      def exchange_settings
        raise NotImplementedError
      end

      def trade_fee
        BigDecimal.new("0.0035").freeze # 0.35%
      end

      def refresh_order_book!
        json = get_json("https://api.kraken.com/0/public/Depth?pair=XBT#{fiat_currency}") or return

        asks = format_asks_bids(json["result"]["XXBTZ#{fiat_currency}"]["asks"])
        bids = format_asks_bids(json["result"]["XXBTZ#{fiat_currency}"]["bids"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

      def balance
        balance = post_private("Balance")

        OpenStruct.new(
          fiat: Money.new(balance["Z#{fiat_currency}"], fiat_currency),
          xbt: BigDecimal.new(balance["XXBT"]),
        ).freeze
      end

      def trade!(args, simulate: false)
        params = {
          pair: "XXBTZ#{fiat_currency}",
          type: args.fetch(:type),
          volume: args.fetch(:volume),
        }

        ordertype = args.fetch(:ordertype, "limit")

        case ordertype
        when "market"
          params.merge!(
            ordertype: "market",
          )
        when "limit"
          params.merge!(
            price: args.fetch(:price),
            ordertype: "limit",
          )
        else
          raise "Unknown ordertype"
        end

        if simulate
          params.merge!(
            validate: true
          )
        end

        Log.debug params
        trade = post_private("AddOrder", params)
        Log.info trade
      end

      def open_orders
        post_private("OpenOrders")["open"]
      end

      def open_orders?
        !open_orders.empty?
      end

    private

      def format_asks_bids(json)
        json.map do |price, volume|
          Offer.new(
            price: Money.new(price, fiat_currency),
            volume: volume
          ).freeze
        end
      end

      def post_private(method, params = {})
        params['nonce'] = nonce

        response = retryable_http_request do
          http_adapter("https://api.kraken.com").post(url_path(method), params) do |request|
            request.headers['API-Key'] = exchange_settings[:api_key]
            request.headers['API-Sign'] = generate_signature(method, params)
          end
        end

        json = JSON.parse(response.body)
        unless json["error"].empty?
          raise RateError if json["error"] == ["EAPI:Rate limit exceeded"]

          p json
          raise "OOPS"
        end

        @delay = 1

        json["result"]

      rescue JSON::ParserError
        retry

      rescue RateError
        @delay == 1 ? @delay = 10 : @delay += 10
        retry
      end

      def nonce
        now = Time.now.to_f

        @delay ||= 1
        if (@nonce || 0) + @delay > now.to_i
          Log.warn "Throttling API call for #{@delay}s to #{self}"
          sleep @delay
          now = Time.now.to_f
        end

        @nonce = now.to_i

        sprintf("%.6f", now).sub(".", "")
      end

      def generate_signature(method, params)
        key = Base64.decode64 exchange_settings[:api_secret]
        message = generate_message(method, params)
        generate_hmac(key, message)
      end

      def generate_message(method, params)
        digest = OpenSSL::Digest.new('sha256', params['nonce'] + encode_params(params)).digest
        url_path(method) + digest
      end

      def generate_hmac(key, message)
        Base64.strict_encode64(OpenSSL::HMAC.digest('sha512', key, message))
      end

      def encode_params(params)
        uri = Addressable::URI.new
        uri.query_values = params
        uri.query
      end

      def url_path(method)
        '/0/private/' + method
      end
    end
  end
end
