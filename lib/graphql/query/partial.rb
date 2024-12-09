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
        selections = [@query.selected_operation]
        type = @query.schema.query # TODO could be other?
        field_defn = nil
        @path.each do |name_in_doc|
          next_selections = []
          selections.each do |selection|
            selection.selections.each do |sel|
              if sel.alias == name_in_doc || sel.name == name_in_doc
                next_selections << sel
              end
            end
          end

          if next_selections.empty?
            raise ArgumentError, "Path `#{@path.inspect}` is not present in this query. `#{name_in_doc.inspect}` was not found. Try a different path or rewrite the query to include it."
          end
          field_name = next_selections.first.name
          field_defn = type.get_field(field_name, @query.context) || raise("Invariant: no field called #{field_name} on #{type.graphql_name}")
          type = field_defn.type
          if type.non_null?
            type = type.of_type
          end
          selections = next_selections
        end
        @ast_nodes = selections
        @root_type = type
        @field_definition = field_defn
      end

      attr_reader :context, :ast_nodes, :root_type, :object, :field_definition, :path

      attr_accessor :multiplex, :result_values

      class Result < GraphQL::Query::Result
        def path
          @query.path
        end
      end

      def result
        @result ||= Result.new(query: self, values: result_values)
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
