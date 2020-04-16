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

                arg_name = arg_defn.name
                # There's no AST node when we dig into arguments from variable values
                ast_arg = @ast_node ? @ast_node.arguments.find { |a| a.name == arg_name } : nil

                if ast_arg.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
                  var_defn = @query.selected_operation.variables.find { |v| v.name == ast_arg.name }
                  # This might be `nil` -- that's ok, we use it to detect whether a default was used.
                  ast_arg = var_defn.default_value
                  # A default value was provided in the variable definition
                  # AND the query wasn't called with a value.
                  # So if this argument is present, it _must_ have come from the default value.
                  default_used = !!(ast_arg.nil? && !@query.variables.provided_variables.key?(ast_arg.name))
                elsif ast_arg.nil?
                  # This value wasn't provided by a variable or from the AST,
                  # it must have come from a default.
                  #
                  # TODO I think this will be wrong if it came from a nested provided value :confounded:
                  default_used = true
                end

                detailed_values[keyword] = ArgumentValue.new(
                  value: arg_value,
                  definition: arg_defn,
                  default_used: default_used,
                  ast_node: ast_arg,
                )
              end
            end

            detailed_values
          end
        end

        # A container for metadata regarding arguments present in a GraphQL query.
        # @see Arguments#argument_values for a hash of these objects.
        class ArgumentValue
          def initialize(definition:, value:, default_used:, ast_node:)
            @definition = definition
            @value = value
            @default_used = default_used
            @ast_node = ast_node
          end

          # @return [Object] The Ruby-ready value for this Argument
          attr_reader :value

          # @return [GraphQL::Schema::Argument] The definition instance for this argument
          attr_reader :definition

          # @return [Boolean] `true` if the schema-defined `default_value:` was applied in this case. (No client-provided value was present.)
          def default_used?
            @default_used
          end

          # If this argument is an input object (or a list of input objects),
          # return a detailed arguments object for it.
          #
          # Returns an array {Arguments} instances if the argument type is a list of input objects.
          #
          # Returns nil if the argument isn't an input object.
          # @return [Interpreter::Arguments, Array<Interpreter::Arguments>, nil]
          def arguments
            return @arguments if defined?(@arguments)
            arg_type = @definition.type.unwrap
            @arguments = if arg_type.kind.input_object?
              # This check is easier than determining `.list_type_at_all?` :eye_roll:
              if value.is_a?(Array)
                ast_value = @ast_node ? @ast_node.value : nil
                if ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
                  ast_value = nil
                end
                value.each_with_index.map { |v, idx|
                  v_node = ast_value ? ast_value[idx] : nil
                  Arguments.new(values: v, ast_node:v_node, owner: arg_type, query: @query)
                }
              else
                Arguments.new(values: value, ast_node: @ast_node, owner: arg_type, query: @query)
              end
            else
              nil
            end
          end
        end
      end
    end
  end
end
