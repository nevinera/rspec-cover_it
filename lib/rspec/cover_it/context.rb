module RSpec
  module CoverIt
    class Context
      def initialize(scope:, rspec_context:)
        @scope, @rspec_context = scope, rspec_context
      end

      def cover_it?
        target_class && metadata.fetch(:cover_it, nil)
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

      private

      attr_reader :scope, :rspec_context

      def metadata
        scope.metadata
      end
    end
  end
end
