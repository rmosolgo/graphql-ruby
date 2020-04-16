# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A wrapper for argument hashes in GraphQL queries.
      #
      # @see GraphQL::Query#arguments_for to get access to these objects.
      class Arguments
        # @return [Hash<Symbol, Object>] The Ruby-style arguments hash, ready for a resolver
        attr_reader :values

        def initialize(values:, ast_node:, owner:, query:)
          @values = values
          @ast_node = ast_node
          @owner = owner
          @query = query
        end

        # Yields `ArgumentValue` instances which contain detailed metadata about each argument.
        def each_value
          argument_values.each { |arg_v| yield(arg_v) }
        end

        def argument_values
          @argument_values ||= begin
            detailed_values = {}
            args_by_keyword = @owner.arguments
              .each_value
              .each_with_object({}) { |defn, obj| obj[defn.keyword] = defn }

            @values.each do |keyword, arg_value|
              arg_defn = args_by_keyword[keyword]
              # It's actually possible to _miss_ here, becuase `extras` are included in `@values`
              if arg_defn
                detailed_values[keyword] = ArgumentValue.new(
                  value: arg_value,
                  definition: arg_defn,
                  default_used: calculate_default_used(keyword, arg_defn.name)
                )
              end
            end

            detailed_values
          end
        end

        private

        def calculate_default_used(arg_keyword, arg_name)
          if !@values.key?(arg_keyword)
            false
          else
            ast_arg = @ast_node.arguments.find { |a| a.name == arg_name }

            if ast_arg.nil?
              true
            elsif ast_arg.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
              var_name = ast_arg.value.name
              if @query.variables.key?(var_name)
                # A value was given, or the variable definition provided a default
                false
              else
                # An optional variable was used, and no value was given
                true
              end
            else
              # An argument value was present in the AST
              false
            end
          end
        end

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
