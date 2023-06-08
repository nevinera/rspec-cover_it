RSpec.describe RSpec::CoverIt::Context do
  let(:feg_file_path) { "fake/file/path" }
  let(:feg_metadata) { {} }
  let(:fake_example_group) { class_double(RSpec::Core::ExampleGroup, file_path: feg_file_path, metadata: feg_metadata) }

  let(:rspec_context) { instance_double(RSpec::Core::ExampleGroup) }
  let(:autoenforce?) { false }
  subject(:rci_context) { described_class.new(scope: fake_example_group, rspec_context: rspec_context, autoenforce: autoenforce?) }

  let(:dclass) { instance_double(Class, name: "DClass") }
  let(:dclass_path) { "/fake/path/to/dclass.rb" }
  before { allow(Object).to receive(:const_source_location).and_call_original }
  before { allow(Object).to receive(:const_source_location).with("DClass").and_return([dclass_path, 2]) }

  let(:all_examples?) { true }
  let(:completeness_checker_class) { RSpec::CoverIt::ExampleGroupCompletenessChecker }
  let(:completeness_checker) { instance_double(completeness_checker_class, running_all_examples?: all_examples?) }
  before { allow(completeness_checker_class).to receive(:new).and_return(completeness_checker) }

  describe "#scope_name" do
    subject(:scope_name) { rci_context.scope_name }
    it { is_expected.to eq("fake/file/path") }
  end

  describe "#target_class" do
    subject(:target_class) { rci_context.target_class }

    context "when a class is being described" do
      let(:feg_metadata) { {described_class: dclass} }
      it { is_expected.to eq(dclass) }
    end

    context "when a class is not being described" do
      let(:feg_metadata) { {} }
      it { is_expected.to be_nil }
    end
  end

  describe "#target_path" do
    let(:feg_metadata) { {described_class: dclass, covers_path: covers_path}.compact }
    subject(:target_path) { rci_context.target_path }

    context "when covers_path is supplied" do
      let(:covers_path) { "/covers/path" }
      it { is_expected.to eq(covers_path) }
    end

    context "when covers_path is not supplied" do
      let(:covers_path) { nil }

      context "when there is no target_class" do
        let(:dclass) { nil }
        it { is_expected.to be_nil }
      end

      context "when there is a target_class" do
        before { expect(dclass).not_to be_nil }
        it { is_expected.to eq(dclass_path) }
      end
    end
  end

  describe "#specific_threshold" do
    let(:feg_metadata) { {cover_it: cover_it}.compact }
    subject(:specific_threshold) { rci_context.specific_threshold }

    context "when cover_it is not supplied" do
      let(:cover_it) { nil }
      it { is_expected.to be_nil }
    end

    context "when cover_it is boolean" do
      let(:cover_it) { true }
      it { is_expected.to be_nil }
    end

    context "when cover_it is an integer" do
      let(:cover_it) { 45 }
      it { is_expected.to be_within(0.00001).of(0.45) }
    end

    context "when cover_it is a float" do
      let(:cover_it) { 47.9 }
      it { is_expected.to be_within(0.00001).of(0.479) }
    end
  end

  describe "#cover_it?" do
    subject(:cover_it?) { rci_context.cover_it? }
    let(:cover_it) { nil }
    let(:all_examples?) { true }
    let(:feg_metadata) { {described_class: dclass, cover_it: cover_it}.compact }

    context "when there is no target class" do
      let(:dclass) { nil }
      it { is_expected.to be_falsey }
    end

    context "when the cover_it value is not supplied" do
      let(:cover_it) { nil }

      context "and autoenforce is turned on" do
        let(:autoenforce?) { true }
        it { is_expected.to be_truthy }
      end

      context "and autoenforce is turned off" do
        let(:autoenforce?) { false }
        it { is_expected.to be_falsey }
      end
    end

    context "when the cover_it value is supplied" do
      context "as a numeric value" do
        let(:cover_it) { 55 }
        it { is_expected.to be_truthy }
      end

      context "as true" do
        let(:cover_it) { true }
        it { is_expected.to be_truthy }
      end

      context "as false" do
        let(:cover_it) { false }
        it { is_expected.to be_falsey }
      end
    end

    context "when the example_group is only running some of its examples" do
      let(:all_examples?) { false }
      it { is_expected.to be_falsey }
    end

    context "when there is a target class, all examples are being run, and cover_it is true" do
      let(:cover_it) { true }
      let(:all_examples?) { true }
      it { is_expected.to be_truthy }
    end
  end
end
