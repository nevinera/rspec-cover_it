module RSpec
  module CoverIt
    class ExampleGroupCompletenessChecker
      # This class uses some bits of the RSpec::Core::ExampleGroup api that are
      # not documented, and are marked `@private` using YARD notation. But I
      # found no other reasonable way to answer this question, so I've isolated
      # my intrusion into this class - hopefully, there will be a more
      # appropriate way to determine this information in the future; I've begun
      # that conversation here: https://github.com/rspec/rspec-core/issues/3037

      def initialize(example_group)
        @example_group = example_group
      end

      def running_all_examples?
        all_examples == filtered_examples
      end

      private

      attr_reader :example_group

      def all_examples
        @_all_examples ||= example_group.descendants.flat_map(&:examples).to_set
      end

      def filtered_examples
        @_filtered_examples ||= example_group.descendant_filtered_examples.to_set
      end
    end
  end
end
