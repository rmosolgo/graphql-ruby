# frozen_string_literal: true
require "fiber"
require "graphql/execution/interpreter/argument_value"
require "graphql/execution/interpreter/arguments"
require "graphql/execution/interpreter/arguments_cache"
require "graphql/execution/interpreter/execution_errors"
require "graphql/execution/interpreter/hash_response"
require "graphql/execution/interpreter/runtime"
require "graphql/execution/interpreter/resolve"
require "graphql/execution/interpreter/handles_raw_value"

module GraphQL
  module Execution
    class Interpreter
      def initialize
      end

      # Support `Executor` :S
      def execute(_operation, _root_type, query)
        runtime = evaluate(query)
        sync_lazies(query: query)
        runtime.final_value
      end

      def self.use(schema_class)
        if schema_class.interpreter?
          definition_line = caller(2, 1).first
          GraphQL::Deprecation.warn("GraphQL::Execution::Interpreter is now the default; remove `use GraphQL::Execution::Interpreter` from the schema definition (#{definition_line})")
        else
          schema_class.query_execution_strategy(self)
          schema_class.mutation_execution_strategy(self)
          schema_class.subscription_execution_strategy(self)
          schema_class.add_subscription_extension_if_necessary
        end
      end

      def self.begin_multiplex(multiplex)
        # Since this is basically the batching context,
        # share it for a whole multiplex
        multiplex.context[:interpreter_instance] ||= self.new
      end

      def self.begin_query(query, multiplex)
        # The batching context is shared by the multiplex,
        # so fetch it out and use that instance.
        interpreter =
          query.context.namespace(:interpreter)[:interpreter_instance] =
          multiplex.context[:interpreter_instance]
        interpreter.evaluate(query)
        query
      end

      def self.finish_multiplex(_results, multiplex)
        interpreter = multiplex.context[:interpreter_instance]
        interpreter.sync_lazies(multiplex: multiplex)
      end

      def self.finish_query(query, _multiplex)
        {
          "data" => query.context.namespace(:interpreter)[:runtime].final_value
        }
      end

      # Run the eager part of `query`
      # @return {Interpreter::Runtime}
      def evaluate(query)
        # Although queries in a multiplex _share_ an Interpreter instance,
        # they also have another item of state, which is private to that query
        # in particular, assign it here:
        runtime = Runtime.new(
          query: query,
          response: HashResponse.new,
        )
        query.context.namespace(:interpreter)[:runtime] = runtime

        query.trace("execute_query", {query: query}) do
          runtime.run_eager
        end

        runtime
      end

      # Run the lazy part of `query` or `multiplex`.
      # @return [void]
      def sync_lazies(query: nil, multiplex: nil)
        tracer = query || multiplex
        if query.nil? && multiplex.queries.length == 1
          query = multiplex.queries[0]
        end
        queries = multiplex ? multiplex.queries : [query]
        final_values = queries.map do |query|
          runtime = query.context.namespace(:interpreter)[:runtime]
          # it might not be present if the query has an error
          runtime ? runtime.final_value : nil
        end
        final_values.compact!
        tracer.trace("execute_query_lazy", {multiplex: multiplex, query: query}) do
          Interpreter::Resolve.resolve_all(final_values, multiplex.dataloader)
        end
        queries.each do |query|
          runtime = query.context.namespace(:interpreter)[:runtime]
          if runtime
            runtime.delete_interpreter_context(:current_path)
            runtime.delete_interpreter_context(:current_field)
            runtime.delete_interpreter_context(:current_object)
            runtime.delete_interpreter_context(:current_arguments)
          end
        end
        nil
      end

      class ListResultFailedError < GraphQL::Error
        def initialize(value:, path:, field:)
          message = "Failed to build a GraphQL list result for field `#{field.path}` at path `#{path.join(".")}`.\n".dup

          message << "Expected `#{value.inspect}` (#{value.class}) to implement `.each` to satisfy the GraphQL return type `#{field.type.to_type_signature}`.\n"

          if field.connection?
            message << "\nThis field was treated as a Relay-style connection; add `connection: false` to the `field(...)` to disable this behavior."
          end
          super(message)
        end
      end
    end
  end
end
