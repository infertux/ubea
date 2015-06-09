RSpec.shared_examples "an exchange" do
  specify("implements #id") { expect(subject.id).to be_a String }
  specify("implements #short_name") { expect(subject.short_name).to be_a String }
  specify("implements #name") { expect(subject.name).to be_a String }
  specify("implements #trade_fee") { expect(subject.trade_fee).to be_a BigDecimal }
  specify("implements #refresh_order_book!") { expect(subject.refresh_order_book!).to be_an Ubea::OrderBook }

  it "has the right fiat currency" do
    klass = subject.class
    klass_currency = klass.to_s.gsub(/\A.*([A-Z][a-z]{2})\Z/, "\\1").upcase

    expect(subject.fiat_currency).to eq klass_currency
  end
end
