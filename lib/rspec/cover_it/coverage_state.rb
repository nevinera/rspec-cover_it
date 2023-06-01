module RSpec
  module CoverIt
    class CoverageState
      attr_reader :name, :filter, :minimum

      def initialize(name: nil, filter: nil, minimum: 1.0)
        @name = name
        @filter = filter
        @minimum = minimum
        @pretest_results = CoverageResults.new(filter: filter)
      end

      # This is intended to be multiply runnable, so that I could load code in
      # separate blocks, and the resulting coverage would be merged together.
      def loading_code(&block)
        should_not_be_already_running!
        Coverage.start
        block.call
        results = Coverage.result
        @pretest_results.add(results)
      end

      def start_tracking_for
        should_not_be_already_running!
        Coverage.start
      end

      def finish_tracking_for(scope, rspec_context)
        context = Context.new(scope: scope, rspec_context: rspec_context)
        results = Coverage.result
        target_results = coverage_for(pretest: pretest_results, results: results, target: context.target_path)
        enforce_coverage!(context: context, coverage: target_results)
      end

      private

      attr_reader :pretest_results

      def should_not_be_already_running!
        fail(IncompatibilityError, "Coverage is already running for some reason") if Coverage.running?
      end

      def coverage_for(pretest:, results:, target:)
        limited_results = CoverageResults.new(filter: target)
        limited_results.add_from(pretest_results)
        limited_results.add(results)
        limited_results
      end

      def enforce_coverage!(context:, coverage:)
        if coverage.amount < minimum
          fail(MissingCoverage, "Class #{context.target_class_name} is only covered at #{coverage.amount.round(2)}%")
        end
      end
    end
  end
end
