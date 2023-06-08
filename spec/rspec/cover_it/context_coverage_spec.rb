RSpec.describe RSpec::CoverIt::ContextCoverage do
  let(:specific_threshold) { nil }
  let(:context) { mock_context target_path: "foo.rb", specific_threshold: specific_threshold }
  let(:pretest_results) { {"foo.rb" => pretest_coverage, "bar.rb" => [0, 1, nil, nil]} }
  subject(:context_coverage) { described_class.new(context: context, pretest_results: pretest_results) }

  let(:pretest_coverage) { [1, 0, nil, 0] }
  let(:precontext_coverage) { [1, 1, nil, 3] }
  let(:postcontext_coverage) { [1, 2, nil, 5] }

  before do
    context_coverage.precontext_coverage = precontext_coverage if precontext_coverage
    context_coverage.postcontext_coverage = postcontext_coverage if postcontext_coverage
  end

  def self.it_has_local_coverage(coverage_array)
    it "has the expected local coverage" do
      if coverage_array.nil?
        expect(context_coverage.local_coverage).to be_nil
      else
        expect(context_coverage.local_coverage).to eq(coverage_array)
      end
    end
  end

  def self.it_has_local_coverage_rate(rate)
    it "has the expected local coverage rate" do
      if rate.nil?
        expect(rate).to be_nil
      else
        expect(context_coverage.local_coverage_rate).to be_within(0.00001).of(rate)
      end
    end
  end

  shared_examples "is not ready for access yet" do
    it "raises a NotReady error when local_coverage is called" do
      expect { context_coverage.local_coverage }
        .to raise_error(RSpec::CoverIt::NotReady)
    end

    it "raises a NotReady error when local_coverage_rate is called" do
      expect { context_coverage.local_coverage_rate }
        .to raise_error(RSpec::CoverIt::NotReady)
    end

    it "raises a NotReady error when enforce! is called" do
      expect { context_coverage.enforce!(default_threshold: 1.0) }
        .to raise_error(RSpec::CoverIt::NotReady)
    end
  end

  shared_examples "enforce! raises a MissingCode error" do
    it "raises a MissingCode error when calling enforce!" do
      expect { context_coverage.enforce!(default_threshold: 1.0) }
        .to raise_error(RSpec::CoverIt::MissingCode, /any code to cover/)
    end
  end

  shared_examples "enforce! raises a MissingCoverage error" do |default_threshold|
    it "raises a MissingCoverage error when calling enforce!" do
      expect { context_coverage.enforce!(default_threshold: default_threshold) }
        .to raise_error(RSpec::CoverIt::MissingCoverage, /is missing coverage/)
    end
  end

  shared_examples "enforce! raises no error" do |default_threshold|
    it "raises no errors when calling enforce!" do
      expect { context_coverage.enforce!(default_threshold: default_threshold) }.not_to raise_error
    end
  end

  context "when precontext_coverage has not been set" do
    let(:precontext_coverage) { nil }
    include_examples "is not ready for access yet"
  end

  context "when postcontext_coverage has not been set" do
    let(:postcontext_coverage) { nil }
    include_examples "is not ready for access yet"
  end

  context "when the target file has no coverable lines" do
    let(:pretest_coverage) { [nil] }
    let(:precontext_coverage) { [nil] }
    let(:postcontext_coverage) { [nil] }
    it_has_local_coverage(nil)
    it_has_local_coverage_rate(nil)
    include_examples "enforce! raises a MissingCode error"
  end

  context "when the tests covered some lines but not all of them" do
    let(:pretest_coverage) { [1, 0, nil, 0] }
    let(:precontext_coverage) { [1, 0, nil, 0] }
    let(:postcontext_coverage) { [5, 2, nil, 0] }
    it_has_local_coverage([5, 2, nil, 0])
    it_has_local_coverage_rate(0.6666666667)
    include_examples "enforce! raises a MissingCoverage error", 0.7
    include_examples "enforce! raises no error", 0.6
  end

  context "when other tests covered all of the lines, but these tests didn't" do
    let(:pretest_coverage) { [1, 0, nil, 0] }
    let(:precontext_coverage) { [1, 2, nil, 4] }
    let(:postcontext_coverage) { [5, 2, nil, 4] }
    it_has_local_coverage([5, 0, nil, 0])
    it_has_local_coverage_rate(0.33333333333)
    include_examples "enforce! raises a MissingCoverage error", 0.4
    include_examples "enforce! raises no error", 0.3
  end

  context "when the pretest results covered all of the lines" do
    let(:pretest_coverage) { [1, 2, nil, 3] }
    let(:precontext_coverage) { [1, 2, nil, 3] }
    let(:postcontext_coverage) { [1, 2, nil, 3] }
    it_has_local_coverage([1, 2, nil, 3])
    it_has_local_coverage_rate(1.0)
    include_examples "enforce! raises a MissingCode error"
  end

  describe "missing coverage error formatting" do
    let(:context) do
      mock_context(
        target_path: "foo.rb",
        specific_threshold: 0.8,
        scope_name: "foo_spec.rb",
        target_class: StandardError
      )
    end

    context "when there is only one uncovered line" do
      let(:pretest_coverage) { [nil, 0] }
      let(:precontext_coverage) { [nil, 3] }
      let(:postcontext_coverage) { [nil, 3] }

      it "raises a MissingCoverage error with the right message" do
        expect { context_coverage.enforce!(default_threshold: 1.0) }.to raise_error do |e|
          expect(e).to be_a(RSpec::CoverIt::MissingCoverage)
          expect(e.message).to eq(
            "Example group `foo_spec.rb` is missing coverage on " \
            "`StandardError` in `foo.rb` on line 1"
          )
        end
      end
    end

    context "when there are several uncovered lines" do
      let(:pretest_coverage) { [nil, 0] * 8 }
      let(:precontext_coverage) { [nil, 3] * 8 }
      let(:postcontext_coverage) { [nil, 3] * 8 }

      it "raises a MissingCoverage error with the right message" do
        expect { context_coverage.enforce!(default_threshold: 1.0) }.to raise_error do |e|
          expect(e).to be_a(RSpec::CoverIt::MissingCoverage)
          expect(e.message).to eq(
            "Example group `foo_spec.rb` is missing coverage on " \
            "`StandardError` in `foo.rb` on lines 1, 3, 5, 7, 9, 11, 13, 15"
          )
        end
      end
    end

    context "when there are many uncovered lines" do
      let(:pretest_coverage) { [nil, 0] * 12 }
      let(:precontext_coverage) { [nil, 3] * 12 }
      let(:postcontext_coverage) { [nil, 3] * 12 }

      it "raises a MissingCoverage error with the right message" do
        expect { context_coverage.enforce!(default_threshold: 1.0) }.to raise_error do |e|
          expect(e).to be_a(RSpec::CoverIt::MissingCoverage)
          expect(e.message).to eq([
            "Example group `foo_spec.rb` is missing coverage on ",
            "`StandardError` in `foo.rb` on 12 lines, ",
            "including 1, 3, 5, 7, 9, 11, 13, 15, 17, 19"
          ].join)
        end
      end
    end
  end
end
