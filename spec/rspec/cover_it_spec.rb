require "open3"

RSpec.describe RSpec::CoverIt do
  let(:target) { "" }
  let(:command) { "cd #{project_path} && rspec #{target}" }

  context "when running a project that should pass" do
    let(:project_path) { fixture_path("projects", "fine") }

    it "produces the expected successful outcome" do
      out, _err, stat = Open3.capture3(command)
      expect(stat).to be_success
      expect(out).to match(/\.\.\.\./)
      expect(out).to match(/Randomized with seed/)
      expect(out).to match(/9 examples, 0 failures/)
    end
  end

  context "when running a project that has uncovered code" do
    let(:project_path) { fixture_path("projects", "uncovered") }
    let(:target) { "spec/fine/foo_spec.rb" }

    it "produces the expected failure outcome" do
      out, _err, stat = Open3.capture3(command)
      expect(stat).not_to be_success
      expect(out).to match(/Randomized with seed/)
      expect(out).to match(/1 example, 0 failures, 1 error occurred outside of examples/)
      expect(out).to match(%r{Example group `\./spec/fine/foo_spec.rb` is missing coverage})
      expect(out).to match(%r{coverage on `Fine::Foo` in})
    end
  end

  context "when running a project that has mis-located code" do
    let(:project_path) { fixture_path("projects", "uncovered") }
    let(:target) { "spec/fine/bar_spec.rb" }

    it "produces the expected failure outcome" do
      out, _err, stat = Open3.capture3(command)
      expect(stat).not_to be_success
      expect(out).to match(/Randomized with seed/)
      expect(out).to match(/6 examples, 0 failures, 1 error occurred outside of examples/)
      expect(out).to match(%r{Example group `\./spec/fine/bar_spec.rb` is attempting to})
      expect(out).to match(%r{to cover the code for class `Fine::Bar`, but})
      expect(out).to match(%r{If this is not the correct path})
    end
  end
end
