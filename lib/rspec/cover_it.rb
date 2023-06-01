module RSpec
  module CoverIt
    Error = Class.new(StandardError)
  end
end

glob = File.expand_path("../cover_it/*.rb", __FILE__)
Dir.glob(glob).sort.each { |f| require(f) }
