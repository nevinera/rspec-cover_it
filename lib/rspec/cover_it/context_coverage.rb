module RSpec
  module CoverIt
    class ContextCoverage
      def initialize(context:, pretest_results:)
        @context, @pretest_results = context, pretest_results
        @precontext_coverage = @postcontext_coverage = nil
      end

      attr_accessor :precontext_coverage, :postcontext_coverage

      def pretest_coverage
        @_pretest_coverage ||= pretest_results[target_path]
      end

      def local_coverage
        return nil unless precontext_coverage && postcontext_coverage
        @_local_coverage ||= pretest_coverage
          .zip(precontext_coverage, postcontext_coverage)
          .map { |a, b, c| line_calculation(a, b, c) }
      end

      def local_coverage_rate
        return nil unless covered_line_count
        covered_line_count.to_f / coverable_line_count.to_f
      end

      def enforce!
        return if local_coverage.nil? || local_coverage_rate >= 1.0
        lines = local_coverage.each_with_index.select { |v, _i| v&.zero? }.map(&:last)

        summary =
          if lines.length == 1
            "on line #{lines.first}"
          elsif lines.length <= 10
            "on lines #{lines.map(&:to_s).join(", ")}"
          else
            "on #{lines.length} lines, including #{lines.first(10).map(&:to_s).join(", ")}"
          end
        message = "Missing coverage in #{context.target_path} #{summary}"
        fail(MissingCoverage, message)
      end

      private

      attr_reader :context, :pretest_results

      def target_path
        @_target_path ||= context.target_path
      end

      # Really, we shouldn't see nil for any of these values unless they are all
      # nil. We want the coverage we'd expect to have seen if we ran _just_ this
      # groups of examples, which ought boe the pretest coverage, plus the
      # number of times each line was run _during_ the context.
      def line_calculation(pretest, precontext, postcontext)
        return nil if pretest.nil? || precontext.nil? || postcontext.nil?
        pretest + (postcontext - precontext)
      end

      def coverable_line_count
        pretest_coverage.compact.count
      end

      def covered_line_count
        return nil unless local_coverage
        local_coverage.count { |executions| executions && executions > 0 }
      end
    end
  end
end
