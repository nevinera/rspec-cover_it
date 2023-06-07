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

      def target_path
        Object.const_source_location(target_class_name).first
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
    end
  end
end
