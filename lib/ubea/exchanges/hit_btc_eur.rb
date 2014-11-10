require "ubea/exchanges/hit_btc_base"

module Ubea
  module Exchange
    class HitBtcEur < HitBtcBase
      def fiat_currency
        "EUR"
      end

      def exchange_settings
        Ubea.config.exchange_settings[:hit_btc_eur]
      end
    end
  end
end
