require "ubea/exchanges/anx_btc_base"

module Ubea
  module Exchange
    class AnxBtcChf < AnxBtcBase
      def fiat_currency
        "CHF"
      end
    end
  end
end
