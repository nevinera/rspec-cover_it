module RSpec
  module CoverIt
    class CoverageState
      attr_reader :name, :filter, :minimum

      def initialize(name: nil, filter: nil, minimum: 1.0)
        @name = name
        @filter = filter
        @minimum = minimum
        @pretest_results = nil
        @context_coverages = {}
      end

      def start_tracking
        fail(IncompatibilityError, "Coverage is already running for some reason") if Coverage.running?
        Coverage.start
      end

      def finish_load_tracking
        @pretest_results = PretestResults.new(
          filter: filter,
          results: Coverage.peek_result
        )
      end

      def start_tracking_for(scope, rspec_context)
        context = Context.new(scope: scope, rspec_context: rspec_context)
        context_coverage_for(context).tap do |context_coverage|
          context_coverage.set_precontext_coverage(Coverage.peek_result)
        end
      end

      def finish_tracking_for(scope, rspec_context)
        context = Context.new(scope: scope, rspec_context: rspec_context)
        context_coverage_for(context).tap do |context_coverage|
          context_coverage.set_postcontext_coverage(Coverage.peek_result)
          context_coverage.enforce_constraints!
        end
      end

      private

      attr_reader :pretest_results

      def context_coverage_for(context)
        @context_coverages[context.target_class] ||= ContextCoverage.new(
          context: context,
          pretest_results: pretest_results
        )
      end
    end
  end
end
