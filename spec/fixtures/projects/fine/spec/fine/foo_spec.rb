RSpec.describe Fine::Foo do
  let(:supplied_a) { 15 }
  subject(:foo) { described_class.new(a: supplied_a) }

  describe "#a?" do
    subject(:a?) { foo.a? }
    it { is_expected.to eq(supplied_a) }
  end

  describe "#a_times" do
    let(:n) { 3 }
    subject(:a_times) { foo.a_times(n) }

    context "when a is a number" do
      let(:supplied_a) { 4 }
      it { is_expected.to eq(12) }
    end

    context "when a is a string" do
      let(:supplied_a) { "q" }
      it { is_expected.to eq("qqq") }
    end
  end
end
