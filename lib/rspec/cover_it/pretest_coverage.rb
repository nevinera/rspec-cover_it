module RSpec
  module CoverIt
    class PretestCoverage
      def initialize(filter:, results:)
        @filter = filter
        @results = results
          .select { |k, _v| filter.nil? || k.start_with?(filter) }
          .map { |k, v| [k, v.dup] }
          .to_h
      end

      def [](path)
        @results[path]
      end
    end
  end
end
