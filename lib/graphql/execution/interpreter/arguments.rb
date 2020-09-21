# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A wrapper for argument hashes in GraphQL queries.
      #
      # @see GraphQL::Query#arguments_for to get access to these objects.
      class Arguments
        extend Forwardable
        include GraphQL::Dig

        # The Ruby-style arguments hash, ready for a resolver.
        # This hash is the one used at runtime.
        #
        # @return [Hash<Symbol, Object>]
        attr_reader :keyword_arguments

        def initialize(keyword_arguments:, argument_values:)
          @keyword_arguments = keyword_arguments
          @argument_values = argument_values
        end

        # @return [Hash{Symbol => ArgumentValue}]
        attr_reader :argument_values

        def_delegators :@keyword_arguments, :key?, :[], :fetch, :keys, :each, :values
        def_delegators :@argument_values, :each_value

        def inspect
          "#<#{self.class} @keyword_arguments=#{keyword_arguments.inspect}>"
        end
      end
    end
  end
end
