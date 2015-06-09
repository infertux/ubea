require "ubea/exchanges/base"

module Ubea
  module Exchange
    class BitcoinCoIdIdr < Base
      BadResponseError = Class.new(Exception)

      def name
        "Bitcoin.co.id (#{fiat_currency})"
      end

      def fiat_currency
        "IDR"
      end

      def trade_fee
        BigDecimal.new("0.003").freeze # 0.3%
      end

      def refresh_order_book!
        json = get_json("https://vip.bitcoin.co.id/api/btc_#{fiat_currency.downcase}/depth") or return

        asks = format_asks_bids(json["sell"])
        bids = format_asks_bids(json["buy"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

      def balance
        balance = post_private("getInfo")

        OpenStruct.new(
          fiat: Money.new(balance["balance"][fiat_currency.downcase].to_s, fiat_currency),
          xbt: BigDecimal.new(balance["balance"]["btc"].to_s),
        ).freeze
      end

      def trade!(args)
        amount_key, amount_value = if args.fetch(:type) == "buy"
          idr = Money.new(args.fetch(:price), fiat_currency) * BigDecimal.new(args.fetch(:volume))
          [:idr, idr.to_s(with_currency: false)]
        else
          [:btc, args.fetch(:volume)]
        end

        params = {
          pair: "btc_#{fiat_currency.downcase}",
          type: args.fetch(:type),
          price: args.fetch(:price),
          amount_key => amount_value,
        }

        Log.debug params
        trade = post_private("trade", params)
        Log.info trade
      end

      def open_orders
        post_private("openOrders")["orders"]
      end

      def open_orders?
        !open_orders.nil?
      end

    private

      def format_asks_bids(json)
        json.map do |price, volume|
          price_idr = Money.new(price.to_s, fiat_currency)
          price_normalized = price_idr.exchange_to(Ubea.config.default_fiat_currency)

          Offer.new(
            price: price_normalized,
            volume: volume
          ).freeze
        end
      end

      def post_private(method, params = {})
        params['method'] = method
        params['nonce'] = nonce

        response = retryable_http_request do
          http_adapter("https://vip.bitcoin.co.id").post(url_path, params) do |request|
            request.headers['Key'] = Ubea.config.exchange_settings[:bitcoin_co_id_idr][:api_key]
            request.headers['Sign'] = generate_signature(params)
          end
        end

        raise BadResponseError if response.body.empty?

        begin
          json = JSON.parse(response.body)
          unless json["success"] == 1
            p json
            raise "OOPS"
          end
          json["return"]

        rescue JSON::ParserError
          raise BadResponseError
        end

      rescue BadResponseError
        Log.warn "BadResponseError for #{self}, retrying..."
        retry
      end

      def nonce
        now = Time.now.to_f

        if (@nonce || 0) + 1 > now.to_i
          Log.warn "Throttling API call for 1s to #{self}"
          sleep 1
          now = Time.now.to_f
        end

        @nonce = now.to_i

        sprintf("%.6f", now).sub(".", "")
      end

      def generate_signature(params)
        key = Ubea.config.exchange_settings[:bitcoin_co_id_idr][:api_secret]
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
