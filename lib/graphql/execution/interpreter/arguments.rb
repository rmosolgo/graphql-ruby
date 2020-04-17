# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A wrapper for argument hashes in GraphQL queries.
      #
      # @see GraphQL::Query#arguments_for to get access to these objects.
      class Arguments
        extend Forwardable

        # The Ruby-style arguments hash, ready for a resolver.
        # This hash is the one used at runtime.
        #
        # @return [Hash<Symbol, Object>]
        attr_reader :keyword_arguments

        def initialize(keyword_arguments:, argument_values:)
          @keyword_arguments = keyword_arguments
          @argument_values = argument_values
        end

        # Yields `ArgumentValue` instances which contain detailed metadata about each argument.
        def each_value
          argument_values.each { |arg_v| yield(arg_v) }
        end

        # @return [Hash{Symbol => ArgumentValue}]
        attr_reader :argument_values

        def_delegators :@keyword_arguments, :key?, :[]

        # A container for metadata regarding arguments present in a GraphQL query.
        # @see Arguments#argument_values for a hash of these objects.
        class ArgumentValue
          def initialize(definition:, value:, default_used:)
            @definition = definition
            @value = value
            @default_used = default_used
          end

          # @return [Object] The Ruby-ready value for this Argument
          attr_reader :value

          # @return [GraphQL::Schema::Argument] The definition instance for this argument
          attr_reader :definition

          # @return [Boolean] `true` if the schema-defined `default_value:` was applied in this case. (No client-provided value was present.)
          def default_used?
            @default_used
          end
        end
      end
    end
  end
end
