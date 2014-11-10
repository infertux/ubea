require "ubea/exchanges/base"

module Ubea
  module Exchange
    class AnxBtcBase < Base
      def name
        "ANXBTC (#{fiat_currency})"
      end

      def trade_fee
        BigDecimal.new("0.005").freeze # 0.5%??? - see https://anxbtc.com/faq#tab1
      end

      def refresh_order_book!
        json = get_json("https://anxpro.com/api/2/BTC#{fiat_currency}/money/depth/full") or return

        asks = format_asks_bids(json["data"]["asks"])
        bids = format_asks_bids(json["data"]["bids"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

    private

      def format_asks_bids(json)
        json.map do |tuple|
          price, volume = tuple["price"], tuple["amount"]
          price_chf = Money.new(price, fiat_currency)
          price_normalized = price_chf.exchange_to(Ubea.config.default_fiat_currency)

          Offer.new(
            price: price_normalized,
            volume: volume
          ).freeze
        end
      end
    end
  end
end
