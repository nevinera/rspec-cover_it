module RSpec
  module CoverIt
    class Context
      def initialize(scope:, rspec_context:, autoenforce:)
        @scope, @rspec_context, @autoenforce = scope, rspec_context, autoenforce
      end

      def cover_it?
        target_class &&
          metadata.fetch(:cover_it, autoenforce?) &&
          completeness_checker.running_all_examples?
      end

      def specific_threshold
        meta_value = metadata.fetch(:cover_it, nil)
        meta_value.is_a?(Numeric) ? meta_value / 100.0 : nil
      end

      def target_path
        metadata.key?(:covers_path) ? metadata_path : inferred_path
      end

      def target_class
        metadata.fetch(:described_class, nil)
      end

      def target_class_name
        target_class.name
      end

      def scope_name
        scope.file_path
      end

      private

      attr_reader :scope, :rspec_context

      def autoenforce?
        @autoenforce
      end

      def metadata
        scope.metadata
      end

      def completeness_checker
        @_completeness_checker ||= ExampleGroupCompletenessChecker.new(scope)
      end

      def metadata_path
        supplied_path = metadata.fetch(:covers_path)
        spec_directory = File.dirname(scope.file_path)
        File.expand_path(supplied_path, spec_directory)
      end

      def inferred_path
        Object.const_source_location(target_class_name).first
      end
    end
  end
end
