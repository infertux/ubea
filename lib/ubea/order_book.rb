module Ubea
  class OrderBook
    attr_reader :asks, :bids
    attr_accessor :market, :updated_at

    def initialize(hash)
      @asks = hash.delete(:asks).sort_by(&:price).freeze # buy
      @bids = hash.delete(:bids).sort_by(&:price).freeze # sell

      raise ArgumentError unless hash.empty?
    end

    def to_param
      market.to_param
    end

    def highest_bid
      bids.last
    end

    def lowest_ask
      asks.first
    end

    def weighted_asks_up_to(max_price)
      weighted_offers(asks, ->(price) { price <= max_price })
    end

    def weighted_bids_down_to(min_price)
      weighted_offers(bids, ->(price) { price >= min_price })
    end

    def min_ask_price_for_volume(max_price, max_volume)
      filter = if max_price
        ->(price) { price <= max_price }
      else
        ->(_) { true }
      end

      interesting_asks = interesting_offers(asks, filter)
      best_offer_price_for_volume(interesting_asks, max_volume)
    end

    def max_bid_price_for_volume(min_price, max_volume)
      filter = if min_price
        ->(price) { price >= min_price }
      else
        ->(_) { true }
      end

      interesting_bids = interesting_offers(bids, filter).reverse # reverse to start from most expensive
      best_offer_price_for_volume(interesting_bids, max_volume)
    end

    def best_offer_price_for_fiat_amount(type, fiat_amount, fiat_currency)
      total_fiat_amount = 0
      good_offers = []

      offers = public_send(type) # asks or bids

      offers.each do |offer|
        break unless total_fiat_amount >= fiat_amount

        offer = offer.dup # NOTE: dup because we're gonna mess with its volume below
        offer.price = offer.price.exchange_to(fiat_currency)
        good_offers << offer
        total_fiat_amount += offer.price * offer.volume
      end

      if total_fiat_amount > fiat_amount
        substract_fiat = total_fiat_amount - fiat_amount
        substract_volume = substract_fiat / good_offers.last.price
        good_offers.last.volume -= substract_volume
      end

      total_weight_price = good_offers.map { |offer| offer.price * offer.volume }.inject(:+) || 0
      total_volume = good_offers.map(&:volume).inject(:+)
      weighted_price = total_weight_price / total_volume

      Offer.new(
        price: good_offers.last.price,
        volume: total_volume,
        weighted_price: weighted_price,
      )
    end

  private

    def interesting_offers(offers, condition)
      offers.select { |offer| condition.call(offer.price) }
    end

    def weighted_offers(offers, condition)
      interesting_offers = interesting_offers(offers, condition)

      total_volume = interesting_offers.map(&:volume).inject(:+) || 0
      total_weight_price = interesting_offers.map { |offer| offer.price * offer.volume }.inject(:+) || 0
      weighted_price = total_weight_price / total_volume

      Offer.new(
        price: Money.new(weighted_price, currency),
        volume: total_volume
      )
    end

    def best_offer_price_for_volume(offers, max_volume)
      total_volume = 0
      good_offers = []

      offers.each do |offer|
        if total_volume <= max_volume
          good_offers << offer.dup # NOTE: dup because we're gonna mess with its volume below
          total_volume += offer.volume
        end
      end

      if total_volume > max_volume
        substract_volume = total_volume - max_volume
        good_offers.last.volume -= substract_volume
        total_volume -= substract_volume
      end

      total_weight_price = good_offers.map { |offer| offer.price * offer.volume }.inject(:+) || 0
      weighted_price = total_weight_price / total_volume

      Offer.new(
        price: good_offers.last.price,
        volume: total_volume,
        weighted_price: weighted_price,
      )
    end

    def currency
      lowest_ask.price.currency
    end
  end
end
