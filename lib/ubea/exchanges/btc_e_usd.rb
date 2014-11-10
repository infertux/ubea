require "ubea/exchanges/btc_e_base"

module Ubea
  module Exchange
    class BtcEUsd < BtcEBase
      def fiat_currency
        "USD"
      end

      def exchange_settings
        Ubea.config.exchange_settings[:btc_e_usd]
      end
    end
  end
end
