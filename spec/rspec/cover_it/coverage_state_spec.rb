RSpec.describe RSpec::CoverIt::CoverageState do
  let(:filter) { nil }
  let(:autoenforce) { false }
  let(:default_threshold) { 97.8 }
  let(:options) { {filter: filter, autoenforce: autoenforce, default_threshold: default_threshold}.compact }
  subject(:coverage_state) { described_class.new(**options) }

  let(:fake_pretest_coverage) { instance_double(RSpec::CoverIt::PretestCoverage) }

  before { allow(Coverage).to receive(:start) }
  before { allow(Coverage).to receive(:peek_result).and_return(fake_coverage_result) }
  before { allow(Coverage).to receive(:running?).and_return(coverage_running?) }
  let(:coverage_running?) { true }
  let(:fake_coverage_result) { {} }

  describe "#start_tracking" do
    subject(:start_tracking) { coverage_state.start_tracking }

    context "when coverage is already running" do
      let(:coverage_running?) { true }

      it "doesn't start coverage again" do
        start_tracking
        expect(Coverage).not_to have_received(:start)
      end
    end

    context "when coverage is not already running" do
      let(:coverage_running?) { false }

      it "starts coverage" do
        start_tracking
        expect(Coverage).to have_received(:start).with(no_args)
      end
    end
  end

  describe "#finish_load_tracking" do
    let(:filter) { "filter" }
    before { allow(RSpec::CoverIt::PretestCoverage).to receive(:new).and_return(fake_pretest_coverage) }

    subject(:finish_load_tracking) { coverage_state.finish_load_tracking }

    context "when Coverage was started with legacy arguments (as we do)" do
      let(:fake_coverage_result) do
        {
          "foo.rb" => [1, 2, nil, 0],
          "bar.rb" => [nil, nil, 0, 5, nil]
        }
      end

      it "fills in pretest results correctly" do
        finish_load_tracking
        expect(RSpec::CoverIt::PretestCoverage)
          .to have_received(:new)
          .with(filter: "filter", results: fake_coverage_result)
      end
    end

    context "when Coverage was started with modern arguments (as simplecov does)" do
      let(:fake_coverage_result) do
        {
          "foo.rb" => {lines: [1, 2, nil, 0]},
          "bar.rb" => {lines: [nil, nil, 0, 5, nil]}
        }
      end

      let(:flat_coverage_result) do
        {
          "foo.rb" => [1, 2, nil, 0],
          "bar.rb" => [nil, nil, 0, 5, nil]
        }
      end

      it "fills in pretest results correctly" do
        finish_load_tracking
        expect(RSpec::CoverIt::PretestCoverage)
          .to have_received(:new)
          .with(filter: "filter", results: flat_coverage_result)
      end
    end
  end

  describe "#start_tracking_for" do
    let(:autoenforce) { false }
    let(:scope) { class_double(RSpec::Core::ExampleGroup) }
    let(:rspec_context) { instance_double(RSpec::Core::ExampleGroup) }
    subject(:start_tracking_for) { coverage_state.start_tracking_for(scope, rspec_context) }

    let!(:fake_context) { stubbed_context_instantiation(cover_it?: cover_it?, target_class: target_class, target_path: target_path) }
    let(:cover_it?) { false }
    let(:target_class) { Integer }
    let(:target_path) { "foo.rb" }

    let(:fake_context_coverage) { instance_double(RSpec::CoverIt::ContextCoverage, "precontext_coverage=": nil) }
    before { allow(RSpec::CoverIt::ContextCoverage).to receive(:new).and_return(fake_context_coverage) }

    before { coverage_state.pretest_results = fake_pretest_coverage }

    it "constructs the context correctly" do
      start_tracking_for
      expect(RSpec::CoverIt::Context)
        .to have_received(:new)
        .with(scope: scope, rspec_context: rspec_context, autoenforce: false)
    end

    context "when the context does not warrant coverage-checking" do
      let(:cover_it?) { false }

      it "does not read the current coverage data" do
        start_tracking_for
        expect(Coverage).not_to have_received(:peek_result)
      end

      it "does not construct the context-coverage object" do
        start_tracking_for
        expect(RSpec::CoverIt::ContextCoverage).not_to have_received(:new)
      end
    end

    context "when the context does warrant coverage-checking" do
      let(:cover_it?) { true }

      it "instantiates the context-coverage object correctly" do
        start_tracking_for
        expect(RSpec::CoverIt::ContextCoverage)
          .to have_received(:new)
          .with(context: fake_context, pretest_results: fake_pretest_coverage)
      end

      context "when the coverage data is legacy-style" do
        let(:target_path) { "foo.rb" }
        let(:fake_coverage_result) { {"foo.rb" => [1, 2, nil, 0], "bar.rb" => [nil, nil, 0, 5, nil]} }

        it "sets the precontext coverage on that object correctly" do
          start_tracking_for
          expect(fake_context_coverage)
            .to have_received(:"precontext_coverage=")
            .with([1, 2, nil, 0])
        end
      end

      context "when the coverage data is modern-style" do
        let(:fake_coverage_result) { {"foo.rb" => {lines: [1, 2, nil, 0]}, "bar.rb" => {lines: [nil, nil, 0, 5, nil]}} }

        it "sets the precontext coverage on that object correctly" do
          start_tracking_for
          expect(fake_context_coverage)
            .to have_received(:"precontext_coverage=")
            .with([1, 2, nil, 0])
        end
      end
    end
  end

  describe "#finish_tracking_for" do
    let(:scope) { class_double(RSpec::Core::ExampleGroup) }
    let(:rspec_context) { instance_double(RSpec::Core::ExampleGroup) }
    subject(:finish_tracking_for) { coverage_state.finish_tracking_for(scope, rspec_context) }

    let!(:fake_context) { stubbed_context_instantiation(cover_it?: cover_it?, target_class: target_class, target_path: target_path) }
    let(:cover_it?) { false }
    let(:target_class) { Integer }
    let(:target_path) { "foo.rb" }

    let(:fake_context_coverage) { instance_double(RSpec::CoverIt::ContextCoverage, "postcontext_coverage=": nil, enforce!: nil) }
    before { coverage_state.context_coverages[target_class] = fake_context_coverage }

    it "constructs the context correctly" do
      finish_tracking_for
      expect(RSpec::CoverIt::Context)
        .to have_received(:new)
        .with(scope: scope, rspec_context: rspec_context, autoenforce: false)
    end

    context "when the context does not warrant coverage-checking" do
      let(:cover_it?) { false }

      it "does not read the current coverage data" do
        finish_tracking_for
        expect(Coverage).not_to have_received(:peek_result)
      end

      it "does not look for the context-coverage object" do
        finish_tracking_for
        expect(fake_context_coverage).not_to have_received(:"postcontext_coverage=")
      end
    end

    context "when the context does warrant coverage-checking" do
      let(:cover_it?) { true }

      context "when the coverage data is legacy-style" do
        let(:target_path) { "foo.rb" }
        let(:fake_coverage_result) { {"foo.rb" => [1, 2, nil, 0], "bar.rb" => [nil, nil, 0, 5, nil]} }

        it "sets the postcontext coverage on that object correctly" do
          finish_tracking_for
          expect(fake_context_coverage)
            .to have_received(:"postcontext_coverage=")
            .with([1, 2, nil, 0])
        end
      end

      context "when the coverage data is modern-style" do
        let(:fake_coverage_result) { {"foo.rb" => {lines: [1, 2, nil, 0]}, "bar.rb" => {lines: [nil, nil, 0, 5, nil]}} }

        it "sets the postcontext coverage on that object correctly" do
          finish_tracking_for
          expect(fake_context_coverage)
            .to have_received(:"postcontext_coverage=")
            .with([1, 2, nil, 0])
        end
      end

      it "enforces constraints on the context-coverage object using the correct default_threshold" do
        finish_tracking_for
        expect(fake_context_coverage).to have_received(:enforce!) do |args|
          expect(args.fetch(:default_threshold)).to be_within(0.00001).of(0.978)
        end
      end
    end
  end
end
