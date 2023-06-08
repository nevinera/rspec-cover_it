RSpec.describe RSpec::CoverIt::PretestCoverage do
  let(:filter) { "/path/prefix/" }

  # Coverage can return multiple formats, but the CoverageState class is currently
  # in charge of format shifting the other formats into the 'compatible' (older)
  # format, which looks like `{paths => [line_status, ...]}`
  let(:results) do
    {
      "/path/prefix/foo.rb" => [1, 2, nil, nil, 0, 1, nil, 2, nil],
      "/wrong/prefix/bar.rb" => [1, 1, nil, nil, 1],
      "/path/prefix/baz.rb" => [1, 2, 3]
    }
  end

  subject(:pretest_coverage) { described_class.new(filter: filter, results: results) }

  it "includes the right files" do
    expect(pretest_coverage["/path/prefix/foo.rb"]).not_to be_nil
    expect(pretest_coverage["/path/prefix/baz.rb"]).not_to be_nil
    expect(pretest_coverage["/wrong/prefix/bar.rb"]).to be_nil
  end

  it "has the expected values" do
    expect(pretest_coverage["/path/prefix/foo.rb"]).to eq([1, 2, nil, nil, 0, 1, nil, 2, nil])
    expect(pretest_coverage["/path/prefix/baz.rb"]).to eq([1, 2, 3])
  end

  it "does not use the original instances of those values" do
    expect(pretest_coverage["/path/prefix/foo.rb"].object_id)
      .not_to eq(results["/path/prefix/foo.rb"].object_id)
  end
end
