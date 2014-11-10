module Ubea
  module Exchange
    class HitBtcBase < Base
      # NOTE: https://hitbtc-com.github.io/hitbtc-api/

      def name
        "HitBTC (#{fiat_currency})"
      end

      def exchange_settings
        raise NotImplementedError
      end

      def fiat_currency
        "EUR"
      end

      def trade_fee
        BigDecimal.new("0.001").freeze # 0.1% - see https://hitbtc.com/fees-and-limits
      end

      def refresh_order_book!
        json = get_json("https://api.hitbtc.com/api/1/public/BTC#{fiat_currency}/orderbook") or return

        asks = format_asks_bids(json["asks"])
        bids = format_asks_bids(json["bids"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

      def balance
        balance = get_private("trading/balance")

        balances = balance["balance"]
        if balances.nil?
          p balance
          raise
        end
        fiat = balances.detect { |bal| bal["currency_code"] == fiat_currency }["cash"]
        xbt = balances.detect { |bal| bal["currency_code"] == "BTC" }["cash"]

        OpenStruct.new(
          fiat: Money.new(fiat.to_s, fiat_currency),
          xbt: BigDecimal.new(xbt.to_s),
        ).freeze
      end

      def trade!(args)
        params = {
          clientOrderId: SecureRandom.hex(32),
          symbol: "BTC#{fiat_currency}",
          side: args.fetch(:type),
          price: args.fetch(:price),
          quantity: (BigDecimal.new(args.fetch(:volume)) * 100).to_f.to_s,
          type: "limit",
        }

        Log.debug params
        trade = post_private("trading/new_order", params)
        Log.info trade
      end

      def open_orders
        get_private("trading/orders/active")["orders"]
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

      def get_private(method, params = {})
        request_private :get, method, params
      end

      def post_private(method, params = {})
        request_private :post, method, params
      end

      def request_private(request_type, method, params = {})
        params['nonce'] = nonce
        params['apikey'] = exchange_settings[:api_key]

        response = http_adapter("http://api.hitbtc.com/api/1") \
                   .public_send(request_type, url_path(method), params) do |request|
          request.headers['X-Signature'] = generate_signature(method, params)
        end

        json = JSON.parse(response.body)
        if json.key? "code"
          p json
          raise "OOPS"
        end

        json
      end

      def nonce
        now = Time.now.to_f

        if (@nonce || 0) + 1 > now.to_i
          Log.warn "Throttling API call for 1s to #{self}"
          sleep 1
          now = Time.now.to_f
        end

        @nonce = now.to_i

        sprintf("%.3f", now).sub(".", "")
      end

      def generate_signature(method, params)
        key = exchange_settings[:api_secret]
        message = generate_message(method, params)
        generate_hmac(key, message)
      end

      def generate_message(method, params)
        url_path(method) + encode_params(params)
      end

      def generate_hmac(key, message)
        OpenSSL::HMAC.hexdigest('sha512', key, message)
      end

      def encode_params(params)
        uri = Addressable::URI.new
        uri.query_values = params
        "?" + uri.query
      end

      def url_path(method)
        '/api/1/' + method
      end
    end
  end
end
