require "coverage"

module RSpec
  module CoverIt
    Error = Class.new(StandardError)
    NotReady = Class.new(Error)
    MissingCode = Class.new(Error)
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

    def self.setup(filter: nil, autoenforce: false)
      RSpec::CoverIt.state = CoverageState.new(filter: filter, autoenforce: autoenforce)
      setup_pretest_tracking
      setup_per_context_tracking
    end

    private_class_method def self.setup_pretest_tracking
      RSpec::CoverIt.state.start_tracking
      RSpec.configure do |config|
        config.prepend_before(:suite) { RSpec::CoverIt.state.finish_load_tracking }
      end
    end

    private_class_method def self.setup_per_context_tracking
      RSpec.configure do |config|
        config.prepend_before(:context) { |context| RSpec::CoverIt.state.start_tracking_for(self.class, context) }
        config.append_after(:context) { |context| RSpec::CoverIt.state.finish_tracking_for(self.class, context) }
      end
    end
  end
end
