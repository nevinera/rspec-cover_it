RSpec.describe Fine::Foo do
  let(:supplied_a) { 15 }
  subject(:foo) { described_class.new(a: supplied_a) }

  describe "#a" do
    subject(:a) { foo.a }
    it { is_expected.to eq(supplied_a) }
  end
end
