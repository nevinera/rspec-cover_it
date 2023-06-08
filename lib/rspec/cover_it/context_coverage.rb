module RSpec
  module CoverIt
    class ContextCoverage
      def initialize(context:, pretest_results:)
        @context, @pretest_results = context, pretest_results
        @precontext_coverage = @postcontext_coverage = nil
      end

      attr_accessor :precontext_coverage, :postcontext_coverage

      def local_coverage
        assert_ready!
        return nil unless precontext_coverage && postcontext_coverage && coverable_lines?
        @_local_coverage ||= pretest_coverage
          .zip(precontext_coverage, postcontext_coverage)
          .map { |a, b, c| line_calculation(a, b, c) }
      end

      def local_coverage_rate
        assert_ready!
        return nil unless covered_line_count
        covered_line_count.to_f / coverable_line_count.to_f
      end

      def enforce!(default_threshold:)
        assert_ready!
        if precovered?
          fail_with_missing_code!
        elsif local_coverage_rate < (context.specific_threshold || default_threshold)
          fail_with_missing_coverage!
        end
      end

      private

      def pretest_coverage
        @_pretest_coverage ||= pretest_results[target_path]
      end

      def coverable_lines?
        pretest_coverage.compact.any?
      end

      def assert_ready!
        return if precontext_coverage && postcontext_coverage
        fail(NotReady, "ContextCoverage was not ready yet, something has gone wrong")
      end

      def fail_with_missing_code!
        fail(MissingCode, <<~MESSAGE.tr("\n", " "))
          Example group `#{context.scope_name}` is attempting to cover the code for class
          `#{context.target_class}`, but it was located at `#{context.target_path}`,
          and does not appear to have any code to cover (or it was all executed before the
          tests started). If this is not the correct path for the code under test, please
          specify the correct path using the `covers:` spec metadata - sometimes the
          rspec-cover_it gem isn't properly able to infer the correct source path for a
          class.
        MESSAGE
      end

      def uncovered_lines
        @_uncovered_lines ||= local_coverage.each_with_index.select { |v, _i| v&.zero? }.map(&:last)
      end

      def single_uncovered_line_summary
        "on line #{uncovered_lines.first}"
      end

      def few_uncovered_lines_summary
        "on lines #{uncovered_lines.map(&:to_s).join(", ")}"
      end

      def many_uncovered_lines_summary
        shortened_list = uncovered_lines.first(10).map(&:to_s).join(", ")
        "on #{uncovered_lines.length} lines, including #{shortened_list}"
      end

      def uncovered_lines_summary
        if uncovered_lines.length == 1
          single_uncovered_line_summary
        elsif uncovered_lines.length <= 10
          few_uncovered_lines_summary
        else
          many_uncovered_lines_summary
        end
      end

      def fail_with_missing_coverage!
        fail(MissingCoverage, <<~MESSAGE.tr("\n", " ").strip)
          Example group `#{context.scope_name}` is missing coverage on
          `#{context.target_class}` in `#{context.target_path}` #{uncovered_lines_summary}
        MESSAGE
      end

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

      def precovered?
        return @_precovered if defined?(@_precovered)
        @_precovered = pretest_coverage.nil? || pretest_coverage.none? { |n| n&.zero? }
      end
    end
  end
end
