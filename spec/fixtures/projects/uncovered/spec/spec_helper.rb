require "rspec"
require_relative "../../../../../lib/rspec/cover_it"

filter_path = File.expand_path("../..", __FILE__)
RSpec::CoverIt.setup(filter: filter_path, autoenforce: true)

require File.expand_path("../../lib/fine", __FILE__)

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = "random"
end
