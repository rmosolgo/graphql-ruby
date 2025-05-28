# frozen_string_literal: true
module GraphQL
  class Query
    # This class is _like_ a {GraphQL::Query}, except it can run on an arbitrary path within a query string.
    #
    # It depends on a "parent" {Query}.
    #
    # During execution, it calls query-related tracing hooks but passes itself as `query:`.
    #
    # The {Partial} will use your {Schema.resolve_type} hook to find the right GraphQL type to use for
    # `object` in some cases.
    #
    # @see Query#run_partials Run via {Query#run_partials}
    class Partial
      include Query::Runnable

      # @param path [Array<String, Integer>] A path in `query.query_string` to start executing from
      # @param object [Object] A starting object for execution
      # @param query [GraphQL::Query] A full query instance that this partial is based on. Caches are shared.
      # @param context [Hash] Extra context values to merge into `query.context`, if provided
      # @param fragment_node [GraphQL::Language::Nodes::InlineFragment, GraphQL::Language::Nodes::FragmentDefinition]
      def initialize(path: nil, object:, query:, context: nil, fragment_node: nil, type: nil)
        @path = path
        @object = object
        @query = query
        @schema = query.schema
        context_vals = @query.context.to_h
        if context
          context_vals = context_vals.merge(context)
        end
        @context = GraphQL::Query::Context.new(query: self, schema: @query.schema, values: context_vals)
        @multiplex = nil
        @result_values = nil
        @result = nil

        if fragment_node
          @ast_nodes = [fragment_node]
          @root_type = type || raise(ArgumentError, "Pass `type:` when using `node:`")
          # This is only used when `@leaf`
          @field_definition = nil
        elsif path.nil?
          raise ArgumentError, "`path:` is required if `node:` is not given; add `path:`"
        else
          set_type_info_from_path
        end

        @leaf = @root_type.unwrap.kind.leaf?
      end

      def leaf?
        @leaf
      end

      attr_reader :context, :query, :ast_nodes, :root_type, :object, :field_definition, :path, :schema

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

      def types
        @query.types
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

      def valid?
        @query.valid?
      end

      def analyzers
        EmptyObjects::EMPTY_ARRAY
      end

      def analysis_errors=(_ignored)
        # pass
      end

      def subscription?
        @query.subscription?
      end

      def selected_operation
        ast_nodes.first
      end

      def static_errors
        @query.static_errors
      end

      def selected_operation_name
        @query.selected_operation_name
      end

      private

      def set_type_info_from_path
        selections = [@query.selected_operation]
        type = @query.root_type
        parent_type = nil
        field_defn = nil

        @path.each do |name_in_doc|
          if name_in_doc.is_a?(Integer)
            if type.list?
              type = type.unwrap
              next
            else
              raise ArgumentError, "Received path with index `#{name_in_doc}`, but type wasn't a list. Type: #{type.to_type_signature}, path: #{@path}"
            end
          end

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
          field_defn = @schema.get_field(type, field_name, @query.context) || raise("Invariant: no field called #{field_name} on #{type.graphql_name}")
          parent_type = type
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
    end
  end
end
