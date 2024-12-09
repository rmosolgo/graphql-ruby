# frozen_string_literal: true
module GraphQL
  class Query
    # This class is _like_ a {GraphQL::Query}, except
    # @see Query#run_partials
    class Partial
      def initialize(path:, object:, query:)
        @path = path
        @object = object
        @query = query
        @context = GraphQL::Query::Context.new(query: self, schema: @query.schema, values: @query.context.to_h)
        @multiplex = nil
        @result_values = nil
        @result = nil
        selection = @query.selected_operation
        type = @query.schema.query # TODO could be other?
        @path.each do |name_in_doc|
          selection = selection.selections.find { |sel| sel.alias == name_in_doc || sel.name == name_in_doc }
          if !selection
            raise ArgumentError, "Path `#{@path.inspect}` is not present in this query. `#{name_in_doc.inspect}` was not found. Try a different path or rewrite the query to include it."
          end
          field_defn = type.get_field(selection.name, @query.context) || raise("Invariant: no field called #{selection.name.inspect} on #{type.graphql_name}")
          type = field_defn.type.unwrap
        end
        @selected_operation = selection
        @root_type = type
      end

      attr_reader :context, :selected_operation, :root_type

      attr_accessor :multiplex, :result_values

      def result
        @result ||= GraphQL::Query::Result.new(query: self, values: result_values)
      end

      def current_trace
        @query.current_trace
      end

      def schema
        @query.schema
      end

      def types
        @query.types
      end

      def root_value
        @object
      end

      # TODO dry with query
      def after_lazy(value, &block)
        if !defined?(@runtime_instance)
          @runtime_instance = context.namespace(:interpreter_runtime)[:runtime]
        end

        if @runtime_instance
          @runtime_instance.minimal_after_lazy(value, &block)
        else
          @schema.after_lazy(value, &block)
        end
      end

      # TODO dry with query
      def arguments_for(ast_node, definition, parent_object: nil)
        arguments_cache.fetch(ast_node, definition, parent_object)
      end

      # TODO dry with query
      def arguments_cache
        @arguments_cache ||= Execution::Interpreter::ArgumentsCache.new(self)
      end

      # TODO dry
      def handle_or_reraise(err)
        @query.schema.handle_or_reraise(context, err)
      end
    end
  end
end
