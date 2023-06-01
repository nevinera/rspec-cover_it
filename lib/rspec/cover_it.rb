require "coverage"

module RSpec
  module CoverIt
    Error = Class.new(StandardError)
    IncompatibilityError = Class.new(Error)
    MissingCoverage = Class.new(Error)
  end
end

glob = File.expand_path("../cover_it/*.rb", __FILE__)
Dir.glob(glob).sort.each { |f| require(f) }

module RSpec
  module CoverIt
    # Intended to wrap the `require` statements in your spec_helper file that
    # actually load your classes. Note that, in the context of an _autoloader_,
    # this approach isn't accurate, and will need some significant change.
    #
    # Most likely, we'll need to register hooks with the autoloader and start
    # tracking the delta across each piece of loaded code. But not yet!
    def self.load_code(name: nil, filter: nil, &block)
      state = CoverageState.new(name: name, filter: filter)
      state.loading_code(&block)
      state
    end

    def self.setup(config, state)
      config.prepend_before(:context) do |context|
        state.start_tracking_for
      end

      config.append_after(:context) do |context|
        state.finish_tracking_for(self.class, context)
      end
    end
  end
end
