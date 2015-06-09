require "ubea/exchanges/base"

module Ubea
  module Exchange
    class BtcEBase < Base
      def fiat_currency
        raise NotImplementedError
      end

      def name
        "BTC-E (#{fiat_currency})"
      end

      def exchange_settings
        raise NotImplementedError
      end

      def trade_fee
        BigDecimal.new("0.002").freeze # 0.2%
      end

      def refresh_order_book!
        json = get_json("https://btc-e.com/api/2/btc_#{fiat_currency.downcase}/depth") or return

        asks = format_asks_bids(json["asks"])
        bids = format_asks_bids(json["bids"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

      def balance
        balance = post_private("getInfo")

        OpenStruct.new(
          fiat: Money.new(balance["funds"][fiat_currency.downcase].to_s, fiat_currency),
          xbt: BigDecimal.new(balance["funds"]["btc"].to_s),
        ).freeze
      end

      def trade!(args)
        params = {
          pair: "btc_#{fiat_currency.downcase}",
          type: args.fetch(:type),
          rate: args.fetch(:price),
          amount: args.fetch(:volume),
        }

        Log.debug params
        trade = post_private("Trade", params)
        Log.info trade
      end

      def open_orders
        post_private("ActiveOrders", {}, false)
      end

      def open_orders?
        open_orders["error"] != "no orders"
      end

    private

      def format_asks_bids(json)
        json.map do |price, volume|
          Offer.new(
            price: Money.new(price.to_s, fiat_currency),
            volume: volume.to_s
          ).freeze
        end
      end

      def post_private(method, params = {}, validate = true)
        params['method'] = method
        params['nonce'] = nonce

        response = retryable_http_request do
          http_adapter("https://btc-e.com").post(url_path, params) do |request|
            request.headers['Key'] = exchange_settings[:api_key]
            request.headers['Sign'] = generate_signature(params)
          end
        end

        json = JSON.parse(response.body)
        return json unless validate

        unless json["success"] == 1
          p json
          raise "OOPS"
        end
        json["return"]
      end

      def nonce
        now = Time.now.to_i + 2

        if now >= (@nonce || 0) - 2
          sleep 1
          now = Time.now.to_i + 2
        end

        @nonce = now
      end

      def generate_signature(params)
        key = exchange_settings[:api_secret]
        message = generate_message(params)
        generate_hmac(key, message)
      end

      def generate_message(params)
        encode_params(params)
      end

      def generate_hmac(key, message)
        OpenSSL::HMAC.hexdigest('sha512', key, message)
      end

      def encode_params(params)
        uri = Addressable::URI.new
        uri.query_values = params
        uri.query
      end

      def url_path
        "/tapi"
      end
    end
  end
end
