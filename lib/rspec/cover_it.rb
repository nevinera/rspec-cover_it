require "coverage"

module RSpec
  module CoverIt
    Error = Class.new(StandardError)
    MissingCoverage = Class.new(Error)
  end
end

glob = File.expand_path("../cover_it/*.rb", __FILE__)
Dir.glob(glob).sort.each { |f| require(f) }

module RSpec
  module CoverIt
    class << self
      attr_accessor :state
    end

    def self.setup(name: nil, filter: nil, global_minimum: 100.0)
      RSpec::CoverIt.state = CoverageState.new(name: name, filter: filter, minimum: global_minimum)
      RSpec::CoverIt.state.start_tracking

      RSpec.configure do |config|
        config.prepend_before(:suite) { RSpec::CoverIt.state.finish_load_tracking }
        config.prepend_before(:context) { |context| RSpec::CoverIt.state.start_tracking_for(self.class, context) }
        config.append_after(:context) { |context| RSpec::CoverIt.state.finish_tracking_for(self.class, context) }
      end
    end
  end
end
