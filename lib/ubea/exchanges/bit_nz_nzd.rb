module Ubea
  module Exchange
    class BitNzNzd < Base
      def website
        "https://bitnz.com/".freeze
      end

      def name
        "bitNZ"
      end

      def fiat_currency
        "NZD"
      end

      def trade_fee
        BigDecimal.new("0.005").freeze # 0.5% - see https://bitnz.com/fees
      end

      def refresh_order_book!
        json = get_json("https://bitnz.com/api/0/orderbook") or return

        asks = format_asks_bids(json["asks"])
        bids = format_asks_bids(json["bids"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

    private

      def format_asks_bids(json)
        json.map do |price, volume|
          price_nzd = Money.new(price.to_s, fiat_currency)
          price_normalized = price_nzd.exchange_to(Ubea.config.default_fiat_currency)

          Offer.new(
            price: price_normalized,
            volume: volume.to_s
          ).freeze
        end
      end
    end
  end
end
