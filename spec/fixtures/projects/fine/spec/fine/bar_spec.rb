RSpec.describe Fine::Bar, covers_path: "../../lib/fine/bar.rb" do
  subject(:bar) { described_class.new }

  describe "#product" do
    subject(:product) { bar.product }

    context "when a and b are both set" do
      before { bar.a = 2 }
      before { bar.b = 3 }
      it { is_expected.to eq(6) }
    end

    context "when a is not set" do
      before { bar.b = 3 }
      it { is_expected.to be_nil }
    end

    context "when b is not set" do
      before { bar.a = 2 }
      it { is_expected.to be_nil }
    end
  end

  describe "#sum" do
    subject(:sum) { bar.sum }

    context "when a and b are both set" do
      before { bar.a = 2 }
      before { bar.b = 3 }
      it { is_expected.to eq(5) }
    end

    context "when a is not set" do
      before { bar.b = 3 }
      it { is_expected.to be_nil }
    end

    context "when b is not set" do
      before { bar.a = 2 }
      it { is_expected.to be_nil }
    end
  end
end
