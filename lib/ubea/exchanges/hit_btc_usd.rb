require "ubea/exchanges/hit_btc_base"

module Ubea
  module Exchange
    class HitBtcUsd < HitBtcBase
      def fiat_currency
        "USD"
      end

      def exchange_settings
        Ubea.config.exchange_settings[:hit_btc_usd]
      end
    end
  end
end
