# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class ArgumentsCache
        def initialize(query)
          @query = query
          @storage = Hash.new do |h, ast_node|
            h[ast_node] = Hash.new do |h2, arg_owner|
              h2[arg_owner] = Hash.new do |h3, parent_object|
                # First, normalize all AST or Ruby values to a plain Ruby hash
                args_hash = prepare_args_hash(ast_node)
                # Then call into the schema to coerce those incoming values
                args = arg_owner.coerce_arguments(parent_object, args_hash, query.context)

                h3[parent_object] = if args.is_a?(GraphQL::Execution::Lazy)
                  args.then { |resolved_args|
                    # when this promise is resolved, update the cache with the resolved value
                    h3[parent_object] = make_detailed_args(resolved_args, ast_node, arg_owner)
                  }
                else
                  make_detailed_args(args, ast_node, arg_owner)
                end
              end
            end
          end
        end

        def fetch(ast_node, argument_owner, parent_object)
          @storage[ast_node][argument_owner][parent_object]
        end

        private

        def make_detailed_args(args, ast_node, arg_owner)
          detailed_args = {}
          arg_owner.arguments.each do |name, defn|
            if !args.key?(defn.keyword)
              # There was neither a provided nor default value for this arg
              next
            end
            ast_arg = ast_node.arguments.find { |a| a.name == name }

            default_used = if ast_arg.nil?
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
            detailed_args[name] = {
              definition: defn,
              value: args[defn.keyword],
              default_used: default_used
            }
          end

          {
            simple: args,
            detailed: detailed_args
          }
        end

        NO_VALUE_GIVEN = Object.new

        def prepare_args_hash(ast_arg_or_hash_or_value)
          case ast_arg_or_hash_or_value
          when Hash
            args_hash = {}
            ast_arg_or_hash_or_value.each do |k, v|
              args_hash[k] = prepare_args_hash(v)
            end
            args_hash
          when Array
            ast_arg_or_hash_or_value.map { |v| prepare_args_hash(v) }
          when GraphQL::Language::Nodes::Field, GraphQL::Language::Nodes::InputObject, GraphQL::Language::Nodes::Directive
            args_hash = {}
            ast_arg_or_hash_or_value.arguments.each do |arg|
              v = prepare_args_hash(arg.value)
              if v != NO_VALUE_GIVEN
                args_hash[arg.name] = v
              end
            end
            args_hash
          when GraphQL::Language::Nodes::VariableIdentifier
            if @query.variables.key?(ast_arg_or_hash_or_value.name)
              variable_value = @query.variables[ast_arg_or_hash_or_value.name]
              prepare_args_hash(variable_value)
            else
              NO_VALUE_GIVEN
            end
          when GraphQL::Language::Nodes::Enum
            ast_arg_or_hash_or_value.name
          when GraphQL::Language::Nodes::NullValue
            nil
          else
            ast_arg_or_hash_or_value
          end
        end
      end
    end
  end
end
