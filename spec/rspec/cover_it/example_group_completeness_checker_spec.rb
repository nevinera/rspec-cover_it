RSpec.describe RSpec::CoverIt::ExampleGroupCompletenessChecker do
  let(:eg_class) { RSpec::Core::ExampleGroup }

  let(:child_eg_one) { class_double(eg_class, examples: child_one_examples) }
  let(:child_one_examples) { ["c", "d"] }

  let(:child_eg_two) { class_double(eg_class, examples: child_two_examples) }
  let(:child_two_examples) { ["e", "f"] }

  let(:eg_descendants) { [eg, child_eg_one, child_eg_two] }
  let(:eg_examples) { ["a", "b"] }
  let(:dfe) { ["a", "c", "b", "d", "e", "f"] }
  let(:eg) { class_double(eg_class, descendant_filtered_examples: dfe, examples: eg_examples) }
  before { allow(eg).to receive(:descendants).and_return(eg_descendants) }

  subject(:checker) { described_class.new(eg) }

  describe "#running_all_examples?" do
    subject(:running_all_examples?) { checker.running_all_examples? }

    context "when the lists match" do
      let(:dfe) { ["a", "b", "c", "d", "e", "f"] }
      it { is_expected.to be_truthy }

      context "but are ordered differently" do
        let(:dfe) { ["f", "b", "a", "d", "e", "c"] }
        it { is_expected.to be_truthy }
      end

      context "but some examples are present multiple times. somehow." do
        let(:dfe) { ["a", "b", "c", "d", "e", "f"] }
        let(:child_two_examples) { ["e", "f", "a", "c", "d"] }
        it { is_expected.to be_truthy }
      end
    end

    context "when the children are missing an example (which shouldn't happen)" do
      let(:child_one_examples) { ["c"] }
      it { is_expected.to be_falsey }
    end

    context "when an example is filtered out" do
      let(:dfe) { %w[a b c d f] }
      it { is_expected.to be_falsey }
    end

    context "when all examples are filtered out" do
      let(:dfe) { [] }
      it { is_expected.to be_falsey }
    end
  end
end
