module Ubea
  module Exchange
    def self.find(exchange_id)
      require_relative "./exchanges/#{exchange_id}"

      klass_name = exchange_id.capitalize.gsub(/_(.)/) { Regexp.last_match[1].capitalize }
      klass = Object.const_get("Ubea::Exchange::#{klass_name}")
      klass.new
    end
  end
end
