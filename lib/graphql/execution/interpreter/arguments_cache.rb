# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class ArgumentsCache
        def initialize(query)
          @query = query
          @dataloader = query.context.dataloader
          @storage = Hash.new do |h, ast_node|
            h[ast_node] = Hash.new do |h2, arg_owner|
              h2[arg_owner] = Hash.new do |h3, parent_object|
                # First, normalize all AST or Ruby values to a plain Ruby hash
                args_hash = self.class.prepare_args_hash(@query, ast_node)
                # Then call into the schema to coerce those incoming values
                total_args_count = arg_owner.arguments.size
                if total_args_count == 0
                  h3[parent_object] = NO_ARGUMENTS
                else
                  resolved_args_count = 0
                  argument_values = {}
                  # TODO how to make sure calls into this cache _while the data is pending_
                  # work properly?
                  h3[parent_object] = argument_values

                  arg_owner.arguments.each do |arg_name, arg_defn|
                    @dataloader.append_job do
                      arg_defn.coerce_into_values(parent_object, args_hash, @query.context, argument_values)
                      resolved_args_count += 1
                      if resolved_args_count == total_args_count
                        kwarg_arguments = @query.schema.after_any_lazies(argument_values.values) {
                          GraphQL::Execution::Interpreter::Arguments.new(
                            argument_values: argument_values,
                          )
                        }

                        h3[parent_object] = @query.schema.after_lazy(kwarg_arguments) do |resolved_args|
                          # when this promise is resolved, update the cache with the resolved value
                          h3[parent_object] = resolved_args
                        end
                      end
                    end
                  end
                end

                h3[parent_object]
              end
            end
          end
        end

        def fetch(ast_node, argument_owner, parent_object)
          @storage[ast_node][argument_owner][parent_object]
          # If any jobs were enqueued, run them now,
          # since this might have been called outside of execution.
          # (The jobs are responsible for updating `result` in-place.)
          @dataloader.run
          # Ack, the _hash_ is updated, but the key is eventually
          # overridden with an immutable arguments instance.
          # The first call queues up the job,
          # then this call fetches the result.
          # TODO this should be better, find a solution
          # that works with merging the runtime.rb code
          @storage[ast_node][argument_owner][parent_object]
        end

        private

        NO_ARGUMENTS = {}.freeze

        NO_VALUE_GIVEN = Object.new

        def self.prepare_args_hash(query, ast_arg_or_hash_or_value)
          case ast_arg_or_hash_or_value
          when Hash
            if ast_arg_or_hash_or_value.empty?
              return NO_ARGUMENTS
            end
            args_hash = {}
            ast_arg_or_hash_or_value.each do |k, v|
              args_hash[k] = prepare_args_hash(query, v)
            end
            args_hash
          when Array
            ast_arg_or_hash_or_value.map { |v| prepare_args_hash(query, v) }
          when GraphQL::Language::Nodes::Field, GraphQL::Language::Nodes::InputObject, GraphQL::Language::Nodes::Directive
            if ast_arg_or_hash_or_value.arguments.empty?
              return NO_ARGUMENTS
            end
            args_hash = {}
            ast_arg_or_hash_or_value.arguments.each do |arg|
              v = prepare_args_hash(query, arg.value)
              if v != NO_VALUE_GIVEN
                args_hash[arg.name] = v
              end
            end
            args_hash
          when GraphQL::Language::Nodes::VariableIdentifier
            if query.variables.key?(ast_arg_or_hash_or_value.name)
              variable_value = query.variables[ast_arg_or_hash_or_value.name]
              prepare_args_hash(query, variable_value)
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
