# frozen_string_literal: true
module GraphQL
  class Query
    # This class is _like_ a {GraphQL::Query}, except
    # @see Query#run_partials
    class Partial
      def initialize(path:, object:, query:, context: nil)
        @path = path
        @object = object
        @query = query
        context_vals = @query.context.to_h
        if context
          context_vals = context_vals.merge(context)
        end
        @context = GraphQL::Query::Context.new(query: self, schema: @query.schema, values: context_vals)
        @multiplex = nil
        @result_values = nil
        @result = nil
        selections = [@query.selected_operation]
        type = @query.schema.query # TODO could be other?
        parent_type = nil
        field_defn = nil
        @path.each do |name_in_doc|
          next_selections = []
          selections.each do |selection|
            selections_to_check = []
            selections_to_check.concat(selection.selections)
            while (sel = selections_to_check.shift)
              case sel
              when GraphQL::Language::Nodes::InlineFragment
                selections_to_check.concat(sel.selections)
              when GraphQL::Language::Nodes::FragmentSpread
                fragment = @query.fragments[sel.name]
                selections_to_check.concat(fragment.selections)
              when GraphQL::Language::Nodes::Field
                if sel.alias == name_in_doc || sel.name == name_in_doc
                  next_selections << sel
                end
              else
                raise "Unexpected selection in partial path: #{sel.class}, #{sel.inspect}"
              end
            end
          end

          if next_selections.empty?
            raise ArgumentError, "Path `#{@path.inspect}` is not present in this query. `#{name_in_doc.inspect}` was not found. Try a different path or rewrite the query to include it."
          end
          field_name = next_selections.first.name
          field_defn = type.get_field(field_name, @query.context) || raise("Invariant: no field called #{field_name} on #{type.graphql_name}")
          parent_type = type
          type = field_defn.type
          if type.non_null?
            type = type.of_type
          end
          selections = next_selections
        end
        @parent_type = parent_type
        @ast_nodes = selections
        @root_type = type
        @field_definition = field_defn
        @leaf = @root_type.unwrap.kind.leaf?
      end

      def leaf?
        @leaf
      end

      attr_reader :context, :query, :ast_nodes, :root_type, :object, :field_definition, :path, :parent_type

      attr_accessor :multiplex, :result_values

      class Result < GraphQL::Query::Result
        def path
          @query.path
        end

        # @return [GraphQL::Query::Partial]
        def partial
          @query
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

      def resolve_type(...)
        @query.resolve_type(...)
      end

      def variables
        @query.variables
      end

      def fragments
        @query.fragments
      end
    end
  end
end
