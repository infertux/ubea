require "ubea/exchanges/kraken_base"

module Ubea
  module Exchange
    class KrakenEur < KrakenBase
      def fiat_currency
        "EUR"
      end

      def exchange_settings
        Ubea.config.exchange_settings[:kraken_eur]
      end
    end
  end
end
