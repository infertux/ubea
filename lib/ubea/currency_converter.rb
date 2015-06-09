require "retryable"
require "ubea/log"

module Ubea
  class CurrencyConverter
    @rates = {}

    def self.convert(amount, from, to)
      amount * rate(from, to)
    end

    def self.rate(from, to)
      pair = [from, to].join

      if @rates[pair].nil? || @rates[pair].updated_at < Time.now - 10 * 60

        rate_1 = YahooExchange.get_rate(from, to)

        rate_2 = begin
          RateExchange.get_rate(from, to)
        rescue OpenURI::HTTPError
          FreeCurrencyConverterAPI.get_rate(from, to)
        end

        spread = (1.0 - rate_1 / rate_2).abs * 100
        if spread > 1
          raise "#{spread.to_f}% spread for #{pair}: #{rate_1} vs #{rate_2}!"
        end

        @rates[pair] = OpenStruct.new(
          rate: rate_1,
          updated_at: Time.now
        ).freeze

      end

      @rates[pair].rate
    end

    class RateExchange
      URL = "http://rate-exchange.appspot.com/currency?from=%s&to=%s".freeze

      def self.get_rate(from, to)
        url = URL % [from, to]
        json = get_json(url)
        rate = json["rate"].to_s
        BigDecimal.new(rate)
      end

      def self.get_json(url)
        retryable(tries: 3, sleep: 1) do
          json = open(url).read
          JSON.parse(json)
        end
      end
    end

    class FreeCurrencyConverterAPI
      URL = "http://www.freecurrencyconverterapi.com/api/v2/convert?q=%s_%s&compact=y".freeze

      def self.get_rate(from, to)
        url = URL % [from, to]
        string = get_json(url, from, to)
        rate = BigDecimal.new(string)

        if rate <= 1E-3
          Log.warn "Cannot retrieve exchange rate for #{from}#{to}, not enough precision, using the opposite pair"

          url = URL % [to, from]
          string = get_json(url, to, from)
          rate = BigDecimal.new(1) / BigDecimal.new(string)
        end

        rate
      end

      def self.get_json(url, from, to)
        retryable(tries: 3, sleep: 1) do
          json = open(url).read
          JSON.parse(json)["#{from}_#{to}"]["val"].to_s
        end
      end
    end

    class YahooExchange
      URL = "http://download.finance.yahoo.com/d/quotes.csv?s=%s%s=X&f=sl1d1&e=.csv".freeze

      def self.get_rate(from, to)
        url = URL % [from, to]
        csv = get_csv(url)
        rate = BigDecimal.new(csv[1].to_s)

        if rate <= 1E-3
          Log.warn "Cannot retrieve exchange rate for #{from}#{to}, not enough precision, using the opposite pair"

          url = URL % [to, from]
          csv = get_csv(url)
          rate = BigDecimal.new(1) / BigDecimal.new(csv[1].to_s)
        end

        rate
      end

      def self.get_csv(url)
        retryable(tries: 3, sleep: 1) do
          csv = open(url).read
          csv.split(",")
        end
      end
    end
  end
end
