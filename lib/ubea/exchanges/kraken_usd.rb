module Ubea
  module Exchange
    class KrakenUsd < KrakenBase
      def fiat_currency
        "USD"
      end

      def exchange_settings
        Ubea.config.exchange_settings[:kraken_usd]
      end
    end
  end
end
