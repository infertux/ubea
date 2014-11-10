module Ubea
  module Exchange
    class BitcoinDeEur < Base
      def fiat_currency
        "EUR"
      end

      def trade_fee
        BigDecimal.new("0.005").freeze # 0.5% - see https://www.bitcoin.de/en/infos#gebuehren
      end

      def refresh_order_book!
        html = get_html("https://www.bitcoin.de/en/market") or return

        asks = format_asks_bids(html, "offer")
        bids = format_asks_bids(html, "order")

        return if asks.empty? || asks.size != bids.size

        mark_as_refreshed
        @order_book = OrderBook.new(asks: asks, bids: bids)
      end

    private

      def format_asks_bids(html, type)
        return unless html.match(/<tbody id="trade_#{type}_results_table_body"(.+?)<\/tbody>/m)

        Regexp.last_match[1].each_line.select { |line| line.include?("data-critical-price") }.map do |line|
          return unless line.match(/<tr[^>]+data-critical-price="([\d\.]+)" data-amount="([\d\.]+)">/)

          Offer.new(price: Money.new(Regexp.last_match[1], fiat_currency), volume: Regexp.last_match[2]).freeze
        end
      end
    end
  end
end
