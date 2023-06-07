module RSpec
  module CoverIt
    class CoverageState
      attr_reader :filter

      def initialize(filter: nil, autoenforce: false)
        @filter, @autoenforce = filter, autoenforce
        @pretest_results = nil
        @context_coverages = {}
      end

      # If SimpleCov or something like it is already running, Coverage may be
      # started already. For our purposes, that should be fine.
      def start_tracking
        Coverage.start unless Coverage.running?
      end

      def finish_load_tracking
        @pretest_results = PretestCoverage.new(filter: filter, results: Coverage.peek_result)
      end

      def start_tracking_for(scope, rspec_context)
        context = context_for(scope, rspec_context)
        return unless context.cover_it?

        context_coverage_for(context).tap do |context_coverage|
          context_coverage.precontext_coverage = Coverage.peek_result[context.target_path]
        end
      end

      def finish_tracking_for(scope, rspec_context)
        context = context_for(scope, rspec_context)
        return unless context.cover_it?

        context_coverage_for(context).tap do |context_coverage|
          context_coverage.postcontext_coverage = Coverage.peek_result[context.target_path]
          context_coverage.enforce!
        end
      end

      private

      attr_reader :pretest_results

      def autoenforce?
        @autoenforce
      end

      def context_for(scope, rspec_context)
        Context.new(scope: scope, rspec_context: rspec_context, autoenforce: autoenforce?)
      end

      def context_coverage_for(context)
        @context_coverages[context.target_class] ||= ContextCoverage.new(
          context: context,
          pretest_results: pretest_results
        )
      end
    end
  end
end
