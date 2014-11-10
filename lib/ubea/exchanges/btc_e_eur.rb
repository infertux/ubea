require "ubea/exchanges/btc_e_base"

module Ubea
  module Exchange
    class BtcEEur < BtcEBase
      def fiat_currency
        "EUR"
      end

      def exchange_settings
        Ubea.config.exchange_settings[:btc_e_eur]
      end
    end
  end
end
