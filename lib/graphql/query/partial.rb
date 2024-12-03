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
      end

      attr_reader :context

      attr_accessor :multiplex, :result_values

      def result
        @result ||= GraphQL::Query::Result.new(query: self, values: result_values)
      end

      def valid?
        true
      end

      def analyzers
        EmptyObjects::EMPTY_ARRAY
      end

      def current_trace
        @query.current_trace
      end

      def analysis_errors=(_errs)
      end

      def subscription?
        false
      end

      def selected_operation
        selection = @query.selected_operation
        @path.each do |name_in_doc|
          selection = selection.selections.find { |sel| sel.alias == name_in_doc || sel.name == name_in_doc }
        end
        selection
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

      def root_type
        # Eventually do the traversal upstream of here, processing the group of partials together.
        selection = @query.selected_operation
        type = @query.schema.query # TODO could be other?
        @path.each do |name_in_doc|
          selection = selection.selections.find { |sel| sel.alias == name_in_doc || sel.name == name_in_doc }
          field_defn = type.get_field(selection.name, @query.context) || raise("Invariant: no field called #{selection.name.inspect} on #{type.graphql_name}")
          type = field_defn.type.unwrap
        end
        type
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
    end
  end
end
