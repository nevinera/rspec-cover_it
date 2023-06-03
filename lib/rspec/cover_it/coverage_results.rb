module RSpec
  module CoverIt
    class CoverageResults
      attr_reader :filter, :data

      def initialize(filter: nil)
        @filter = filter
        @data = {}
      end

      def add(results)
        results.each_pair do |key, value|
          add_data(key, value) if key.start_with?(filter)
        end
      end

      def add_from(other_results)
        add(other_results.data)
      end

      def amount
        return 0.0 if relevant_line_count <= 0
        100.0 * covered_line_count.to_f / relevant_line_count.to_f
      end

      private

      def add_data(path, line_values)
        return unless path.start_with?(filter)

        if data.key?(path)
          data[path].zip(line_values)
        else
          data[path] = line_values
        end
      end

      def relevant_line_count
        data.values.map { |f| f.compact.count }.sum
      end

      def covered_line_count
        data.values.map { |f| f.compact.reject(&:zero?).count }.sum
      end
    end
  end
end
