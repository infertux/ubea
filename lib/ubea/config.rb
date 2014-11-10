require "ostruct"

module Ubea
  class Config
    def self.default
      config = OpenStruct.new

      config.default_fiat_currency = "USD" # ideally the most used currency so we do as little conversions as possible
      config.exchange_settings = {}

      config
    end
  end
end
