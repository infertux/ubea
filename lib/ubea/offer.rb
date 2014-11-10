require "bigdecimal"

module Ubea
  class Offer
    attr_reader :price, :weighted_price, :volume

    def initialize(hash)
      self.price = hash.delete(:price)
      self.weighted_price = hash.delete(:weighted_price)
      self.volume = Money.new(hash.delete(:volume), "BTC")

      raise ArgumentError unless hash.empty?
      raise ArgumentError, "#{price.class} is not Money" unless price.is_a? Money
    end

    def to_h
      {
        weighted_price: weighted_price.to_f.to_s,
        limit_price: price.to_f.to_s,
        volume: volume.to_f.to_s,
      }
    end

    def inspect
      "#<Ubea::Offer price=#{price} volume=#{volume}>"
    end

    alias_method :to_s, :inspect

    def price=(price)
      raise ArgumentError if price < 0
      @price = price
    end

    def weighted_price=(weighted_price)
      raise ArgumentError if weighted_price && weighted_price < 0
      @weighted_price = weighted_price
    end

    def volume=(volume)
      raise ArgumentError if volume < 0
      @volume = volume
    end
  end
end
