require "ubea/money"

module Ubea
  RSpec.describe Money do
    subject { Money.new("1000.10", "USD") }
    let(:usd) { subject } # just an alias

    describe "#to_s" do
      it "returns the correct amount by default" do
        expect(subject.to_s).to eq "1 000.1 USD"
      end

      it "returns the correct amount without currency" do
        expect(subject.to_s(with_currency: false)).to eq "1 000.1"
      end
    end

    context "using different currencies" do
      it "doesn't allow implicit calculations with different currencies" do
        eur = Money.new(1, "EUR")
        expect { usd + eur }.to raise_error(Money::CurrencyMismatch)
      end
    end
  end
end
