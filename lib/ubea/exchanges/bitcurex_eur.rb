module Ubea
  module Exchange
    class BitcurexEur < Base
      # NOTE: https://eur.bitcurex.com/

      def fiat_currency
        "EUR"
      end

      def trade_fee
        BigDecimal.new("0.004").freeze # 0.4% - see https://eur.bitcurex.com/op%C5%82aty-i-limity
      end

      def refresh_order_book!
        json = get_json("https://#{fiat_currency.downcase}.bitcurex.com/data/orderbook.json") or return

        asks = format_asks_bids(json["asks"])
        bids = format_asks_bids(json["bids"])

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

    private

      def format_asks_bids(json)
        json.map do |price, volume|
          Offer.new(
            price: Money.new(price.to_s, fiat_currency),
            volume: volume.to_s,
          ).freeze
        end
      end
    end
  end
end
