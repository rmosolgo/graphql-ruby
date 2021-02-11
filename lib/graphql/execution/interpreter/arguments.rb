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
        def keyword_arguments
          @keyword_arguments ||= begin
            kwargs = {}
            argument_values.each do |name, arg_val|
              kwargs[name] = arg_val.value
            end
            kwargs
          end
        end

        # @param argument_values [nil, Hash{Symbol => ArgumentValue}]
        def initialize(argument_values:)
          @argument_values = argument_values
          @empty = argument_values.nil? || argument_values.empty?
        end

        # @return [Hash{Symbol => ArgumentValue}]
        def argument_values
          @argument_values ||= {}
        end

        def empty?
          @empty
        end

        def_delegators :keyword_arguments, :key?, :[], :fetch, :keys, :each, :values
        def_delegators :argument_values, :each_value

        def inspect
          "#<#{self.class} @keyword_arguments=#{keyword_arguments.inspect}>"
        end
      end
    end
  end
end
