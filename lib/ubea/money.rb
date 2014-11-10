require "bigdecimal"
require "ubea/currency_converter"

module Ubea
  class Money < BigDecimal
    CurrencyMismatch = Class.new(Exception)

    attr_reader :currency

    def initialize(amount, currency)
      self.currency = currency

      super(amount)
    end

    def exchange_to(new_currency)
      return self if new_currency == currency

      new_amount = CurrencyConverter.convert(self, currency, new_currency)
      self.class.new new_amount, new_currency
    end

    def to_s(with_currency: true, auto_format: true, tooltip_currency: false)
      amount = dup
      currency = self.currency.dup

      old_amount_string = if tooltip_currency
        amount.exchange_to(tooltip_currency).to_s(auto_format: false)
      end

      if auto_format
        if currency == "BTC" && amount < 1
          amount *= 1E6
          currency = "bits"
          self.max_decimal_places = 2
        end
      end

      amount = sprintf("%.#{decimal_places}f", amount)

      left, right = amount.split('.')

      if right
        right.gsub!(/(\d{3})(?=\d)/, '\\1 ') # thousand sep
        right.gsub!(/[0 ]+$/, '') # remove superfluous traling zeros
        groups = right.split(" ")
        right << "0" * (3 - groups.last.size) if groups.size > 1 && groups.last # padding
      end

      amount = left.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse
      amount << "." << right if right && !right.empty?

      amount << " " << currency if with_currency

      if tooltip_currency && tooltip_currency != currency
        amount = %(<span title="#{old_amount_string}" data-toggle="tooltip">#{amount}</span>)
      end

      amount
    end

    def inspect
      "#<Ubea::Money amount=#{self}>"
    end

    def +(other)
      assert_currency!(other)
      self.class.new super, currency
    end

    def -(other)
      assert_currency!(other)
      self.class.new super, currency
    end

    def *(other)
      assert_currency!(other, strict: false)
      self.class.new super, currency
    end

    def /(other)
      assert_currency!(other, strict: false)
      self.class.new super, currency
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      to_s == other.to_s
    end

    # <=> does not work somehow???
    def >(other)
      assert_currency!(other)
      super
    end

    def >=(other)
      assert_currency!(other)
      super
    end

    def <(other)
      assert_currency!(other)
      super
    end

    def <=(other)
      assert_currency!(other)
      super
    end

    # Keep currency when marshaling
    def _dump(level)
      [super.to_s.split(':').last, currency].join ':'
    end

    def self._load(args)
      new(*args.split(':'))
    end

  private

    attr_accessor :max_decimal_places

    def currency=(currency)
      raise "Currency cannot be nil" unless currency
      @currency = currency
    end

    def decimal_places
      max = max_decimal_places || 8 # NOTE: don't care about extra decimals

      0.upto(max) do |i|
        return i if self == round(i)
      end

      max
    end

    def assert_currency!(other, strict: true)
      return if other.is_a?(self.class) && other.currency == "BTC" unless strict

      raise CurrencyMismatch, "#{inspect} != #{other.inspect}" if other.is_a?(self.class) && other.currency != currency
    end
  end
end
